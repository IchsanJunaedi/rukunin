-- supabase/migrations/20260323_community_contacts.sql

create table public.community_contacts (
  id           uuid primary key default gen_random_uuid(),
  community_id uuid not null references public.communities(id) on delete cascade,
  nama         text not null,
  jabatan      text not null,
  phone        text not null,
  photo_url    text,
  urutan       int not null default 0,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

alter table public.community_contacts enable row level security;

-- Admin komunitas: full CRUD
create policy "Admin can manage community_contacts"
  on public.community_contacts for all
  using (is_admin_of(community_id))
  with check (is_admin_of(community_id));

-- Warga komunitas: read only
create policy "Resident can view community_contacts"
  on public.community_contacts for select
  using (community_id = my_community_id());
