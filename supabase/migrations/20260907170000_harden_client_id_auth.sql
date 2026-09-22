-- Client IDs are now allocated only by the server-side client-auth function.
-- Public clients must not be able to consume the sequence directly.
revoke all on function public.next_client_id() from public;
revoke all on function public.next_client_id() from anon;
revoke all on function public.next_client_id() from authenticated;
grant execute on function public.next_client_id() to service_role;

-- Legacy phone -> auth-email lookup is no longer part of the client login flow.
-- Keep the function for compatibility with old deployed clients, but do not
-- expose it to unauthenticated or authenticated Data API callers.
revoke all on function public.get_auth_email_by_phone(text) from public;
revoke all on function public.get_auth_email_by_phone(text) from anon;
revoke all on function public.get_auth_email_by_phone(text) from authenticated;
