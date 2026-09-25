-- Vslast Premium: client/admin chat
-- One private thread per customer, with private image storage.

create table if not exists public.chat_threads (
  id uuid primary key default gen_random_uuid(),
  client_user_id uuid not null unique references public.profiles(id) on delete cascade,
  client_id text,
  last_message_at timestamptz,
  last_message_preview text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.chat_threads(id) on delete cascade,
  sender_user_id uuid not null references public.profiles(id) on delete restrict,
  sender_role text not null check (sender_role in ('customer','admin')),
  body text,
  image_path text,
  created_at timestamptz not null default now(),
  read_at timestamptz,
  constraint chat_messages_content_check check (
    nullif(trim(coalesce(body, '')), '') is not null or image_path is not null
  )
);

create index if not exists chat_threads_last_message_idx
  on public.chat_threads(last_message_at desc nulls last);

create index if not exists chat_messages_thread_created_idx
  on public.chat_messages(thread_id, created_at);

create index if not exists chat_messages_unread_idx
  on public.chat_messages(thread_id, read_at)
  where read_at is null;

alter table public.chat_threads enable row level security;
alter table public.chat_messages enable row level security;

drop policy if exists chat_threads_select on public.chat_threads;
create policy chat_threads_select
on public.chat_threads
for select to authenticated
using (
  client_user_id = auth.uid()
  or public.is_admin_user()
);

drop policy if exists chat_threads_insert on public.chat_threads;
create policy chat_threads_insert
on public.chat_threads
for insert to authenticated
with check (
  client_user_id = auth.uid()
  and not public.is_admin_user()
);

drop policy if exists chat_threads_update on public.chat_threads;
create policy chat_threads_update
on public.chat_threads
for update to authenticated
using (
  client_user_id = auth.uid()
  or public.is_admin_user()
)
with check (
  client_user_id = auth.uid()
  or public.is_admin_user()
);

drop policy if exists chat_messages_select on public.chat_messages;
create policy chat_messages_select
on public.chat_messages
for select to authenticated
using (
  exists (
    select 1
    from public.chat_threads t
    where t.id = chat_messages.thread_id
      and (t.client_user_id = auth.uid() or public.is_admin_user())
  )
);

drop policy if exists chat_messages_insert on public.chat_messages;
create policy chat_messages_insert
on public.chat_messages
for insert to authenticated
with check (
  sender_user_id = auth.uid()
  and (
    (sender_role = 'customer' and not public.is_admin_user())
    or (sender_role = 'admin' and public.is_admin_user())
  )
  and exists (
    select 1
    from public.chat_threads t
    where t.id = chat_messages.thread_id
      and (t.client_user_id = auth.uid() or public.is_admin_user())
  )
);

drop policy if exists chat_messages_update on public.chat_messages;
create policy chat_messages_update
on public.chat_messages
for update to authenticated
using (
  exists (
    select 1
    from public.chat_threads t
    where t.id = chat_messages.thread_id
      and (t.client_user_id = auth.uid() or public.is_admin_user())
  )
)
with check (
  exists (
    select 1
    from public.chat_threads t
    where t.id = chat_messages.thread_id
      and (t.client_user_id = auth.uid() or public.is_admin_user())
  )
);

grant select, insert, update on public.chat_threads to authenticated;
grant select, insert, update on public.chat_messages to authenticated;

-- Private storage bucket: chat images are never public.
insert into storage.buckets (id, name, public)
values ('chat-images', 'chat-images', false)
on conflict (id) do update set public = false;

drop policy if exists chat_images_select on storage.objects;
create policy chat_images_select
on storage.objects
for select to authenticated
using (
  bucket_id = 'chat-images'
  and exists (
    select 1
    from public.chat_threads t
    where t.id::text = (storage.foldername(name))[1]
      and (t.client_user_id = auth.uid() or public.is_admin_user())
  )
);

drop policy if exists chat_images_insert on storage.objects;
create policy chat_images_insert
on storage.objects
for insert to authenticated
with check (
  bucket_id = 'chat-images'
  and exists (
    select 1
    from public.chat_threads t
    where t.id::text = (storage.foldername(name))[1]
      and (t.client_user_id = auth.uid() or public.is_admin_user())
  )
);

drop policy if exists chat_images_update on storage.objects;
create policy chat_images_update
on storage.objects
for update to authenticated
using (
  bucket_id = 'chat-images'
  and exists (
    select 1
    from public.chat_threads t
    where t.id::text = (storage.foldername(name))[1]
      and (t.client_user_id = auth.uid() or public.is_admin_user())
  )
)
with check (
  bucket_id = 'chat-images'
  and exists (
    select 1
    from public.chat_threads t
    where t.id::text = (storage.foldername(name))[1]
      and (t.client_user_id = auth.uid() or public.is_admin_user())
  )
);

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'chat_messages'
  ) then
    alter publication supabase_realtime add table public.chat_messages;
  end if;
end $$;

create or replace function public.chat_touch_thread()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  update public.chat_threads
  set last_message_at = new.created_at,
      last_message_preview = case
        when new.image_path is not null and nullif(trim(coalesce(new.body,'')), '') is null
          then 'Изображение'
        else left(trim(coalesce(new.body,'')), 120)
      end,
      updated_at = now()
  where id = new.thread_id;
  return new;
end;
$$;

drop trigger if exists trg_chat_touch_thread on public.chat_messages;
create trigger trg_chat_touch_thread
after insert on public.chat_messages
for each row
execute function public.chat_touch_thread();

revoke execute on function public.chat_touch_thread() from public, anon, authenticated;
