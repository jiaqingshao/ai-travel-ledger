# AI 旅行账本 (AI Travel Ledger)

> 让自驾游团队告别"算账半小时，扯皮两小时"

## 项目状态

| 项 | 值 |
|---|---|
| **阶段** | 阶段 1 - 需求对齐（当前） |
| **版本** | v0.1 |
| **创建日期** | 2026-06-14 |
| **目标平台** | Android 首发，iOS (V1.1) |

## 一句话定位

专门为自驾游/团队游场景设计的智能记账与分摊工具，让多人 AA 结算从 30 分钟缩短到 30 秒。

## 目标用户

### 主要用户
- 自驾游/团队游（3-15 人）—— 朋友、情侣、家庭、同事
- 25-45 岁，周末周边游 + 长假长途游
- 痛点：付款分散、算账扯皮、记账麻烦

### 次要用户（V1.1+）
- 户外俱乐部、驴友群、毕业旅行、亲子游、公司团建

### V2.0 客户群
- 企业团建、商业活动（报销场景）

## 核心价值

1. **3 秒快速记账** — 极简录入流程
2. **智能分摊规则** — 均摊 / 比例 / 部分人参与
3. **最优结算路径** — 自动减少转账笔数
4. **中文场景优化** — 红包、AA、自驾专属分类（油费/过路费/停车费）

## MVP 功能 (P0)

| 功能 | 状态 | 文档 |
|---|---|---|
| 旅程管理 | 📝 待开发 | [E-001](roadmap/epic-001-trip-management/epic.md) |
| 快速记账 | 📝 待开发 | [E-002](roadmap/epic-002-expense-recording/epic.md) |
| 基础分摊 | 📝 待开发 | [E-003](roadmap/epic-003-splitting-rules/epic.md) |
| 结算引擎 | 📝 待开发 | [E-004](roadmap/epic-004-settlement-engine/epic.md) |

## 技术栈

| 类别 | 选型 | 理由 |
|---|---|---|
| 移动端 | **Flutter (Dart)** | 跨平台、AI 生成质量高、对 C 程序员友好 |
| 后端 | **Supabase** | Postgres+Auth+Storage 一体化、免费层够用 |
| IDE | **Trae** | 中文友好、免费 |
| AI 模型 | **本地 Qwen3.6** + 云端 API | 几乎 0 token 费 |
| 设计 | Figma + Galileo AI | 设计稿转代码 |

## 目录结构

```
ai-travel-ledger/
├── README.md                  # 本文件
├── docs/
│   ├── 01-requirements/       # 需求（脑暴/PRD/FSD/用户故事/竞品）
│   ├── 02-architecture/       # 架构（技术栈/系统设计/数据模型/ADR）
│   └── 03-management/         # 管理（会议/周报/风险）
├── design/                    # UI 设计稿
├── roadmap/                   # wbs-planner 工作分解
│   ├── roadmap.md
│   ├── epic-001-trip-management/
│   ├── epic-002-expense-recording/
│   ├── epic-003-splitting-rules/
│   ├── epic-004-settlement-engine/
│   └── epic-005-sharing-export/
└── assets/                    # 资源（图片/图标）
```

## 阶段进度

- [x] **阶段 0** - 立项 ✅
- [ ] **阶段 1** - 需求对齐（**当前**）
  - [ ] 需求脑暴
  - [ ] PRD 撰写
  - [ ] FSD 撰写
  - [ ] 用户故事
  - [ ] 竞品分析
- [ ] **阶段 2** - 架构设计
- [ ] **阶段 3** - 规划落地（Roadmap/Epic/Task 拆分）
- [ ] **阶段 4** - 迭代交付

## 里程碑

- **M1 内测版 (T+2 月)**：E-001~E-004 完整功能
- **M2 正式版 1.0 (T+3 月)**：E-005~E-007，Google Play 上架
- **M3 商业版 2.0 (T+6 月)**：E-008~E-010，付费功能

## License

Private / 内部项目
