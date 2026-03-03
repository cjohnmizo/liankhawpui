-- Liankhawpui RLS baseline
-- Run in Supabase SQL editor as a project owner.

-- Helper function to read current app role from public.profiles.
create or replace function public.current_app_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select role from public.profiles where id = auth.uid() limit 1),
    'guest'
  );
$$;

revoke all on function public.current_app_role() from public;
grant execute on function public.current_app_role() to anon, authenticated;

-- Prevent normal users from changing their own role.
create or replace function public.prevent_self_role_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() = old.id
     and new.role is distinct from old.role
     and public.current_app_role() not in ('editor', 'admin') then
    raise exception 'Only editor/admin can change roles';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_prevent_self_role_change on public.profiles;
create trigger trg_prevent_self_role_change
before update on public.profiles
for each row execute function public.prevent_self_role_change();

alter table if exists public.profiles enable row level security;
alter table if exists public.announcements enable row level security;
alter table if exists public.news enable row level security;
alter table if exists public.organizations enable row level security;
alter table if exists public.office_bearers enable row level security;
alter table if exists public.books enable row level security;
alter table if exists public.chapters enable row level security;

-- PROFILES
drop policy if exists profiles_select_self_or_staff on public.profiles;
create policy profiles_select_self_or_staff
on public.profiles
for select
using (
  auth.uid() = id
  or public.current_app_role() in ('editor', 'admin')
);

drop policy if exists profiles_insert_self_guest on public.profiles;
create policy profiles_insert_self_guest
on public.profiles
for insert
with check (
  auth.uid() = id
  and role = 'guest'
);

drop policy if exists profiles_update_self_or_staff on public.profiles;
create policy profiles_update_self_or_staff
on public.profiles
for update
using (
  auth.uid() = id
  or public.current_app_role() in ('editor', 'admin')
)
with check (
  auth.uid() = id
  or public.current_app_role() in ('editor', 'admin')
);

drop policy if exists profiles_delete_admin_only on public.profiles;
create policy profiles_delete_admin_only
on public.profiles
for delete
using (public.current_app_role() = 'admin');

-- PUBLIC READ TABLES
drop policy if exists announcements_read_all on public.announcements;
create policy announcements_read_all
on public.announcements
for select
using (true);

drop policy if exists news_read_published_or_staff on public.news;
create policy news_read_published_or_staff
on public.news
for select
using (
  is_published = true
  or public.current_app_role() in ('editor', 'admin')
);

drop policy if exists organizations_read_all on public.organizations;
create policy organizations_read_all
on public.organizations
for select
using (true);

drop policy if exists office_bearers_read_all on public.office_bearers;
create policy office_bearers_read_all
on public.office_bearers
for select
using (true);

drop policy if exists books_read_all on public.books;
create policy books_read_all
on public.books
for select
using (true);

drop policy if exists chapters_read_all on public.chapters;
create policy chapters_read_all
on public.chapters
for select
using (true);

-- STAFF WRITE PERMISSIONS
drop policy if exists announcements_insert_staff on public.announcements;
create policy announcements_insert_staff
on public.announcements
for insert
with check (public.current_app_role() in ('editor', 'admin'));

drop policy if exists announcements_update_staff on public.announcements;
create policy announcements_update_staff
on public.announcements
for update
using (public.current_app_role() in ('editor', 'admin'))
with check (public.current_app_role() in ('editor', 'admin'));

drop policy if exists announcements_delete_staff on public.announcements;
create policy announcements_delete_staff
on public.announcements
for delete
using (public.current_app_role() in ('editor', 'admin'));

drop policy if exists news_insert_staff on public.news;
create policy news_insert_staff
on public.news
for insert
with check (public.current_app_role() in ('editor', 'admin'));

drop policy if exists news_update_staff on public.news;
create policy news_update_staff
on public.news
for update
using (public.current_app_role() in ('editor', 'admin'))
with check (public.current_app_role() in ('editor', 'admin'));

drop policy if exists news_delete_staff on public.news;
create policy news_delete_staff
on public.news
for delete
using (public.current_app_role() in ('editor', 'admin'));

drop policy if exists organizations_insert_staff on public.organizations;
create policy organizations_insert_staff
on public.organizations
for insert
with check (public.current_app_role() in ('editor', 'admin'));

drop policy if exists organizations_update_staff on public.organizations;
create policy organizations_update_staff
on public.organizations
for update
using (public.current_app_role() in ('editor', 'admin'))
with check (public.current_app_role() in ('editor', 'admin'));

drop policy if exists organizations_delete_staff on public.organizations;
create policy organizations_delete_staff
on public.organizations
for delete
using (public.current_app_role() in ('editor', 'admin'));

drop policy if exists office_bearers_insert_staff on public.office_bearers;
create policy office_bearers_insert_staff
on public.office_bearers
for insert
with check (public.current_app_role() in ('editor', 'admin'));

drop policy if exists office_bearers_update_staff on public.office_bearers;
create policy office_bearers_update_staff
on public.office_bearers
for update
using (public.current_app_role() in ('editor', 'admin'))
with check (public.current_app_role() in ('editor', 'admin'));

drop policy if exists office_bearers_delete_staff on public.office_bearers;
create policy office_bearers_delete_staff
on public.office_bearers
for delete
using (public.current_app_role() in ('editor', 'admin'));
