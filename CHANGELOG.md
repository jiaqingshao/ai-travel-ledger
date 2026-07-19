# CHANGELOG - AI 旅行账本

所有重要变更记录在此。

## [Unreleased]

### 🐛 Bug Fixes (Bug 修复)
- **ISSUE-042**: Provider.family 缓存导致编辑不生效 (M-4 → S-26 升级) (2026-07-20)
  - 修 `expenseByIdProvider` / `tripByIdProvider` / `membersByGroupProvider` 3 个 Provider
  - 从 `Provider.family` + `ref.watch(no-op)` 改为 `StreamProvider.autoDispose.family` + `repo.watch()`
  - UI 适配 `AsyncValue` (expense_detail / trip_detail / trip_edit)
  - 加 2 个回归测试 (update 后立刻返回新值)
  - 同根因影响: 改金额/类别/描述/附件不生效, 多设备同步不响应, 热重载不刷新详情页

### 📋 Decisions (决策记录)
- **ADR-004**: PRD v0.3 三个 P0 功能（E-008 语音记账 / E-009 重复费用 / E-010 旅程统计）**暂缓至 V1.1 候选**（2026-07-15）。详见 [`docs/02-architecture/04-adr/ADR-004-prd-v0.3-p0-defer.md`](docs/02-architecture/04-adr/ADR-004-prd-v0.3-p0-defer.md)
- **ADR-005**: 发布路线改为**国内 Android only**（2026-07-15）。详见 [`docs/02-architecture/04-adr/ADR-005-android-cn-only.md`](docs/02-architecture/04-adr/ADR-005-android-cn-only.md)
  - ❌ iOS 适配 暂缓（需 Apple Developer $99/年 + ios/ 从未启用）
  - ❌ Google Play 上架 暂缓（国内无法使用）
  - ✅ 改为 ISSUE-034 国内 Android 上架（华为/小米/OPPO/vivo/应用宝 等）
- **ADR-008** (取代 ADR-007): Phase 1 纯本地模式 + 云功能 V2.0 启用（2026-07-15 13:50）。详见 [`docs/02-architecture/04-adr/ADR-008-phase1-local-only-cloud-deferred.md`](docs/02-architecture/04-adr/ADR-008-phase1-local-only-cloud-deferred.md)
  - ✅ 创始人复查 TCB 个人版 = ¥19.9/月（**不是免费**），ADR-007 撤销
  - ✅ V1.3 Phase 1 = 纯本地（默认 Hive, 无云依赖）
  - ✅ 云代码 / UI / 设置菜单 **完整保留**（未来 V2.0 重启成本极低）
  - ✅ 符合"国内合规 + ¥0 永久"约束
  - 🔄 V2.0 时重新评估云提供商

### Planned (V1.3 候选)
- **国内 Android 上架 (V1.3 Phase 1 = 纯本地版) — [ISSUE-034]**
- ISSUE-026 step 5: 下载所有附件为 ZIP（可选）
- Sentry 崩溃监控接入（可选）
- 多设备 UX（V1.3 限制：只本地多设备间导入导出）

> **v1.3 候选变更**：撤销 ADR-007 TCB 迁移 (ISSUE-036)，V1.3 Phase 1 纯本地。云功能 V2.0 启用时再评估 (ISSUE-037)。

> **v0.3 P0 暂缓说明**: V1.2 cloud-milestone (2026-07-14) 实际交付 P0 = **5 个** (E-001 ~ E-005，其中 E-005 仅子集)。E-008/009/010 不在 V1.3 计划内，**V1.1 重新评估时再决定是否启用**。

---

## [1.1.0] - 2026-07-10 (V1.1 编辑能力)

### ✨ Features (代码已实现, 待 Supabase 包发布)

- **SplitRuleEditPage**: 分摊规则全屏编辑器 (已合并)
- **附件编辑**: 费用详情可修改付款人/时间/分摊规则/附件 (ISSUE-024 修复)
- **"保存并继续"按钮**: 费用输入流优化

### 🔧 Build

- NDK 版本锁定 (避免新 PC 编译漂移)
- `.gitignore release` 屏蔽大产物
- Supabase 工具脚本: `run-with-supabase.ps1` / `build-with-supabase.ps1` / `check_supabase_schema.py`

---

## [1.0.0] - 2026-07-04

### 🎉 首个 Release 版本

完整功能 + 云端同步架构 + 测试覆盖 + 文档齐全。

### ✨ Features (新功能)

#### 核心功能
- **旅程管理**：创建/编辑/删除/归档/恢复
- **成员管理**：增删改查 + 角色（组织者/成员）
- **分组功能**：家庭/公司/部门/团队 + 按组结算
- **记账**：10 个内置类别 + 5 种分摊规则
- **结算**：净收支 + 最优转账（贪心算法）
- **演示数据**：京都赏樱 7 日（3 成员 + 4 笔费用）

#### 云端同步（Supabase）
- 7 张 Postgres 表（profiles, trips, members, groups, expenses, transfers, collaborators）
- RLS 策略（基于协作者角色）
- 3 个权限函数
- 离线优先同步引擎
- Last-write-wins 冲突解决
- 登录/注册 UI

#### UI 设计
- Material 3 主题 + 完整 ColorScheme
- 旅程列表卡片化（蓝色渐变统计卡片）
- 旅程详情财务概览（绿色渐变卡片）
- 渐变空状态插图
- 中文界面完整

### 🛠 Build & Distribution

- **Release APK**: 23.6 MB (vs debug 110MB, 4.6x 压缩)
- **App Bundle AAB**: 23.7 MB (Google Play 上传用)
- **签名**: v1 + v2 双重签名（keystore 已生成）
- **R8 混淆**: minify + shrinkResources

### 🧪 Testing

- **225 个测试全绿** (100% 通过率)
- 单元测试: 单元 (~165)
- 集成测试: 9 个跨层场景
- E2E 测试: 6 个同步流程
- 测试耗时: ~20 秒

### 📚 Documentation

- README.md（项目总览）
- docs/01-requirements/（PRD + FSD）
- docs/02-architecture/（架构 + ADR + 测试报告）
- docs/03-management/（Issue Tracker + 进度报告）
- docs/04-deployment/supabase-deploy-guide.md（部署指南）
- 完整 Supabase 部署脚本

### 🔧 Tech Stack

- Flutter 3.24.5 + Dart 3.5.4
- Riverpod 2.x 状态管理
- Hive 本地存储
- Supabase 云端
- Material 3 设计系统

### 📊 Project Stats

- 代码量: ~5,800 行 Dart
- SQL: 431 行
- 测试: 4,142 行
- 文档: ~3,500 行
- Git commits: 30+

---

## 版本说明

- **Major (1.x)**: 重大功能变更（如 V1.0 = MVP 完成）
- **Minor (1.0.x)**: 新功能添加
- **Patch (1.0.0.x)**: Bug 修复

格式参考：[Semantic Versioning](https://semver.org/)