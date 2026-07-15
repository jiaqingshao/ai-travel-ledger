# 数据模型 (Data Model)

**最后更新**: 2026-07-15 (PR-Y1.2 重写)
**基于**: V1.3.0-phase1-local pre-release commit `a12f65e`

---

## 📊 模型总览

| 模型 | Hive TypeId | 用途 |
|---|---|---|
| **Trip** | 0 | 旅程 |
| **Member** | 1 | 成员 |
| **Group** | 2 | 分组（家庭/公司/部门/团队/其他）|
| **Expense** | 3 | 费用 |
| **Attachment** | 4 | 附件元数据 |
| **SplitRule** (sealed) | — | 分摊规则（5 种）|
| **ExpenseCategory** (enum) | — | 类别（10 种 + other）|
| **SyncStatus** (enum) | — | 同步状态 |
| **TransferRecord** | 14 | 已结清转账 |
| **TripCollaborator** | 12 | 旅程协作者（云端权限）|
| **Profile** | 10 | 用户扩展信息 |

---

## 🏠 本地优先模型 (Hive)

Hive 作为本地真相源（local-first），云端仅同步（Phase 1 不推云，ADR-008）。

### Trip（旅程）

```dart
@HiveType(typeId: 0)
class Trip extends HiveObject {
  @HiveField(0) String id;            // UUID
  @HiveField(1) String name;          // 旅程名
  @HiveField(2) DateTime? startDate;
  @HiveField(3) DateTime? endDate;
  @HiveField(4) String? destination;   // 目的地
  @HiveField(5) String? baseCurrency;  // 基础货币 (如 'CNY')
  @HiveField(6) String createdBy;      // 用户ID（云模式 = auth.users.id）
  @HiveField(7) bool archived;         // 是否归档
  @HiveField(8) DateTime createdAt;
  @HiveField(9) DateTime? updatedAt;
  @HiveField(10) String? status;       // 状态: preparing/ongoing/ended/archived
}
```

### Member（成员）

```dart
@HiveType(typeId: 1)
class Member extends HiveObject {
  @HiveField(0) String id;            // UUID
  @HiveField(1) String tripId;        // FK -> Trip.id
  @HiveField(2) String nickname;       // 显示名
  @HiveField(3) String role;          // organizer / member
  @HiveField(4) String? avatarColor;   // 头像色 (hex)
  @HiveField(5) String? groupId;       // FK -> Group.id (归属组)
  @HiveField(6) DateTime createdAt;
  @HiveField(7) DateTime? updatedAt;
  @HiveField(8) bool active;          // 是否在当前活跃组中（用于过滤）
}
```

### Group（分组）

```dart
@HiveType(typeId: 2)
class Group extends HiveObject {
  @HiveField(0) String id;            // UUID
  @HiveField(1) String tripId;        // FK -> Trip.id
  @HiveField(2) String name;          // 组名（"张家" / "公司" 等）
  @HiveField(3) String type;          // family / company / dept / team / other
  @HiveField(4) String? color;        // 色值 (hex)
  @HiveField(5) DateTime createdAt;
  @HiveField(6) DateTime? updatedAt;
}
```

### Expense（费用）⭐ 最复杂

```dart
@HiveType(typeId: 3)
class Expense extends HiveObject {
  @HiveField(0) String id;                   // UUID
  @HiveField(1) String tripId;               // FK -> Trip.id
  @HiveField(2) String? payerId;             // FK -> Member.id 付款人
  @HiveField(3) double amount;               // 金额（保留 2 位小数）
  @HiveField(4) String currency;             // 货币代码（如 'CNY'）
  @HiveField(5) ExpenseCategory category;    // 类别枚举
  @HiveField(6) String? description;         // 备注
  @HiveField(7) DateTime occurredAt;         // 发生日期
  @HiveField(8) DateTime createdAt;
  @HiveField(9) String splitRuleJson;        // 序列化 SplitRule
  @HiveField(10) List<String> attachments;  // 附件 URL 列表 (云存储路径)
  @HiveField(11) String? attachmentMetadata; // V1.2 JSONB 元数据 (结构化备份)
  @HiveField(12) SyncStatus syncStatus;      // pending/synced/failed
  @HiveField(13) DateTime? deletedAt;        // 软删除时间
  @HiveField(14) DateTime? updatedAt;
}
```

**字段说明**：

- **`splitRuleJson`**: 5 种分摊规则的 JSON 字符串（见 SplitRule sealed class）
- **`attachments`**: URL 字符串列表（云存储路径，比如 `expense-attachments/{tripId}/{expenseId}/{uuid}.jpg`）
- **`attachmentMetadata`**: V1.2 新增，JSONB 格式：
  ```json
  {
    "items": [
      {
        "url": "https://xxx.supabase.co/...",
        "fileName": "receipt.jpg",
        "sizeBytes": 12345,
        "mimeType": "image/jpeg",
        "uploadedAt": "2026-07-12T..."
      }
    ]
  }
  ```
  双写策略：URL 同步到 `attachments` (text[]) 保持兼容 + JSONB 存结构化数据

### Attachment（附件元数据）

```dart
@HiveType(typeId: 4)
class Attachment extends HiveObject {
  @HiveField(0) String url;          // 完整 URL
  @HiveField(1) String? fileName;    // 原始文件名
  @HiveField(2) int? sizeBytes;
  @HiveField(3) String? mimeType;
  @HiveField(4) String? uploadedAt;  // ISO 8601
}
```

### TransferRecord（已结清转账）

```dart
@HiveType(typeId: 14)
class TransferRecord extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String tripId;             // FK -> Trip.id
  @HiveField(2) String fromMemberId;       // 应付方
  @HiveField(3) String toMemberId;         // 应收方
  @HiveField(4) double amount;             // 金额
  @HiveField(5) DateTime settledAt;        // 结清时间
  @HiveField(6) String? note;              // 备注（"微信转账"等）
}
```

**重要**: TransferRecord **不依附 Expense**（注释明确）。
它按 `tripId + fromMemberId + toMemberId` 关联——每次结算由 settlement engine 重新计算。

---

## 🔄 分摊规则（SplitRule sealed）

5 种分摊规则，由 Dart sealed class 实现：

```dart
sealed class SplitRule {
  Map<String, dynamic> toJson();
}

// 1. 均摊
class SplitEqual extends SplitRule { List<String> memberIds; }

// 2. 按比例
class SplitRatios extends SplitRule { Map<String, double> ratios; /* 归一化到 1.0 */ }

// 3. 按份数
class SplitShares extends SplitRule { Map<String, int> shares; }

// 4. 固定金额
class SplitFixed extends SplitRule { Map<String, double> amounts; }

// 5. 按组（v0.3 独家）
class SplitByGroup extends SplitRule { List<String> groupIds; }
```

**使用**: `Expense.splitRuleJson` 是这些 splitRule `toJson()` 的字符串。

---

## 🛜 云端模型（Supabase Postgres）

⚠️ V1.3 Phase 1 = **纯本地模式**（ADR-008），云端代码/架构保留但**不启用**。
云端 syncStatus/deletedAt 字段保留作 V2.0 重启时使用。

7 张表 + 3 条 RLS（参考 `supabase/migrations/00001_initial_schema.sql`）：

### 1. profiles
- 与 Supabase auth.users 1:1
- 含 `handle_new_user` trigger 自动创建

### 2. trips
- 含 `trip_status` ENUM ('preparing', 'ongoing', 'ended', 'archived')

### 3. members
- FK -> trips
- role: organizer / member

### 4. groups
- FK -> trips
- type: family / company / dept / team / other

### 5. expenses
- ⚠️ 含 `sync_status` ENUM ('pending', 'synced', 'failed')
- ⚠️ 含 `attachment_metadata` JSONB 字段（V1.2 新增，由 00003 迁移添加）

### 6. transfers (transfer_records)

### 7. trip_collaborators
- 含 `role` 字段（用于 RLS）

### RLS 策略 (00002)

- **trips**: 仅 trips.owner_id = auth.uid() 可读写
- **members/groups/expenses/transfers**: 通过 trip_collaborators 间接 RLS
- **trip_collaborators**: 仅 owner 可管理

### Storage 策略 (00003)

- **expense-attachments** bucket: 公开读 / 协作者写 / owner 删

---

## 📦 Hive Box 布局（lib/data/boxes.dart）

```dart
class HiveBoxes {
  Box<Trip> trips;            // typeId 0
  Box<Member> members;        // typeId 1
  Box<Group> groups;          // typeId 2
  Box<Expense> expenses;      // typeId 3
  Box<Attachment> attachments; // typeId 4
  Box<Profile> profiles;      // typeId 10
  Box<TripCollaborator> tripCollaborators;  // typeId 12
  Box<TransferRecord> transferRecords;       // typeId 14
  Box<AppSettings> appSettings;              // typeId 100+
}
```

---

## 🔧 migration 历史

| 版本 | 文件 | 内容 |
|---|---|---|
| 00001 | `00001_initial_schema.sql` | 7 张表 + 索引 |
| 00002 | `00002_rls_policies.sql` | RLS 策略 + 3 个 helper function |
| 00003 | `00003_expense_attachments_storage.sql` | expense-attachments bucket + attachment_metadata JSONB + sync trigger |

---

## 📋 与代码一致性（PR-Y1.2 修复确认）

| 检查项 | 状态 |
|---|---|
| Expense.attachmentMetadata 字段存在 | ✅ PR-3 + V1.2 step 1 (commit 34355b4) |
| SyncStatus 枚举 | ✅ lib/data/models/sync_status.dart |
| TransferRecord 不带 expenseId | ✅ 设计意图 |
| Attachment 模型独立 | ✅ V1.2 step 2 引入 |
| Group.type 枚举 (5 种) | ✅ |

---

*生成时间: 2026-07-15 17:10*
*对应 commit: a12f65e (V1.3.0-phase1-local pre-release)*
