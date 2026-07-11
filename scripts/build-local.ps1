#!/usr/bin/env pwsh
# ============================================
# AI 旅行账本 - 本地模式构建脚本 (便捷封装)
# ============================================
#
# 等价于: pwsh scripts\build-apk.ps1 -Local
#
# 用法:
#   pwsh scripts\build-local.ps1
#
# 输出: release\ai-travel-ledger-vX.Y.Z+NN-local.apk (无 Supabase 配置)
# ============================================

& (Join-Path $PSScriptRoot 'build-apk.ps1') -Local @args