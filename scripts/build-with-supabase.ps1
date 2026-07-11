#!/usr/bin/env pwsh
# ============================================
# AI 旅行账本 - Supabase 模式构建脚本 (便捷封装)
# ============================================
#
# 等价于: pwsh scripts\build-apk.ps1 -WithSupabase
#
# 用法:
#   $env:SUPABASE_URL = "https://xxx.supabase.co"
#   $env:SUPABASE_ANON_KEY = "eyJ..."
#   pwsh scripts\build-with-supabase.ps1
#
# 输出: release\ai-travel-ledger-vX.Y.Z+NN-cloud.apk
# ============================================

& (Join-Path $PSScriptRoot 'build-apk.ps1') -WithSupabase @args