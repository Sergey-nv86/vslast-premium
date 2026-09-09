drop policy if exists "Admins can view loyalty accounts"
on public.loyalty_accounts;

create policy "Admins can view loyalty accounts"
on public.loyalty_accounts
for select
to authenticated
using (is_admin_user());
