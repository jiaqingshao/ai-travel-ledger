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
  - `docs/04-deployment/supabase-project-info.md`
  - `.secrets\cloud-key.txt`（gitignore）
- **service_role key 不入仓**（能 bypass RLS，绝不外传）
- **RLS 策略保护**：所有数据访问受 Row Level Security 限制

---

## 📦 附件列表

下载后请校验 SHA1：

```powershell
Get-FileHash ai-travel-ledger-v1.2.0+0-cloud-milestone.apk -Algorithm SHA1
```

| 文件 | 描述 | SHA1 |
|---|---|---|
| `ai-travel-ledger-v1.2.0+0-cloud-milestone.apk` | 🏆 **推荐** - Cloud Milestone APK | 见同名 .sha1 |
| `ai-travel-ledger-v1.2.0+0-cloud-milestone.zip` | 同上（含 CHANGELOG） | — |
| `ai-travel-ledger-v1.2.0+0-cloud.apk` | 标准云端版（不带 🏆 徽章） | 见同名 .sha1 |

---

## 🆚 与普通版的区别

普通云端版和 Cloud Milestone 版 **业务逻辑完全相同**，唯一区别是：
- **Milestone 版**：在 About 页面顶部有醒目的金棕色 🏆 徽章 + 里程碑简介
- **视觉区分**：方便分发时识别"这是值得优先测试的版本"

如需装普通云端版（不带徽章），下载 `ai-travel-ledger-v1.2.0+0-cloud.apk` 即可。

---

**发布日期**: 2026-07-14
**Build Variant**: cloud-milestone
**Git Tag**: `milestone-v1.2-cloud`

*由 AI 旅行账本开发团队 + 用户协作完成*
