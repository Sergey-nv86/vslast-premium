-- ============================================================================
-- Vslast Premium
-- Firebase Cloud Messaging device tokens
-- ============================================================================

create table if not exists public.user_devices (
  id uuid primary key default gen_random_uuid(),

  user_id uuid not null references auth.users(id) on delete cascade,

  fcm_token text not null,

  platform text not null
    check (platform in ('ios', 'android', 'web', 'macos', 'windows', 'linux')),

  is_active boolean not null default true,

  created_at timestamptz not null default now(),

  updated_at timestamptz not null default now(),

  unique (user_id, fcm_token)
);

create index if not exists user_devices_user_id_idx
  on public.user_devices(user_id);

create index if not exists user_devices_active_idx
  on public.user_devices(is_active);

alter table public.user_devices enable row level security;

drop policy if exists "user_devices_select_own"
  on public.user_devices;

create policy "user_devices_select_own"
  on public.user_devices
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "user_devices_insert_own"
  on public.user_devices;

create policy "user_devices_insert_own"
  on public.user_devices
  for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "user_devices_update_own"
  on public.user_devices;

create policy "user_devices_update_own"
  on public.user_devices
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "user_devices_delete_own"
  on public.user_devices;

create policy "user_devices_delete_own"
  on public.user_devices
  for delete
  to authenticated
  using (auth.uid() = user_id);

grant select, insert, update, delete
  on public.user_devices
  to authenticated;
