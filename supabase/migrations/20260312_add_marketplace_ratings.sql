-- ==========================================
-- 3. Table Ratings
-- ==========================================
create table if not exists public.ratings (
  id uuid default gen_random_uuid() primary key,
  listing_id uuid references public.marketplace_listings(id) on delete cascade not null,
  rater_id uuid references public.profiles(id) on delete cascade not null, -- pembeli
  seller_id uuid references public.profiles(id) on delete cascade not null, -- penjual
  score smallint check (score >= 1 and score <= 5) not null,
  comment text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(listing_id, rater_id) -- satu orang hanya bisa rate 1 barang sekali
);

-- RLS
alter table public.ratings enable row level security;

-- Policy baca: semua user terautentikasi bisa membaca rating
create policy "Semua orang bs baca rating"
  on public.ratings for select
  to authenticated
  using (true);

-- Policy insert: rater_id harus match auth.uid, bukan nge-rate diri sendiri
create policy "Pembeli bisa ngasi rating ke org lain"
  on public.ratings for insert
  to authenticated
  with check (
    rater_id = auth.uid() and 
    seller_id != auth.uid()
  );
