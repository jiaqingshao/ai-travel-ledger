# AI 旅行账本 — 项目文件目录一览表

**版本**: v0.1
**更新日期**: 2026-06-24
**项目路径**: `C:\Users\jiaqi\.openclaw\workspace\projects\ai-travel-ledger\`

---

## 1. 项目根目录

| 文件 | 说明 |
|---|---|
| `README.md` | 项目主说明文件 |
| `pubspec.yaml` | Flutter 项目依赖配置 |
| `pubspec.lock` | 依赖版本锁定文件 |
| `.gitignore` | Git 忽略规则 |
| `ai-programming-tips.html` | AI 编程技巧参考 |
| `AI编程最佳实践指南.pdf` | AI 编程最佳实践 PDF |
| `gen_pdf.py` | PDF 生成脚本 |
| `stress_test.ps1` | 压力测试脚本 |

---

## 2. `.dart_tool/` — Flutter/Dart 构建缓存

| 目录/文件 | 说明 |
|---|---|
| `package_config.json` | 包配置 |
| `build/entrypoint/` | 构建入口 |
| `build/generated/` | 代码生成文件（Hive 等） |
| `pub/bin/build_runner/` | Build Runner 快照 |

> ⚠️ 此目录为构建缓存，无需手动管理

---

## 3. `.trae/` — Trae IDE 配置

| 文件 | 说明 |
|---|---|
| `instructions.md` | Trae AI 编程指令配置 |

---

## 4. `.vscode/` — VS Code 配置

| 文件 | 说明 |
|---|---|
| `extensions.json` | 推荐扩展列表 |
| `launch.json` | 调试配置 |
| `settings.json` | 工作区设置 |

---

## 5. `assets/` — 资源文件

```
assets/
├── icons/          # 应用图标
│   └── .gitkeep
└── images/         # 图片资源
    └── .gitkeep
```

---

## 6. `design/` — 设计稿

```
design/
├── mockups/        # 界面原型
│   └── .gitkeep
└── wireframes/     # 线框图
    └── .gitkeep
```

---

## 7. `docs/` — 📋 项目文档

### 7.1 `docs/01-requirements/` — 需求文档

| 文件 | 说明 | 版本 |
|---|---|---|
| `01-brainstorm.md` | 需求脑暴记录 | ✅ 完成 |
| `02-prd.md` | 产品需求式样书 | v0.2 |
| `03-fsd.md` | 产品功能式样书 | v0.1 |
| `04-user-stories.md` | 用户故事 | ✅ 完成 |
| `05-competitor-analysis.md` | 竞品分析 | ✅ 完成 |
| `README.md` | 需求文档索引 | — |

### 7.2 `docs/02-architecture/` — 架构文档

| 文件 | 说明 |
|---|---|
| `01-tech-stack.md` | 技术栈选型 |
| `02-system-design.md` | 系统架构设计 |
| `03-data-model.md` | 数据模型定义 |
| `README.md` | 架构文档索引 |
| `04-adr/ADR-001-flutter.md` | ADR-001: Flutter 选型决策 |
| `04-adr/ADR-002-supabase.md` | ADR-002: Supabase 选型决策 |
| `04-adr/ADR-003-ide-choice.md` | ADR-003: IDE 选型决策 |

### 7.3 `docs/03-management/` — 管理文档

| 文件/目录 | 说明 |
|---|---|
| `project-development-guidelines.md` | 项目开发管理规范（v0.1）|
| `risk-register.md` | 风险登记册 |
| `event-log.md` | 任务执行事件日志 |
| `meeting-notes/` | 日报、会议记录 |
| `weekly-reports/` | 周报归档 |

### 7.4 `docs/99-reference/` — 参考资料

| 文件 | 说明 |
|---|---|
| `trae-config-guide.md` | Trae 配置指南 |

---

## 8. `lib/` — 🎯 源代码

```
lib/
├── main.dart                 # 应用入口
├── core/                     # 核心服务
│   ├── ai_config.dart        # AI 配置
│   └── ai_service.dart       # AI 服务
├── data/                     # 数据层
│   ├── datasources/
│   │   ├── local/            # 本地存储 (Hive)
│   │   └── remote/           # 远程存储 (Supabase)
│   ├── models/               # 数据模型
│   │   ├── expense.dart      # 账目模型
│   │   ├── group.dart        # 组模型
│   │   ├── member.dart       # 成员模型
│   │   └── trip.dart         # 旅程模型
│   ├── repositories/         # 仓储
│   └── sync/                 # 同步逻辑
├── domain/                   # 领域层
│   ├── services/
│   │   └── settlement_engine.dart  # 结算引擎
│   └── usecases/             # 用例
└── presentation/             # 展示层
    ├── screens/
    │   └── ai_settings_screen.dart
    └── widgets/
        └── model_selector.dart
```

---

## 9. `roadmap/` — 🗺️ 项目路线图

| 目录/文件 | 说明 |
|---|---|
| `roadmap.md` | 总体路线图 |
| `epic-001-trip-management/epic.md` | Epic 001: 旅程管理 |
| `epic-002-expense-recording/epic.md` | Epic 002: 快速记账 |
| `epic-003-splitting-rules/epic.md` | Epic 003: 分摊规则 |
| `epic-004-settlement-engine/epic.md` | Epic 004: 结算引擎 |
| `epic-005-sharing-export/epic.md` | Epic 005: 分享导出 |

---

## 10. `scripts/` — 脚本

| 文件 | 说明 |
|---|---|
| `setup-flutter.cmd` | Flutter 环境设置脚本（批处理） |
| `setup-flutter.ps1` | Flutter 环境设置脚本（PowerShell） |

---

## 目录结构总览

```
ai-travel-ledger/
│
├── 📄 pubspec.yaml                    # Flutter 项目配置
├── 📄 .gitignore
├── 📄 README.md
│
├── 📁 .dart_tool/                     # 构建缓存（自动生成）
├── 📁 .trae/                          # Trae IDE 配置
├── 📁 .vscode/                        # VS Code 配置
│
├── 📁 assets/                         # 资源文件
│   ├── icons/
│   └── images/
│
├── 📁 design/                         # 设计稿
│   ├── mockups/
│   └── wireframes/
│
├── 📁 docs/                           # 📋 项目文档 ⭐
│   ├── 01-requirements/               # 需求文档
│   ├── 02-architecture/               # 架构文档
│   ├── 03-management/                 # 管理文档 ⭐
│   │   ├── meeting-notes/             # 日报 ⭐
│   │   └── weekly-reports/            # 周报 ⭐
│   └── 99-reference/                  # 参考资料
│
├── 📁 lib/                            # 🎯 源代码 ⭐
│   ├── core/
│   ├── data/
│   ├── domain/
│   └── presentation/
│
├── 📁 roadmap/                        # 🗺️ 路线图
│   ├── roadmap.md
│   └── epic-001~005/
│
└── 📁 scripts/                        # 脚本
    ├── setup-flutter.cmd
    └── setup-flutter.ps1
```

---

## 文件统计

| 类别 | 文件数 | 说明 |
|---|---|---|
| **文档** | 13 | 需求/架构/管理/参考资料 |
| **代码** | 11 | lib 目录下源码 |
| **Epic** | 5 | 5 个功能 Epic |
| **配置** | 6 | .gitignore, pubspec.yaml, IDE 配置等 |
| **脚本** | 2 | Flutter 环境设置 |
| **总计** | **37** | 不含构建缓存 |

---

## 关键目录说明

| 目录 | 用途 | 重要性 |
|---|---|---|
| `docs/01-requirements/` | 需求文档（PRD/FSD/脑暴） | ⭐⭐⭐⭐⭐ |
| `docs/02-architecture/` | 架构设计（技术栈/数据模型/ADR） | ⭐⭐⭐⭐⭐ |
| `docs/03-management/` | 管理文档（规范/风险/报告） | ⭐⭐⭐⭐⭐ |
| `lib/` | 源代码 | ⭐⭐⭐⭐⭐ |
| `roadmap/` | 路线图/Epic 规划 | ⭐⭐⭐⭐ |
| `assets/` | 资源文件 | ⭐⭐⭐ |
| `design/` | 设计稿 | ⭐⭐ |
| `scripts/` | 环境设置脚本 | ⭐⭐ |

> ⭐ 越多越重要

---

## 定时报告

| 报告类型 | Cron 表达式 | 生成时间 | 保存路径 |
|---|---|---|---|
| **开发日报** | `0 0 * * *` | 每天 00:00 | `docs/03-management/meeting-notes/daily-YYYY-MM-DD.md` |
| **开发周报** | `0 0 * * 0` | 每周日 00:00 | `docs/03-management/weekly-reports/weekly-YYYY-WXX.md` |
| **开发月报** | `0 0 1 * *` | 每月 1 号 00:00 | `docs/03-management/monthly-YYYY-MM.md` |

> 📌 报告由 cron 定时任务自动生成，无需手动操作

---

*本文档由 PM 自动生成，随项目演进持续更新。*
