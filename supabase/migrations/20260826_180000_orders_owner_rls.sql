-- ============================================================
-- ORDERS RLS
-- Разрешаем владельцу bakery работать с заказами.
-- Клиент продолжает работать только со своими заказами.
-- ============================================================

-- ------------------------------------------------------------
-- OWNER: просмотр всех заказов
-- ------------------------------------------------------------

drop policy if exists "orders_owner_select" on public.orders;

create policy "orders_owner_select"
on public.orders
for select
to authenticated
using (
  exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and lower(coalesce(p.role, '')) = 'owner'
  )
);


-- ------------------------------------------------------------
-- OWNER: изменение заказов
-- ------------------------------------------------------------

drop policy if exists "orders_owner_update" on public.orders;

create policy "orders_owner_update"
on public.orders
for update
to authenticated
using (
  exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and lower(coalesce(p.role, '')) = 'owner'
  )
)
with check (
  exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and lower(coalesce(p.role, '')) = 'owner'
  )
);


-- ------------------------------------------------------------
-- OWNER: создание заказов
-- Не обязательно для админки, но сохраняем возможность
-- создавать заказ при необходимости.
-- ------------------------------------------------------------

drop policy if exists "orders_owner_insert" on public.orders;

create policy "orders_owner_insert"
on public.orders
for insert
to authenticated
with check (
  exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and lower(coalesce(p.role, '')) = 'owner'
  )
);


-- ------------------------------------------------------------
-- OWNER: удаление заказов
-- Сейчас не используется интерфейсом, поэтому НЕ разрешаем.
-- ------------------------------------------------------------


-- ============================================================
-- ПРОВЕРКА
-- ============================================================

select
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
from pg_policies
where schemaname = 'public'
  and tablename = 'orders'
order by policyname;
