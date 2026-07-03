# Supabase 数据库 Schema 设计

**版本**：v1.0  
**日期**：2026-07-03  
**关联 ADR**：[ADR-002-supabase](../02-architecture/04-adr/ADR-002-supabase.md)  
**迁移文件**：[supabase/migrations/](../../supabase/migrations/)

---

## 📊 数据模型总览

```
auth.users (Supabase 内置)
    ↓ 1:1
profiles (用户扩展)
    ↓ 1:N
trips (旅程)
    ↓ 1:N         ↓ 1:N          ↓ 1:N
trip_members   trip_groups    expenses
    ↓ N:1           ↓ 1:N
trip_member_groups (成员-组)

trip_collaborators (访问控制)
transfer_records (转账记录)
```

---

## 🗃️ 表清单

| # | 表名 | 用途 | 主要字段 |
|---|---|---|---|
| 1 | `profiles` | 用户扩展信息 | id (FK auth.users), display_name, avatar_url |
| 2 | `trips` | 旅程主表 | id, name, start_date, end_date, status |
| 3 | `trip_members` | 旅程成员 | trip_id, user_id, nickname, role, group_id |
| 4 | `trip_groups` | 旅程分组 | trip_id, name, group_type |
| 5 | `expenses` | 账目 | trip_id, payer_id, amount_cents, category, split_rule_json |
| 6 | `transfer_records` | 转账记录 | trip_id, from_member_id, to_member_id, amount_cents |
| 7 | `trip_collaborators` | 协作者关系 | trip_id, user_id, role |

---

## 🔐 RLS 策略摘要

| 表 | 读 | 写 |
|---|---|---|
| profiles | 所有登录用户 | 仅自己 |
| trips | trip 的协作者 | trip 的 owner/editor |
| trip_members | trip 的协作者 | trip 的 owner/editor |
| trip_groups | trip 的协作者 | trip 的 owner/editor |
| expenses | trip 的协作者 | trip 的 owner/editor（创建者必须是 auth.uid()）|
| transfer_records | trip 的协作者 | trip 的 owner/editor |
| trip_collaborators | 仅自己 | 仅 trip owner |

**权限助手函数**：
- `user_can_read_trip(trip_id)` → 是否在 collaborator 表中
- `user_can_write_trip(trip_id)` → 是否 owner/editor
- `user_is_trip_owner(trip_id)` → 是否 trip 创建者

---

## 🆔 数据类型映射（Hive → Postgres）

| Hive 字段 | Postgres 字段 | 说明 |
|---|---|---|
| `double amount` | `BIGINT amount_cents` | 单位:分(避免浮点) |
| `DateTime` | `TIMESTAMPTZ` | 时区感知的 UTC |
| `String splitRuleJson` | `JSONB split_rule_json` | 可索引可查询 |
| `enum TripStatus` | `ENUM trip_status` | preparing/ongoing/ended/archived |
| `UUID id` (String) | `UUID id` | Postgres 生成 |
| `String currency` | `TEXT currency` | ISO 4217 |

---

## 🔄 同步策略

### 离线优先（Offline-First）

```
[用户操作] → [本地 Hive] → [UI 立即更新]
                  ↓
            [SyncStatus.pending]
                  ↓ (网络可用时)
            [Supabase REST API]
                  ↓ (成功)
            [SyncStatus.synced]
```

### 冲突解决

- **Last-Write-Wins**：比较 `updated_at`，新的覆盖旧的
- 软删除：`deleted_at` IS NOT NULL → 标记删除，不物理删除
- Pull 时不主动删除本地数据（避免误删）

### 自动同步时机

| 触发 | 行为 |
|---|---|
| 应用启动 | pull 远端 → 合并本地 |
| 每 30 秒 | push pending → pull 远端 |
| 手动触发 | 立即完整同步 |
| 网络恢复 | 立即 push pending |

---

## 🚀 部署步骤

### 1. 创建 Supabase 项目

1. 访问 https://supabase.com 注册
2. New Project → 选 Singapore region（国内近）
3. 等待 1-2 分钟初始化

### 2. 执行 SQL 迁移

```bash
# 方式 A: Supabase Dashboard SQL Editor
# 复制 supabase/migrations/00001_initial_schema.sql 全部内容到 SQL Editor → Run
# 再执行 00002_rls_policies.sql

# 方式 B: supabase CLI
supabase db push
```

### 3. 配置 Dart 端

```bash
# 获取 Project URL 和 anon key（在 Supabase Dashboard → Settings → API）
flutter run \
  --dart-define=SUPABASE_URL=https://xxxxxxxxxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIs...
```

### 4. 注册首个用户

1. 打开 APP → 点击右上角云朵图标
2. 切换到"注册"标签
3. 输入邮箱 + 密码（≥6位） + 昵称
4. 登录后即可同步数据

---

## 💰 容量预估

| 指标 | 免费层 | 估算需求 | 余量 |
|---|---|---|---|
| 数据库 | 500 MB | ~50MB (1万 trips) | 10x |
| 月活用户 | 50,000 | < 100 | 500x |
| 存储（票据）| 1 GB | ~500MB (1万张图) | 2x |
| 流量 | 2 GB/月 | ~500MB/月 | 4x |

**结论**：MVP 阶段完全够用，无需付费。

---

## 🔮 后续扩展（V1.1+）

| 功能 | 实现方式 |
|---|---|
| 实时多人协作 | Postgres Replication + Realtime（已加 supabase_realtime publication）|
| 离线冲突可视化 | CRDT 或 OT 算法 |
| 数据导出/导入 | Storage bucket + CSV/JSON |
| 二维码邀请 | Edge Function 生成短期 token |
| 票据 OCR | Edge Function + Tesseract |

---

*生成时间：2026-07-03 19:55*