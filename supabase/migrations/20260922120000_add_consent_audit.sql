create table if not exists public.consents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  consent_type text not null check (consent_type in ('personal_data_processing','terms_acceptance','marketing')),
  document_version text not null,
  granted_at timestamptz not null default now(),
  withdrawn_at timestamptz,
  ip_address inet,
  user_agent text,
  source text not null default 'registration',
  created_at timestamptz not null default now()
);
create index if not exists idx_consents_user_id on public.consents(user_id);
create index if not exists idx_consents_type_granted_at on public.consents(consent_type, granted_at desc);
alter table public.consents enable row level security;
drop policy if exists "Users can read own consents" on public.consents;
create policy "Users can read own consents" on public.consents for select to authenticated using (auth.uid() = user_id);
drop policy if exists "Owners can read all consents" on public.consents;
create policy "Owners can read all consents" on public.consents for select to authenticated using (public.is_owner());
