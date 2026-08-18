-- ============================================================
-- Всласть — авторизация по телефону
--
-- Телефон хранится в public.profiles.
-- Supabase Auth использует email + password.
--
-- Flutter:
--   phone
--      ↓
--   get_auth_email_by_phone()
--      ↓
--   email
--      ↓
--   Supabase Auth
--
-- Функция возвращает только email активного пользователя.
-- Поля профиля клиенту не раскрываются.
-- ============================================================

create or replace function public.get_auth_email_by_phone(
  p_phone text
)
returns text
language sql
security definer
set search_path = public
as $$
  select email
  from public.profiles
  where phone = p_phone
    and is_active = true
  limit 1;
$$;

revoke all
on function public.get_auth_email_by_phone(text)
from public;

grant execute
on function public.get_auth_email_by_phone(text)
to anon, authenticated;

-- ============================================================
-- Проверка функции
-- ============================================================

select public.get_auth_email_by_phone('+79224042872');

select public.get_auth_email_by_phone('+79129399754');
