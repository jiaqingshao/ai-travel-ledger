# 🚚 AI 旅行账本 - PC 迁移操作手册

**适用版本**：v1.0
**适用日期**：2026-07-04 及以后
**预计迁移耗时**：30-60 分钟（首次）/ 5-10 分钟（已有镜像）

---

## 📋 你需要准备的清单

| 项目 | 来源 |
|---|---|
| 项目源代码 | `C:\Users\jiaqi\.openclaw\workspace\projects\ai-travel-ledger\` (本机) |
| Flutter SDK | 3.24.5 |
| Android Studio + SDK | 2026.1.1 (Quail) |
| JDK 17 | portable 版 (`C:\src\jdk-17`) |
| Supabase 项目 | URL: `zvqnawllsdmisntkxdwp.supabase.co` |

---

## 步骤 1️⃣：安装基础工具（新 PC）

### 1.1 安装 Git for Windows

👉 https://git-scm.com/download/win

安装时选 "Git from command line"

### 1.2 安装 Java JDK 17

```powershell
# 下载 portable 版 (zip 解压即用)
Invoke-WebRequest "https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_windows-x64_bin.zip" -OutFile C:\tmp\jdk.zip
Expand-Archive C:\tmp\jdk.zip -DestinationPath C:\src\
# 重命名为 jdk-17
Rename-Item C:\src\jdk-17.0.2 C:\src\jdk-17

# 设置环境变量
[Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\src\jdk-17", "User")
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\src\jdk-17\bin", "User")
```

### 1.3 安装 Flutter 3.24.5

```powershell
# 下载 Flutter
Invoke-WebRequest "https://storage.flutter-io.cn/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip" -OutFile C:\tmp\flutter.zip
Expand-Archive C:\tmp\flutter.zip -DestinationPath C:\src\

# 设置环境变量
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\src\flutter\bin", "User")

# 验证
flutter --version
```

### 1.4 安装 Android Studio + SDK

👉 https://developer.android.com/studio

安装时勾选：
- ✅ Android SDK Platform 34/35/36
- ✅ Android SDK Build-Tools 33.0.1+
- ✅ Android Emulator
- ✅ Android Virtual Device (AVD)

### 1.5 配置 Android SDK 环境变量

```powershell
$androidSdk = "$env:LOCALAPPDATA\Android\Sdk"
[Environment]::SetEnvironmentVariable("ANDROID_HOME", $androidSdk, "User")
[Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $androidSdk, "User")
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$androidSdk\platform-tools;$androidSdk\cmdline-tools\latest\bin;$androidSdk\emulator", "User")
```

### 1.6 安装 Android SDK 平台（cmdline-tools）

```powershell
sdkmanager "platforms;android-34" "platforms;android-35" "platforms;android-36" "build-tools;33.0.1" "build-tools;35.0.0" "build-tools;36.0.0" "platform-tools" "emulator"
```

### 1.7 创建模拟器

```powershell
# 安装 AVD (Pixel 5 + API 34)
avdmanager create avd -n Pixel5_API34 -k "system-images;android-34;google_apis;x86_64" -d pixel_5
```

---

## 步骤 2️⃣：复制项目代码

### 选项 A：从 Git 仓库（推荐）

```powershell
# 找到你的 git 仓库 URL
git clone https://your-repo/ai-travel-ledger.git
cd ai-travel-ledger
flutter pub get
```

### 选项 B：从本机复制（最简单）

**在本机上**，打包整个项目目录（**排除** `build/` 和 `.dart_tool/`）：

```powershell
# PowerShell 压缩（排除大的中间目录）
$src = "C:\Users\jiaqi\.openclaw\workspace\projects\ai-travel-ledger"
$dst = "C:\tmp\ai-travel-ledger.zip"

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($src, $dst, [System.IO.Compression.CompressionLevel]::Optimal, $false)

# 看大小
Get-Item $dst | Select-Object Name, Length
```

**传输到新 PC**（任选一种）：
- U 盘 / 移动硬盘
- 局域网共享
- 微信文件传输助手（< 2GB 没问题）
- 邮件附件

**在新 PC 上解压**：

```powershell
# 假设 D:\Downloads\ai-travel-ledger.zip
Expand-Archive D:\Downloads\ai-travel-ledger.zip -DestinationPath C:\Users\你的用户名\Projects\
cd C:\Users\你的用户名\Projects\ai-travel-ledger
flutter pub get
```

---

## 步骤 3️⃣：配置 Gradle（Android 构建）

### 3.1 创建 keystore（如果丢失了，需要重新生成并重新签名）

**如果你在本机上保留了 keystore** (`C:\Users\jiaqi\.android\ai-travel-ledger-release.jks`)：

- 把整个 `C:\Users\jiaqi\.android\` 文件夹复制到新 PC 同位置

**如果你没保留**（需要重新生成）：

```powershell
# 新 PC 上执行
$env:JAVA_HOME = "C:\src\jdk-17"
$env:Path = "$env:JAVA_HOME\bin;$env:Path"

keytool -genkey -v -keystore C:\Users\你的用户名\.android\ai-travel-ledger-release.jks `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -alias ai-travel-ledger `
  -storepass aitravel2026 -keypass aitravel2026 `
  -dname "CN=AI Travel Ledger, OU=App, O=Personal, L=Shanghai, ST=Shanghai, C=CN"
```

### 3.2 创建 key.properties

新建 `C:\Users\你的用户名\.android\key.properties`：

```
storeFile=C:/Users/你的用户名/.android/ai-travel-ledger-release.jks
storePassword=aitravel2026
keyAlias=ai-travel-ledger
keyPassword=aitravel2026
```

### 3.3 配置 Gradle Java Home

新建 `C:\Users\你的用户名\.gradle\gradle.properties`：

```
org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=2G
org.gradle.java.home=C:\\src\\jdk-17
android.useAndroidX=true
android.enableJetifier=true
```

---

## 步骤 4️⃣：验证项目能跑

```powershell
cd C:\Users\你的用户名\Projects\ai-travel-ledger

# 1. 检查环境
flutter doctor

# 2. 拉依赖
flutter pub get

# 3. 跑测试 (验证 225 个测试全绿)
flutter test

# 4. 跑分析 (确保 0 编译错误)
flutter analyze

# 5. 启动模拟器
emulator -avd Pixel5_API34 -no-window -no-audio -no-snapshot -gpu swiftshader_indirect

# 6. 构建 Debug APK (含 Supabase 配置)
flutter build apk --debug --dart-define=SUPABASE_URL=https://zvqnawllsdmisntkxdwp.supabase.co --dart-define=SUPABASE_ANON_KEY=***
```

---

## 步骤 5️⃣：Supabase 配置（关键）

### 5.1 SQL 迁移

- 在新 PC 上打开 https://supabase.com/dashboard/project/zvqnawllsdmisntkxdwp
- 左 → SQL Editor → New query
- 复制项目里的 `supabase/migrations/00001_initial_schema.sql` → Run
- 复制 `00002_rls_policies.sql` → Run

### 5.2 创建模拟器 AVD

```powershell
# 如果你本机已经创建过 AVD，复制整个 ~/.android/avd 目录到新 PC
# 否则按步骤 1.7 重新创建

# 启动 AVD
emulator -avd Pixel5_API34 -no-window -no-audio -no-snapshot -gpu swiftshader_indirect
```

### 5.3 安装 APK + 测试

```powershell
adb install build\app\outputs\flutter-apk\app-debug.apk
adb shell am start -n com.aitravel.ledger.ai_travel_ledger/.MainActivity
```

---

## 📦 完整文件清单（需要复制到新 PC）

### 必须复制 ✅

| 路径 | 说明 |
|---|---|
| `projects/ai-travel-ledger/` | 整个项目目录（**去掉** `build/` 和 `.dart_tool/`）|
| `~/.android/ai-travel-ledger-release.jks` | 签名 keystore |
| `~/.android/key.properties` | Gradle 配置 |
| `~/.gradle/gradle.properties` | Gradle 全局配置 |

### 不需要复制 ❌（环境重新生成）

- `~/.android/avd/` — 新 PC 上重新创建即可
- `build/` — Flutter 会重新生成
- `.dart_tool/` — Flutter pub get 会重新生成
- `~/.gradle/caches/` — Gradle 会重新下载
- `~/AndroidStudioProjects/` — Android Studio 重新初始化

---

## 🔍 移植完成验证清单

跑完所有步骤后，逐项打勾：

- [ ] `flutter doctor` 全部绿色 ✓
- [ ] `flutter test` 显示 `225/225 passed`
- [ ] `flutter analyze` 0 error
- [ ] 模拟器启动成功（Pixel5_API34）
- [ ] APK install 成功
- [ ] APP 启动 → 看到 "我的旅程" 主页
- [ ] Supabase init 日志：`***** Supabase init completed *****`
- [ ] 点云朵图标 → 注册 → 邮箱验证 → 登录成功
- [ ] 创建测试行程 → 在 Supabase Table Editor 看到数据

---

## 🆘 常见问题

### Q: Flutter 编译很慢？

**A**: 第一次构建会下载 Gradle 8.3 + 所有 Maven 依赖，约 200MB。需要 5-15 分钟。

### Q: Gradle 报 `ZipFile error`？

**A**: 之前的 gradle zip 损坏。删除 `~/.gradle/wrapper/dists/gradle-8.3-all/*` 重新下载。

### Q: `flutter build` 报 `compileSdk 36` warning？

**A**: 这是 app_links 插件需要。Gradle 编译会自动用最高 SDK，向后兼容。

### Q: 模拟器 ANR "System not responding"？

**A**: 模拟器首次 boot 慢，等 1-2 分钟。或用 `-no-snapshot-load` 跳过快照。

### Q: Supabase anon key 在哪？

**A**: 在你之前的 `key.properties` 文件或 Supabase Dashboard → Settings → API。

### Q: 我忘带 keystore 了怎么办？

**A**: ⚠️ **严重**：keystore 丢失 = 无法更新已发布的 APP。

- 如果之前没上架：随便生成一个新 keystore
- 如果已上架：**APP 必须用原 keystore 重新签名**，否则用户更新会失败

---

## 💡 我的建议

**最简单方案**：本机 `git push` 到 GitHub/Gitee，新 PC `git clone`，然后按步骤 1+3 安装工具。

如果项目还没 git 仓库：

```powershell
# 本机
cd C:\Users\jiaqi\.openclaw\workspace\projects\ai-travel-ledger
git init
git add .
git commit -m "v1.0 complete"
# 推到 GitHub (需先在 GitHub 创建空仓库)
git remote add origin https://github.com/你的用户名/ai-travel-ledger.git
git push -u origin main
```

---

## 📞 需要我帮你做什么？

- ✅ 写一个**自动化安装脚本**（一键装 Flutter + Android SDK）
- ✅ 写**迁移检查脚本**（验证新 PC 环境）
- ✅ **打包关键文件**为压缩包给你
- ✅ 任何步骤卡住了告诉我，我帮你排查

---

## 🔗 相关文档

- [Release 构建指南](./release-build-guide.md)
- [Supabase 部署指南](./supabase-deploy-guide.md)
- [Supabase 项目信息](./supabase-project-info.md)
- [测试报告](../03-management/test-report-2026-07-04.md)

---

*最后更新：2026-07-04*