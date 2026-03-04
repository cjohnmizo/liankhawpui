-- Story module updates:
-- 1) add optional chapter image URL
-- 2) allow editor/admin write access for books and chapters
-- 3) ensure there is a default Khawlian Chanchin row for single-book UX

alter table if exists public.chapters
  add column if not exists image_url text;

insert into public.books (id, title, author, cover_url, description)
select
  '00000000-0000-0000-0000-000000000001'::uuid,
  'Khawlian Chanchin',
  null,
  null,
  'History and souvenir of Khawlian Village'
where not exists (select 1 from public.books);

drop policy if exists books_insert_staff on public.books;
create policy books_insert_staff
on public.books
for insert
with check (public.current_app_role() in ('editor', 'admin'));

drop policy if exists books_update_staff on public.books;
create policy books_update_staff
on public.books
for update
using (public.current_app_role() in ('editor', 'admin'))
with check (public.current_app_role() in ('editor', 'admin'));

drop policy if exists books_delete_staff on public.books;
create policy books_delete_staff
on public.books
for delete
using (public.current_app_role() in ('editor', 'admin'));

drop policy if exists chapters_insert_staff on public.chapters;
create policy chapters_insert_staff
on public.chapters
for insert
with check (public.current_app_role() in ('editor', 'admin'));

drop policy if exists chapters_update_staff on public.chapters;
create policy chapters_update_staff
on public.chapters
for update
using (public.current_app_role() in ('editor', 'admin'))
with check (public.current_app_role() in ('editor', 'admin'));

drop policy if exists chapters_delete_staff on public.chapters;
create policy chapters_delete_staff
on public.chapters
for delete
using (public.current_app_role() in ('editor', 'admin'));
