-- Storage bucket and RLS for announcement/news attachments.
-- Keep limits aligned with app policy:
-- - image attachments: max 40 KB (enforced in app)
-- - document attachments: max 70 KB

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'post-attachments',
  'post-attachments',
  true,
  71680,
  array[
    'image/jpeg',
    'image/png',
    'image/webp',
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'text/plain'
  ]
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

alter table storage.objects enable row level security;

drop policy if exists post_attachments_public_read on storage.objects;
create policy post_attachments_public_read
on storage.objects
for select
using (bucket_id = 'post-attachments');

drop policy if exists post_attachments_staff_insert on storage.objects;
create policy post_attachments_staff_insert
on storage.objects
for insert
with check (
  bucket_id = 'post-attachments'
  and auth.uid() is not null
  and public.current_app_role() in ('editor', 'admin')
);

drop policy if exists post_attachments_staff_update on storage.objects;
create policy post_attachments_staff_update
on storage.objects
for update
using (
  bucket_id = 'post-attachments'
  and public.current_app_role() in ('editor', 'admin')
)
with check (
  bucket_id = 'post-attachments'
  and public.current_app_role() in ('editor', 'admin')
);

drop policy if exists post_attachments_staff_delete on storage.objects;
create policy post_attachments_staff_delete
on storage.objects
for delete
using (
  bucket_id = 'post-attachments'
  and public.current_app_role() in ('editor', 'admin')
);
