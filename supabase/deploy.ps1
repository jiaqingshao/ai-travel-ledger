#!/usr/bin/env pwsh
# ============================================
# AI 旅行账本 - Supabase 一键部署脚本
# ============================================
#
# 使用方式:
#   1. 安装 Supabase CLI: https://supabase.com/docs/guides/cli
#      npm install -g supabase
#   2. 登录: supabase login
#   3. 关联项目: supabase link --project-ref <your-project-id>
#   4. 运行: pwsh deploy.ps1
#
# 或者直接执行 SQL:
#   - 手动复制 supabase/migrations/*.sql 到 Supabase Dashboard → SQL Editor
#
# ============================================

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$MigrationsDir = Join-Path $ProjectRoot 'supabase\migrations'

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  AI 旅行账本 - Supabase 部署脚本" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# 检查 supabase CLI
Write-Host "[1/5] 检查 Supabase CLI..." -ForegroundColor Yellow
$supabase = Get-Command supabase -ErrorAction SilentlyContinue
if (-not $supabase) {
    Write-Host "❌ Supabase CLI 未安装" -ForegroundColor Red
    Write-Host ""
    Write-Host "请先安装:" -ForegroundColor Yellow
    Write-Host "  npm install -g supabase" -ForegroundColor White
    Write-Host ""
    Write-Host "或者跳过 CLI,手动部署:" -ForegroundColor Yellow
    Write-Host "  1. 打开 https://supabase.com/dashboard" -ForegroundColor White
    Write-Host "  2. 进入 SQL Editor" -ForegroundColor White
    Write-Host "  3. 依次执行以下文件:" -ForegroundColor White
    Write-Host "     - $MigrationsDir\00001_initial_schema.sql" -ForegroundColor White
    Write-Host "     - $MigrationsDir\00002_rls_policies.sql" -ForegroundColor White
    exit 1
}
Write-Host "✅ Supabase CLI 已安装: $($supabase.Source)" -ForegroundColor Green
Write-Host ""

# 检查登录状态
Write-Host "[2/5] 检查登录状态..." -ForegroundColor Yellow
try {
    $null = supabase projects list 2>&1
    Write-Host "✅ 已登录 Supabase" -ForegroundColor Green
} catch {
    Write-Host "❌ 未登录" -ForegroundColor Red
    Write-Host "请运行: supabase login" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# 检查项目链接
Write-Host "[3/5] 检查项目链接..." -ForegroundColor Yellow
if (-not (Test-Path "$ProjectRoot\supabase\.temp\project-ref")) {
    Write-Host "⚠️  未链接到项目" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "请提供项目 ID (从 Dashboard URL 获取):" -ForegroundColor Yellow
    Write-Host "  形如: https://supabase.com/dashboard/project/abcdefghijk" -ForegroundColor White
    Write-Host "  项目 ID 是: abcdefghijk" -ForegroundColor White
    $projectRef = Read-Host "项目 ID"
    if ([string]::IsNullOrWhiteSpace($projectRef)) {
        Write-Host "❌ 项目 ID 不能为空" -ForegroundColor Red
        exit 1
    }
    supabase link --project-ref $projectRef
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ 链接失败" -ForegroundColor Red
        exit 1
    }
}
Write-Host "✅ 项目已链接" -ForegroundColor Green
Write-Host ""

# 列出迁移文件
Write-Host "[4/5] 待执行迁移文件:" -ForegroundColor Yellow
$migrations = Get-ChildItem "$MigrationsDir\*.sql" | Sort-Object Name
foreach ($m in $migrations) {
    Write-Host "  - $($m.Name) ($('{0:N1}' -f ($m.Length/1KB)) KB)" -ForegroundColor White
}
Write-Host ""

# 推送迁移
Write-Host "[5/5] 推送迁移到 Supabase..." -ForegroundColor Yellow
$confirm = Read-Host "确认推送? (y/N)"
if ($confirm -ne 'y' -and $confirm -ne 'Y') {
    Write-Host "❌ 已取消" -ForegroundColor Yellow
    exit 0
}

supabase db push
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 部署失败" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "  ✅ 部署成功!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
Write-Host "下一步:" -ForegroundColor Cyan
Write-Host "  1. 打开 https://supabase.com/dashboard" -ForegroundColor White
Write-Host "  2. Table Editor 验证 7 张表已创建" -ForegroundColor White
Write-Host "  3. Settings → API 复制 URL 和 anon key" -ForegroundColor White
Write-Host "  4. 启动 APP:" -ForegroundColor White
Write-Host "     flutter run --dart-define=SUPABASE_URL=<URL> --dart-define=SUPABASE_ANON_KEY=<KEY>" -ForegroundColor White
Write-Host ""
Write-Host "详细指南: docs/04-deployment/supabase-deploy-guide.md" -ForegroundColor Yellow