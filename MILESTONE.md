# 🏆 AI 旅行账本 - 里程碑版本说明

> 本文档记录每个里程碑版本的**意义、特性、定义**，
> 帮助你判断何时该用里程碑版、何时该用普通版。

---

## 🎯 里程碑版本 vs 普通版本的区别

| 类型 | 何时用 | About 页面 | APK 文件名 |
|---|---|---|---|
| **普通版 (local / cloud)** | 日常开发 / 内测 / 灰度 | 标准页面 | `...-local.apk` / `...-cloud.apk` |
| **里程碑版** | 重大功能完成 / 推荐给用户测试 | 顶部带 🏆 金棕色徽章 | `...-cloud-milestone.apk` |

里程碑版 = **同代码 + 额外徽章**，不会改动业务逻辑。
仅作为"提醒/标榜"用途，让测试/分发时一眼能识别"这是值得优先体验的版本"。

---

## 🏆 Milestone 1: `cloud-v1.2`

**Tag**: `🏆 Cloud Milestone`
**ID**: `cloud-v1.2`
**日期**: 2026-07-14
**Git Tag**: `milestone-v1.2-cloud`
**APK**: `release\v1.2.0+0-cloud-milestone\ai-travel-ledger-v1.2.0+0-cloud-milestone.apk`

### 为什么是里程碑？

**AI 旅行账本从"纯本地工具"升级为"云端协作工具"。**

之前 (v0.x ~ v1.0)：
- 纯本地，所有数据存在手机 SQLite/Hive
- 卸载 APP = 数据清空
- 不能跨设备同步
- 备份靠手动导出

现在 (v1.2 milestone)：
- ✅ **原生集成 Supabase 云同步**：7 张 Postgres 表 + Storage 上传 + Realtime 订阅
- ✅ **零配置安装**：用户不用填 URL/Key（开发者预编译进 APK）
- ✅ **多设备同步**：登录任意邮箱即可跨设备访问同一份数据
- ✅ **RLS 保护**：数据访问受 Row Level Security 限制，账号隔离
- ✅ **离线兜底**：网络断开 → 自动回退本地模式，恢复连接 → 自动重连
- ✅ **附件云端备份**：V1.2 起的所有附件自动上传 Supabase Storage
- ✅ **完整的服务端基座**：为 V1.3 团队协作 / V2.0 企业版铺路

### 包含 83 个 commits + 250/250 测试

| 里程碑进度 | 日期 | 描述 |
|---|---|---|
| `v1.0.0` | 2026-07-04 | 首次 Release（基础记账/分摊/结算） |
| `v0.2.0` | 2026-07-10 | V1.1（分摊规则可编辑 + 费用详情编辑） |
| `v1.0.0-local` | 2026-07-11 | 真机反馈修复包（ISSUE-027~030） |
| **`🏆 v1.2-cloud`** | **2026-07-14** | **首版云端（V1.2 附件 + 云同步上线）** |

### 用户视角的"这是什么"

> 如果你身边有朋友想用 AA 记账工具，
> 推荐装这个 **🏆 Cloud Milestone** 版本：
>
> - **3 秒快速记账**：输入金额 → 选付款人 → 一键保存
> - **智能分摊**：均摊/比例/份数/固定/按组 5 种方式
> - **多设备同步**：手机和电脑都能看到
> - **附件照片**：发票拍一下直接存云端
> - **AI 旅行账本 · 云**：launcher 看到这个标题就是云端版

### 技术栈里程碑

- **前后端**：Flutter 3.24 + Riverpod 2.x + Supabase BaaS
- **数据**：本地 Hive + 远端 Postgres 7 张表 + Storage bucket
- **安全**：JWT anon key + RLS + service_role 隔离
- **构建**：GitHub-style release workflow + PowerShell build scripts

---

## 📦 里程碑版本发布流程

```
1. 完成一组大特性            (e.g. 接入云同步)
2. 写 MILESTONE.md 条目       (本文档)
3. 标记 git tag               (git tag -a milestone-v1.X-cloud -m "...")
4. 构建 milestone APK         (pwsh scripts\build-cloud-milestone.ps1)
5. 复制到 NAS 真机目录        (自动)
6. 推 git tag 到远端          (git push origin milestone-v1.X-cloud)
7. 通知用户 / 推 Play Store
```

---

## 🆕 下一个里程碑候选

> ⚠️ **v1.3-team 暂缓**（详见 [ADR-005](docs/02-architecture/04-adr/ADR-005-android-cn-only.md)），改为 `v1.3-cn-stores`

- **`v1.3-cn-stores`** ⭐ 推荐 — **国内 Android 上架**（华为/小米/OPPO/vivo/应用宝/360 等，ISSUE-034）
  - 前置: R011 软著 + R012 ICP 备案 评估
  - V1.3 起点试水: 1-2 个主流商店（如小米 + OPPO）
  - 配套: 隐私政策 + 用户协议 + 应用截图 + 各商店 IAP 接入
- `v2.0-enterprise` — 企业版（部门/项目/审批流）
- `v2.0-ai` — AI 智能识别小票（OCR 自动记账，海外 iOS + Google Play 时启用）

### ⏸️ 暂缓候选

- ⏸️ **iOS 适配**（ADR-005，无 Apple Developer 付费计划 + ios/ 从未启用；重启条件：付费账号 + 全球市场）
- ⏸️ **Google Play 上架**（ADR-005，国内无法访问；重启条件：海外市场计划）
- ⏸️ **V1.1 候选**（ADR-004）

---

*最后更新：2026-07-15 — ADR-005 调整发布路线为国内 Android only*
*维护者: AI 旅行账本开发团队*
