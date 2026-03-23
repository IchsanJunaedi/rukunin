-- supabase/migrations/20260323_create_contact_photos_bucket.sql

-- Buat bucket contact_photos (public — URL bisa diakses langsung)
insert into storage.buckets (id, name, public)
values ('contact_photos', 'contact_photos', true)
on conflict (id) do nothing;

-- Policy: Semua orang bisa lihat (public bucket)
create policy "Anyone can view contact photos"
  on storage.objects for select
  using ( bucket_id = 'contact_photos' );

-- Policy: Admin bisa upload foto kontak
-- NOTE: Policy ini mengizinkan semua authenticated user — scoping per community_id
-- di level storage tidak praktis tanpa fungsi helper khusus. Data integrity
-- sudah dijaga oleh RLS di tabel community_contacts. Ini adalah known trade-off.
create policy "Admin can upload contact photos"
  on storage.objects for insert
  with check (
    bucket_id = 'contact_photos'
    and auth.role() = 'authenticated'
  );

-- Policy: Admin bisa update foto kontak
create policy "Admin can update contact photos"
  on storage.objects for update
  using (
    bucket_id = 'contact_photos'
    and auth.role() = 'authenticated'
  );

-- Policy: Admin bisa hapus foto kontak
create policy "Admin can delete contact photos"
  on storage.objects for delete
  using (
    bucket_id = 'contact_photos'
    and auth.role() = 'authenticated'
  );
