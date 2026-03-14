-- ==============================================================================
-- FIX: Supabase RLS Update pada tabel communities selalu silently fail (return 0 rows)
-- Jalankan script ini di menu SQL Editor pada dashboard Supabase Anda.
-- ==============================================================================

-- 1. Hapus policy lama yang bermasalah (jika ada)
DROP POLICY IF EXISTS "Admin dapat update info komunitas" ON public.communities;

-- 2. Buat ulang policy dengan menambahkan klausul WITH CHECK
--    USING memfilter baris mana yang bisa di-update
--    WITH CHECK memastikan data setelah di-update masih memenuhi syarat (admin dari komunitas tsb)
CREATE POLICY "Admin dapat update info komunitas"
  ON public.communities
  FOR UPDATE
  USING (is_admin_of(id))
  WITH CHECK (is_admin_of(id));

-- 3. (Opsional tapi aman) Pastikan fungsi is_admin_of sudah benar
-- KITA TIDAK DROP FUNCTION KARENA DIPAKAI BANYAK POLICY
CREATE OR REPLACE FUNCTION public.is_admin_of(community uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
      AND community_id = community
      AND role = 'admin'
  );
$$;
