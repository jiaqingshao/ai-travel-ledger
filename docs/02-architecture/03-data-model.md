# 数据模型 (Data Model)

**版本**: v0.2（基于 PRD v0.3，新增语音/重复/统计相关表）
**日期**: 2026-06-28

---

## 一、实体关系图 (ER)

```
┌──────────┐ 1       ∞ ┌──────────┐ 1       ∞ ┌──────────┐
│   User   │───────────│   Trip   │───────────│ Expense  │
│          │           │          │           │          │
└──────────┘           └────┬─────┘           └────┬─────┘
                            │ 1                    │ ∞
                            │                      │
                            │ ∞                    │ 1
                      ┌─────┴─────┐           ┌────┴─────┐
                      │  Member   │           │  Payer   │
                      │           │           │ (Member) │
                      └─────┬─────┘           └──────────┘
                            │ ∞
                            │  🆕 可选属于
                            │ ∞
                      ┌─────┴─────┐
                      │   Group   │  🆕
                      │(家庭/部门) │
                      └───────────┘
                            │ ∞
                            │
                            │ ∞
                      ┌─────┴─────┐ 1       ∞ ┌──────────┐
                      │Settlement │───────────│ Transfer │
                      │  (逻辑)   │           │  (行项)  │
                      └───────────┘           └──────────┘

  ┌──────────┐ 1       ∞ ┌──────────────┐
  │ Expense  │───────────│ ExpenseSplit │
  │          │           │              │
  └──────────┘           └──────────────┘
```

---

## 二、Postgres 表结构

### 2.1 users（用户）
```sql
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           TEXT UNIQUE,
    phone           TEXT UNIQUE,
    nickname        TEXT NOT NULL,
    avatar_url      TEXT,
    created_at      TIMESTAMPTZ DEFAULT now(),
    updated_at      TIMESTAMPTZ DEFAULT now()
);
```

### 2.2 trips（旅程）
```sql
CREATE TYPE trip_status AS ENUM ('active', 'archived');

CREATE TABLE trips (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            TEXT NOT NULL CHECK (length(name) <= 50),
    start_date      DATE NOT NULL,
    end_date        DATE,
    destination     TEXT,
    base_currency   CHAR(3) NOT NULL DEFAULT 'CNY',
    status          trip_status NOT NULL DEFAULT 'active',
    created_by      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at      TIMESTAMPTZ DEFAULT now(),
    updated_at      TIMESTAMPTZ DEFAULT now(),
    
    CHECK (end_date IS NULL OR end_date >= start_date)
);

CREATE INDEX idx_trips_created_by ON trips(created_by);
CREATE INDEX idx_trips_status ON trips(status);
```

### 2.3 members（成员）
```sql
CREATE TYPE member_role AS ENUM ('organizer', 'member');

CREATE TABLE members (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id         UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    nickname        TEXT NOT NULL CHECK (length(nickname) <= 20),
    avatar_color    CHAR(7),  -- #RRGGBB
    role            member_role NOT NULL DEFAULT 'member',
    user_id         UUID REFERENCES users(id) ON DELETE SET NULL,  -- 可选关联
    group_id        UUID,  -- 🆕 所属组（见 groups 表）
    joined_at       TIMESTAMPTZ DEFAULT now(),
    
    FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE SET NULL
);

CREATE INDEX idx_members_trip_id ON members(trip_id);
CREATE INDEX idx_members_user_id ON members(user_id);
CREATE INDEX idx_members_group_id ON members(group_id);  -- 🆕
```

### 2.3.1 🆕 groups（组）
```sql
CREATE TYPE group_type AS ENUM ('family', 'company', 'department', 'team', 'other');

CREATE TABLE groups (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id         UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    name            TEXT NOT NULL CHECK (length(name) <= 30),
    group_type      group_type NOT NULL DEFAULT 'other',
    color           CHAR(7),  -- #RRGGBB
    created_at      TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_groups_trip_id ON groups(trip_id);
CREATE INDEX idx_groups_type ON groups(group_type);
```

**组设计要点**:
- 一个成员最多属于一个组（简化 MVP）
- 删除组时，成员 `group_id` 自动 SET NULL
- 组颜色用于 UI 区分（头像、列表项）

### 2.4 expenses（账目）
```sql
CREATE TYPE expense_category AS ENUM (
    'food', 'lodging', 'transport', 'fuel', 'toll',
    'parking', 'ticket', 'shopping', 'entertainment', 'other'
);

CREATE TYPE sync_status AS ENUM ('synced', 'pending', 'failed');

CREATE TABLE expenses (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id         UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    payer_id        UUID NOT NULL REFERENCES members(id) ON DELETE RESTRICT,
    amount          DECIMAL(12, 2) NOT NULL CHECK (amount > 0),
    currency        CHAR(3) NOT NULL DEFAULT 'CNY',
    category        expense_category NOT NULL,
    description     TEXT,
    occurred_at     TIMESTAMPTZ NOT NULL,
    created_at      TIMESTAMPTZ DEFAULT now(),
    updated_at      TIMESTAMPTZ DEFAULT now(),
    split_rule      JSONB NOT NULL,  -- {type, participants, values}
    attachments     TEXT[],          -- 最多 3 个 URL
    sync_status     sync_status DEFAULT 'synced',
    
    -- 软删除
    deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_expenses_trip_id ON expenses(trip_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_expenses_payer_id ON expenses(payer_id);
CREATE INDEX idx_expenses_occurred_at ON expenses(trip_id, occurred_at DESC);
```

### 2.5 expense_splits（分摊明细）
```sql
CREATE TABLE expense_splits (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expense_id      UUID NOT NULL REFERENCES expenses(id) ON DELETE CASCADE,
    member_id       UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    amount          DECIMAL(12, 2) NOT NULL CHECK (amount >= 0),
    settled         BOOLEAN DEFAULT false,
    
    UNIQUE(expense_id, member_id)
);

CREATE INDEX idx_splits_member_settled ON expense_splits(member_id, settled);
```

### 2.6 settlements（结算单）
```sql
CREATE TABLE settlements (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id         UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    computed_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    summary         JSONB NOT NULL,  -- {total_expense, member_count, ...}
    balances        JSONB NOT NULL,  -- [{member_id, net}]
    transfers       JSONB NOT NULL,  -- [{from, to, amount}]
    
    -- 历史快照，每次结算留档
    created_by      UUID REFERENCES users(id)
);

CREATE INDEX idx_settlements_trip_id ON settlements(trip_id, computed_at DESC);
```

### 2.7 transfer_records（转账记录）
```sql
CREATE TABLE transfer_records (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    settlement_id   UUID NOT NULL REFERENCES settlements(id) ON DELETE CASCADE,
    from_member_id  UUID NOT NULL REFERENCES members(id),
    to_member_id    UUID NOT NULL REFERENCES members(id),
    amount          DECIMAL(12, 2) NOT NULL,
    settled_at      TIMESTAMPTZ,
    note            TEXT,
    
    CHECK (from_member_id != to_member_id)
);

CREATE INDEX idx_transfers_settlement ON transfer_records(settlement_id);
CREATE INDEX idx_transfers_from_settled ON transfer_records(from_member_id, settled_at);
```

### 2.8 🆕 recurring_expenses（重复费用规则）

```sql
CREATE TYPE recurring_frequency AS ENUM ('daily', 'weekly', 'monthly', 'yearly');

CREATE TABLE recurring_expenses (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id         UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    template        JSONB NOT NULL,  -- {payer_id, category, amount, split_rule, description}
    frequency       recurring_frequency NOT NULL,
    interval_value  INT NOT NULL DEFAULT 1,  -- 每 N 个周期
    day_of_week     INT CHECK (day_of_week BETWEEN 0 AND 6),  -- 0=Sun, 6=Sat（仅 weekly）
    day_of_month    INT CHECK (day_of_month BETWEEN 1 AND 31),  -- 1-31（仅 monthly）
    start_date      DATE NOT NULL,
    end_date        DATE,  -- 可空，长期
    last_generated  DATE,
    next_due        DATE NOT NULL,
    enabled         BOOLEAN NOT NULL DEFAULT true,
    created_by      UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ DEFAULT now(),
    updated_at      TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_recurring_trip_id ON recurring_expenses(trip_id);
CREATE INDEX idx_recurring_next_due ON recurring_expenses(next_due) WHERE enabled = true;
CREATE INDEX idx_recurring_enabled ON recurring_expenses(enabled);
```

**使用方式**：
- 用户一次性配置"每周一付民宿 800"
- 系统每天 00:05 扫描 `next_due <= today AND enabled = true`
- 命中后用 `template` 生成 `expenses` 行（带 `source='recurring'`）
- 更新 `last_generated = today`、`next_due` 推进到下次

### 2.9 🆕 voice_recordings（语音识别记录）

```sql
CREATE TYPE voice_status AS ENUM ('pending', 'parsed', 'confirmed', 'failed');

CREATE TABLE voice_recordings (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id         UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    raw_text        TEXT NOT NULL,  -- STT 识别原始文本
    parsed_json     JSONB,  -- {payer, amount, category, description, confidence}
    expense_id      UUID REFERENCES expenses(id) ON DELETE SET NULL,  -- 关联生成的账目
    status          voice_status NOT NULL DEFAULT 'pending',
    created_by      UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_voice_trip_id ON voice_recordings(trip_id);
CREATE INDEX idx_voice_created_at ON voice_recordings(trip_id, created_at DESC);
CREATE INDEX idx_voice_status ON voice_recordings(status);
```

### 2.10 🆕 expenses 表扩展字段

```sql
ALTER TABLE expenses ADD COLUMN source TEXT DEFAULT 'manual' 
    CHECK (source IN ('manual', 'voice', 'recurring', 'import'));
ALTER TABLE expenses ADD COLUMN voice_recording_id UUID REFERENCES voice_recordings(id) ON DELETE SET NULL;
ALTER TABLE expenses ADD COLUMN recurring_rule_id UUID REFERENCES recurring_expenses(id) ON DELETE SET NULL;
```

**字段含义**：
- `source`：账目来源（手动/语音/重复/导入），便于筛选和统计
- `voice_recording_id`：反查语音识别记录（用于审计）
- `recurring_rule_id`：反查重复费用规则（用于追溯）

---

## 三、Row Level Security (RLS)

### 3.1 trips
```sql
-- 用户可看自己创建的或作为成员的旅程
ALTER TABLE trips ENABLE ROW LEVEL SECURITY;

CREATE POLICY "view_own_trips" ON trips
    FOR SELECT
    USING (
        created_by = auth.uid()
        OR id IN (
            SELECT trip_id FROM members WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "create_own_trips" ON trips
    FOR INSERT
    WITH CHECK (created_by = auth.uid());

CREATE POLICY "update_own_trips" ON trips
    FOR UPDATE
    USING (created_by = auth.uid());
```

### 3.2 members
```sql
ALTER TABLE members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "view_members_in_my_trips" ON members
    FOR SELECT
    USING (
        trip_id IN (
            SELECT id FROM trips WHERE created_by = auth.uid()
            UNION
            SELECT trip_id FROM members WHERE user_id = auth.uid()
        )
    );
```

### 3.3 expenses
```sql
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "view_expenses_in_my_trips" ON expenses
    FOR SELECT
    USING (
        trip_id IN (
            SELECT id FROM trips WHERE created_by = auth.uid()
            UNION
            SELECT trip_id FROM members WHERE user_id = auth.uid()
        )
    );
```

---

## 四、本地存储 (Hive)

### 4.1 Box 设计

```dart
// 同步状态
Box<SyncStatus>('sync_status')

// 缓存
Box<Trip>('trips')
Box<Expense>('expenses')

// 用户偏好
Box('settings')  // 主题、语言、上次付款人等
```

### 4.2 数据同步策略

| 场景 | 策略 |
|---|---|
| 启动 | 拉取最新数据 + 推送本地 pending |
| 在线操作 | 写本地 → 异步推送 |
| 离线操作 | 写本地 → 标记 pending |
| 网络恢复 | 推送所有 pending |

---

## 五、数据迁移策略

### 5.1 Schema 变更
- 使用 Supabase Migration
- 每次发布前在 staging 测试
- 保留回滚脚本

### 5.2 客户端数据迁移
- App 启动检查 schema version
- 需要时自动执行数据迁移
- 用户无感知

---

*此文档由 Tech Lead + DBA 维护，Schema 变更需走评审流程*
