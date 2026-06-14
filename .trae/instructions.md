# AI 旅行账本 - Trae 项目指令

> 这是给 Trae AI 读的项目说明。当用户在本项目中提问时，请遵循以下原则。

## 项目背景

- **产品名**: AI 旅行账本 (AI Travel Ledger)
- **一句话定位**: 自驾游/团队游场景的智能记账与分摊工具，让多人 AA 结算从 30 分钟缩短到 30 秒
- **目标用户**: 3-15 人的自驾游/朋友/家庭/同事团队
- **目标平台**: Android（首发），iOS（V1.1）
- **技术栈**: Flutter 3.x (Dart) + Supabase + Riverpod

## 当前进度（2026-06-14）

- ✅ **阶段 0**: 立项 + 项目骨架
- ✅ **阶段 1**: 文档（PRD/FSD/用户故事/竞品分析/数据模型/3 个 ADR）
- ✅ **阶段 2**: 架构设计（技术选型 + 系统设计 + 数据模型 + ADR）
- ✅ **阶段 3**: Roadmap + 5 个 Epic
- 🚧 **阶段 4**: Flutter 项目初始化（进行中）
  - ✅ lib 三层架构（core/data/domain/presentation）
  - ✅ AI 模型接入（lib/core/ai_config.dart + ai_service.dart）
  - ✅ 数据模型（Trip, Member, TripGroup, Expense）
  - ✅ 结算引擎（lib/domain/services/settlement_engine.dart）
  - ⬜ 旅程管理 UI（E-001）

## 开发原则

1. **MVP 优先** - 先完成 P0 核心功能（旅程管理/记账/分摊/结算），不追求完美
2. **3 秒记账** - 录入流程要极简，不超过 3 次点击
3. **离线优先** - 支持弱网/无网环境（自驾场景信号差）
4. **中文优先** - 界面、提示、错误信息全部中文
5. **AI 优先** - 复杂功能让 Trae AI 生成代码，PM 负责验收

## AI 模型策略

| 任务类型 | 用什么模型 | 理由 |
|---|---|---|
| 复杂 Agent 任务 | **MiniMax M3**（云端） | 1M 上下文、能力强 |
| 多文件重构 | MiniMax M3 | 理解力强 |
| 日常代码补全 | Qwen3.6 35B（本地） | 免费、快 |
| 文档撰写 | Qwen3.6 | 中文友好、免费 |
| 简单问答 | Qwen3.6 | 免费 |
| 敏感代码 | Qwen3.6 | 数据不出本机 |

## 重要文档位置

- 需求文档: `docs/01-requirements/`
  - 脑暴: `01-brainstorm.md`
  - PRD: `02-prd.md` ⭐
  - FSD: `03-fsd.md` ⭐
  - 用户故事: `04-user-stories.md`
  - 竞品: `05-competitor-analysis.md`
- 架构文档: `docs/02-architecture/`
  - 技术选型: `01-tech-stack.md`
  - 系统设计: `02-system-design.md`
  - 数据模型: `03-data-model.md` ⭐
  - ADR: `04-adr/`
- 任务清单: `roadmap/` ⭐
- 风险登记: `docs/03-management/risk-register.md`
- Trae 配置: `docs/99-reference/trae-config-guide.md`

## 代码架构（已建）

```
lib/
├── main.dart                          # 入口（含 ProviderScope）
├── core/                              # 核心层
│   ├── ai_config.dart                # AI 模型配置（Riverpod）
│   └── ai_service.dart               # AI 服务（OpenAI 兼容 + fallback）
├── data/                              # 数据层
│   ├── models/                        # 数据模型
│   │   ├── trip.dart                 # 旅程
│   │   ├── member.dart               # 成员
│   │   ├── group.dart                # 🆕 组（家庭/企业/部门/团队/其他）
│   │   └── expense.dart              # 账目 + SplitRule
│   ├── datasources/                   # 数据源
│   │   ├── local/                    # Hive + SQLite
│   │   └── remote/                   # Supabase
│   ├── repositories/                  # 仓库
│   └── sync/                          # 同步逻辑
├── domain/                            # 业务逻辑层
│   ├── usecases/                      # 业务用例
│   └── services/                      # 核心服务
│       └── settlement_engine.dart    # 结算引擎（含按组聚合）
└── presentation/                      # UI 层
    ├── screens/                       # 屏幕
    │   └── ai_settings_screen.dart   # AI 设置页（已建）
    └── widgets/                       # 组件
        └── model_selector.dart       # 模型选择器（已建）
```

## 代码规范

- **命名**: 变量/函数 `camelCase`，类 `PascalCase`，常量 `UPPER_SNAKE_CASE`
- **注释**: 关键业务逻辑必须有中文注释
- **提交规范**: `feat:` / `fix:` / `docs:` / `refactor:` / `test:` 前缀
- **分支**: `feature/xxx`、`hotfix/xxx`，禁止直改 `main`
- **状态管理**: Riverpod（**不是** Provider）
- **路由**: go_router（暂未集成）
- **本地存储**: Hive（**主**） + SQLite（复杂查询）

## 关键数据模型

### Trip
- id, name, startDate, endDate?, destination?, baseCurrency, status, createdBy, createdAt

### Member  
- id, tripId, nickname, avatarColor?, role, userId?, **groupId?**, joinedAt

### TripGroup 🆕
- id, tripId, name, **groupType** (family/company/department/team/other), color?

### Expense
- id, tripId, payerId, amount, currency, category, description?, occurredAt, **splitRuleJson**, attachments, syncStatus, deletedAt?

### SplitRule (JSON)
```json
{
  "type": "equal" | "ratio" | "shares" | "specific",
  "participants": [
    { "type": "group", "id": "..." },
    { "type": "member", "id": "..." }
  ],
  "values": { "id1": 1.0 }
}
```

## 不要做的事

- ❌ 不要做泛记账（专注自驾游/团队游场景）
- ❌ 不要做旅途规划（交给专业 App）
- ❌ 不要引入未在 ADR 中讨论的技术栈
- ❌ 不要在代码里写英文用户提示（必须中文）
- ❌ 不要用 Provider 状态管理（用 Riverpod）
- ❌ 不要 commit `*.g.dart`、`pubspec.lock`、二进制大文件
- ❌ 不要在 API Key 字段写真实 key（用 `REPLACE_WITH_YOUR_xxx_KEY` 占位）

## 下一步任务（优先级排序）

1. 集成 Supabase（lib/data/datasources/remote/）
2. 集成 Hive 本地存储（lib/data/datasources/local/）
3. 旅程列表 + 创建 UI（E-001）
4. 成员管理 + 组管理 UI（E-001）
5. 快速记账 UI（E-002）
6. 分摊规则 UI（E-003）
7. 结算单 UI（E-004）

## 联系

- 项目问题: 查看 `docs/01-requirements/` 和 `docs/02-architecture/`
- 风险: `docs/03-management/risk-register.md`
- 配置问题: `docs/99-reference/trae-config-guide.md`
