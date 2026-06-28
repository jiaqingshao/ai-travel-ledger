# ============================================
# Flutter 环境一键初始化脚本
# 在 PowerShell 中运行（**不是** OpenClaw）
# 用法：.\setup-flutter.ps1
# ============================================

$ErrorActionPreference = 'Stop'

Write-Host "🚀 Flutter 环境初始化" -ForegroundColor Cyan
Write-Host ""

# 1. 设置国内镜像
Write-Host "1️⃣  设置国内镜像..." -ForegroundColor Yellow
$env:FLUTTER_STORAGE_BASE_URL = 'https://storage.flutter-io.cn'
$env:PUB_HOSTED_URL = 'https://pub.flutter-io.cn'
[System.Environment]::SetEnvironmentVariable('FLUTTER_STORAGE_BASE_URL', $env:FLUTTER_STORAGE_BASE_URL, 'User')
[System.Environment]::SetEnvironmentVariable('PUB_HOSTED_URL', $env:PUB_HOSTED_URL, 'User')
Write-Host "  ✅ FLUTTER_STORAGE_BASE_URL = https://storage.flutter-io.cn"
Write-Host "  ✅ PUB_HOSTED_URL = https://pub.flutter-io.cn"

# 2. 验证 Flutter 安装
Write-Host ""
Write-Host "2️⃣  验证 Flutter 安装..." -ForegroundColor Yellow
$flutterVer = & 'C:\src\flutter\bin\flutter.bat' --no-version-check --version 2>&1
$flutterVer | Select-Object -First 5

# 3. 关闭分析
Write-Host ""
Write-Host "3️⃣  关闭使用分析..." -ForegroundColor Yellow
& 'C:\src\flutter\bin\flutter.bat' --disable-analytics 2>&1 | Select-Object -First 3

# 4. 接受 Android 许可（前提是装了 Android SDK）
Write-Host ""
Write-Host "4️⃣  接受 Android 许可（如果装好 Android SDK 后再跑）..." -ForegroundColor Yellow
Write-Host "  ⏭️  跳过（Android SDK 还没装）"

# 5. 完整 doctor
Write-Host ""
Write-Host "5️⃣  Flutter 完整状态检查..." -ForegroundColor Yellow
Write-Host "  ⏳ 这会下载约 100MB 数据"
& 'C:\src\flutter\bin\flutter.bat' doctor 2>&1

Write-Host ""
Write-Host "=================================" -ForegroundColor Green
Write-Host "✅ Flutter 初始化完成！" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host ""
Write-Host "下一步：" -ForegroundColor Yellow
Write-Host "  1. 装 Android Studio: https://developer.android.com/studio"
Write-Host "  2. 打开 Android Studio → SDK Manager 装 Android SDK"
Write-Host "  3. cd 到项目目录：cd C:\Users\jiaqi\.openclaw\workspace\projects\ai-travel-ledger"
Write-Host "  4. 跑：flutter pub get"
Write-Host "  5. 跑：flutter doctor 看是否全部 ✅"
