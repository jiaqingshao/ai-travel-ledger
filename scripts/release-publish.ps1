#!/usr/bin/env pwsh
# ============================================
# AI 旅行账本 - GitHub Release 一键发布脚本
# ============================================
#
# 通过 GitHub REST API 把当前 milestone tag 发布为正式 Release
# 上传 APK / Zip / SHA1 等附件
#
# 前置: 需要一个 Personal Access Token (classic), scope = repo
#       推荐用一次性 fine-grained token (Contents: Read+Write only on this repo)
#       获取地址: https://github.com/settings/tokens/new
#
# 用法:
#   pwsh scripts\release-publish.ps1 -Token "ghp_..."
#   或: $env:GH_TOKEN = "ghp_..."; pwsh scripts\release-publish.ps1
#
# 发布完后建议立刻去 https://github.com/settings/tokens revoke 这个 token
# ============================================

param(
    [string]$Token = $null,
    [string]$Tag = "milestone-v1.2-cloud",
    [string]$Title = "🏆 v1.2.0+0 - Cloud Milestone (First Release)",
    [string]$ReleaseDir = "release\v1.2.0+0-cloud-milestone",
    [string]$Repo = "jiaqingshao/ai-travel-ledger"
)

$ErrorActionPreference = 'Stop'

# ===== Token 来源 =====
if (-not $Token) {
    $Token = $env:GH_TOKEN
}
if (-not $Token) {
    $TokenFile = (Join-Path (Split-Path -Parent $PSScriptRoot) ".secrets\gh-token.txt")
    if (Test-Path $TokenFile) {
        $Token = (Get-Content $TokenFile -Raw).Trim()
    }
}

if (-not $Token) {
    Write-Host "❌ 找不到 GitHub Token" -ForegroundColor Red
    Write-Host ""
    Write-Host "获取 token: https://github.com/settings/tokens/new" -ForegroundColor Cyan
    Write-Host "  Required scope: 'repo' (全部) OR fine-grained 'Contents: Read+Write'" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "提供方式 (3 选 1):" -ForegroundColor Yellow
    Write-Host "  [A] 直接传: pwsh scripts\release-publish.ps1 -Token 'ghp_***'" -ForegroundColor White
    Write-Host "  [B] 环境变量: `$env:GH_TOKEN = 'ghp_***'; pwsh scripts\release-publish.ps1" -ForegroundColor White
    Write-Host "  [C] 文件: 创建 .secrets\gh-token.txt (gitignored), 写入 token, 跑脚本" -ForegroundColor White
    Write-Host ""
    Write-Host "⚠️  发布完后请立刻去 https://github.com/settings/tokens 撤销这个 token" -ForegroundColor Red
    exit 1
}

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "  🚀 发布 GitHub Release" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Repo:  $Repo" -ForegroundColor White
Write-Host "Tag:   $Tag" -ForegroundColor White
Write-Host "Title: $Title" -ForegroundColor White
Write-Host "Assets: 将在 release 创建后从 $ReleaseDir 上传" -ForegroundColor White
Write-Host ""

# ===== 验证 token + 取得 user =====
Write-Host "[1/5] 验证 token..." -ForegroundColor Yellow
$headers = @{
    "Authorization" = "Bearer $Token"
    "Accept"        = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
    "User-Agent"    = "ai-travel-ledger-release-script"
}
try {
    $userResp = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers -Method GET
    Write-Host "✅  Token 有效 (登录用户: $($userResp.login))" -ForegroundColor Green
} catch {
    Write-Host "❌ Token 无效: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# ===== 验证 tag 已存在 =====
Write-Host "[2/5] 验证 tag '$Tag' 已存在..." -ForegroundColor Yellow
try {
    $tagResp = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/git/ref/tags/$Tag" -Headers $headers -Method GET
    $tagSha = $tagResp.object.sha
    Write-Host "✅  Tag 存在 (sha: $($tagSha.Substring(0, 12))...)" -ForegroundColor Green
} catch {
    Write-Host "❌ Tag 不存在或 token 权限不够" -ForegroundColor Red
    Write-Host "   请先: git push origin $Tag" -ForegroundColor Yellow
    exit 1
}

# ===== 准备 release notes =====
Write-Host "[3/5] 生成 release notes..." -ForegroundColor Yellow
$projectRoot = Split-Path -Parent $PSScriptRoot
$milestoneMd = Join-Path $projectRoot "MILESTONE.md"
$releaseNotes = @"

## 🏆 这是 AI 旅行账本的首个正式 Release！

标志着 **从纯本地工具升级为云端协作工具**。

### ☁️ Cloud Milestone 主要特性

- ✅ **零配置安装**：Supabase URL + anon key 编译时注入，用户安装即用云模式
- ✅ **多设备同步**：登录任意邮箱即可跨设备访问同一份数据
- ✅ **RLS 保护**：数据访问受 Row Level Security 限制，账号隔离
- ✅ **离线兜底**：网络断开自动回退本地模式，恢复连接自动重连
- ✅ **附件云端备份**（V1.2）：Supabase Storage 自动上传发票/照片
- ✅ **完整登录注册**：Supabase Auth + 邮箱验证

### 🎯 包含 V1.2 全部能力

- ✅ W1-W4 Epic（旅程/记账/分摊/结算）+ 5 种分摊方式（均摊/比例/份数/固定/按组）
- ✅ V1.1 编辑能力（分摊规则 / 费用详情 / 附件可编辑）
- ✅ V1.2 附件（拍照/选图/上传/预览/费用列表徽章/行程汇总）
- ✅ ISSUE-027~030 真机反馈全部修复

### 📊 测试 & 质量

- 单元测试: 250/250 通过
- flutter analyze: 0 errors
- APK Size: 24.7 MB（R8 minified + signed）
- Gradle: tree-shake icons, 99.2% reduction

### 🚀 快速体验

1. **先卸载旧版**（如有）
2. 安装 APK: `ai-travel-ledger-v1.2.0+0-cloud-milestone.apk`
3. 启动 APP → **直接进登录页**（零配置）
4. 任意邮箱注册 → 查收 Supabase 验证邮件
5. 登入后右上角 ☁️ 转绿色 = 已连接
6. 创一笔费用 → 查看 About 页面 → 看到 🏆 徽章 = **里程碑版本确认**

### 📚 完整文档

- 里程碑体系说明: 项目根 `MILESTONE.md`
- Supabase 配置: `docs/04-deployment/supabase-project-info.md`
- Supabase 部署指南: `docs/04-deployment/supabase-deploy-guide.md`
- 跨 PC 迁移手册: `docs/04-deployment/pc-migration-guide.md`

### 🔐 安全说明

- **anon key 已记录**于项目文档（用户授权）：
  - `\`docs\04-deployment\supabase-project-info.md\``
  - `\`\.secrets\cloud-key.txt\``（gitignore）
- **service_role key 不入仓**（能 bypass RLS，绝不外传）
- **RLS 策略保护**：所有数据访问受 Row Level Security 限制

---

## 📦 附件列表

下载后请校验 SHA1：

\`\`\`powershell
Get-FileHash ai-travel-ledger-v1.2.0+0-cloud-milestone.apk -Algorithm SHA1
\`\`\`

| 文件 | 描述 | SHA1 |
|---|---|---|
| `ai-travel-ledger-v1.2.0+0-cloud-milestone.apk` | 🏆 **推荐** - Cloud Milestone APK | 同下 |
| `ai-travel-ledger-v1.2.0+0-cloud-milestone.zip` | 同上（含 CHANGELOG） | — |
| `ai-travel-ledger-v1.2.0+0-cloud.apk` | 标准云端版（不带 🏆 徽章） | — |

---

## 🆚 与普通版的区别

普通云端版和 Cloud Milestone 版 **业务逻辑完全相同**，唯一区别是：
- **Milestone 版**：在 About 页面顶部有醒目的金棕色 🏆 徽章 + 里程碑简介
- **视觉区分**：方便分发时识别"这是值得优先测试的版本"

如需装普通云端版（不带徽章），下载 `ai-travel-ledger-v1.2.0+0-cloud.apk` 即可。

---

**发布日期**: $(Get-Date -Format 'yyyy-MM-dd')
**Build Variant**: cloud-milestone
**Git Tag**: \`$Tag\`

*由 AI 旅行账本开发团队 + 用户协作完成*
"@

Write-Host "✅ Notes 准备完成 ($($releaseNotes.Length) 字符)" -ForegroundColor Green
Write-Host ""

# ===== 创建 Release =====
Write-Host "[4/5] 创建 Release..." -ForegroundColor Yellow
$createBody = @{
    tag_name         = $Tag
    target_commitish = "main"
    name             = $Title
    body             = $releaseNotes
    draft            = $false
    prerelease       = $false
    generate_release_notes = $false
} | ConvertTo-Json -Depth 5

try {
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases" -Headers $headers -Method POST -Body $createBody -ContentType "application/json"
    $releaseId = $release.id
    $releaseUrl = $release.html_url
    Write-Host "✅  Release 创建成功" -ForegroundColor Green
    Write-Host "   URL: $releaseUrl" -ForegroundColor Cyan
    Write-Host "   ID: $releaseId" -ForegroundColor Cyan
} catch {
    $errBody = $_.ErrorDetails.Message | ConvertFrom-Json -ErrorAction SilentlyContinue
    Write-Host "❌ Release 创建失败" -ForegroundColor Red
    if ($errBody.message) {
        Write-Host "   GitHub: $($errBody.message)" -ForegroundColor Yellow
    } else {
        Write-Host "   $($_.Exception.Message)" -ForegroundColor Yellow
    }
    exit 1
}
Write-Host ""

# ===== 上传资产 =====
Write-Host "[5/5] 上传附件..." -ForegroundColor Yellow
$releaseDirAbs = Join-Path (Split-Path -Parent $PSScriptRoot) $ReleaseDir
if (-not (Test-Path $releaseDirAbs)) {
    Write-Host "❌ 目录不存在: $releaseDirAbs" -ForegroundColor Red
    exit 1
}

# 上传里程碑 APK + Zip + SHA1
$filesToUpload = Get-ChildItem $releaseDirAbs -File | Where-Object { $_.Extension -in '.apk', '.zip', '.sha1' -or $_.Name -in 'CHANGELOG.md' }
foreach ($file in $filesToUpload) {
    $uploadUrl = "https://uploads.github.com/repos/$Repo/releases/$releaseId/assets?name=$($file.Name)"
    Write-Host "   上传: $($file.Name) ($([math]::Round($file.Length/1MB, 2)) MB)..." -ForegroundColor Gray -NoNewline
    try {
        $fileBytes = [System.IO.File]::ReadAllBytes($file.FullName)
        $base64 = [Convert]::ToBase64String($fileBytes)

        $uploadHeaders = @{
            "Authorization" = "Bearer $Token"
            "Accept"        = "application/vnd.github+json"
            "X-GitHub-Api-Version" = "2022-11-28"
            "Content-Type"  = "application/octet-stream"
            "User-Agent"    = "ai-travel-ledger-release-script"
        }

        Invoke-RestMethod -Uri $uploadUrl -Headers $uploadHeaders -Method POST -Body $base64 -ContentType "application/octet-stream" | Out-Null
        Write-Host " ✅" -ForegroundColor Green
    } catch {
        Write-Host " ❌" -ForegroundColor Red
        Write-Host "   失败原因: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# 也上传普通 cloud 版（标准版不带 milestone 徽章）
$cloudReleaseDir = Join-Path (Split-Path -Parent $PSScriptRoot) "release\v1.2.0+0-cloud"
if (Test-Path $cloudReleaseDir) {
    Write-Host "   --- 普通 cloud 版（不带徽章）---" -ForegroundColor Gray
    $cloudFiles = Get-ChildItem $cloudReleaseDir -File | Where-Object { $_.Extension -in '.apk', '.zip' }
    foreach ($file in $cloudFiles) {
        $uploadUrl = "https://uploads.github.com/repos/$Repo/releases/$releaseId/assets?name=$($file.Name)"
        Write-Host "   上传: $($file.Name)..." -ForegroundColor Gray -NoNewline
        try {
            $fileBytes = [System.IO.File]::ReadAllBytes($file.FullName)
            $base64 = [Convert]::ToBase64String($fileBytes)
            Invoke-RestMethod -Uri $uploadUrl -Headers $uploadHeaders -Method POST -Body $base64 -ContentType "application/octet-stream" | Out-Null
            Write-Host " ✅" -ForegroundColor Green
        } catch {
            Write-Host " ❌" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "===========================================" -ForegroundColor Green
Write-Host "  ✅ Release 发布完成!" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green
Write-Host ""
Write-Host "🔗 URL:    $releaseUrl" -ForegroundColor Cyan
Write-Host "🏷️  Tag:    $Tag" -ForegroundColor Cyan
Write-Host "📦 Assets:  $((Get-ChildItem $releaseDirAbs -File | Measure-Object).Count) 个文件" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  建议立即撤销 GitHub Token:" -ForegroundColor Yellow
Write-Host "   https://github.com/settings/tokens" -ForegroundColor Cyan
Write-Host ""
