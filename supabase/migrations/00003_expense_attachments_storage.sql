-- ============================================
-- AI 旅行账本 - Migration 00003: 费用附件上传 (ISSUE-026, V1.2)
-- ============================================
--
-- 内容:
-- 1. 新建 Supabase Storage bucket `expense-attachments` (公开读, 私有写)
-- 2. RLS: 只有协作者可以写/删除自己旅程的附件
-- 3. 在 expenses 表添加 attachment_metadata JSONB 字段 (元数据备份)
--
-- 前置:
-- ✅ 00001_initial_schema.sql — expenses 表已建
-- ✅ 00002_rls_policies.sql — 协作者权限已建
--
-- 关联 ISSUE:
-- - ISSUE-026 票据照片上传 (V1.2)
-- - 拆 5 步的 Step 1 (数据模型 + Storage + RLS)
--
-- 应用方法 (在 Supabase Dashboard SQL Editor 跑, 一次性):
--   复制全文 → 粘贴 → Run
--
-- 回滚 (如果需要):
--   DROP POLICY IF EXISTS "Expense attachments are viewable by trip collaborators" ON storage.objects;
--   DROP POLICY IF EXISTS "Expense attachments are insertable by trip collaborators" ON storage.objects;
--   DROP POLICY IF EXISTS "Expense attachments are deletable by trip owner" ON storage.objects;
--   DELETE FROM storage.buckets WHERE id = 'expense-attachments';
--   ALTER TABLE expenses DROP COLUMN IF EXISTS attachment_metadata;
-- ============================================

-- ============================================
-- PART 1: 新建 Storage bucket
-- ============================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'expense-attachments',
  'expense-attachments',
  true,  -- 公开读 (账单分享时图片可访问)
  10 * 1024 * 1024,  -- 10 MB / file (防止 OOM)
  ARRAY[
    'image/jpeg', 'image/jpg', 'image/png', 'image/webp',
    'image/gif', 'image/heic', 'image/heif',
    'application/pdf'
  ]
)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- PART 2: Storage RLS 策略
-- ============================================
--
-- 路径结构: `{tripId}/{expenseId}/{uuid}.{ext}`
-- 用户可以上传/查看/删除 任意 trip_id 在自己参与的旅程下 的附件

-- Drop existing policies (idempotent re-runs)
DROP POLICY IF EXISTS "Expense attachments are viewable by trip collaborators" ON storage.objects;
DROP POLICY IF EXISTS "Expense attachments are insertable by trip collaborators" ON storage.objects;
DROP POLICY IF EXISTS "Expense attachments are deletable by trip owner" ON storage.objects;

-- View (SELECT): 路径以 tripId 开头, 且 tripId 在 user 有协作权限的旅程里
CREATE POLICY "Expense attachments are viewable by trip collaborators"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'expense-attachments'
    AND EXISTS (
      SELECT 1 FROM public.trips t
      JOIN public.trip_collaborators c ON c.trip_id = t.id
      WHERE t.id::text = split_part(name, '/', 1)
        AND c.user_id = auth.uid()
    )
  );

-- Insert (INSERT): 同 view 条件 (必须是协作者才能上传)
CREATE POLICY "Expense attachments are insertable by trip collaborators"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'expense-attachments'
    AND EXISTS (
      SELECT 1 FROM public.trips t
      JOIN public.trip_collaborators c ON c.trip_id = t.id
      WHERE t.id::text = split_part(name, '/', 1)
        AND c.user_id = auth.uid()
    )
  );

-- Delete: 只有旅程 owner 能删除附件
CREATE POLICY "Expense attachments are deletable by trip owner"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'expense-attachments'
    AND EXISTS (
      SELECT 1 FROM public.trips t
      WHERE t.id::text = split_part(name, '/', 1)
        AND t.owner_id = auth.uid()
    )
  );

-- ============================================
-- PART 3: expenses 表加 attachment_metadata 字段
-- ============================================
--
-- 设计:
-- - attachments JSONB / string[] (00001 里已经有 attachments: text[])
-- - attachment_metadata JSONB (本 migration 新加) - 存结构化元数据
--   { "items": [{ "url": "...", "fileName": "...", "sizeBytes": 12345, "mimeType": "image/jpeg", "uploadedAt": "2026-07-12T..." }] }
--
-- 保留旧 attachments text[] 不删, 双写 (直到 Dart 端完全迁移到 attachment_metadata)

ALTER TABLE public.expenses
  ADD COLUMN IF NOT EXISTS attachment_metadata JSONB DEFAULT '{"items": []}'::jsonb;

-- 触发器: 写 attachment_metadata 时自动同步到 attachments (url 列表)
-- 这样 view 现有 column 仍有值
-- [PR-2 修复] S-2: 原来用 jsonb_array_elements_text 把整个 JSON 对象 stringify 进 text[],
-- 现改为提取每项的 url 字段 (text[] 存的就是 url 列表)
CREATE OR REPLACE FUNCTION sync_expense_attachments()
RETURNS TRIGGER AS $$
BEGIN
  NEW.attachments := ARRAY(
    SELECT (item->>'url')::text
    FROM jsonb_array_elements(
      COALESCE(NEW.attachment_metadata->'items', '[]'::jsonb)
    ) AS item
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_expense_attachments ON public.expenses;
CREATE TRIGGER trg_sync_expense_attachments
  BEFORE INSERT OR UPDATE ON public.expenses
  FOR EACH ROW
  EXECUTE FUNCTION sync_expense_attachments();

-- ============================================
-- PART 4: RLS for attachment_metadata (继承 expenses RLS)
-- ============================================
--
-- 沿用现有 RLS (00002), attachment_metadata 字段已有协作者权限检查。
-- 不需要额外策略。

-- ============================================
-- 应用日志
-- ============================================
--
-- 2026-07-12 14:30 (Asia/Shanghai) — 创建
--   - bucket: expense-attachments (公开读, 10MB 限制)
--   - RLS: VIEW (协作者) / INSERT (协作者) / DELETE (owner)
--   - 表字段: attachment_metadata JSONB
--   - 触发器: 同步 attachments text[] <-> attachment_metadata
--
-- 2026-07-15 09:41 (Asia/Shanghai) — [PR-2 修复]
--   - S-1: collaborators → trip_collaborators (2 处 JOIN 引用错的表名, 部署必失败)
--   - S-2: 触发器从 jsonb_array_elements_text (stringify 整个对象) 改为提取 (item->>'url')
--         现在 attachments text[] 存的是干净的 URL 列表
