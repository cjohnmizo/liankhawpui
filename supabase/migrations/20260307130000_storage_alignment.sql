-- Align storage with the current media pipeline.
-- Images stay public in post-attachments.
-- Documents move to a private post-documents bucket and are opened via signed URLs.

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
  1048576,
  array[
    'image/jpeg',
    'image/png',
    'image/webp'
  ]
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'post-documents',
  'post-documents',
  false,
  5242880,
  array[
    'application/pdf',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  ]
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists post_documents_read_signed on storage.objects;
create policy post_documents_read_signed
on storage.objects
for select
using (
  bucket_id = 'post-documents'
  and auth.uid() is not null
);

drop policy if exists post_documents_staff_insert on storage.objects;
create policy post_documents_staff_insert
on storage.objects
for insert
with check (
  bucket_id = 'post-documents'
  and auth.uid() is not null
  and public.current_app_role() in ('editor', 'admin')
);

drop policy if exists post_documents_staff_update on storage.objects;
create policy post_documents_staff_update
on storage.objects
for update
using (
  bucket_id = 'post-documents'
  and public.current_app_role() in ('editor', 'admin')
)
with check (
  bucket_id = 'post-documents'
  and public.current_app_role() in ('editor', 'admin')
);

drop policy if exists post_documents_staff_delete on storage.objects;
create policy post_documents_staff_delete
on storage.objects
for delete
using (
  bucket_id = 'post-documents'
  and public.current_app_role() in ('editor', 'admin')
);
