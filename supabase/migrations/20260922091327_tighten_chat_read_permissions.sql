-- Vslast Premium: tighten chat message read permissions.
drop policy if exists chat_messages_update on public.chat_messages;
drop policy if exists chat_threads_update on public.chat_threads;

create or replace function public.mark_chat_messages_read(p_thread_id uuid)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_count integer;
begin
  update public.chat_messages m
  set read_at = now()
  where m.thread_id = p_thread_id
    and m.read_at is null
    and m.sender_user_id <> auth.uid()
    and exists (
      select 1 from public.chat_threads t
      where t.id = m.thread_id
        and (t.client_user_id = auth.uid() or public.is_admin_user())
    );
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke execute on function public.mark_chat_messages_read(uuid) from public, anon;
grant execute on function public.mark_chat_messages_read(uuid) to authenticated;
