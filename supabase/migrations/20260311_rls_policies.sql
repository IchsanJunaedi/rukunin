-- ============================================================
-- RUKUNIN — Row Level Security (RLS)
-- Jalankan di Supabase SQL Editor SETELAH schema terbuat
-- ============================================================

-- ============================================================
-- AKTIFKAN RLS di semua tabel
-- ============================================================
alter table public.profiles enable row level security;
alter table public.invoices enable row level security;
alter table public.payments enable row level security;
alter table public.expenses enable row level security;
alter table public.announcements enable row level security;
alter table public.marketplace_listings enable row level security;
alter table public.ai_logs enable row level security;
alter table public.billing_types enable row level security;
alter table public.communities enable row level security;

-- ============================================================
-- HELPER FUNCTION — cek apakah user adalah admin di community-nya
-- ============================================================
create or replace function public.is_admin_of(community uuid)
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid()
      and community_id = community
      and role = 'admin'
  );
$$;

-- Helper: ambil community_id milik user yang sedang login
create or replace function public.my_community_id()
returns uuid
language sql
security definer
stable
as $$
  select community_id from public.profiles
  where id = auth.uid();
$$;

-- ============================================================
-- POLICY — COMMUNITIES
-- ============================================================
-- Admin bisa lihat community-nya sendiri
create policy "Admin dapat lihat community sendiri"
  on public.communities for select
  using (is_admin_of(id));

-- ============================================================
-- POLICY — PROFILES
-- ============================================================
-- Admin bisa lihat semua profil di community-nya
create policy "Admin dapat lihat semua profil di community"
  on public.profiles for select
  using (is_admin_of(community_id));

-- Admin bisa insert profil baru di community-nya
create policy "Admin dapat tambah profil"
  on public.profiles for insert
  with check (is_admin_of(community_id));

-- Admin bisa update profil di community-nya
create policy "Admin dapat update profil"
  on public.profiles for update
  using (is_admin_of(community_id));

-- Warga bisa lihat profil dirinya sendiri
create policy "Warga dapat lihat profil sendiri"
  on public.profiles for select
  using (id = auth.uid());

-- Warga bisa update profilnya sendiri (nama, foto, HP)
create policy "Warga dapat update profil sendiri"
  on public.profiles for update
  using (id = auth.uid());

-- ============================================================
-- POLICY — BILLING_TYPES
-- ============================================================
create policy "Admin dapat kelola jenis iuran"
  on public.billing_types for all
  using (is_admin_of(community_id));

create policy "Warga dapat lihat jenis iuran aktif"
  on public.billing_types for select
  using (community_id = my_community_id() and is_active = true);

-- ============================================================
-- POLICY — INVOICES
-- ============================================================
create policy "Admin dapat kelola semua tagihan"
  on public.invoices for all
  using (is_admin_of(community_id));

-- Warga hanya bisa lihat tagihan miliknya sendiri
create policy "Warga dapat lihat tagihan sendiri"
  on public.invoices for select
  using (resident_id = auth.uid());

-- ============================================================
-- POLICY — PAYMENTS
-- ============================================================
create policy "Admin dapat lihat semua pembayaran"
  on public.payments for all
  using (is_admin_of(community_id));

-- Warga bisa lihat pembayaran dari invoice miliknya
create policy "Warga dapat lihat pembayaran sendiri"
  on public.payments for select
  using (
    community_id = my_community_id()
    and exists (
      select 1 from public.invoices
      where invoices.id = payments.invoice_id
        and invoices.resident_id = auth.uid()
    )
  );

-- ============================================================
-- POLICY — EXPENSES
-- ============================================================
create policy "Admin dapat kelola pengeluaran"
  on public.expenses for all
  using (is_admin_of(community_id));

-- Warga bisa lihat pengeluaran (transparansi keuangan)
create policy "Warga dapat lihat pengeluaran"
  on public.expenses for select
  using (community_id = my_community_id());

-- ============================================================
-- POLICY — ANNOUNCEMENTS
-- ============================================================
create policy "Admin dapat kelola pengumuman"
  on public.announcements for all
  using (is_admin_of(community_id));

-- Warga bisa lihat semua pengumuman di community-nya
create policy "Warga dapat lihat pengumuman"
  on public.announcements for select
  using (community_id = my_community_id());

-- ============================================================
-- POLICY — MARKETPLACE_LISTINGS
-- ============================================================
create policy "Admin dapat kelola semua listing"
  on public.marketplace_listings for all
  using (is_admin_of(community_id));

-- Warga bisa lihat semua listing di community-nya
create policy "Warga dapat lihat listing marketplace"
  on public.marketplace_listings for select
  using (community_id = my_community_id());

-- Warga bisa buat listing baru
create policy "Warga dapat buat listing"
  on public.marketplace_listings for insert
  with check (
    seller_id = auth.uid()
    and community_id = my_community_id()
  );

-- Warga hanya bisa update/hapus listing miliknya
create policy "Warga dapat update listing sendiri"
  on public.marketplace_listings for update
  using (seller_id = auth.uid());

-- ============================================================
-- POLICY — AI_LOGS
-- ============================================================
-- Hanya admin yang bisa insert & lihat log AI
create policy "Admin dapat kelola ai_logs"
  on public.ai_logs for all
  using (is_admin_of(community_id));

-- ============================================================
-- SELESAI: RLS aktif di 9 tabel dengan policy lengkap
-- ============================================================
