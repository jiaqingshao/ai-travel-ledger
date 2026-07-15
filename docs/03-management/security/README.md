# 🔐 AI 旅行账本 安全管理 (Security)

> 本目录包含 **密钥、签名证书、敏感凭据**，必须不入 git。
> 已通过 `.gitignore` 排除 `keystore-backup/` 和 `docs/03-management/security/`。

---

## 📂 当前文件

### 入 git 的（公开文档）

- `README.md` (本文件)
- `keystore-decision-history.md` （未来归档 - 待写）

### **不入 git**（敏感资料，开发者本地维护）

- `keystore-v2-credentials.txt` —— **V2 keystore 凭据**
  - 创建日期: 2026-07-15
  - 含 32 字符强密码 + 证书指纹
  - 仅用于 V1.3 国内上架前的 V2 keystore 迁移
  - **必须额外备份到 1Password / Bitwarden / NAS**
- `keystore-v1-credentials.txt` —— 旧 v1 keystore 凭据（如未来补）

### 不在本目录（workspace 内但不进 git）

- `keystore-backup/ai-travel-ledger-release-v2.jks` —— V2 keystore 文件副本
- `keystore-backup/ai-travel-ledger-release-v1.jks` —— V1 keystore 文件备份
- `C:\Users\jiaqi\.android\ai-travel-ledger-release-v2.jks` —— V2 keystore 主文件

---

## ⚠️ 安全操作规范

### ✅ 应该

1. **额外备份到离线位置**（1Password / Bitwarden / USB）
2. **定期验证 keystore 完整**（`keytool -list -v ...`）
3. **更换 owner 时交接清晰**（ADR + README + 凭据 3 件齐）
4. **commit 前检查**：`git status` 必须显示 0 sensitive files staged

### ❌ 不应该

1. ❌ **邮件发送** keystore / 凭据（明文不安全）
2. ❌ **聊天记录含密码**（OpenClaw/微信/QQ 都可能泄露）
3. ❌ **打印** 凭据文件（打印机可能被回收）
4. ❌ **截图** 凭据文件（云盘/截图软件可能上传）

---

## 🔁 V1.3 切换流程

详见 [ADR-006](../../02-architecture/04-adr/ADR-006-keystore-v2.md) §"切换流程（V1.3 上架前）"

**前置检查**:
- [ ] R011 软著办好
- [ ] R012 ICP 备案方案决
- [ ] V1.3 隐私政策 + 截图 + 描述 准备好
- [ ] **1Password / Bitwarden 备份确认**

**切换步骤**（V1.3 上架当天执行）:
1. `Copy-Item android/key.properties android/key.properties.v1.bak`
2. 编辑 `android/key.properties`，密码用 `keystore-v2-credentials.txt` 替换
3. `flutter clean && flutter build apk --release`
4. `keytool -printcert -jarfile build\app\outputs\flutter-apk\app-release.apk` 验证 SHA1 `C4:39:C4:43:25:F4:1E:FA:...`
5. 真机测试 + 卸载旧版装新版（v1.2 用户必须先卸载再装新版）
6. 提交应用商店（ISSUE-034 流程启动）

---

## 📚 历史

| 版本 | 日期 | 凭据强度 | 备注 |
|---|---|---|---|
| **v1** | 2026-07-10 | ❌ 弱（`aitravel2026`，13 字符，2048 位 RSA）| 沿用至 V1.2 milestone |
| **v2** | 2026-07-15 | ✅ 强（32 字符随机，4096 位 RSA，PKCS12，完整 DN，25 年有效期） | 备份好待启用（ADR-006） |

---

*2026-07-15 创建 | V2 keystore 已生成, 未启用 (V1.3 上架前切换)*
