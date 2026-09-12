-- Enable realtime updates for client order status.
-- Client-side RLS already limits SELECT access to the user's own orders.

do $$
begin
  if not exists (
    select 1
    from pg_publication p
    join pg_publication_rel pr on pr.prpubid = p.oid
    join pg_class c on c.oid = pr.prrelid
    join pg_namespace n on n.oid = c.relnamespace
    where p.pubname = 'supabase_realtime'
      and n.nspname = 'public'
      and c.relname = 'orders'
  ) then
    execute 'alter publication supabase_realtime add table public.orders';
  end if;
end
$$;
