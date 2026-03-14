-- ============================================================
-- RUKUNIN — Migration: Phase 2 - Verifikasi Pembayaran Manual
-- Jalankan di Supabase SQL Editor
-- ============================================================

-- 1. Kolom bukti bayar & timestamp update di invoices
ALTER TABLE public.invoices
  ADD COLUMN IF NOT EXISTS proof_url  text,
  ADD COLUMN IF NOT EXISTS updated_at timestamptz;

-- 2. Perbaiki status check constraint — tambahkan 'awaiting_verification'
--    (DROP dulu karena tidak bisa ALTER constraint langsung di PG)
ALTER TABLE public.invoices
  DROP CONSTRAINT IF EXISTS invoices_status_check;

ALTER TABLE public.invoices
  ADD CONSTRAINT invoices_status_check
  CHECK (status IN ('pending', 'paid', 'overdue', 'awaiting_verification'));

-- 3. Info rekening & QRIS untuk pembayaran manual ke kas RW
ALTER TABLE public.communities
  ADD COLUMN IF NOT EXISTS bank_name      text,
  ADD COLUMN IF NOT EXISTS account_number text,
  ADD COLUMN IF NOT EXISTS account_name   text,
  ADD COLUMN IF NOT EXISTS qris_url       text;

-- 4. Tarif kendaraan per jenis iuran (IPL dinamis)
ALTER TABLE public.billing_types
  ADD COLUMN IF NOT EXISTS cost_per_motorcycle numeric(12,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS cost_per_car        numeric(12,2) NOT NULL DEFAULT 0;

-- 5. Jumlah kendaraan milik warga (untuk kalkulasi iuran)
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS motorcycle_count integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS car_count        integer NOT NULL DEFAULT 0;

-- 6. RLS: warga bisa update invoice miliknya sendiri
--    (dipakai untuk upload bukti bayar → set proof_url + status = awaiting_verification)
CREATE POLICY "Warga dapat upload bukti bayar tagihan sendiri"
  ON public.invoices FOR UPDATE
  USING  (resident_id = auth.uid())
  WITH CHECK (resident_id = auth.uid());

-- 7. RLS: admin bisa update data komunitasnya (payment settings)
CREATE POLICY "Admin dapat update info komunitas"
  ON public.communities FOR UPDATE
  USING (is_admin_of(id));

-- ============================================================
-- SELESAI
-- ============================================================
