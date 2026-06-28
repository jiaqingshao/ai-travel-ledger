# AI 旅行账本 — 项目文件目录结构一览表

**版本**: v1.0
**更新日期**: 2026-06-25
**项目路径**: `C:\Users\jiaqi\.openclaw\workspace\projects\ai-travel-ledger\`
**状态**: 需求对齐完成，待启动开发

---

## 📁 项目根目录

| 文件名 | 说明 | 状态 |
|---|---|---|
| `README.md` | 项目主说明文件，包含项目定位、目标用户、核心功能、技术栈、里程碑 | ✅ 已完成 |
| `pubspec.yaml` | Flutter 项目依赖配置文件 | ✅ 已完成 |
| `pubspec.lock` | 依赖版本锁定文件（自动生成） | ✅ 已完成 |
| `.gitignore` | Git 忽略规则，排除编译产物和敏感信息 | ✅ 已完成 |
| `ai-programming-tips.html` | AI 编程技巧参考文档 | ✅ 已完成 |
| `AI编程最佳实践指南.pdf` | AI 编程最佳实践 PDF 资料 | ✅ 已完成 |
| `gen_pdf.py` | PDF 生成脚本（Python） | ✅ 已完成 |
| `stress_test.ps1` | 压力测试 PowerShell 脚本 | ✅ 已完成 |
| `directory-guide.md` | 项目文件目录指南 | ✅ 已完成 |

---

## 📁 .dart_tool/ — Flutter/Dart 构建缓存

| 目录/文件 | 说明 | 自动生成 |
|---|---|---|
| `package_config.json` | Dart 包配置 | ✅ |
| `package_config_subset` | 包配置子集 | ✅ |
| `version` | Flutter 版本信息 | ✅ |
| `build/entrypoint/` | 构建入口文件 | ✅ |
| `build/generated/` | 代码生成文件（Hive 模型等） | ✅ |
| `build_resolvers/` | 构建解析器缓存 | ✅ |
| `pub/bin/build_runner/` | Build Runner 快照 | ✅ |

> ⚠️ 此目录为构建缓存，无需手动管理，已添加到 `.gitignore`

---

## 📁 .trae/ — Trae IDE 配置

| 文件名 | 说明 | 状态 |
|---|---|---|
| `instructions.md` | Trae AI 编程指令配置，定义 AI 助手在项目中的角色和行为准则 | ✅ 已完成 |

---

## 📁 .vscode/ — VS Code 配置

| 文件名 | 说明 | 状态 |
|---|---|---|
| `extensions.json` | 推荐安装的 VS Code 扩展列表 | ✅ 已完成 |
| `launch.json` | 调试配置（Flutter 运行/调试） | ✅ 已完成 |
| `settings.json` | 工作区特定设置 | ✅ 已完成 |

---

## 📁 assets/ — 资源文件

| 目录/文件 | 说明 | 状态 |
|---|---|---|
| `icons/.gitkeep` | 图标占位符（待添加应用图标） | ✅ |
| `images/.gitkeep` | 图片资源占位符（待添加素材） | ✅ |

---

## 📁 design/ — 设计稿

| 目录/文件 | 说明 | 状态 |
|---|---|---|
| `mockups/.gitkeep` | 界面原型占位符（待添加设计稿） | ✅ |
| `wireframes/.gitkeep` | 线框图占位符（待添加线框图） | ✅ |

---

## 📁 docs/01-requirements/ — 需求文档

| 文件名 | 说明 | 版本 | 状态 |
|---|---|---|---|
| `README.md` | 需求文档索引，列出所有需求文档 | — | ✅ |
| `01-brainstorm.md` | 需求脑暴记录，包含用户痛点、市场机会、功能列表 | v0.1 | ✅ |
| `02-prd.md` | 产品需求式样书，包含产品定位、目标用户、核心功能、商业模式 | v0.2 | ✅ |
| `03-fsd.md` | 产品功能式样书，详细功能描述、界面说明、交互流程 | v0.1 | ✅ |
| `04-user-stories.md` | 用户故事，按 Epic 组织，包含验收标准 | v0.1 | ✅ |
| `05-competitor-analysis.md` | 竞品分析，对比 Splitwise、百事 AA 记账、AA 账本、圈子账本 | v0.1 | ✅ |

**核心需求摘要**：
- **一句话定位**：专为自驾游/团队游场景设计的智能记账与分摊工具
- **核心价值**：3 秒快速记账 + 智能分摊 + 最优结算 + 中文场景优化
- **目标市场**：中国大陆 Android 用户（5 亿+）
- **商业模式**：免费版（基础功能）+ 高级版（￥18/月）+ 企业版（V2）
- **MVP 功能**：旅程管理、快速记账、基础分摊、结算引擎（4 个 Epic）

---

## 📁 docs/02-architecture/ — 架构文档

| 文件名 | 说明 | 版本 | 状态 |
|---|---|---|---|
| `README.md` | 架构文档索引 | — | ✅ |
| `01-tech-stack.md` | 技术选型，对比 Flutter/React Native/Kotlin/Swift，最终选 Flutter | v0.1 | ✅ |
| `02-system-design.md` | 系统架构设计，包含整体架构图、模块划分、数据流 | v0.1 | ✅ |
| `03-data-model.md` | 数据模型，定义 Trip/Member/Expense/Group 等实体及关系 | v0.1 | ✅ |
| `04-adr/ADR-001-flutter.md` | ADR-001: Flutter 选型决策记录 | — | ✅ |
| `04-adr/ADR-002-supabase.md` | ADR-002: Supabase 选型决策记录 | — | ✅ |
| `04-adr/ADR-003-ide-choice.md` | ADR-003: IDE 选型决策记录（Trae 主 + Cursor 备） | — | ✅ |

**架构要点**：
- **分层架构**：Presentation → Domain → Data → Infrastructure
- **本地优先**：Hive 本地存储 + 异步同步到 Supabase
- **离线优先**：无网络也能记账，恢复后自动同步
- **分组快照**：账目记录分组快照，后续组变更不影响历史数据

---

## 📁 docs/03-management/ — 管理文档

| 文件名 | 说明 | 版本 | 状态 |
|---|---|---|---|
| `project-development-guidelines.md` | 项目开发管理规范（团队架构/代码管理/文档管理/测试规范/KPI/汇报机制） | v0.1 | ✅ |
| `risk-register.md` | 风险登记册，列出所有风险及应对方案 | v0.1 | ✅ |
| `event-log.md` | 任务执行事件日志，记录失败任务及修复情况 | v0.1 | ✅ |
| `meeting-notes/README.md` | 会议记录目录说明 | — | ✅ |
| `meeting-notes/daily-*.md` | 每日开发日报（自动生成） | — | ✅ |
| `weekly-reports/README.md` | 周报归档目录说明 | — | ✅ |

**管理规范要点**：
- **团队架构**：PM + 开发 A（后端）+ 开发 B（前端）+ QA（测试）
- **代码管理**：Git + GitHub、原子化提交、语义化 commit、分支保护
- **文档管理**：版本控制、变更记录、审批流程
- **测试规范**：单元测试 + 集成测试 + E2E 测试 + 质量门禁
- **KPI 指标**：每个角色 5 项 KPI，每周/月考核
- **汇报机制**：日报（每日 00:00）+ 周报（每周日 00:00）+ 月报（每月 1 号 00:00）

---

## 📁 docs/99-reference/ — 参考资料

| 文件名 | 说明 | 状态 |
|---|---|---|
| `trae-config-guide.md` | Trae 配置指南，包含 AI 模型配置、环境变量、项目设置 | ✅ |

---

## 📁 lib/ — 🎯 源代码

### lib/ — 主入口

| 文件 | 说明 | 状态 |
|---|---|---|
| `main.dart` | 应用入口，初始化依赖、配置、路由 | ✅ 骨架 |

### lib/core/ — 核心服务

| 文件 | 说明 | 状态 |
|---|---|---|
| `ai_config.dart` | AI 模型配置（M3 + Qwen3.6 35B 本地） | ✅ |
| `ai_service.dart` | AI 服务接口定义 | ✅ 骨架 |

### lib/data/ — 数据层

#### lib/data/models/ — 数据模型

| 文件 | 说明 | 状态 |
|---|---|---|
| `trip.dart` | 旅程模型（id, name, dates, status, currency...） | ✅ |
| `trip.g.dart` | Trip 模型的 JSON 序列化（自动生成） | ✅ |
| `member.dart` | 成员模型（id, tripId, nickname, avatarColor, role...） | ✅ |
| `member.g.dart` | Member 模型的 JSON 序列化（自动生成） | ✅ |
| `expense.dart` | 账目模型（id, tripId, payerId, amount, category, splitRule...） | ✅ |
| `expense.g.dart` | Expense 模型的 JSON 序列化（自动生成） | ✅ |
| `group.dart` | 组模型（id, tripId, name, groupType, color...） | ✅ |
| `group.g.dart` | Group 模型的 JSON 序列化（自动生成） | ✅ |

#### lib/data/datasources/ — 数据源

| 目录/文件 | 说明 | 状态 |
|---|---|---|
| `local/` | 本地数据源（Hive/SQLite） | ⏸️ 待开发 |
| `remote/` | 远程数据源（Supabase REST/GraphQL） | ⏸️ 待开发 |

#### lib/data/repositories/ — 仓储

| 目录/文件 | 说明 | 状态 |
|---|---|---|
| `*` | 仓储接口 + 实现（抽象数据访问） | ⏸️ 待开发 |

#### lib/data/sync/ — 同步逻辑

| 目录/文件 | 说明 | 状态 |
|---|---|---|
| `*` | 本地优先同步策略、冲突解决、重复检测 | ⏸️ 待开发 |

### lib/domain/ — 领域层

#### lib/domain/services/ — 领域服务

| 文件 | 说明 | 状态 |
|---|---|---|
| `settlement_engine.dart` | 结算引擎（贪心算法 + 按组聚合） | ✅ 骨架 |

#### lib/domain/usecases/ — 用例

| 目录/文件 | 说明 | 状态 |
|---|---|---|
| `*` | 用例类（创建旅程、记录账目、结算等） | ⏸️ 待开发 |

### lib/presentation/ — 展示层

#### lib/presentation/screens/ — 页面

| 文件 | 说明 | 状态 |
|---|---|---|
| `ai_settings_screen.dart` | AI 模型设置页面 | ✅ 骨架 |

#### lib/presentation/widgets/ — 组件

| 文件 | 说明 | 状态 |
|---|---|---|
| `model_selector.dart` | 模型选择器组件 | ✅ 骨架 |

---

## 📁 roadmap/ — 🗺️ 路线图

| 文件/目录 | 说明 | 状态 |
|---|---|---|
| `roadmap.md` | 总体路线图（M1 内测 → M2 正式版 → M3 商业版） | ✅ |
| `epic-001-trip-management/epic.md` | Epic 001: 旅程管理（创建/邀请/分组/状态管理） | ✅ |
| `epic-002-expense-recording/epic.md` | Epic 002: 快速记账（10 类别 + 4 分摊类型 + 票据上传） | ✅ |
| `epic-003-splitting-rules/epic.md` | Epic 003: 分摊规则（均摊/按比例/部分人参与/按组） | ✅ |
| `epic-004-settlement-engine/epic.md` | Epic 004: 结算引擎（贪心算法 + 最优路径） | ✅ |
| `epic-005-sharing-export/epic.md` | Epic 005: 分享导出（账单分享、PDF 导出、截图） | ✅ |

---

## 📁 scripts/ — 脚本

| 文件名 | 说明 | 状态 |
|---|---|---|
| `setup-flutter.cmd` | Flutter 环境设置脚本（批处理） | ✅ |
| `setup-flutter.ps1` | Flutter 环境设置脚本（PowerShell） | ✅ |

---

## 📊 文件统计

| 类别 | 文件数 | 说明 |
|---|---|---|
| **文档** | 14 | 需求/架构/管理/参考资料 |
| **代码** | 11 | lib 目录下源码（骨架） |
| **Epic** | 5 | 5 个功能 Epic 文档 |
| **配置** | 6 | .gitignore, pubspec.yaml, IDE 配置 |
| **资源** | 4 | .gitkeep 占位符 |
| **脚本** | 2 | Flutter 环境设置 |
| **参考资料** | 2 | HTML + PDF |
| **总计** | **44** | 不含构建缓存 |

---

## 📈 目录结构总览

```
ai-travel-ledger/
│
├── 📄 pubspec.yaml                    # Flutter 项目配置
├── 📄 .gitignore                      # Git 忽略规则
├── 📄 README.md                       # 项目主说明
├── 📄 ai-programming-tips.html        # AI 编程技巧参考
├── 📄 AI编程最佳实践指南.pdf          # AI 编程最佳实践 PDF
├── 📄 gen_pdf.py                     # PDF 生成脚本
├── 📄 stress_test.ps1                # 压力测试脚本
├── 📄 directory-guide.md             # 项目文件目录指南
│
├── 📁 .dart_tool/                     # 构建缓存（自动生成）
├── 📁 .trae/                          # Trae IDE 配置
│   └── instructions.md
├── 📁 .vscode/                        # VS Code 配置
│   ├── extensions.json
│   ├── launch.json
│   └── settings.json
│
├── 📁 assets/                         # 资源文件
│   ├── icons/
│   └── images/
│
├── 📁 design/                         # 设计稿（占位）
│   ├── mockups/
│   └── wireframes/
│
├── 📁 docs/                           # 📋 项目文档 ⭐⭐⭐⭐⭐
│   ├── 01-requirements/               # 需求文档 ⭐⭐⭐⭐⭐
│   │   ├── README.md
│   │   ├── 01-brainstorm.md           # 脑暴记录
│   │   ├── 02-prd.md                  # PRD v0.2
│   │   ├── 03-fsd.md                  # FSD v0.1
│   │   ├── 04-user-stories.md         # 用户故事
│   │   └── 05-competitor-analysis.md  # 竞品分析
│   ├── 02-architecture/               # 架构文档 ⭐⭐⭐⭐⭐
│   │   ├── README.md
│   │   ├── 01-tech-stack.md           # 技术栈
│   │   ├── 02-system-design.md        # 系统架构
│   │   ├── 03-data-model.md           # 数据模型
│   │   └── 04-adr/                    # 架构决策记录
│   │       ├── ADR-001-flutter.md
│   │       ├── ADR-002-supabase.md
│   │       └── ADR-003-ide-choice.md
│   ├── 03-management/                 # 管理文档 ⭐⭐⭐⭐⭐
│   │   ├── project-development-guidelines.md  # 管理规范
│   │   ├── risk-register.md           # 风险登记册
│   │   ├── event-log.md              # 事件日志
│   │   ├── meeting-notes/             # 日报归档
│   │   │   ├── README.md
│   │   │   └── daily-YYYY-MM-DD.md   # 日报文件
│   │   └── weekly-reports/            # 周报归档
│   │       └── README.md
│   └── 99-reference/                  # 参考资料
│       └── trae-config-guide.md
│
├── 📁 lib/                            # 🎯 源代码 ⭐⭐⭐⭐⭐
│   ├── main.dart                      # 入口
│   ├── core/                          # 核心服务
│   │   ├── ai_config.dart
│   │   └── ai_service.dart
│   ├── data/                          # 数据层
│   │   ├── datasources/               # 数据源
│   │   │   ├── local/                 # 本地存储
│   │   │   └── remote/                # 远程存储
│   │   ├── models/                    # 数据模型 ⭐
│   │   │   ├── trip.dart
│   │   │   ├── member.dart
│   │   │   ├── expense.dart
│   │   │   └── group.dart
│   │   ├── repositories/              # 仓储
│   │   └── sync/                      # 同步逻辑
│   ├── domain/                        # 领域层
│   │   ├── services/                  # 领域服务
│   │   │   └── settlement_engine.dart # 结算引擎
│   │   └── usecases/                  # 用例
│   └── presentation/                  # 展示层
│       ├── screens/                   # 页面
│       └── widgets/                   # 组件
│
├── 📁 roadmap/                        # 🗺️ 路线图
│   ├── roadmap.md
│   ├── epic-001-trip-management/epic.md
│   ├── epic-002-expense-recording/epic.md
│   ├── epic-003-splitting-rules/epic.md
│   ├── epic-004-settlement-engine/epic.md
│   └── epic-005-sharing-export/epic.md
│
└── 📁 scripts/                        # 脚本
    ├── setup-flutter.cmd
    └── setup-flutter.ps1
```

---

## ⭐ 重要度标注

| 标记 | 说明 | 说明 |
|---|---|---|
| ⭐⭐⭐⭐⭐ | **核心文件** | 必须维护，直接影响项目 |
| ⭐⭐⭐⭐ | **重要文件** | 对开发有重要影响 |
| ⭐⭐⭐ | **一般文件** | 对开发有一定影响 |
| ⭐⭐ | **辅助文件** | 参考资料，非必需 |
| ⭐ | **可选文件** | 锦上添花 |

---

## 📅 定时报告

| 报告类型 | Cron 表达式 | 生成时间 | 保存路径 |
|---|---|---|---|
| **开发日报** | `0 0 * * *` | 每天 00:00 | `docs/03-management/meeting-notes/daily-YYYY-MM-DD.md` |
| **开发周报** | `0 0 * * 0` | 每周日 00:00 | `docs/03-management/weekly-reports/weekly-YYYY-WXX.md` |
| **开发月报** | `0 0 1 * *` | 每月 1 号 00:00 | `docs/03-management/monthly-YYYY-MM.md` |

> 📌 报告由 cron 定时任务自动生成，无需手动操作

---

## 🔄 版本历史

| 版本 | 日期 | 变更内容 |
|---|---|---|
| v0.1 | 2026-06-14 | 项目骨架初始化 |
| v0.2 | 2026-06-17 | PRD/FSD 更新，增加分组功能 |
| v1.0 | 2026-06-25 | 生成项目文件目录结构一览表 |

---

*本文档由 PM 自动生成，随项目演进持续更新。*
