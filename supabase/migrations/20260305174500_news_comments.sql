-- News comments for signed-in users

create table if not exists public.news_comments (
  id uuid primary key default gen_random_uuid(),
  news_id uuid not null references public.news(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  author_name text,
  content text not null check (char_length(trim(content)) between 1 and 800),
  created_at timestamptz not null default now()
);

create index if not exists idx_news_comments_news_id_created_at
  on public.news_comments(news_id, created_at desc);

alter table public.news_comments enable row level security;

drop policy if exists news_comments_read_published_or_staff on public.news_comments;
create policy news_comments_read_published_or_staff
on public.news_comments
for select
using (
  exists (
    select 1
    from public.news n
    where n.id = news_comments.news_id
      and (n.is_published = true or public.current_app_role() in ('editor', 'admin'))
  )
);

drop policy if exists news_comments_insert_authenticated on public.news_comments;
create policy news_comments_insert_authenticated
on public.news_comments
for insert
with check (
  auth.uid() = user_id
  and exists (
    select 1
    from public.news n
    where n.id = news_comments.news_id
      and (n.is_published = true or public.current_app_role() in ('editor', 'admin'))
  )
);

drop policy if exists news_comments_update_owner_or_staff on public.news_comments;
create policy news_comments_update_owner_or_staff
on public.news_comments
for update
using (
  auth.uid() = user_id or public.current_app_role() in ('editor', 'admin')
)
with check (
  auth.uid() = user_id or public.current_app_role() in ('editor', 'admin')
);

drop policy if exists news_comments_delete_owner_or_staff on public.news_comments;
create policy news_comments_delete_owner_or_staff
on public.news_comments
for delete
using (
  auth.uid() = user_id or public.current_app_role() in ('editor', 'admin')
);
