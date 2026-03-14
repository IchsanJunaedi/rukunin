-- ============================================================
-- RUKUNIN — Database Schema
-- Jalankan seluruh script ini di Supabase SQL Editor
-- ============================================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ============================================================
-- 1. COMMUNITIES — Data RW
-- ============================================================
create table public.communities (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  address text,
  rw_number text not null,
  admin_phone text,
  subscription_tier text not null default 'basic',
  unit_limit integer not null default 300,
  created_at timestamptz not null default now()
);

-- ============================================================
-- 2. PROFILES — Semua user: admin RT dan warga
-- ============================================================
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  community_id uuid references public.communities(id) on delete set null,
  full_name text not null,
  phone text,
  nik text,
  unit_number text,
  role text not null default 'resident' check (role in ('admin', 'resident')),
  status text not null default 'active' check (status in ('active', 'inactive')),
  photo_url text,
  created_at timestamptz not null default now()
);

-- ============================================================
-- 3. BILLING_TYPES — Jenis iuran (IPL, keamanan, kebersihan, dll.)
-- ============================================================
create table public.billing_types (
  id uuid primary key default uuid_generate_v4(),
  community_id uuid not null references public.communities(id) on delete cascade,
  name text not null,
  amount numeric(12,2) not null default 0,
  billing_day integer not null default 10 check (billing_day between 1 and 28),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- ============================================================
-- 4. INVOICES — Tagihan per warga per bulan
-- ============================================================
create table public.invoices (
  id uuid primary key default uuid_generate_v4(),
  community_id uuid not null references public.communities(id) on delete cascade,
  resident_id uuid not null references public.profiles(id) on delete cascade,
  billing_type_id uuid not null references public.billing_types(id) on delete restrict,
  amount numeric(12,2) not null,
  month integer not null check (month between 1 and 12),
  year integer not null,
  due_date date not null,
  status text not null default 'pending' check (status in ('pending', 'paid', 'overdue')),
  payment_link text,
  payment_token text,
  wa_sent_at timestamptz,
  created_at timestamptz not null default now(),
  unique (resident_id, billing_type_id, month, year)
);

-- ============================================================
-- 5. PAYMENTS — Rekam setiap pembayaran berhasil
-- ============================================================
create table public.payments (
  id uuid primary key default uuid_generate_v4(),
  invoice_id uuid not null references public.invoices(id) on delete restrict,
  community_id uuid not null references public.communities(id) on delete cascade,
  amount numeric(12,2) not null,
  method text,
  gateway_ref text,
  paid_at timestamptz not null default now()
);

-- ============================================================
-- 6. EXPENSES — Pengeluaran kas lingkungan
-- ============================================================
create table public.expenses (
  id uuid primary key default uuid_generate_v4(),
  community_id uuid not null references public.communities(id) on delete cascade,
  amount numeric(12,2) not null,
  category text not null check (category in ('Kebersihan', 'Keamanan', 'Infrastruktur', 'Sosial', 'Operasional', 'Lain-lain')),
  description text,
  receipt_url text,
  expense_date date not null default current_date,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

-- ============================================================
-- 7. ANNOUNCEMENTS — Pengumuman dari admin ke warga
-- ============================================================
create table public.announcements (
  id uuid primary key default uuid_generate_v4(),
  community_id uuid not null references public.communities(id) on delete cascade,
  title text not null,
  body text not null,
  type text not null default 'info' check (type in ('info', 'warning', 'urgent')),
  wa_broadcast_sent boolean not null default false,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

-- ============================================================
-- 8. MARKETPLACE_LISTINGS — Jual beli antar warga
-- ============================================================
create table public.marketplace_listings (
  id uuid primary key default uuid_generate_v4(),
  community_id uuid not null references public.communities(id) on delete cascade,
  seller_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text,
  price numeric(12,2) not null default 0,
  category text not null default 'Lain-lain',
  images text[] default '{}',
  status text not null default 'available' check (status in ('available', 'sold', 'inactive')),
  created_at timestamptz not null default now()
);

-- ============================================================
-- 9. AI_LOGS — Log interaksi AI (data skripsi)
-- ============================================================
create table public.ai_logs (
  id uuid primary key default uuid_generate_v4(),
  community_id uuid not null references public.communities(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete set null,
  query_type text not null,
  prompt_summary text,
  response_summary text,
  tokens_used integer,
  response_time_ms integer,
  created_at timestamptz not null default now()
);

-- ============================================================
-- INDEX — untuk query yang sering dipakai
-- ============================================================
create index idx_profiles_community on public.profiles(community_id);
create index idx_invoices_community on public.invoices(community_id);
create index idx_invoices_resident on public.invoices(resident_id);
create index idx_invoices_status on public.invoices(status);
create index idx_invoices_month_year on public.invoices(month, year);
create index idx_payments_community on public.payments(community_id);
create index idx_expenses_community on public.expenses(community_id);
create index idx_announcements_community on public.announcements(community_id);
create index idx_marketplace_community on public.marketplace_listings(community_id);
create index idx_ai_logs_community on public.ai_logs(community_id);

-- ============================================================
-- SELESAI: 9 tabel + 10 index berhasil dibuat
-- ============================================================
