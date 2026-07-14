#!/usr/bin/env pwsh
# ============================================
# AI 旅行账本 - 云端版构建便捷脚本 (V1.2+)
# ============================================
#
# 等价于:
#   $env:SUPABASE_URL = "https://zvqnawllsdmisntkxdwp.supabase.co"
#   $env:SUPABASE_ANON_KEY = "eyJ..."
#   pwsh scripts\build-apk.ps1 -WithSupabase
#
# 用法:
#   # 方式 1: 环境变量 (一次性, 推荐用于 CI)
#   $env:SUPABASE_ANON_KEY = "eyJ..."
#   pwsh scripts\build-cloud.ps1
#
#   # 方式 2: 读取 secrets 文件 (推荐本地开发)
#   # 把 anon key 写到项目根 .secrets\cloud-key.txt (一键忽略)
#   pwsh scripts\build-cloud.ps1
#
#   # 方式 3: 直接调用 (快捷)
#   pwsh scripts\build-cloud.ps1 -Key "eyJ..."
#
# 输出: release\ai-travel-ledger-vX.Y.Z+NN-cloud.apk
# ============================================

param(
    [string]$Key = $null
)

$ErrorActionPreference = 'Stop'

# ===== URL 写死 (项目已知, 开发者维护) =====
$env:SUPABASE_URL = "https://zvqnawllsdmisntkxdwp.supabase.co"

# ===== Key 来源优先级 =====
# 1. -Key 参数
# 2. $env:SUPABASE_ANON_KEY
# 3. .secrets\cloud-key.txt 文件 (gitignore'd)
if (-not $Key -and $env:SUPABASE_ANON_KEY) {
    $Key = $env:SUPABASE_ANON_KEY
}

if (-not $Key) {
    $secretFile = Join-Path (Split-Path -Parent $PSScriptRoot) ".secrets\cloud-key.txt"
    if (Test-Path $secretFile) {
        $Key = (Get-Content $secretFile -Raw).Trim()
    }
}

if (-not $Key) {
    Write-Host "❌ 找不到 Supabase anon key" -ForegroundColor Red
    Write-Host ""
    Write-Host "提供方式 (任选一个):" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [A] 直接传入:  pwsh scripts\build-cloud.ps1 -Key `"eyJ...`"" -ForegroundColor Cyan
    Write-Host "  [B] 环境变量:  `$env:SUPABASE_ANON_KEY = `"eyJ...`"; pwsh scripts\build-cloud.ps1" -ForegroundColor Cyan
    Write-Host "  [C] Secret文件: 创建 .secrets\cloud-key.txt, 把 key 写进去 (gitignore'd)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "获取 key: https://supabase.com/dashboard/project/zvqnawllsdmisntkxdwp/settings/api" -ForegroundColor Cyan
    Write-Host "         → Project API keys → anon / public 📋" -ForegroundColor Cyan
    exit 1
}

$env:SUPABASE_ANON_KEY = $Key

# ===== 调用统一 build 脚本 =====
& (Join-Path $PSScriptRoot 'build-apk.ps1') -WithSupabase @args
