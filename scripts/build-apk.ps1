#!/usr/bin/env pwsh
# ============================================
# AI 旅行账本 - Release APK 构建脚本 (统一版)
# ============================================
#
# 用法:
#   pwsh scripts\build-apk.ps1                  # 自动检测 (默认本地模式)
#   pwsh scripts\build-apk.ps1 -Local           # 强制本地模式（不接 Supabase）
#   pwsh scripts\build-apk.ps1 -WithSupabase    # 强制 Supabase 模式
#
# Supabase 模式:
#   1. 设置环境变量:
#      $env:SUPABASE_URL = "https://xxx.supabase.co"
#      $env:SUPABASE_ANON_KEY = "eyJ..."
#   2. 运行: pwsh scripts\build-apk.ps1 -WithSupabase
#
# 输出: release\ai-travel-ledger-vX.Y.Z+NN-{local|cloud}.apk
#
# ============================================

param(
    [switch]$Local = $false,
    [switch]$WithSupabase = $false,
    [string]$OutputDir = $null
)

$ErrorActionPreference = 'Stop'

# 路径
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
Set-Location $ProjectRoot

# ===== 模式检测 =====
if (-not $Local -and -not $WithSupabase) {
    # 未指定 → 看环境变量
    $hasUrl = $env:SUPABASE_URL -and $env:SUPABASE_URL.Trim().Length -gt 0
    $hasKey = $env:SUPABASE_ANON_KEY -and $env:SUPABASE_ANON_KEY.Trim().Length -gt 0
    if ($hasUrl -and $hasKey) {
        $WithSupabase = $true
    } else {
        $Local = $true
    }
}

# ===== pubspec 版本读取 =====
$pubspecPath = Join-Path $ProjectRoot 'pubspec.yaml'
$pubspecContent = Get-Content $pubspecPath -Raw
if ($pubspecContent -match 'version:\s*(\d+\.\d+\.\d+)\+(\d+)') {
    $versionName = $Matches[1]
    $versionCode = $Matches[2]
} else {
    Write-Host "❌ 无法从 pubspec.yaml 读取版本号" -ForegroundColor Red
    exit 1
}

# ===== 构建 dart-define 参数 =====
$dartDefines = @()
if ($WithSupabase) {
    if (-not $env:SUPABASE_URL -or -not $env:SUPABASE_ANON_KEY) {
        Write-Host "❌ Supabase 模式需要 SUPABASE_URL 和 SUPABASE_ANON_KEY 环境变量" -ForegroundColor Red
        Write-Host "   $env:SUPABASE_URL = $env:SUPABASE_URL" -ForegroundColor Yellow
        Write-Host "   $env:SUPABASE_ANON_KEY = $($env:SUPABASE_ANON_KEY.Substring(0, [Math]::Min(20, $env:SUPABASE_ANON_KEY.Length)))..." -ForegroundColor Yellow
        exit 1
    }
    $dartDefines += "--dart-define=SUPABASE_URL=$env:SUPABASE_URL"
    $dartDefines += "--dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY"
    $modeTag = "cloud"
    $modeDesc = "☁️  Supabase: ENABLED ($env:SUPABASE_URL)"
    $modeColor = "Green"
} else {
    # 本地模式：不传 SUPABASE_URL/KEY，isConfigured 会返回 false → 纯本地运行
    $modeTag = "local"
    $modeDesc = "📱 Supabase: DISABLED (local-only)"
    $modeColor = "Yellow"
}

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  AI 旅行账本 v$versionName+$versionCode - 构建 APK" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host $modeDesc -ForegroundColor $modeColor
Write-Host ""

# ===== Clean =====
Write-Host "[1/5] Clean..." -ForegroundColor Yellow
$env:PATH = "C:\src\flutter\bin;$env:PATH"
flutter clean 2>&1 | Out-Null
Write-Host "✅ Clean 完成" -ForegroundColor Green
Write-Host ""

# ===== Pub get =====
Write-Host "[2/5] Pub get..." -ForegroundColor Yellow
flutter pub get 2>&1 | Out-Null
Write-Host "✅ Dependencies 安装完成" -ForegroundColor Green
Write-Host ""

# ===== Build =====
Write-Host "[3/5] 构建 release APK..." -ForegroundColor Yellow
$buildArgs = @('build', 'apk', '--release') + $dartDefines
flutter @buildArgs
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build 失败" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Build 成功" -ForegroundColor Green
Write-Host ""

# ===== Package =====
Write-Host "[4/5] 打包 release v$versionName ($modeTag)..." -ForegroundColor Yellow
if ($OutputDir) {
    $releaseDir = $OutputDir
} else {
    $releaseDir = Join-Path $ProjectRoot "release\v$versionName-$modeTag"
}
New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null

$apkSrc = Join-Path $ProjectRoot 'build\app\outputs\flutter-apk\app-release.apk'
$apkDst = Join-Path $releaseDir "ai-travel-ledger-v$versionName-$modeTag.apk"
Copy-Item $apkSrc $apkDst -Force

$sha1 = (Get-FileHash $apkDst -Algorithm SHA1).Hash.ToLower()
$sha1 | Out-File (Join-Path $releaseDir "ai-travel-ledger-v$versionName-$modeTag.apk.sha1") -Encoding ASCII
Write-Host "✅ APK: $apkDst" -ForegroundColor Green
Write-Host "   SHA1: $sha1" -ForegroundColor Cyan
Write-Host "   大小: $([math]::Round((Get-Item $apkDst).Length / 1MB, 2)) MB" -ForegroundColor Cyan
Write-Host ""

# ===== CHANGELOG =====
Write-Host "[5/5] 生成 CHANGELOG + README..." -ForegroundColor Yellow

$modeFeatures = if ($WithSupabase) {
    @"

### ☁️ Supabase 云同步已启用

- 右上角 ☁️ 图标变**绿色** (vs 灰色 = 未连接)
- 登录/注册页面可用
- 数据自动同步到云端
- 多设备同步

### 配套服务

- Project URL: $env:SUPABASE_URL
- anon key 前缀: $($env:SUPABASE_ANON_KEY.Substring(0, [Math]::Min(40, $env:SUPABASE_ANON_KEY.Length)))...
"@
} else {
    @"

### 📱 本地模式 (无云同步)

- 右上角 ☁️ 图标保持**灰色** (未连接 Supabase)
- 数据存储在本地 Hive
- 卸载 APP = 数据清空 (建议配合备份或升级到 Supabase 版本)
- 不依赖网络, 完全离线可用
"@
}

$changelog = @"
# AI 旅行账本 v$versionName - $modeTag 模式

**发布日期**: $(Get-Date -Format 'yyyy-MM-dd')
**版本号**: $versionName+$versionCode (versionName $versionName, versionCode $versionCode)
**模式**: $modeTag
**APK 大小**: $([math]::Round((Get-Item $apkDst).Length / 1MB, 2)) MB
**SHA1**: $sha1

---

$modeFeatures

---

## ✨ 包含 V1.1 编辑能力 (v0.2.0)

- **SplitRuleEditPage**: 分摊规则全屏编辑器 (5 种分摊模式)
- **费用详情编辑**: 金额/类别/备注/付款人/时间/分摊规则/附件 全部可改
- **保存并继续按钮**: 费用录入流优化 (ISSUE-023-RECONFIRM 修复)
- **键盘遮挡修复**: TextField 加 scrollPadding=200 (ISSUE-022)
- **登录友好提示**: 邮箱未验证有专门提示 (ISSUE-021)
- **结算空状态**: 0 成员旅程有 EmptyView (ISSUE-020)

---

## 📊 测试

228/228 全过 (含 V1.1 新增 3 个)

---

## 🚀 安装步骤

1. 手机开启"未知来源应用安装"
2. 传输 APK 到手机
3. **必须先卸载旧版** (新 keystore 签名不同)
4. 点击安装
5. $(if ($WithSupabase) { "启动后点右上角 ☁️ 注册账号" } else { "直接使用 (本地模式, 无需账号)" })

---

## ⚠️ 升级重要提示

- **必须先卸载旧版** (签名不同, 否则装不上)
- $(if ($WithSupabase) { "卸载前先在旧版 APP 内配置好 Supabase 同步并上传数据" } else { "本地模式: 卸载前请确认不需要保留本地数据" })
"@
$changelog | Out-File (Join-Path $releaseDir 'CHANGELOG.md') -Encoding UTF8

$readme = @"
# AI 旅行账本 v$versionName - $modeTag 模式

## 快速安装

1. **先卸载旧版** (签名不同)
2. 安装此 APK
3. $(if ($WithSupabase) { "启动 APP, 点右上角 ☁️" } else { "启动 APP, 直接使用" })
$(if ($WithSupabase) { "4. 注册账号 (任意邮箱)" } else { "" })
$(if ($WithSupabase) { "5. 查邮箱点验证链接" } else { "" })
$(if ($WithSupabase) { "6. 返回 APP 登录" } else { "" })
$(if ($WithSupabase) { "7. 数据自动同步 ✅" } else { "" })

## 验证 SHA1

\`\`\`powershell
Get-FileHash ai-travel-ledger-v$versionName-$modeTag.apk -Algorithm SHA1
# 预期: $sha1
\`\`\`

## 详细文档

- docs/04-deployment/supabase-deploy-guide.md
- docs/04-deployment/supabase-project-info.md
"@
$readme | Out-File (Join-Path $releaseDir 'README.md') -Encoding UTF8

# zip
$zipPath = Join-Path $ProjectRoot "release\ai-travel-ledger-v$versionName-$modeTag.zip"
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Add-Type -A System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($releaseDir, $zipPath, [System.IO.Compression.CompressionLevel]::Optimal, $false)

# ===== [6/6] 自动复制到 NAS 真机获取目录 =====
# 需求 (2026-07-11): 今后生成的 APK 自动拷贝一份到 NAS, 便于真机直接获取
# NAS 路径可被局域网真机直接访问, 无需中转
Write-Host "[6/6] 复制到 NAS 真机目录..." -ForegroundColor Yellow
$nasDir = "\\192.168.1.170\学习\开发"
if (Test-Path $nasDir) {
    try {
        Copy-Item $apkDst $nasDir -Force
        Copy-Item "$apkDst.sha1" $nasDir -Force -ErrorAction SilentlyContinue
        $nasApk = Join-Path $nasDir (Split-Path $apkDst -Leaf)
        Write-Host "✅ 已复制到 $nasApk" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  NAS 复制失败: $_" -ForegroundColor Yellow
        Write-Host "   可手动复制: $apkDst -> $nasDir" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  NAS 路径不可达: $nasDir" -ForegroundColor Yellow
    Write-Host "   可手动复制: $apkDst -> $nasDir" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "=========================================" -ForegroundColor Green
Write-Host "  ✅ v$versionName-$modeTag Release 完成!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
Write-Host "APK:       $apkDst" -ForegroundColor Cyan
Write-Host "NAS APK:   $(Join-Path $nasDir (Split-Path $apkDst -Leaf))" -ForegroundColor Cyan
Write-Host "ZIP:       $zipPath" -ForegroundColor Cyan
Write-Host "SHA1:      $sha1" -ForegroundColor Cyan
Write-Host ""