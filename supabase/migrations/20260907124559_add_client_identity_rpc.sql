-- Vslast Premium: client identity bridge RPC.
-- Uses auth.uid() only as an internal security anchor.
-- No name, phone, email, birth date or address is created here.

create or replace function public.ensure_client_account()
returns table(client_id text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_client_id text;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  select ca.client_id
    into v_client_id
  from public.client_accounts ca
  where ca.legacy_user_id = v_user_id
    and ca.status = 'active'
  limit 1;

  if v_client_id is null then
    v_client_id := public.next_client_id();

    insert into public.client_accounts (client_id, legacy_user_id, status)
    values (v_client_id, v_user_id, 'active')
    on conflict (legacy_user_id) do update
      set status = 'active', updated_at = now()
    returning client_accounts.client_id into v_client_id;
  end if;

  return query select v_client_id;
end;
$$;

revoke all on function public.ensure_client_account() from public;
grant execute on function public.ensure_client_account() to authenticated;
