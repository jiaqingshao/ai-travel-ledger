-- =====================================================
-- AI Travel Ledger - Row Level Security Policies (v1.0)
-- =====================================================
-- 创建时间：2026-07-03
-- 策略原则：
--   - 任何登录用户都可以创建自己的 trip
--   - trip 通过 trip_collaborators 控制访问
--   - viewer: 只读 / editor: 可写 expense / owner: 全部
-- =====================================================

-- 启用 RLS
ALTER TABLE public.profiles           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trips              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_members       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_groups        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transfer_records   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_collaborators ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- profiles - 任何登录用户都可以看,可改自己的
-- =====================================================
CREATE POLICY "profiles_select_all" ON public.profiles
  FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

CREATE POLICY "profiles_insert_own" ON public.profiles
  FOR INSERT
  WITH CHECK (id = auth.uid());

-- =====================================================
-- trip_collaborators - 自己相关的行可读
-- =====================================================
CREATE POLICY "collab_select_self" ON public.trip_collaborators
  FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "collab_insert_owner" ON public.trip_collaborators
  FOR INSERT
  WITH CHECK (
    -- 创建者必须是 trip 的 owner
    EXISTS (
      SELECT 1 FROM public.trips t
      WHERE t.id = trip_id
        AND t.created_by = auth.uid()
    )
  );

CREATE POLICY "collab_update_owner" ON public.trip_collaborators
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.trips t
      WHERE t.id = trip_id
        AND t.created_by = auth.uid()
    )
  );

CREATE POLICY "collab_delete_owner" ON public.trip_collaborators
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.trips t
      WHERE t.id = trip_id
        AND t.created_by = auth.uid()
    )
  );

-- =====================================================
-- trips - 通过 trip_collaborators 控制
-- =====================================================
CREATE OR REPLACE FUNCTION public.user_can_read_trip(p_trip_id UUID)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.trip_collaborators
    WHERE trip_id = p_trip_id
      AND user_id = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.user_can_write_trip(p_trip_id UUID)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.trip_collaborators
    WHERE trip_id = p_trip_id
      AND user_id = auth.uid()
      AND role IN ('owner', 'editor')
  );
$$;

CREATE OR REPLACE FUNCTION public.user_is_trip_owner(p_trip_id UUID)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.trips
    WHERE id = p_trip_id
      AND created_by = auth.uid()
  );
$$;

-- 读 trip
CREATE POLICY "trips_select_collaborator" ON public.trips
  FOR SELECT
  USING (public.user_can_read_trip(id));

-- 创建 trip
CREATE POLICY "trips_insert_authenticated" ON public.trips
  FOR INSERT
  WITH CHECK (
    auth.role() = 'authenticated'
    AND created_by = auth.uid()
  );

-- 更新 trip（owner 或 editor）
CREATE POLICY "trips_update_collaborator" ON public.trips
  FOR UPDATE
  USING (public.user_can_write_trip(id))
  WITH CHECK (public.user_can_write_trip(id));

-- 删除 trip（只有 owner）
CREATE POLICY "trips_delete_owner" ON public.trips
  FOR DELETE
  USING (public.user_is_trip_owner(id));

-- =====================================================
-- trip_members - 跟随 trip 的权限
-- =====================================================
CREATE POLICY "members_select_via_trip" ON public.trip_members
  FOR SELECT
  USING (public.user_can_read_trip(trip_id));

CREATE POLICY "members_insert_via_trip" ON public.trip_members
  FOR INSERT
  WITH CHECK (public.user_can_write_trip(trip_id));

CREATE POLICY "members_update_via_trip" ON public.trip_members
  FOR UPDATE
  USING (public.user_can_write_trip(trip_id))
  WITH CHECK (public.user_can_write_trip(trip_id));

CREATE POLICY "members_delete_via_trip" ON public.trip_members
  FOR DELETE
  USING (public.user_is_trip_owner(trip_id));

-- =====================================================
-- trip_groups - 跟随 trip 的权限
-- =====================================================
CREATE POLICY "groups_select_via_trip" ON public.trip_groups
  FOR SELECT
  USING (public.user_can_read_trip(trip_id));

CREATE POLICY "groups_insert_via_trip" ON public.trip_groups
  FOR INSERT
  WITH CHECK (public.user_can_write_trip(trip_id));

CREATE POLICY "groups_update_via_trip" ON public.trip_groups
  FOR UPDATE
  USING (public.user_can_write_trip(trip_id))
  WITH CHECK (public.user_can_write_trip(trip_id));

CREATE POLICY "groups_delete_via_trip" ON public.trip_groups
  FOR DELETE
  USING (public.user_is_trip_owner(trip_id));

-- =====================================================
-- expenses - 跟随 trip 的权限
-- =====================================================
CREATE POLICY "expenses_select_via_trip" ON public.expenses
  FOR SELECT
  USING (public.user_can_read_trip(trip_id));

CREATE POLICY "expenses_insert_via_trip" ON public.expenses
  FOR INSERT
  WITH CHECK (
    public.user_can_write_trip(trip_id)
    AND created_by = auth.uid()
  );

CREATE POLICY "expenses_update_via_trip" ON public.expenses
  FOR UPDATE
  USING (public.user_can_write_trip(trip_id))
  WITH CHECK (public.user_can_write_trip(trip_id));

CREATE POLICY "expenses_delete_via_trip" ON public.expenses
  FOR DELETE
  USING (public.user_is_trip_owner(trip_id));

-- =====================================================
-- transfer_records - 跟随 trip 的权限
-- =====================================================
CREATE POLICY "transfers_select_via_trip" ON public.transfer_records
  FOR SELECT
  USING (public.user_can_read_trip(trip_id));

CREATE POLICY "transfers_insert_via_trip" ON public.transfer_records
  FOR INSERT
  WITH CHECK (public.user_can_write_trip(trip_id));

CREATE POLICY "transfers_delete_via_trip" ON public.transfer_records
  FOR DELETE
  USING (public.user_is_trip_owner(trip_id));

-- =====================================================
-- Realtime 订阅授权（可选）
-- =====================================================
-- 允许已登录用户订阅 trips 表变更
ALTER PUBLICATION supabase_realtime ADD TABLE public.trips;
ALTER PUBLICATION supabase_realtime ADD TABLE public.expenses;
ALTER PUBLICATION supabase_realtime ADD TABLE public.trip_members;

-- =====================================================
-- 完成
-- =====================================================