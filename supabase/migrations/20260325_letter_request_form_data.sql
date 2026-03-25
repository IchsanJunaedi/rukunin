-- ============================================================
-- Letter Request Form Data & Communities Leader Info
-- ============================================================

-- 1. Tambah kolom baru di letter_requests
ALTER TABLE public.letter_requests
  ADD COLUMN IF NOT EXISTS form_data JSONB,
  ADD COLUMN IF NOT EXISTS applicant_name TEXT;

-- 2. Ganti CHECK constraint status
--    (mengubah dari: 'pending','in_progress','ready','completed','rejected'
--     menjadi: 'pending','verified','completed','rejected')
ALTER TABLE public.letter_requests
  DROP CONSTRAINT IF EXISTS letter_requests_status_check;

ALTER TABLE public.letter_requests
  ADD CONSTRAINT letter_requests_status_check
  CHECK (status IN ('pending', 'verified', 'completed', 'rejected'));

-- 3. Tambah leader_name di communities
--    (dipakai Edge Function generate-letter tapi belum ada di migrations)
ALTER TABLE public.communities
  ADD COLUMN IF NOT EXISTS leader_name TEXT;
