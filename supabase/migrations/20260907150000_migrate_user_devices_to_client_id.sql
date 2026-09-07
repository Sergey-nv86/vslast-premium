-- Vslast Premium: migrate push device ownership to client_id.
-- Transitional: keep user_id for compatibility while making client_id the
-- primary business identity for device lookup.

create or replace function public.sync_user_device_client_id()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.client_id is null and new.user_id is not null then
    select ca.client_id
      into new.client_id
    from public.client_accounts ca
    where ca.legacy_user_id = new.user_id
      and ca.status = 'active'
    limit 1;
  end if;

  return new;
end;
$$;

revoke all on function public.sync_user_device_client_id() from public;

drop trigger if exists user_devices_sync_client_id on public.user_devices;

create trigger user_devices_sync_client_id
before insert or update of user_id, client_id
on public.user_devices
for each row
execute function public.sync_user_device_client_id();

-- Backfill any device that may have appeared between the identity migration
-- and creation of this trigger.
update public.user_devices d
set client_id = ca.client_id,
    updated_at = now()
from public.client_accounts ca
where d.client_id is null
  and d.user_id = ca.legacy_user_id
  and ca.status = 'active';

create index if not exists user_devices_client_id_active_idx
  on public.user_devices(client_id, is_active);
