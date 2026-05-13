-- Storage buckets

insert into storage.buckets (id, name, public) values ('item-photos', 'item-photos', false)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public) values ('scan-photos', 'scan-photos', true)
on conflict (id) do nothing;

-- Item photos: users access their own only
create policy "item_photos_select_own"
  on storage.objects for select
  using (
    bucket_id = 'item-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "item_photos_insert_own"
  on storage.objects for insert
  with check (
    bucket_id = 'item-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "item_photos_delete_own"
  on storage.objects for delete
  using (
    bucket_id = 'item-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- Scan photos: anonymous upload (rate limited at function level)
create policy "scan_photos_anon_insert"
  on storage.objects for insert
  with check (bucket_id = 'scan-photos');

create policy "scan_photos_public_read"
  on storage.objects for select
  using (bucket_id = 'scan-photos');
