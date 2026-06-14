# AI 旅行账本 - 产品功能式样书 (FSD)

**版本**: v0.1 (草稿)
**日期**: 2026-06-14
**状态**: 待 PRD 完成后细化

---

## 1. 旅程管理 - 详细规格

### 1.1 屏幕列表
| 屏幕 | 路径 | 说明 |
|---|---|---|
| 旅程列表 | `/trips` | 所有活跃 + 历史旅程 |
| 创建旅程 | `/trips/new` | 新建表单 |
| 旅程详情（首页） | `/trips/:id` | Dashboard |
| 成员管理 | `/trips/:id/members` | 增删改成员 |
| 旅程设置 | `/trips/:id/settings` | 修改/结束/归档 |

### 1.2 数据模型

#### 1.2.1 旅程 Trip
| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| id | UUID | 是 | 主键 |
| name | string(50) | 是 | 旅程名称 |
| start_date | date | 是 | 出发日期 |
| end_date | date | 否 | 结束日期（可空，进行中） |
| destination | string(100) | 否 | 目的地 |
| base_currency | string(3) | 是 | 基准货币，默认 CNY |
| status | enum | 是 | active / archived |
| created_by | UUID | 是 | 创建者（user_id） |
| created_at | timestamp | 是 | |

#### 1.2.2 成员 Member
| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| id | UUID | 是 | 主键 |
| trip_id | UUID | 是 | 所属旅程 |
| nickname | string(20) | 是 | 昵称 |
| avatar_color | string(7) | 否 | 头像颜色（自动分配） |
| role | enum | 是 | organizer / member |
| user_id | UUID | 否 | 关联真实用户（可空） |
| joined_at | timestamp | 是 | |

### 1.3 业务流程

**创建旅程**:
```
1. 点击"+" → 2. 填写名称、日期、目的地
              ↓
3. 添加成员（输入昵称，可多选）
              ↓
4. 提交 → 5. 跳到旅程详情页
```

**邀请成员加入**:
```
1. 在成员管理页点击"邀请"
              ↓
2. 生成分享链接 / 二维码
              ↓
3. 对方打开链接 → 4. 输入昵称加入
              ↓
5. 实时同步到所有成员的 App
```

### 1.4 异常处理
| 场景 | 处理 |
|---|---|
| 创建旅程时网络异常 | 本地保存草稿，恢复网络后上传 |
| 成员昵称重复 | 自动加后缀（如"张三 2"）|
| 旅程归档后再编辑 | 提示"需先恢复为活跃" |

---

## 2. 快速记账 - 详细规格

### 2.1 屏幕列表
| 屏幕 | 路径 | 说明 |
|---|---|---|
| 账目列表 | `/trips/:id/expenses` | 旅程内所有账目 |
| 记账 | `/trips/:id/expenses/new` | 录入表单 |
| 账目详情 | `/trips/:id/expenses/:eid` | 查看/编辑/删除 |

### 2.2 数据模型

#### 2.2.1 账目 Expense
| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| id | UUID | 是 | 主键 |
| trip_id | UUID | 是 | 所属旅程 |
| payer_id | UUID | 是 | 付款人 |
| amount | decimal(12,2) | 是 | 金额 |
| currency | string(3) | 是 | 货币 |
| category | enum | 是 | 费用类别 |
| description | string(200) | 否 | 备注 |
| occurred_at | timestamp | 是 | 发生时间 |
| created_at | timestamp | 是 | 录入时间 |
| split_rule | JSON | 是 | 分摊规则 |
| attachments | string[] | 否 | 附件 URL 列表（最多 3 个）|
| sync_status | enum | 是 | synced / pending / failed |

#### 2.2.2 费用类别
| 类别代码 | 显示名 | 颜色 | 图标 |
|---|---|---|---|
| food | 餐饮 | 橙 | 🍽️ |
| lodging | 住宿 | 蓝 | 🏨 |
| transport | 交通 | 绿 | 🚗 |
| fuel | 油费 | 黄 | ⛽ |
| toll | 过路费 | 灰 | 🛣️ |
| parking | 停车费 | 紫 | 🅿️ |
| ticket | 门票 | 红 | 🎫 |
| shopping | 购物 | 粉 | 🛍️ |
| entertainment | 娱乐 | 青 | 🎮 |
| other | 其他 | 黑 | 📦 |

#### 2.2.3 分摊规则 SplitRule
```json
{
  "type": "equal" | "ratio" | "shares" | "specific",
  "participants": ["uuid1", "uuid2", ...],
  "values": {
    "uuid1": 1.0,
    "uuid2": 1.0
  }
}
```

| type | 含义 | values 字段含义 |
|---|---|---|
| equal | 全员均摊 | 不使用 |
| ratio | 按比例分摊 | 比例值（总和=1）|
| shares | 按份数分摊 | 份数（整数）|
| specific | 固定金额 | 固定金额 |

### 2.3 业务流程

**快速记账流程（3 步）**:
```
1. 选择付款人
   默认：上次付款人
   备选：所有成员
   
2. 选择费用类别
   默认：上次类别
   9 个常用类别 + "其他"
   
3. 输入金额
   默认：弹出数字键盘
   实时校验
```

**完整记账流程（可选字段）**:
```
[快速 3 步] →
   可选点击"更多"：
   - 添加备注
   - 拍照附件
   - 自定义分摊
   - 修改时间
   - 选择币种
```

### 2.4 性能要求
- 录入响应 < 500ms
- 输入金额时实时校验
- 列表滚动 60fps

---

## 3. 分摊规则 - 详细规格

### 3.1 数据模型
详见 §2.2.3 SplitRule

### 3.2 算法

**均摊**:
```
每人金额 = 总金额 / 参与人数
尾差 = 总金额 - 每人金额 × 参与人数
尾差补偿给第一个成员（按惯例）
```

**比例分摊**:
```
每人金额 = 总金额 × (个人比例 / 总比例)
尾差补偿给比例最大者
```

**份数分摊**:
```
每人金额 = 总金额 × (个人份数 / 总份数)
尾差补偿给份数最多者
```

**固定金额**:
```
每人金额 = values[uuid]
校验：sum(values) = 总金额，否则提示错误
```

### 3.3 UI 流程
```
[选择分摊方式] →
   ├─ 均摊 → 自动分配，无需操作
   ├─ 比例 → 显示每个成员的比例滑块
   ├─ 份数 → 显示每个成员的份数（默认 1）
   └─ 固定 → 显示每个成员的金额输入框
        ↓
   [预览分摊结果] → [确认]
```

---

## 4. 结算引擎 - 详细规格

### 4.1 算法

#### 4.1.1 计算每人净收支
```python
for member in trip.members:
    paid = sum(expense.amount for expense in trip.expenses if expense.payer_id == member.id)
    should_pay = sum(split.amount for split in expense_splits if split.member_id == member.id)
    net[member.id] = paid - should_pay
```

#### 4.1.2 最优转账路径（贪心算法）
```python
def minimize_transfers(balances):
    debtors = sorted([(id, -amt) for id, amt in balances.items() if amt < 0], key=lambda x: -x[1])
    creditors = sorted([(id, amt) for id, amt in balances.items() if amt > 0], key=lambda x: -x[1])
    
    transfers = []
    i, j = 0, 0
    while i < len(debtors) and j < len(creditors):
        d_id, d_amt = debtors[i]
        c_id, c_amt = creditors[j]
        transfer_amt = min(d_amt, c_amt)
        transfers.append((d_id, c_id, transfer_amt))
        
        d_amt -= transfer_amt
        c_amt -= transfer_amt
        
        if d_amt == 0: i += 1
        else: debtors[i] = (d_id, d_amt)
        
        if c_amt == 0: j += 1
        else: creditors[j] = (c_id, c_amt)
    
    return transfers
```

#### 4.1.3 复杂度
- 时间复杂度: O(n log n)（排序）+ O(n)（匹配）
- 空间复杂度: O(n)
- n=15 人时，结算 < 10ms

### 4.2 输出格式

**按个人粒度**:
```json
{
  "trip_id": "uuid",
  "view": "individual",
  "computed_at": "2026-06-14T10:00:00Z",
  "summary": {
    "total_expense": 5000.00,
    "currency": "CNY",
    "member_count": 5,
    "expense_count": 23
  },
  "balances": [
    { "member_id": "uuid1", "nickname": "张三", "net": 800.00 },
    { "member_id": "uuid2", "nickname": "李四", "net": -500.00 }
  ],
  "transfers": [
    { "from": "uuid2", "from_nickname": "李四", "to": "uuid1", "to_nickname": "张三", "amount": 500.00 }
  ]
}
```

**🆕 按组粒度（新增）**:
```json
{
  "trip_id": "uuid",
  "view": "group",
  "computed_at": "2026-06-14T10:00:00Z",
  "summary": {
    "total_expense": 5000.00,
    "currency": "CNY",
    "group_count": 2,
    "member_count": 5,
    "expense_count": 23
  },
  "group_balances": [
    {
      "group_id": "uuid1",
      "group_name": "张家",
      "group_type": "family",
      "net": 800.00,
      "members": [
        { "member_id": "uuid1a", "nickname": "张爸", "net": 500.00 },
        { "member_id": "uuid1b", "nickname": "张妈", "net": 200.00 },
        { "member_id": "uuid1c", "nickname": "张小", "net": 100.00 }
      ]
    },
    {
      "group_id": "uuid2",
      "group_name": "李家",
      "group_type": "family",
      "net": -800.00,
      "members": [
        { "member_id": "uuid2a", "nickname": "李爸", "net": -500.00 },
        { "member_id": "uuid2b", "nickname": "李妈", "net": -300.00 }
      ]
    }
  ],
  "transfers": [
    { "from_group": "李家", "to_group": "张家", "amount": 800.00 }
  ]
}
```

**🆕 组内计算逻辑**:
1. 先按 §4.1.1 计算每人净收支
2. 按 `group_id` 分组累加，得到每组净收支
3. 在"组维度"上跑 §4.1.2 贪心算法
4. 转账列表展示"X家 → Y家，¥Z"

### 4.3 标记已结算
- 成员点击"已转给 XX"按钮
- 该笔转账记录 `settled_at = now()`
- 不影响总账计算（只标记）

---

## 5. 分享导出 - 详细规格 (V1.1)

### 5.1 分享图片
- 自动生成结算单图片（长图）
- 包含：旅程名、总金额、人均、转账列表
- 一键分享到微信/QQ/复制图片

### 5.2 导出 PDF
- 标准格式 PDF
- 包含详细账目列表

---

## 6. 错误码定义

| 错误码 | 说明 | 用户提示 |
|---|---|---|
| E001 | 旅程不存在 | "该旅程已删除" |
| E002 | 权限不足 | "你没有权限操作" |
| E003 | 金额非法 | "请输入有效金额" |
| E004 | 网络异常 | "网络异常，请稍后重试" |
| E005 | 同步失败 | "保存失败，已暂存本地" |

---

*此文档由 PM + Tech Lead 共同维护*
