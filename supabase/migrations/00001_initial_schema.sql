-- =====================================================
-- AI Travel Ledger - Initial Schema (v1.0)
-- =====================================================
-- 创建时间：2026-07-03
-- 关联文档：docs/02-architecture/05-supabase-schema.md
-- 数据源：lib/data/models/{trip,group,member,expense,transfer_record}.dart
-- =====================================================

-- 启用扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- 1. profiles - 用户扩展信息
-- =====================================================
-- 与 auth.users (Supabase 内置) 一对一
CREATE TABLE public.profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL,
  avatar_url  TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.profiles IS '用户扩展信息,与 auth.users 1:1';

-- 自动同步 auth.users -> profiles
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)));
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- 2. trips - 旅程
-- =====================================================
CREATE TYPE public.trip_status AS ENUM ('preparing', 'ongoing', 'ended', 'archived');

CREATE TABLE public.trips (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name           TEXT NOT NULL,
  destination    TEXT,
  start_date     DATE NOT NULL,
  end_date       DATE,
  base_currency  TEXT NOT NULL DEFAULT 'CNY',
  status         public.trip_status NOT NULL DEFAULT 'preparing',
  created_by     UUID NOT NULL REFERENCES auth.users(id),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at     TIMESTAMPTZ  -- 软删除
);

CREATE INDEX idx_trips_created_by ON public.trips(created_by) WHERE deleted_at IS NULL;
CREATE INDEX idx_trips_status ON public.trips(status) WHERE deleted_at IS NULL;

COMMENT ON TABLE public.trips IS '旅程主表 - 一行 = 一次旅行';

-- =====================================================
-- 3. trip_members - 旅程成员
-- =====================================================
CREATE TYPE public.member_role AS ENUM ('organizer', 'member');

CREATE TABLE public.trip_members (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  trip_id       UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
  user_id       UUID REFERENCES auth.users(id),  -- 可空：未注册成员
  nickname      TEXT NOT NULL,
  avatar_color  TEXT,  -- #RRGGBB
  role          public.member_role NOT NULL DEFAULT 'member',
  joined_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_trip_members_trip ON public.trip_members(trip_id);
CREATE INDEX idx_trip_members_user ON public.trip_members(user_id);

COMMENT ON TABLE public.trip_members IS '旅程成员 - 一个用户可参与多个 trip';

-- =====================================================
-- 4. trip_groups - 旅程分组
-- =====================================================
CREATE TYPE public.group_type AS ENUM ('family', 'company', 'department', 'team', 'other');

CREATE TABLE public.trip_groups (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  trip_id     UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  group_type  public.group_type NOT NULL DEFAULT 'other',
  color       TEXT,  -- #RRGGBB
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_trip_groups_trip ON public.trip_groups(trip_id);

COMMENT ON TABLE public.trip_groups IS '旅程分组 - 一个 trip 内可有多组(家庭/部门)';

-- =====================================================
-- 5. trip_member_groups - 成员与组关联（一对多）
-- =====================================================
ALTER TABLE public.trip_members
  ADD COLUMN group_id UUID REFERENCES public.trip_groups(id) ON DELETE SET NULL;

CREATE INDEX idx_trip_members_group ON public.trip_members(group_id);

COMMENT ON COLUMN public.trip_members.group_id IS '所属组(一人最多一组)';

-- =====================================================
-- 6. expenses - 账目
-- =====================================================
CREATE TYPE public.expense_category AS ENUM (
  'food', 'lodging', 'transport', 'fuel', 'toll',
  'parking', 'ticket', 'shopping', 'entertainment', 'other'
);

CREATE TABLE public.expenses (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  trip_id         UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
  payer_id        UUID NOT NULL REFERENCES public.trip_members(id) ON DELETE RESTRICT,
  amount_cents    BIGINT NOT NULL CHECK (amount_cents >= 0),  -- 单位:分(避免浮点)
  currency        TEXT NOT NULL DEFAULT 'CNY',
  category        public.expense_category NOT NULL,
  description     TEXT NOT NULL DEFAULT '',
  occurred_at     TIMESTAMPTZ NOT NULL,
  split_rule_json JSONB NOT NULL,  -- SplitRule JSON
  receipt_url     TEXT,             -- 票据照片
  created_by      UUID NOT NULL REFERENCES auth.users(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_expenses_trip ON public.expenses(trip_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_expenses_payer ON public.expenses(payer_id);
CREATE INDEX idx_expenses_occurred ON public.expenses(occurred_at DESC);
CREATE INDEX idx_expenses_split_gin ON public.expenses USING GIN (split_rule_json);

COMMENT ON TABLE public.expenses IS '账目主表 - 包含分摊规则 JSON';
COMMENT ON COLUMN public.expenses.amount_cents IS '金额(分),避免浮点精度问题';

-- =====================================================
-- 7. transfer_records - 转账记录（结算用）
-- =====================================================
CREATE TABLE public.transfer_records (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  trip_id        UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
  from_member_id UUID NOT NULL REFERENCES public.trip_members(id) ON DELETE RESTRICT,
  to_member_id   UUID NOT NULL REFERENCES public.trip_members(id) ON DELETE RESTRICT,
  amount_cents   BIGINT NOT NULL CHECK (amount_cents >= 0),
  currency       TEXT NOT NULL DEFAULT 'CNY',
  note           TEXT NOT NULL DEFAULT '',
  transferred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_transfer_trip ON public.transfer_records(trip_id);
CREATE INDEX idx_transfer_from ON public.transfer_records(from_member_id);
CREATE INDEX idx_transfer_to ON public.transfer_records(to_member_id);

COMMENT ON TABLE public.transfer_records IS '转账记录 - 结算后实际收付款';

-- =====================================================
-- 8. trip_collaborators - 协作者（控制谁能看/写）
-- =====================================================
CREATE TYPE public.collaborator_role AS ENUM ('owner', 'editor', 'viewer');

CREATE TABLE public.trip_collaborators (
  trip_id    UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role       public.collaborator_role NOT NULL DEFAULT 'editor',
  invited_by UUID REFERENCES auth.users(id),
  invited_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (trip_id, user_id)
);

CREATE INDEX idx_collab_user ON public.trip_collaborators(user_id);

COMMENT ON TABLE public.trip_collaborators IS '协作者关系表 - 控制 trip 的访问权限';

-- =====================================================
-- 自动触发: trip 创建者自动成为 owner
-- =====================================================
CREATE OR REPLACE FUNCTION public.handle_new_trip()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.trip_collaborators (trip_id, user_id, role)
  VALUES (NEW.id, NEW.created_by, 'owner');
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_trip_created
  AFTER INSERT ON public.trips
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_trip();

-- =====================================================
-- updated_at 自动维护
-- =====================================================
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER set_trips_updated_at BEFORE UPDATE ON public.trips
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_members_updated_at BEFORE UPDATE ON public.trip_members
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_groups_updated_at BEFORE UPDATE ON public.trip_groups
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_expenses_updated_at BEFORE UPDATE ON public.expenses
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- =====================================================
-- 视图: trip 统计信息（dashboard 用）
-- =====================================================
CREATE OR REPLACE VIEW public.trip_summary AS
SELECT
  t.id AS trip_id,
  t.name,
  t.status,
  COUNT(DISTINCT e.id) FILTER (WHERE e.deleted_at IS NULL) AS expense_count,
  COALESCE(SUM(e.amount_cents) FILTER (WHERE e.deleted_at IS NULL), 0) AS total_cents,
  COUNT(DISTINCT m.id) AS member_count
FROM public.trips t
LEFT JOIN public.expenses e ON e.trip_id = t.id
LEFT JOIN public.trip_members m ON m.trip_id = t.id
WHERE t.deleted_at IS NULL
GROUP BY t.id, t.name, t.status;

COMMENT ON VIEW public.trip_summary IS '旅程统计视图 - 列表页直接查询';

-- =====================================================
-- 完成
-- =====================================================
-- 下一步: 创建 RLS 策略 (00002_rls_policies.sql)