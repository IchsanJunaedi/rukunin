-- ============================================================
-- RUKUNIN — Migration: Buat bucket payment_proofs di Storage
-- Jalankan di Supabase SQL Editor
-- ============================================================

-- 1. Buat bucket payment_proofs (public — URL bisa diakses langsung untuk verifikasi admin)
INSERT INTO storage.buckets (id, name, public)
VALUES ('payment_proofs', 'payment_proofs', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Warga authenticated bisa upload ke folder miliknya sendiri
CREATE POLICY "Warga dapat upload bukti bayar"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'payment_proofs'
    AND auth.role() = 'authenticated'
  );

-- 3. Warga hanya bisa lihat file miliknya sendiri
CREATE POLICY "Warga dapat lihat bukti bayar sendiri"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'payment_proofs'
    AND auth.role() = 'authenticated'
  );

-- 4. Admin bisa lihat semua bukti bayar di komunitasnya
--    (via service role key di Edge Function, atau policy tambahan jika diperlukan)

-- ============================================================
-- SELESAI
-- ============================================================
