-- Vslast Premium: client identity layer
-- Transitional, non-destructive migration.
-- Keeps legacy user_id/auth linkage while introducing stable CLIENT-ID.

create table if not exists public.client_accounts (
  id uuid primary key default gen_random_uuid(),
  client_id text not null unique,
  legacy_user_id uuid unique,
  status text not null default 'active'
    check (status in ('active', 'blocked', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create sequence if not exists public.client_id_seq start 1;

create or replace function public.next_client_id()
returns text
language sql
security invoker
as $$
  select 'C-' || lpad(nextval('public.client_id_seq')::text, 6, '0');
$$;

insert into public.client_accounts (client_id, legacy_user_id)
select
  'C-' || lpad(row_number() over (order by p.created_at, p.id)::text, 6, '0'),
  p.id
from public.profiles p
left join public.client_accounts ca on ca.legacy_user_id = p.id
where ca.id is null;

select setval(
  'public.client_id_seq',
  greatest(
    coalesce((
      select max(substring(client_id from 3)::bigint)
      from public.client_accounts
      where client_id ~ '^C-[0-9]{6}$'
    ), 0),
    1
  ),
  true
);

alter table public.favorites add column if not exists client_id text;
alter table public.carts add column if not exists client_id text;
alter table public.orders add column if not exists client_id text;
alter table public.loyalty_accounts add column if not exists client_id text;
alter table public.loyalty_transactions add column if not exists client_id text;
alter table public.push_tokens add column if not exists client_id text;
alter table public.user_devices add column if not exists client_id text;
alter table public.push_events add column if not exists recipient_client_id text;
alter table public.crm_customer_cycles add column if not exists client_id text;
alter table public.crm_bonus_grants add column if not exists client_id text;

update public.favorites f
set client_id = ca.client_id
from public.client_accounts ca
where f.client_id is null and f.user_id = ca.legacy_user_id;

update public.carts c
set client_id = ca.client_id
from public.client_accounts ca
where c.client_id is null and c.user_id = ca.legacy_user_id;

update public.orders o
set client_id = ca.client_id
from public.client_accounts ca
where o.client_id is null and o.user_id = ca.legacy_user_id;

update public.loyalty_accounts l
set client_id = ca.client_id
from public.client_accounts ca
where l.client_id is null and l.user_id = ca.legacy_user_id;

update public.loyalty_transactions l
set client_id = ca.client_id
from public.client_accounts ca
where l.client_id is null and l.user_id = ca.legacy_user_id;

update public.push_tokens p
set client_id = ca.client_id
from public.client_accounts ca
where p.client_id is null and p.user_id = ca.legacy_user_id;

update public.user_devices d
set client_id = ca.client_id
from public.client_accounts ca
where d.client_id is null and d.user_id = ca.legacy_user_id;

update public.push_events e
set recipient_client_id = ca.client_id
from public.client_accounts ca
where e.recipient_client_id is null
  and e.recipient_user_id = ca.legacy_user_id;

update public.crm_customer_cycles c
set client_id = ca.client_id
from public.client_accounts ca
where c.client_id is null and c.user_id = ca.legacy_user_id;

update public.crm_bonus_grants b
set client_id = ca.client_id
from public.client_accounts ca
where b.client_id is null and b.user_id = ca.legacy_user_id;

create index if not exists favorites_client_id_idx
  on public.favorites(client_id);
create index if not exists carts_client_id_idx
  on public.carts(client_id);
create index if not exists orders_client_id_idx
  on public.orders(client_id);
create index if not exists loyalty_transactions_client_id_idx
  on public.loyalty_transactions(client_id);
create index if not exists push_tokens_client_id_idx
  on public.push_tokens(client_id);
create index if not exists user_devices_client_id_idx
  on public.user_devices(client_id);
create index if not exists push_events_recipient_client_id_idx
  on public.push_events(recipient_client_id);
create index if not exists crm_customer_cycles_client_id_idx
  on public.crm_customer_cycles(client_id);
create index if not exists crm_bonus_grants_client_id_idx
  on public.crm_bonus_grants(client_id);

alter table public.client_accounts enable row level security;

revoke all on public.client_accounts from anon;
revoke all on public.client_accounts from authenticated;
grant select on public.client_accounts to authenticated;

drop policy if exists client_accounts_select_own on public.client_accounts;
create policy client_accounts_select_own
on public.client_accounts
for select to authenticated
using (legacy_user_id = (select auth.uid()));
