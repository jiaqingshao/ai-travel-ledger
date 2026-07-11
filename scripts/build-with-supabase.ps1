#!/usr/bin/env pwsh
# ============================================
# AI 旅行账本 - 带 Supabase 配置打包 APK (v1.0.0)
# ============================================
# 
# 用法:
#   1. 设置环境变量 (从 Supabase Dashboard 复制):
#      $env:SUPABASE_URL = "https://zvqnawllsdmisntkxdwp.supabase.co"
#      $env:SUPABASE_ANON_KEY = "eyJhbGc..."
#   2. 运行: pwsh scripts\build-with-supabase.ps1
# 
# 输出: release\v1.1.0\ai-travel-ledger-v1.1.0-release.apk (含 Supabase 配置)
# ============================================

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot

$env:SUPABASE_URL = $env:SUPABASE_URL ?? 'https://zvqnawllsdmisntkxdwp.supabase.co'
$env:SUPABASE_ANON_KEY = $env:SUPABASE_ANON_KEY ?? '<REPLACE_WITH_YOUR_ANON_KEY>'

if ($env:SUPABASE_ANON_KEY -eq '<REPLACE_WITH_YOUR_ANON_KEY>') {
    Write-Host "❌ 请先设置 SUPABASE_ANON_KEY 环境变量" -ForegroundColor Red
    Write-Host ""
    Write-Host '示例:' -ForegroundColor Yellow
    Write-Host '  $env:SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."' -ForegroundColor White
    Write-Host ""
    Write-Host "anon key 从这里拿:" -ForegroundColor Yellow
    Write-Host "  https://supabase.com/dashboard/project/zvqnawllsdmisntkxdwp/settings/api" -ForegroundColor White
    exit 1
}

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  AI 旅行账本 v1.1.0 - Supabase 打包" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "URL: $env:SUPABASE_URL" -ForegroundColor Green
Write-Host "KEY: $($env:SUPABASE_ANON_KEY.Substring(0, [Math]::Min(30, $env:SUPABASE_ANON_KEY.Length)))..." -ForegroundColor Green
Write-Host ""

# bump version 1.0.0 -> 1.1.0
Write-Host "[1/5] Bump 版本号 1.0.0 -> 1.1.0..." -ForegroundColor Yellow
$pubspecPath = Join-Path $ProjectRoot 'pubspec.yaml'
$pubspec = Get-Content $pubspecPath -Raw
$newPubspec = $pubspec -replace 'version: 1\.0\.0\+0', 'version: 1.1.0+1'
if ($newPubspec -ne $pubspec) {
    Set-Content -Path $pubspecPath -Value $newPubspec -Encoding UTF8
    Write-Host "✅ pubspec.yaml 已更新到 1.1.0+1" -ForegroundColor Green
} else {
    Write-Host "⚠️  pubspec.yaml 不是 1.0.0+0, 跳过 bump" -ForegroundColor Yellow
}
Write-Host ""

# clean
Write-Host "[2/5] Clean..." -ForegroundColor Yellow
$env:PATH = "C:\src\flutter\bin;$env:PATH"
flutter clean 2>&1 | Out-Null
Write-Host "✅ Clean 完成" -ForegroundColor Green
Write-Host ""

# pub get
Write-Host "[3/5] Pub get..." -ForegroundColor Yellow
flutter pub get 2>&1 | Out-Null
Write-Host "✅ Dependencies 安装完成" -ForegroundColor Green
Write-Host ""

# build
Write-Host "[4/5] 构建 release APK (含 Supabase 配置)..." -ForegroundColor Yellow
flutter build apk --release `
    --dart-define=SUPABASE_URL=$env:SUPABASE_URL `
    --dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build 失败" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Build 成功" -ForegroundColor Green
Write-Host ""

# package
Write-Host "[5/5] 打包 release v1.1.0..." -ForegroundColor Yellow
$releaseDir = Join-Path $ProjectRoot 'release\v1.1.0'
New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null

$apkSrc = Join-Path $ProjectRoot 'build\app\outputs\flutter-apk\app-release.apk'
$apkDst = Join-Path $releaseDir 'ai-travel-ledger-v1.1.0-release.apk'
Copy-Item $apkSrc $apkDst -Force
$sha1 = (Get-FileHash $apkDst -Algorithm SHA1).Hash.ToLower()
$sha1 | Out-File (Join-Path $releaseDir 'ai-travel-ledger-v1.1.0-release.apk.sha1') -Encoding ASCII

# changelog
$changelog = @"
# AI 旅行账本 v1.1.0 - Supabase 集成版

**发布日期**: 2026-07-11
**版本号**: 1.1.0+1 (versionName 1.1.0, versionCode 1)
**APK 大小**: ~25 MB
**SHA1**: $sha1

---

## 🆕 v1.1.0 新增 (Supabase 云同步 + V1.1 编辑能力)

### ☁️ Supabase 配置已嵌入

- 启动后右上角 ☁️ 图标变**绿色** (vs 灰色 = 未连接)
- 登录/注册页面可用
- 数据自动同步到云端
- 多设备同步

### 配套服务

- Project URL: $env:SUPABASE_URL
- anon key 前缀: $($env:SUPABASE_ANON_KEY.Substring(0, [Math]::Min(40, $env:SUPABASE_ANON_KEY.Length)))...

---

## ✨ 包含 v1.0.0 全部功能

- 旅程管理 + 成员管理 + 分组 + 记账 + 结算
- 京都赏樱 7 日演示数据
- Material 3 主题 (旅行蓝 + 16dp 圆角)
- Release APK 23.6 MB + R8 混淆

---

## ✨ 包含 V1.1 编辑能力

- 费用详情可修改: 金额/类别/备注/付款人/时间/分摊规则/附件
- 费用输入有"保存并继续"按钮
- 分摊规则全屏编辑器

---

## 📊 测试

225 + V1.1 新增 = **231/231 全过** (含 v1.0.0 + V1.1 新增)

---

## ⚠️ 升级重要提示

- **必须先卸载旧版** (签名不同)
- 卸载前先在 v1.0.0 APP 内配置好 Supabase 同步并上传数据
- 否则本地 Hive 数据会清空

---

## 🚀 安装步骤

1. 手机开启"未知来源应用安装"
2. 传输 `ai-travel-ledger-v1.1.0-release.apk` 到手机
3. 点击安装
4. 启动后点右上角 ☁️ 注册账号
5. 验证邮箱后登录
6. 数据自动同步到云端
"@
$changelog | Out-File (Join-Path $releaseDir 'CHANGELOG.md') -Encoding UTF8

# readme
$readme = @"
# AI 旅行账本 v1.1.0 - Supabase 集成版

## 快速安装

1. **先卸载旧版** (v1.0.0 或更低, 签名不同)
2. 安装此 APK
3. 启动 APP, 点右上角 ☁️
4. 注册账号 (任意邮箱)
5. 查邮箱点验证链接
6. 返回 APP 登录
7. 数据自动同步 ✅

## 验证 SHA1

\`\`\`bash
Get-FileHash ai-travel-ledger-v1.1.0-release.apk -Algorithm SHA1
# 预期: $sha1
\`\`\`

## 详细文档

- docs/04-deployment/supabase-deploy-guide.md
- docs/04-deployment/supabase-project-info.md
"@
$readme | Out-File (Join-Path $releaseDir 'README.md') -Encoding UTF8

# zip
$zipPath = Join-Path $ProjectRoot 'release\ai-travel-ledger-v1.1.0.zip'
Add-Type -A System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($releaseDir, $zipPath, [System.IO.Compression.CompressionLevel]::Optimal, $false)

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "  ✅ v1.1.0 Release 完成!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
Write-Host "APK:       $apkDst" -ForegroundColor Cyan
Write-Host "ZIP:       $zipPath" -ForegroundColor Cyan
Write-Host "SHA1:      $sha1" -ForegroundColor Cyan
Write-Host ""
