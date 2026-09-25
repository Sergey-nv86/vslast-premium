-- Admin chat: exact client identity, direct chat creation, and tier broadcasts.
-- Group messaging is segmented private delivery: each client receives the message
-- in their own private thread and never sees other customers.

update public.chat_threads t
set client_id = ca.client_id
from public.client_accounts ca
where t.client_id is null
  and ca.legacy_user_id = t.client_user_id
  and ca.status = 'active';

create or replace function public.chat_sync_client_id()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if new.client_id is null and new.client_user_id is not null then
    select ca.client_id into new.client_id
    from public.client_accounts ca
    where ca.legacy_user_id = new.client_user_id
      and ca.status = 'active'
    limit 1;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_chat_sync_client_id on public.chat_threads;
create trigger trg_chat_sync_client_id
before insert or update of client_user_id on public.chat_threads
for each row execute function public.chat_sync_client_id();

revoke execute on function public.chat_sync_client_id() from public, anon, authenticated;

create or replace function public.admin_chat_clients()
returns table(client_user_id uuid, client_id text, level text, display_name text, phone text)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.is_admin_user() then raise exception 'Недостаточно прав'; end if;

  return query
  select ca.legacy_user_id,
         ca.client_id,
         lower(coalesce(la.level, 'silver')),
         coalesce(nullif(trim(p.display_name), ''),
                  nullif(trim(concat_ws(' ', p.first_name, p.last_name)), ''),
                  'Клиент'),
         coalesce(p.phone, '')
  from public.client_accounts ca
  join public.profiles p on p.id = ca.legacy_user_id
  left join public.loyalty_accounts la on la.user_id = ca.legacy_user_id
  where ca.status = 'active' and p.role = 'customer' and p.is_active = true
  order by ca.client_id;
end;
$$;

revoke execute on function public.admin_chat_clients() from public, anon;
grant execute on function public.admin_chat_clients() to authenticated;

create or replace function public.admin_ensure_chat_thread(p_client_user_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare v_thread_id uuid; v_client_id text;
begin
  if not public.is_admin_user() then raise exception 'Недостаточно прав'; end if;

  select ca.client_id into v_client_id
  from public.client_accounts ca
  join public.profiles p on p.id = ca.legacy_user_id
  where ca.legacy_user_id = p_client_user_id
    and ca.status = 'active' and p.role = 'customer' and p.is_active = true
  limit 1;

  if v_client_id is null then raise exception 'Активный клиент не найден'; end if;

  insert into public.chat_threads(client_user_id, client_id)
  values(p_client_user_id, v_client_id)
  on conflict(client_user_id) do update
    set client_id = coalesce(public.chat_threads.client_id, excluded.client_id),
        updated_at = now()
  returning id into v_thread_id;

  if v_thread_id is null then
    select id into v_thread_id from public.chat_threads
    where client_user_id = p_client_user_id;
  end if;
  return v_thread_id;
end;
$$;

revoke execute on function public.admin_ensure_chat_thread(uuid) from public, anon;
grant execute on function public.admin_ensure_chat_thread(uuid) to authenticated;

create or replace function public.admin_broadcast_chat_message(p_body text, p_level text default null)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_admin_role text; v_count integer := 0; v_client record; v_thread_id uuid;
  v_level text := nullif(lower(trim(coalesce(p_level, ''))), '');
begin
  if auth.uid() is null then raise exception 'Пользователь не авторизован'; end if;

  select role into v_admin_role from public.profiles
  where id = auth.uid() and is_active = true;

  if v_admin_role not in ('owner','admin','manager') then
    raise exception 'Недостаточно прав для рассылки клиентам';
  end if;
  if p_body is null or length(trim(p_body)) = 0 then raise exception 'Сообщение не может быть пустым'; end if;
  if v_level is not null and v_level not in ('gold','premium') then raise exception 'Неизвестная группа клиентов'; end if;

  for v_client in
    select ca.legacy_user_id as user_id, ca.client_id
    from public.client_accounts ca
    join public.profiles p on p.id = ca.legacy_user_id
    left join public.loyalty_accounts la on la.user_id = ca.legacy_user_id
    where ca.status = 'active' and p.is_active = true and p.role = 'customer'
      and (v_level is null or lower(coalesce(la.level, 'silver')) = v_level)
  loop
    insert into public.chat_threads(client_user_id, client_id)
    values(v_client.user_id, v_client.client_id)
    on conflict(client_user_id) do update
      set client_id = coalesce(public.chat_threads.client_id, excluded.client_id),
          updated_at = now()
    returning id into v_thread_id;

    if v_thread_id is null then
      select id into v_thread_id from public.chat_threads
      where client_user_id = v_client.user_id;
    end if;

    insert into public.chat_messages(thread_id, sender_user_id, sender_role, body)
    values(v_thread_id, auth.uid(), 'admin', trim(p_body));
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;

revoke execute on function public.admin_broadcast_chat_message(text, text) from public, anon;
grant execute on function public.admin_broadcast_chat_message(text, text) to authenticated;
