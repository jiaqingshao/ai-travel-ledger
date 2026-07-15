# ADR-006: 生成 v2 keystore 强密码（V1.3 上架前准备）

**状态**: 已采纳（v2 已生成，配置未切换）
**日期**: 2026-07-15
**决策者**: 创始人 + 主 Agent
**优先级**: 高（V1.3 国内上架前置条件）

---

## 背景

旧 release keystore `ai-travel-ledger-release.jks`（v1）有以下问题：

1. **弱密码**: `aitravel2026`（13 字符，包含字典词，可暴力破解）
2. **同密码**: storePassword = keyPassword = `aitravel2026`
3. **2048 位 RSA**: 2010 年代标准，2026 年可用但推荐升级到 4096 位
4. **无完整 DN**: 缺少关键属性（如 OU、O、L、ST 等）
5. **配置简单可猜**: `android/key.properties` 文件路径 + keyAlias 命名规则一致

V1.2 cloud-milestone (87 commits + 250 测试) 已发布且公网可下载 APK。如果旧 keystore 密码泄露，攻击者可：

- 用旧 keystore + 同样包名签名恶意 APK，骗用户安装
- 在 V1.3 国内上架后，被 Google 反查时识别 keystore mismatch

---

## 决策

**采纳方案 A：生成 v2 keystore + 强密码 + 备份，但不立即切换配置**

---

## 候选方案

### 方案 A: 立即备份强密码 keystore v2（采纳）✅

**行动**:
1. 生成 v2 keystore：4096 位 RSA + 25 年有效期 + 完整 DN + 32 字符随机密码
2. 备份到 `keystore-backup/` 目录（不入 git）
3. 密码备份到 `docs/03-management/security/keystore-v2-credentials.txt`（不入 git）
4. 写 ADR-006 + 操作文档
5. **不切换 key.properties 配置**（V1.2 milestone 仍可用旧 keystore）

**优点**:
- ✅ 提前准备好 V1.3 上架用的 keystore
- ✅ V1.2 milestone 不受影响（旧 keystore 继续用）
- ✅ 强密码立即生效（防 V1.2 - V1.3 期间泄露风险）
- ✅ 25 年有效期，覆盖 V2.0 全生命周期

**缺点**:
- ❌ 当前构建仍用弱密码（直到 V1.3 上架前切换）

### 方案 B: 立即切换（高风险）❌ 不推荐

**风险**: V1.2 milestone 所有用户必须卸载重装——会失去评论/留存数据，且没有强迁移流程

### 方案 C: 完全不动 ❌ 不推荐

**风险**: V1.3 上架时面临灾难（密码泄露已被恶意利用，需要紧急修复）

---

## v2 keystore 元数据

| 字段 | 值 |
|---|---|
| **路径** | `C:/Users/jiaqi/.android/ai-travel-ledger-release-v2.jks` |
| **别名** | `ai-travel-ledger-v2` |
| **类型** | PKCS12 |
| **密码** | `eDDrUM3gDJZDzCAvDc9AlLlZJEx0F1jQ`（32 字符随机） |
| **DN** | `CN=AI Travel Ledger (cn-only), OU=Mobile, O=Individual Founder, L=Shanghai, ST=Shanghai, C=CN` |
| **算法** | RSA 4096 位 |
| **有效期** | 2026-07-15 → 2051-07-09 (9,125 天 / 25 年) |
| **SHA1 指纹** | `C4:39:C4:43:25:F4:1E:FA:2B:CC:7A:91:DA:D9:F1:D6:13:54:51:71` |
| **SHA256 指纹** | `F9:1E:47:FA:F7:07:51:06:55:53:10:E1:0F:F2:17:9F:79:0E:46:90:B7:71:93:7C:0D:4C:C6:64:0B:70:1B:DB` |

**文件备份**:
- `keystore-backup/ai-travel-ledger-release-v2.jks` (4514 字节, SHA1 `ECAC59BB38F2065C901C8C5DEDF4E8A447156635`)
- `keystore-backup/ai-travel-ledger-release-v1.jks` (2812 字节, SHA1 `906B2AF9A7A5F385D646A1D4C75D908499A8E34A`)

**密码备份**: `docs/03-management/security/keystore-v2-credentials.txt`（不入 git）

---

## 切换流程（V1.3 上架前）

### 前置
- [ ] R011 软著办好（1-2 月）
- [ ] R012 ICP 备案方案决
- [ ] V1.3 国内 Android 上架准备完（隐私政策/截图/描述）

### 切换步骤

```powershell
# 1. 备份当前 key.properties（万一回滚）
Copy-Item android/key.properties android/key.properties.v1.bak

# 2. 用 v2 信息更新 key.properties
# storeFile=C:/Users/jiaqi/.android/ai-travel-ledger-release-v2.jks
# storePassword=eDDrUM3gDJZDzCAvDc9AlLlZJEx0F1jQ
# keyAlias=ai-travel-ledger-v2
# keyPassword=eDDrUM3gDJZDzCAvDc9AlLlZJEx0F1jQ

# 3. 清理并重新构建
flutter clean
flutter build apk --release

# 4. 验证签名
& "$env:JAVA_HOME\bin\keytool.exe" -printcert -jarfile build\app\outputs\flutter-apk\app-release.apk
# 期望: SHA1 C4:39:C4:43:25:F4:1E:FA:2B:CC:7A:91:DA:D9:F1:D6:13:54:51:71

# 5. 本地真机测试 + 卸载旧版装新版

# 6. 提交到应用商店（ISSUE-034 流程）

# 7. 发布后用户通知：必须先卸载旧版才能装新版
```

### 回滚（万一 V1.3 上架失败）

```powershell
Copy-Item android/key.properties.v1.bak android/key.properties -Force
flutter clean
flutter build apk --release
```

---

## 影响

### 对 V1.2 milestone

**无影响**。V1.2 milestone APK 用 v1 keystore 签名，继续工作；v2 只是准备好未启用。

### 对 V1.3 上架

V1.3 上架第一版必须用 v2 keystore 签名——所有 V1.2 用户必须卸载重装。

### 对备份策略

- 文件：`keystore-backup/` 在 workspace，但**不入 git**（被 .gitignore 排除）
- 密码：`docs/03-management/security/keystore-v2-credentials.txt` **不入 git**
- 强烈建议把 jks 文件 + credentials.txt **上传到 NAS / 1Password / Bitwarden**（额外备份，离线位置）

---

## 安全检查清单

- [x] 32 字符随机密码（18 字节熵）
- [x] PKCS12 格式（Android 现代格式）
- [x] 4096 位 RSA（2026 标准）
- [x] 25 年有效期（覆盖 V2.0）
- [x] 完整 DN（含 OU/O/L/ST/C）
- [x] V1.3 切换流程文档化
- [x] 备份已存本地 keystore-backup/
- [x] 密码已存 docs/security/ 但不入 git
- [ ] 创始人上传到 NAS / 1Password（待用户执行）
- [ ] 旧 keystore 密码评估是否需要 rotate（仍 weak，但不立即威胁）

---

## 工作清单

| # | 文件 | 状态 |
|---|---|---|
| 1 | `docs/02-architecture/04-adr/ADR-006-keystore-v2.md`（本文档） | ✅ |
| 2 | `keystore-backup/ai-travel-ledger-release-v2.jks` (备份文件) | ✅ |
| 3 | `keystore-backup/ai-travel-ledger-release-v1.jks` (旧备份) | ✅ |
| 4 | `docs/03-management/security/keystore-v2-credentials.txt` (密码备份, 不入 git) | ✅ |
| 5 | `docs/03-management/security/README.md` (操作文档) | ✅ |
| 6 | `.gitignore` 加 `keystore-backup/` 和 `docs/03-management/security/` 排除 | ✅ |
| 7 | `android/key.properties` 暂不改（V1.3 启动时切换） | ⏸️ |
| 8 | 创始人上传 .jks + credentials.txt 到 NAS / 1Password | ⏸️ |

---

*ADR-006 的存在意义：在 V1.3 上架时，**第一站打开本文档**就能看到完整切换流程 + 备份位置 + 回滚方案。V2.0 时也可以回顾 25 年有效期的 v2 决策。*
