-- ============================================================
-- RUKUNIN — Migration: Tabel Anggota Keluarga (Family Members)
-- Jalankan di Supabase SQL Editor
-- ============================================================

CREATE TABLE public.family_members (
  id uuid primary key default uuid_generate_v4(),
  resident_id uuid not null references public.profiles(id) on delete cascade,
  full_name text not null,
  nik text,
  relationship text not null check (relationship in ('Istri', 'Suami', 'Anak', 'Orang Tua', 'Lainnya')),
  created_at timestamptz not null default now()
);

-- RLS (Row Level Security)
ALTER TABLE public.family_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin dapat melihat anggota keluarga warga di komunitasnya"
  ON public.family_members FOR SELECT
  USING (
    resident_id IN (
      SELECT id FROM public.profiles 
      WHERE community_id = (SELECT community_id FROM public.profiles p WHERE p.id = auth.uid())
    )
  );

CREATE POLICY "Admin dapat menambah/mengubah anggota keluarga di komunitasnya"
  ON public.family_members FOR ALL
  USING (
    resident_id IN (
      SELECT id FROM public.profiles 
      WHERE community_id = (SELECT community_id FROM public.profiles p WHERE p.id = auth.uid())
    )
  );

-- ============================================================
-- SELESAI
-- ============================================================
