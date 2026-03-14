-- ==========================================
-- 1. Table Announcements
-- ==========================================
create table if not exists public.announcements (
  id uuid default gen_random_uuid() primary key,
  community_id uuid references public.communities(id) on delete cascade not null,
  title text not null,
  body text not null,
  type text default 'info', -- 'info', 'penting', 'urgent'
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS
alter table public.announcements enable row level security;

-- Policy Warga baca Pengumuman (hanya komunitasnya sendiri)
create policy "Warga dapat membaca pengumuman communitynya" 
  on public.announcements for select 
  using (
    community_id = (
      select community_id from public.profiles where id = auth.uid()
    )
  );

-- Policy Admin insert/delete pengumuman
create policy "Admin dapat mengubah pengumuman communitynya"
  on public.announcements for all
  using (
    community_id = (
      select community_id from public.profiles where id = auth.uid() and role = 'admin'
    )
  );

-- ==========================================
-- 2. Table Marketplace Listings
-- ==========================================
create table if not exists public.marketplace_listings (
  id uuid default gen_random_uuid() primary key,
  community_id uuid references public.communities(id) on delete cascade not null,
  seller_id uuid references public.profiles(id) on delete cascade not null,
  title text not null,
  description text,
  price bigint,
  category text default 'lainnya',
  images _text default '{}'::text[],
  status text default 'active', -- 'active' | 'sold'
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS
alter table public.marketplace_listings enable row level security;

create policy "Users dapat baca listing dlm communitynya" 
  on public.marketplace_listings for select 
  using (
    community_id = (
      select community_id from public.profiles where id = auth.uid()
    )
  );

create policy "Seller dapat merubah listing miliknya sendiri"
  on public.marketplace_listings for all
  using (seller_id = auth.uid());
