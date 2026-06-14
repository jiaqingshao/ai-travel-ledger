# AI 旅行账本 - Trae 项目指令

> 这是给 Trae AI 读的项目说明。当用户在本项目中提问时，请遵循以下原则。

## 项目背景

- **产品名**: AI 旅行账本 (AI Travel Ledger)
- **一句话定位**: 自驾游/团队游场景的智能记账与分摊工具
- **目标用户**: 3-15 人的自驾游/朋友/家庭/同事团队
- **目标平台**: Android（首发），iOS（V1.1）
- **技术栈**: Flutter (Dart) + Supabase

## 开发原则

1. **MVP 优先** - 先完成 P0 核心功能（旅程管理/记账/分摊/结算），不追求完美
2. **3 秒记账** - 录入流程要极简，不超过 3 次点击
3. **离线优先** - 支持弱网/无网环境（自驾场景信号差）
4. **中文优先** - 界面、提示、错误信息全部中文

## 核心功能模块

1. **旅程管理 (epic-001)** - 创建/编辑/结束旅程，添加成员
2. **快速记账 (epic-002)** - 选付款人→选类型→填金额→保存
3. **分摊规则 (epic-003)** - 均摊/比例/部分人参与
4. **结算引擎 (epic-004)** - 自动算"谁给谁多少钱"，优化转账
5. **分享导出 (epic-005)** - 生成结算图，一键分享

## 重要文档位置

- 需求文档: `docs/01-requirements/`
- 架构文档: `docs/02-architecture/`
- 任务清单: `roadmap/`
- 风险登记: `docs/03-management/risk-register.md`

## 代码规范

- **命名**: 变量/函数 `camelCase`，类 `PascalCase`，常量 `UPPER_SNAKE_CASE`
- **注释**: 关键业务逻辑必须有中文注释
- **提交规范**: `feat:` / `fix:` / `docs:` / `refactor:` / `test:` 前缀
- **分支**: `feature/xxx`、`hotfix/xxx`，禁止直改 `main`

## 不要做的事

- ❌ 不要做泛记账（专注自驾游/团队游场景）
- ❌ 不要做旅途规划（交给专业 App）
- ❌ 不要引入未在 ADR 中讨论的技术栈
- ❌ 不要在代码里写英文用户提示（必须中文）

## 常见任务路径

- **新增屏幕**: `lib/screens/<feature>/<name>_screen.dart`
- **新增组件**: `lib/widgets/<feature>/<name>_widget.dart`
- **数据模型**: `lib/models/<entity>.dart`
- **BaaS 调用**: `lib/services/<entity>_service.dart`
- **状态管理**: Riverpod (推荐) 或 Provider
