-- Make sure the avatars bucket exists
insert into storage.buckets (id, name, public) 
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- Policy: Anyone can view avatars
create policy "Public Access to Avatars"
on storage.objects for select
using ( bucket_id = 'avatars' );

-- Policy: Authenticated users can upload avatars
-- and they can only upload to their own folder (folder name = user id)
create policy "Users can upload their own avatars"
on storage.objects for insert
with check (
    bucket_id = 'avatars' 
    and auth.role() = 'authenticated'
);

-- Policy: Users can update their own avatars
create policy "Users can update their own avatars"
on storage.objects for update
using (
    bucket_id = 'avatars' 
    and auth.role() = 'authenticated'
)
with check (
    bucket_id = 'avatars' 
    and auth.role() = 'authenticated'
);

-- Policy: Users can delete their own avatars
create policy "Users can delete their own avatars"
on storage.objects for delete
using (
    bucket_id = 'avatars' 
    and auth.role() = 'authenticated'
);
