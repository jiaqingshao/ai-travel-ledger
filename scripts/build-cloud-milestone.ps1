#!/usr/bin/env pwsh
# ============================================
# AI 旅行账本 - Cloud Milestone 构建脚本 (V1.2)
# ============================================
#
# 给 cloud 版本打一个特殊里程碑徽章（在 About 页面显示 🏆），
# 让分发时一眼能识别"这是值得用户优先测试的版本"。
#
# 用法:
#   pwsh scripts\build-cloud-milestone.ps1
#
# 输出: release\ai-travel-ledger-vX.Y.Z+NN-cloud-milestone.apk
#
# Milestone 字段注入说明 (lib\config\build_milestone.dart):
#   BUILD_MILESTONE_TAG    = "🏆 Cloud Milestone"
#   BUILD_MILESTONE_ID     = "cloud-v1.2"
#   BUILD_MILESTONE_TITLE  = "首个云端同步版本"
#   BUILD_MILESTONE_SUBTITLE = "原生集成 Supabase 云同步，零配置即可多设备共享..."
#   BUILD_MILESTONE_DATE   = "2026-07-14"
#
# 内部: 调用 scripts\build-cloud.ps1（其内部调用 build-apk.ps1 -WithSupabase）
# ============================================

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
Set-Location $ProjectRoot

# ===== Milestone 元数据 =====
$env:BUILD_MILESTONE_TAG = "🏆 Cloud Milestone"
$env:BUILD_MILESTONE_ID  = "cloud-v1.2"
$env:BUILD_MILESTONE_TITLE = "首个云端同步版本"
$env:BUILD_MILESTONE_SUBTITLE = "原生集成 Supabase 云同步：零配置安装即可注册账号、多设备数据同步、Sentry 级联 RLS 保护。标志着 AI 旅行账本从纯本地工具升级为云端协作工具。"
$env:BUILD_MILESTONE_DATE = "2026-07-14"

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  🏆 Cloud Milestone Build" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Tag:       $env:BUILD_MILESTONE_TAG" -ForegroundColor Yellow
Write-Host "ID:        $env:BUILD_MILESTONE_ID" -ForegroundColor Yellow
Write-Host "Title:     $env:BUILD_MILESTONE_TITLE" -ForegroundColor Yellow
Write-Host "Date:      $env:BUILD_MILESTONE_DATE" -ForegroundColor Yellow
Write-Host ""

# ===== 调用 build-cloud.ps1 (它再调用 build-apk.ps1 -WithSupabase) =====
# 强制本地重新构建 + 注入 milestone env vars
# 注意: 不通过 SUPABASE_URL/SUPABASE_ANON_KEY 暴露敏感，依赖 .secrets\cloud-key.txt

$buildCloudScript = Join-Path $ScriptDir 'build-cloud.ps1'
if (-not (Test-Path $buildCloudScript)) {
    Write-Host "❌ 找不到 scripts\build-cloud.ps1" -ForegroundColor Red
    exit 1
}

# 调用并继承所有 milestone env vars
Write-Host "=== 调用 build-cloud.ps1 ===" -ForegroundColor Cyan
Write-Host ""
& $buildCloudScript @args
$exitCode = $LASTEXITCODE

if ($exitCode -ne 0) {
    Write-Host "❌ Build 失败 exit=$exitCode" -ForegroundColor Red
    exit $exitCode
}

# ===== Rename 输出 APK 为 milestone 标识 =====
$srcApk = Join-Path $ProjectRoot "release\v1.2.0+0-cloud\ai-travel-ledger-v1.2.0+0-cloud.apk"
if (-not (Test-Path $srcApk)) {
    Write-Host "❌ 找不到源 APK: $srcApk" -ForegroundColor Red
    exit 1
}

$milestoneDir = Join-Path $ProjectRoot "release\v1.2.0+0-cloud-milestone"
New-Item -ItemType Directory -Force -Path $milestoneDir | Out-Null

$dstApk = Join-Path $milestoneDir "ai-travel-ledger-v1.2.0+0-cloud-milestone.apk"
Copy-Item $srcApk $dstApk -Force

$sha1 = (Get-FileHash $dstApk -Algorithm SHA1).Hash.ToLower()
$sha1 | Out-File "$dstApk.sha1" -Encoding ASCII

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "  🏆 Milestone APK 完成!" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
Write-Host "APK:       $dstApk" -ForegroundColor Cyan
Write-Host "Size:      $([math]::Round((Get-Item $dstApk).Length / 1MB, 2)) MB" -ForegroundColor Cyan
Write-Host "SHA1:      $sha1" -ForegroundColor Cyan
Write-Host ""

# ===== 复制到 NAS 真机目录 =====
$nasDir = "\\192.168.1.170\学习\开发"
if (Test-Path $nasDir) {
    try {
        Copy-Item $dstApk $nasDir -Force
        Copy-Item "$dstApk.sha1" $nasDir -Force -ErrorAction SilentlyContinue
        $nasApk = Join-Path $nasDir (Split-Path $dstApk -Leaf)
        Write-Host "NAS APK:   $nasApk" -ForegroundColor Cyan
        Write-Host ""
    } catch {
        Write-Host "⚠️  NAS 复制失败: $_" -ForegroundColor Yellow
    }
}

Write-Host "安装后特性：" -ForegroundColor Yellow
Write-Host "  - About 页面顶部出现 🏆 金棕色徽章 + 云端同步简介" -ForegroundColor White
Write-Host "  - launcher app 名: 'AI 旅行账本 · 云'" -ForegroundColor White
Write-Host "  - 零配置云模式已就绪" -ForegroundColor White
Write-Host ""
