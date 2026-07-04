# CHANGELOG - AI 旅行账本

所有重要变更记录在此。

## [Unreleased]

### Planned
- 票据照片上传（Supabase Storage）
- iOS 适配
- 实时多人协作 UI
- Google Play 上架

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