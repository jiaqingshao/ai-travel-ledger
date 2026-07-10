#!/usr/bin/env pwsh
# ============================================
# AI 旅行账本 - Supabase 启动脚本 (v0.2.0)
# ============================================
# 
# 用法:
#   1. 复制此脚本到 scripts\run-with-supabase.ps1
#   2. 填入 SUPABASE_URL 和 SUPABASE_ANON_KEY (从 Supabase Dashboard 复制)
#   3. 在项目根目录运行: pwsh scripts\run-with-supabase.ps1
# 
# 或者:
#   1. 设置环境变量:
#      $env:SUPABASE_URL = "https://xxx.supabase.co"
#      $env:SUPABASE_ANON_KEY = "eyJ..."
#   2. flutter run --dart-define=SUPABASE_URL=$env:SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY
# 
# ============================================

$ErrorActionPreference = 'Stop'

# 优先从环境变量读，没有再硬编码（用户填）
$env:SUPABASE_URL = $env:SUPABASE_URL ?? 'https://zvqnawllsdmisntkxdwp.supabase.co'
$env:SUPABASE_ANON_KEY = $env:SUPABASE_ANON_KEY ?? '<REPLACE_WITH_YOUR_ANON_KEY>'

# 检查 anon key 是否还是占位符
if ($env:SUPABASE_ANON_KEY -eq '<REPLACE_WITH_YOUR_ANON_KEY>') {
    Write-Host "❌ 请先设置 SUPABASE_ANON_KEY 环境变量" -ForegroundColor Red
    Write-Host ""
    Write-Host "方法 A: 在 PowerShell 设置:" -ForegroundColor Yellow
    Write-Host '  $env:SUPABASE_ANON_KEY = "eyJhbGciOi..."' -ForegroundColor White
    Write-Host ""
    Write-Host "方法 B: 直接修改本脚本第 23 行" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "anon key 在 Supabase Dashboard 获取:" -ForegroundColor Yellow
    Write-Host "  https://supabase.com/dashboard/project/zvqnawllsdmisntkxdwp/settings/api" -ForegroundColor White
    exit 1
}

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  AI 旅行账本 - Supabase 启动" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "URL: $env:SUPABASE_URL" -ForegroundColor Green
Write-Host "KEY: $($env:SUPABASE_ANON_KEY.Substring(0, [Math]::Min(30, $env:SUPABASE_ANON_KEY.Length)))..." -ForegroundColor Green
Write-Host ""

# 验证 supabase 项目可达
Write-Host "[1/3] 验证 Supabase 项目..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$env:SUPABASE_URL/auth/v1/health" -Method GET -TimeoutSec 10 -ErrorAction Stop
    Write-Host "✅ Supabase 项目可达 (HTTP $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "❌ Supabase 项目不可达: $_" -ForegroundColor Red
    Write-Host "检查 URL 是否正确, 网络是否通" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# 验证 schema (PostgREST)
Write-Host "[2/3] 验证数据库 schema..." -ForegroundColor Yellow
$headers = @{
    "apikey" = $env:SUPABASE_ANON_KEY
    "Authorization" = "Bearer $env:SUPABASE_ANON_KEY"
}
$tables = @('trips', 'expenses', 'trip_members', 'trip_groups', 'profiles', 'transfer_records', 'trip_collaborators')
$missing = @()
foreach ($t in $tables) {
    try {
        $r = Invoke-WebRequest -Uri "$env:SUPABASE_URL/rest/v1/$($t)?select=id&limit=1" -Headers $headers -Method GET -TimeoutSec 5 -ErrorAction Stop
        Write-Host "  ✅ $t" -ForegroundColor Green
    } catch {
        $code = $_.Exception.Response.StatusCode.value__
        if ($code -eq 401) {
            Write-Host "  ✅ $t (存在, RLS 保护)" -ForegroundColor Green
        } else {
            Write-Host "  ❌ $t (HTTP $code)" -ForegroundColor Red
            $missing += $t
        }
    }
}
if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "⚠️ 缺失表: $($missing -join ', ')" -ForegroundColor Yellow
    Write-Host "需要执行 SQL 迁移:" -ForegroundColor Yellow
    Write-Host "  1. 打开 https://supabase.com/dashboard/project/zvqnawllsdmisntkxdwp/sql/new" -ForegroundColor White
    Write-Host "  2. 复制 supabase\migrations\00001_initial_schema.sql 内容, Run" -ForegroundColor White
    Write-Host "  3. 复制 supabase\migrations\00002_rls_policies.sql 内容, Run" -ForegroundColor White
    Write-Host ""
    $continue = Read-Host "已执行迁移? (y/N)"
    if ($continue -ne 'y' -and $continue -ne 'Y') {
        Write-Host "❌ 已取消" -ForegroundColor Yellow
        exit 1
    }
}
Write-Host ""

# 启动 APP
Write-Host "[3/3] 启动 APP (Ctrl+C 退出)..." -ForegroundColor Yellow
Write-Host ""
$env:PATH = "C:\src\flutter\bin;$env:PATH"
flutter run `
    --dart-define=SUPABASE_URL=$env:SUPABASE_URL `
    --dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY
