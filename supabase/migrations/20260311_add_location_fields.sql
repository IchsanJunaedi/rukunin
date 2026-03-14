-- ============================================================
-- RUKUNIN — Migration: Struktur Lokasi Lengkap
-- Jalankan di Supabase SQL Editor
-- ============================================================

-- 1. Drop FK constraint agar profiles bisa dibuat tanpa auth account warga
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;

-- 2. Tambah kolom alamat lengkap ke communities
ALTER TABLE public.communities
  ADD COLUMN IF NOT EXISTS province    text,
  ADD COLUMN IF NOT EXISTS kabupaten   text,
  ADD COLUMN IF NOT EXISTS kecamatan   text,
  ADD COLUMN IF NOT EXISTS kelurahan   text,
  ADD COLUMN IF NOT EXISTS rt_count    integer NOT NULL DEFAULT 3;

-- 3. Tambah kolom RT & Blok ke profiles (warga)
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS rt_number   integer,
  ADD COLUMN IF NOT EXISTS block       text;

-- 4. Tambah kolom email agar bisa dipakai untuk self-signup warga nanti
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS email text;

-- ============================================================
-- SELESAI
-- ============================================================
