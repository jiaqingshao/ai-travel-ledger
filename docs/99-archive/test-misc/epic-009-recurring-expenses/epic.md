# Epic: 重复费用 (Recurring Expenses)

- **ID:** E-009
- **状态:** 未开始
- **优先级:** P0（v0.3 新增）
- **目标:** 一次设置，长期自动记账

## 背景

2026-06-28 市场调研发现：
- Splitwise Pro 的 **Recurring Expenses** 是付费转化核心功能
- 长期旅程 / 包车 / 民宿场景强烈需要（"每周一付民宿 800"）
- 国内同类基本没做好，是个差异化机会

## 验收标准

- [ ] 支持固定周期：每天/每周/每月/每年
- [ ] 支持自定义日期触发（每月 15 号发工资）
- [ ] 一次性设置，长期生效
- [ ] 可暂停/恢复
- [ ] 可编辑金额和周期
- [ ] 提前 1 天通知（可选）
- [ ] 历史生成记录可查
- [ ] 智能跳过节假日（可选，V1.1）
- [ ] 支持组维度（"张家每周一付民宿"）

## Task 清单

| ID | Task | 状态 | 备注 |
|----|------|------|------|
| T-001 | 数据模型：recurring_expenses 表 | Backlog | 见 Data Model §2.8 |
| T-002 | 重复费用规则创建 UI | Backlog | 类向导 |
| T-003 | 周期计算器（next_due 字段自动更新）| Backlog | cron 表达式 |
| T-004 | 自动生成账目任务（本地 cron）| Backlog | workmanager 包 |
| T-005 | 历史生成记录视图 | Backlog | |
| T-006 | 编辑/暂停/恢复/删除 | Backlog | |
| T-007 | 提前通知（FCM / 本地通知）| Backlog | flutter_local_notifications |
| T-008 | 节假日跳过配置 | Backlog | V1.1 |
| T-009 | 同步：跨设备规则同步 | Backlog | |
| T-010 | 单元测试：周期边界条件 | Backlog | |

## 数据模型

新增表 `recurring_expenses`，详见 `docs/02-architecture/03-data-model.md` §2.8。

关键字段：
- `template` JSONB：账目模板（payer_id, category, amount, split_rule）
- `frequency` TEXT：daily/weekly/monthly/yearly
- `interval` INT：每 N 个周期
- `day_of_week` INT：0-6（仅 weekly）
- `day_of_month` INT：1-31（仅 monthly）
- `next_due` DATE：下次触发日
- `enabled` BOOLEAN：是否启用

## 备注

- **本地优先**：规则存本地，跨设备同步 V1.1
- **手动触发**：支持"立即生成一笔"，用于补录
- **生成后通知**：生成后推送"已自动记账"消息，避免重复录入
- **金额跟随**：支持"按指数调整"（房租每年涨 5%）V1.1

## 用户故事参考

- US-015: 设置每周自动记账