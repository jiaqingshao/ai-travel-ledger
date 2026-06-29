# AI 旅行账本 — Phase 1 测试计划

**版本**: v1.0
**日期**: 2026-06-29
**作者**: QA Agent
**适用范围**: Task 1.1-1.5 (Phase 1 - 数据模型 + 结算引擎 + 存储)
**基于文档**:
- docs/01-requirements/03-fsd-detailed.md v0.4
- docs/02-architecture/03-data-model.md v0.2

---

## 一、测试目标

| 维度 | 目标 |
|------|------|
| 单元测试覆盖率 | ≥ 70%（核心模块 ≥ 90%） |
| 性能基线 | 100 笔账目结算 < 1 秒 |
| 集成场景 | 端到端流程可跑通，无数据丢失 |
| AC 覆盖 | Phase 1 范围 P0 AC 100% 覆盖 |

## 二、模块覆盖率目标

| 模块 | 用例数 | 覆盖率目标 | 严重度 |
|------|--------|-----------|--------|
| SettlementEngine.calculateNetBalances | 5 | ≥ 95% | P0 |
| SettlementEngine.minimizeTransfers | 5 | ≥ 95% | P0 |
| SettlementEngine.byGroup | 3 | ≥ 90% | P0 |
| SplitCalculator (4 种类型) | 8 | ≥ 90% | P0 |
| DuplicateDetector | 4 | ≥ 85% | P0 |
| 数据模型序列化 | 4 | ≥ 80% | P0 |
| 集成场景 | 3 | 100% 流程 | P0 |
| **合计** | **32** | - | - |

## 三、性能基线

| 场景 | 数据规模 | 性能目标 | 测试方法 |
|------|----------|----------|----------|
| 结算 100 笔账目 | 5 成员 × 100 笔 | < 1 秒 | Stopwatch 包裹 |
| 结算 500 笔账目 | 5 成员 × 500 笔 | < 3 秒 | 压力测试 |
| Hive 序列化 1000 笔 | - | < 500ms | 批量读写 |
| 重复检测 1000 笔历史 | 1000 笔 | < 50ms | O(n) 扫描 |

## 四、边界条件清单

- [B1] 空成员列表（expenses 为空，balances 全为 0）
- [B2] 单成员（自己付自己全单，无转账）
- [B3] 极端金额（0.01 元 / 1,000,000 元 / 浮点精度）
- [B4] 零金额 / 负金额（应拒绝）
- [B5] 净收支完全平衡（无转账路径）
- [B6] 所有余额都向一个人集中（极端债权/债务）
- [B7] 浮点尾差（100/3=33.33...）
- [B8] 跨日账目（occurredAt 不同日期）
- [B9] 未确认账目（approvalStatus != confirmed）应被排除
- [B10] 软删除账目（deletedAt != null）应被排除
- [B11] 组成员为空
- [B12] 重复检测：同日同金额同类同人
- [B13] 跨日边界（00:00:00）
- [B14] 序列化往返一致性
- [B15] 字段缺省值
- [B16] 100 成员压力（性能上限）

---

## 五、测试用例详细设计

### 模块 1：SettlementEngine.calculateNetBalances

#### TC-SE-CNB-01: 正常场景 — 5 成员均摊
- **标题**: 5 成员均摊 5 笔账目，验证净收支计算正确
- **前置**: members=[A,B,C,D,E]，expenses=[A付100均摊5人, B付50均摊5人, C付200均摊5人, D付30均摊5人, E付20均摊5人]
- **输入**:
  - expenses = [100, 50, 200, 30, 20] 分别由 A,B,C,D,E 支付
  - splits = 每笔均摊给所有 5 人
- **预期输出**:
  - 每人支付: A=100, B=50, C=200, D=30, E=20
  - 每人应付: 400/5 = 80
  - 净收支: A=+20, B=-30, C=+120, D=-50, E=-60
  - 余额总和 = 0
- **边界**: [B16]
- **严重度**: P0
- **对应 AC**: AC-25

#### TC-SE-CNB-02: 未确认账目排除
- **标题**: approvalStatus=unconfirmed 的账目不计入净收支
- **前置**: 1 笔已确认 100 元 (payer=A)，1 笔未确认 50 元 (payer=B)
- **输入**: 5 成员，未确认账目的 split 也传入
- **预期输出**:
  - 净收支仅基于 100 元那笔
  - 未确认的 50 元被忽略
- **边界**: [B9]
- **严重度**: P0
- **对应 AC**: AC-25, AC-15

#### TC-SE-CNB-03: 空账目列表
- **标题**: expenses=[] 时所有成员余额为 0
- **前置**: 5 成员
- **输入**: expenses=[], splits={}
- **预期输出**:
  - 所有成员余额 = 0.0
  - 余额总和 = 0
- **边界**: [B1]
- **严重度**: P0
- **对应 AC**: AC-25

#### TC-SE-CNB-04: 极端大金额（1,000,000）
- **标题**: 1 笔 1,000,000 元，无浮点精度损失
- **前置**: 2 成员
- **输入**: payer=A, amount=1,000,000, split=50/50
- **预期输出**:
  - A 余额 = +500,000
  - B 余额 = -500,000
  - 误差 < 0.001
- **边界**: [B3]
- **严重度**: P0

#### TC-SE-CNB-05: 浮点尾差处理（100/3=33.33...）
- **标题**: 总额 100 元分给 3 人，尾差给第一人
- **前置**: 3 成员
- **输入**: payer=A, amount=100.00, split 均摊 3 人
- **预期输出**:
  - A=100-33.33-33.33-33.34 = +0.00 (含尾差)
  - 余额总和 = 0
- **边界**: [B7]
- **严重度**: P0

---

### 模块 2：SettlementEngine.minimizeTransfers

#### TC-SE-MT-01: 简单 2 人转账
- **标题**: A 应收 100，B 应付 100 → 1 笔转账
- **前置**: balances = {A: 100, B: -100}
- **输入**: minimizeTransfers(balances)
- **预期输出**:
  - transfers = [{from: B, to: A, amount: 100}]
  - 笔数 = 1（最优）
- **严重度**: P0
- **对应 AC**: AC-26

#### TC-SE-MT-02: 多人贪心 — 最大债权 + 最大债务
- **标题**: balances = {A: 300, B: -200, C: -100}
- **前置**: 3 成员
- **输入**: minimizeTransfers
- **预期输出**:
  - B → A: 200
  - C → A: 100
  - 笔数 = 2（最优）
- **边界**: [B6]
- **严重度**: P0
- **对应 AC**: AC-26

#### TC-SE-MT-03: 多对多贪心（链式）
- **标题**: balances = {A: 200, B: -100, C: -50, D: -50}
- **前置**: 4 成员
- **输入**: minimizeTransfers
- **预期输出**:
  - 3 笔转账
  - 总金额 = 200（所有 debt 都被还清）
  - 排序：大债权 A 先被还
- **严重度**: P0
- **对应 AC**: AC-26

#### TC-SE-MT-04: 完全平衡（无转账）
- **标题**: 所有余额 = 0
- **前置**: balances = {A: 0, B: 0, C: 0}
- **输入**: minimizeTransfers
- **预期输出**:
  - transfers = []
  - 笔数 = 0
- **边界**: [B5]
- **严重度**: P0

#### TC-SE-MT-05: 浮点容差（±0.01 内视为 0）
- **标题**: balance = 0.005 应被忽略
- **前置**: balances = {A: 100, B: -99.99, C: -0.005, D: -0.005}
- **输入**: minimizeTransfers
- **预期输出**:
  - C, D 被忽略（abs < 0.01）
  - transfers = [{B → A: 99.99}]
- **边界**: [B7]
- **严重度**: P0
- **对应 AC**: AC-26

---

### 模块 3：SettlementEngine.byGroup

#### TC-SE-BG-01: 两组结算
- **标题**: 张家(+800) 与 李家(-500) → 张家应收李家 500
- **前置**: groups=[张家, 李家, 未分组]，每个组含若干成员
- **输入**: 成员 balances 聚合到组
- **预期输出**:
  - transfers = [{from: 李家, to: 张家, amount: 500}]
  - 组名正确（不显示 UUID）
- **严重度**: P0
- **对应 AC**: AC-28, AC-29

#### TC-SE-BG-02: 未分组成员
- **标题**: 部分成员 groupId=null
- **前置**: 1 个张家成员 + 1 个未分组成员
- **输入**: 成员 balances
- **预期输出**:
  - 未分组成员归到 __no_group__ 虚拟组
  - GroupSettlement 中 groupName = '未分组'
- **严重度**: P0
- **对应 AC**: AC-28

#### TC-SE-BG-03: 多组多成员
- **标题**: 3 组（家、公司、其他），各含 2 成员
- **前置**: 6 成员
- **输入**: 6 成员的 balances 聚合到 3 组
- **预期输出**:
  - 组维度的 balances 正确聚合
  - 贪心算法在组维度上跑
  - 输出 GroupSettlement 列表
- **严重度**: P0
- **对应 AC**: AC-28, AC-29

---

### 模块 4：SplitCalculator

#### TC-SC-EA-01: equalAll — 100/3 浮点尾差
- **标题**: 100 元分给 3 人
- **输入**: totalAmount=100, memberIds=[A,B,C]
- **预期输出**:
  - {A: 33.34, B: 33.33, C: 33.33} (尾差给第一人)
  - 总和 = 100
- **边界**: [B7]
- **严重度**: P0
- **对应 AC**: AC-21, AC-12

#### TC-SC-EA-02: equalAll — 1 人
- **标题**: 100 元分给 1 人
- **输入**: totalAmount=100, memberIds=[A]
- **预期输出**:
  - {A: 100.0}
- **边界**: [B2]
- **严重度**: P0

#### TC-SC-ES-01: equalSelected — 指定 3 人
- **标题**: 100 元均摊给 B,C,D（不含 A）
- **输入**: totalAmount=100, memberIds=[B,C,D]
- **预期输出**:
  - {B: 33.34, C: 33.33, D: 33.33}
- **严重度**: P0
- **对应 AC**: AC-12

#### TC-SC-BG-01: byGroup — 两组均摊
- **标题**: 200 元分给张家(2人) + 李家(3人)
- **输入**: totalAmount=200, groups=[张家(2), 李家(3)]
- **预期输出**:
  - 张家每人 40，李家每人 40（共 5 人）
  - {张家A: 40, 张家B: 40, 李家A: 40, 李家B: 40, 李家C: 40}
- **严重度**: P0
- **对应 AC**: AC-22, AC-12

#### TC-SC-BG-02: byGroup — 组内空
- **标题**: groups 都为空 memberIds
- **输入**: groups=[]，totalAmount=100
- **预期输出**:
  - 返回 {} (空 Map)
- **边界**: [B11]
- **严重度**: P0

#### TC-SC-BG-03: byGroup — 跨日期快照
- **标题**: 组变更后历史账目仍正确
- **输入**: 用旧的 SplitGroupSnapshot 调用
- **预期输出**:
  - 仍按快照时的组员计算，不引用当前 member.groupId
- **严重度**: P0
- **对应 AC**: AC-23, AC-8

#### TC-SC-BM-01: byMember — 固定金额正确
- **标题**: 100 元由用户手动分配 A=50, B=30, C=20
- **输入**: totalAmount=100, values={A:50, B:30, C:20}
- **预期输出**:
  - {A: 50, B: 30, C: 20}
- **严重度**: P0
- **对应 AC**: AC-21

#### TC-SC-BM-02: byMember — sum 不等报错
- **标题**: 100 元分配 A=50, B=30, C=15 (sum=95)
- **输入**: totalAmount=100, values={A:50, B:30, C:15}
- **预期输出**:
  - 抛 AssertionError 或返回错误
  - 错误信息明确指出 sum mismatch
- **严重度**: P0
- **对应 AC**: AC-21

---

### 模块 5：DuplicateDetector

#### TC-DD-01: 同日同金额同类同人 → 重复
- **标题**: 完全匹配
- **输入**:
  - new: payer=A, amount=100, category=food, occurredAt=2026-06-29 10:00
  - existing: payer=A, amount=100, category=food, occurredAt=2026-06-29 12:00
- **预期输出**: true（重复）
- **严重度**: P0
- **对应 AC**: AC-14

#### TC-DD-02: 同日但金额不同 → 不重复
- **标题**: 金额 0.01 差异
- **输入**:
  - new: amount=100
  - existing: amount=100.01
- **预期输出**: false
- **严重度**: P0

#### TC-DD-03: 跨日边界（23:59:59 vs 00:00:01）
- **标题**: 跨日不算重复
- **输入**:
  - new: occurredAt=2026-06-29 00:00:01
  - existing: occurredAt=2026-06-28 23:59:59
- **预期输出**: false
- **边界**: [B13]
- **严重度**: P0
- **对应 AC**: AC-14

#### TC-DD-04: 不同类别 → 不重复
- **标题**: 同金额同人同时段，类别不同
- **输入**:
  - new: category=food
  - existing: category=lodging
- **预期输出**: false
- **严重度**: P0
- **对应 AC**: AC-14

---

### 模块 6：数据模型序列化

#### TC-DM-01: Trip JSON 往返
- **标题**: Trip → JSON → Trip 无字段丢失
- **输入**: Trip(name='东京', startDate=2026-07-01, ...)
- **预期输出**:
  - 序列化后 JSON 包含所有字段
  - 反序列化后字段值完全一致（id/createdAt 等）
- **严重度**: P0
- **对应 AC**: AC-1

#### TC-DM-02: Expense with SplitRule 嵌套序列化
- **标题**: Expense 嵌套 SplitRule JSON
- **输入**: Expense + SplitRule(equalAll, participants)
- **预期输出**:
  - splitRule JSON 正确嵌套
  - 反序列化后 SplitRule.type/participants 保留
- **严重度**: P0
- **对应 AC**: AC-12

#### TC-DM-03: Hive Box 持久化往返
- **标题**: Expense 写入 Hive 后读出字段一致
- **输入**: Hive box, Expense 实例
- **预期输出**:
  - 读出的 Expense 与写入一致
  - DateTime 精度保留（毫秒）
- **严重度**: P0
- **对应 AC**: AC-1, AC-9

#### TC-DM-04: 缺省值反序列化
- **标题**: JSON 缺字段时使用缺省值
- **输入**: JSON 缺 attachments/endDate
- **预期输出**:
  - attachments = []
  - endDate = null
  - 其他字段正常
- **边界**: [B15]
- **严重度**: P0

---

### 模块 7：集成场景

#### TC-INT-01: 端到端 — 创建旅程 → 记账 → 结算 → 转账
- **标题**: 完整流程
- **步骤**:
  1. 创建 Trip（5 成员）
  2. 添加 10 笔 expense（不同付款人、不同分摊）
  3. 调用 SettlementEngine.calculateNetBalances
  4. 调用 SettlementEngine.minimizeTransfers
  5. 生成 Settlement 记录
  6. 生成 Transfer 记录
- **预期输出**:
  - Settlement 包含 balances + transfers
  - 余额总和 = 0
  - 转账笔数最优
  - Hive 持久化后能查回
- **严重度**: P0
- **对应 AC**: AC-25, AC-26, AC-27, AC-30

#### TC-INT-02: 组变更 → 历史账目仍正确
- **标题**: 账目创建后修改成员所在组
- **步骤**:
  1. 创建 Trip，成员 A 在组 G1
  2. 用 SplitGroupSnapshot(G1 含 A) 记账
  3. 修改 A.groupId = G2
  4. 重算该历史账目
- **预期输出**:
  - 历史账目仍按 G1 快照计算
  - 不受 A 当前 groupId 变化影响
- **严重度**: P0
- **对应 AC**: AC-8, AC-23

#### TC-INT-03: 100 笔账目结算性能
- **标题**: 性能基线
- **步骤**:
  1. 创建 5 成员
  2. 随机生成 100 笔 expense
  3. 用 Stopwatch 包裹 SettlementEngine
- **预期输出**:
  - calculateNetBalances < 200ms
  - minimizeTransfers < 100ms
  - 总耗时 < 1 秒
- **边界**: [B16]
- **严重度**: P0
- **对应 AC**: AC-31

---

## 六、测试数据 Fixtures

### 标准测试集（5 成员）
`
member_A: organizer
member_B: member
member_C: member
member_D: member
member_E: member
`

### 边界测试集
- 1 成员 [B2]
- 0 成员 [B1]
- 100 成员 [B16]
- 极小金额 0.01 [B3]
- 极大金额 1,000,000 [B3]

## 七、AC 覆盖矩阵

| AC | 覆盖用例 | 状态 |
|----|---------|------|
| AC-1 | TC-DM-01, TC-DM-03 | ✅ |
| AC-8 | TC-INT-02 | ✅ |
| AC-12 | TC-SC-EA-01, TC-SC-ES-01, TC-SC-BG-01 | ✅ |
| AC-14 | TC-DD-01, TC-DD-03, TC-DD-04 | ✅ |
| AC-15 | TC-SE-CNB-02 | ✅ |
| AC-21 | TC-SC-EA-01, TC-SC-BM-01, TC-SC-BM-02 | ✅ |
| AC-22 | TC-SC-BG-01 | ✅ |
| AC-23 | TC-SC-BG-03, TC-INT-02 | ✅ |
| AC-25 | TC-SE-CNB-01..05 | ✅ |
| AC-26 | TC-SE-MT-01..05 | ✅ |
| AC-27 | TC-INT-01 | ✅ |
| AC-28 | TC-SE-BG-01..03 | ✅ |
| AC-30 | TC-INT-01 | ✅ |
| AC-31 | TC-INT-03 | ✅ |

**Phase 1 P0 AC 覆盖：100%**

## 八、风险与依赖

| 风险 | 影响 | 缓解 |
|------|------|------|
| 浮点精度（100/3）| 尾差 | _adjustRounding 统一处理 |
| 时间戳时区 | 跨日判断 | 统一使用本地时区 |
| Hive 版本兼容 | 序列化失败 | 锁定 hive_flutter 1.x |
| 算法极端情况 | 性能 | n=15 限制 + 性能测试 |

## 九、QA 验收标准

Phase 1 完成的验收条件：
1. ✅ 32 个测试用例全部实现并通过
2. ✅ 单元测试覆盖率 ≥ 70%（核心模块 ≥ 90%）
3. ✅ 100 笔账目结算 < 1 秒
4. ✅ 无 P0/P1 级别 Bug
5. ✅ 集成测试 3 个场景全部通过
6. ✅ AC 覆盖率 100%

## 十、用例统计

| 模块 | 用例数 | 通过标准 |
|------|--------|----------|
| SettlementEngine.calculateNetBalances | 5 | 100% |
| SettlementEngine.minimizeTransfers | 5 | 100% |
| SettlementEngine.byGroup | 3 | 100% |
| SplitCalculator | 8 | 100% |
| DuplicateDetector | 4 | 100% |
| 数据模型序列化 | 4 | 100% |
| 集成场景 | 3 | 100% |
| **合计** | **32** | **100%** |

---

*此测试计划由 QA Agent 设计，所有用例需 dev 阶段实现并由 QA 独立验证通过*
