# Release APK 构建指南

**日期**：2026-07-04  
**版本**：v1.0

---

## 🎯 已完成

✅ 生成 Release 签名 keystore  
✅ 配置 `android/app/build.gradle` 签名  
✅ 创建 ProGuard 规则  
✅ 构建 Release APK（**23.6 MB**）  
✅ 构建 App Bundle `.aab`（**23.7 MB**，Google Play 上传用）  
✅ APK 签名验证（v1 + v2 双重签名）  
✅ 在 Android 模拟器实机启动成功  

---

## 📊 APK 对比

| 类型 | 大小 | 用途 |
|---|---|---|
| Debug APK | 110 MB | 开发调试（带调试符号） |
| **Release APK** | **23.6 MB** | **侧载分发** |
| **Release AAB** | **23.7 MB** | **Google Play 上传** |

压缩比 **4.6x**（R8 混淆 + tree-shaking）。

---

## 🔐 签名配置

### keystore 文件

```
C:\Users\jiaqi\.android\ai-travel-ledger-release.jks
```

| 参数 | 值 |
|---|---|
| 别名 | `ai-travel-ledger` |
| 密码 | `aitravel2026`（占位，生产请换）|
| 算法 | RSA 2048 |
| 有效期 | 10000 天（~27 年）|

⚠️ **生产部署前必须**：
1. 改用更强的密码
2. 备份 keystore 到 2+ 个安全位置（丢了无法更新 APP！）

### key.properties

```
C:\Users\jiaqi\.android\key.properties
C:\Users\jiaqi\.openclaw\workspace\projects\ai-travel-ledger\android\key.properties
```

⚠️ **不要提交到 git**（已在 `.gitignore` 中）

---

## 🚀 构建命令

### Debug（开发用）
```bash
flutter build apk --debug
# 输出: build/app/outputs/flutter-apk/app-debug.apk (110 MB)
```

### Release（分发用）
```bash
flutter build apk --release
# 输出: build/app/outputs/flutter-apk/app-release.apk (23.6 MB)
```

### App Bundle（Google Play 用）
```bash
flutter build appbundle --release
# 输出: build/app/outputs/bundle/release/app-release.aab (23.7 MB)
```

### Split APK（按架构分发）
```bash
flutter build apk --release --split-per-abi
# 输出 3 个更小的 APK
```

---

## ✅ APK 验证

```bash
# 验证签名
$ANDROID_HOME/build-tools/33.0.1/apksigner verify --verbose build/app/outputs/flutter-apk/app-release.apk
```

输出：
```
Verifies
Verified using v1 scheme (JAR signing): true
Verified using v2 scheme (APK Signature Scheme v2): true
Number of signers: 1
```

---

## 📲 分发方式

### 1. 微信/邮件分享（侧载）

直接发 APK 文件给用户，让他们：
1. 手机打开 APK 文件
2. 允许"安装未知来源应用"
3. 安装

### 2. Google Play 上架

1. 注册 Google Play Developer 账号（$25 一次性）
2. Play Console → 创建应用
3. 上传 `.aab` 文件
4. 填应用信息 + 截图
5. 提交审核

### 3. 国内应用商店

需额外资质：
- 应用宝、华为、小米、OPPO、vivo
- 每个商店都要单独提交 + 审核（1-7 天）

---

## 🛡️ ProGuard 规则说明

`android/app/proguard-rules.pro` 已配置：
- ✅ Flutter 引擎类保留
- ✅ Supabase SDK 类保留
- ✅ Gson 序列化（Supabase JSON）保留
- ✅ Kotlin 反射保留
- ✅ Google Play Core 类忽略（我们不用 Split Install）
- ✅ Android Log.v/d/i 在 Release 中移除

如果以后添加新插件报错，参考 `build/app/outputs/mapping/release/missing_rules.txt`。

---

## ⚠️ 已知限制

| 限制 | 说明 | 何时处理 |
|---|---|---|
| 调试 keystore 没用 | 当前 keystore 是临时测试用 | 上架前重新生成 |
| Supabase 未配置 | 默认本地模式运行 | 启动时加 dart-define |
| 没有 iOS | Flutter 代码通用但未编译 | 需 macOS + Xcode |

---

## 🔄 更新流程

第一次上架后，用户安装 v1.0。要发 v1.1：

1. 修改代码
2. `flutter build appbundle --release`（必须用**同一个 keystore**）
3. 上传到 Play Console
4. 用户自动收到更新（Play Store 推送）

⚠️ **keystore 丢了 = APP 永远无法更新**，必须重新发布新 APP。

---

## 🎁 下一步

代码侧所有工作完成。下一步是部署 Supabase（让云端同步真的能用）。

详见：📋 Supabase 部署指南（待用户操作）