-- ============================================================
-- ВСЛАСТЬ — ГРАФИК ЗАПЕКОВ
-- ============================================================

create table if not exists public.bake_schedules (
  id uuid primary key default gen_random_uuid(),
  bake_date date not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.bake_schedule_items (
  id uuid primary key default gen_random_uuid(),
  schedule_id uuid not null
    references public.bake_schedules(id)
    on delete cascade,
  product_id uuid not null
    references public.products(id)
    on delete cascade,
  created_at timestamptz not null default now(),

  unique(schedule_id, product_id)
);

create index if not exists idx_bake_schedules_date
  on public.bake_schedules(bake_date);

create index if not exists idx_bake_schedule_items_schedule
  on public.bake_schedule_items(schedule_id);

create index if not exists idx_bake_schedule_items_product
  on public.bake_schedule_items(product_id);

alter table public.bake_schedules enable row level security;
alter table public.bake_schedule_items enable row level security;

drop policy if exists "bake_schedules_public_read"
  on public.bake_schedules;

create policy "bake_schedules_public_read"
on public.bake_schedules
for select
to authenticated
using (true);

drop policy if exists "bake_schedule_items_public_read"
  on public.bake_schedule_items;

create policy "bake_schedule_items_public_read"
on public.bake_schedule_items
for select
to authenticated
using (true);

drop policy if exists "bake_schedules_admin_insert"
  on public.bake_schedules;

create policy "bake_schedules_admin_insert"
on public.bake_schedules
for insert
to authenticated
with check (
  exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and lower(coalesce(p.role, '')) in (
        'owner',
        'admin',
        'manager',
        'seller',
        'baker',
        'pastrychef'
      )
  )
);

drop policy if exists "bake_schedules_admin_update"
  on public.bake_schedules;

create policy "bake_schedules_admin_update"
on public.bake_schedules
for update
to authenticated
using (
  exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and lower(coalesce(p.role, '')) in (
        'owner',
        'admin',
        'manager',
        'seller',
        'baker',
        'pastrychef'
      )
  )
)
with check (
  exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and lower(coalesce(p.role, '')) in (
        'owner',
        'admin',
        'manager',
        'seller',
        'baker',
        'pastrychef'
      )
  )
);

drop policy if exists "bake_schedules_admin_delete"
  on public.bake_schedules;

create policy "bake_schedules_admin_delete"
on public.bake_schedules
for delete
to authenticated
using (
  exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and lower(coalesce(p.role, '')) in (
        'owner',
        'admin',
        'manager',
        'seller',
        'baker',
        'pastrychef'
      )
  )
);

drop policy if exists "bake_items_admin_insert"
  on public.bake_schedule_items;

create policy "bake_items_admin_insert"
on public.bake_schedule_items
for insert
to authenticated
with check (
  exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and lower(coalesce(p.role, '')) in (
        'owner',
        'admin',
        'manager',
        'seller',
        'baker',
        'pastrychef'
      )
  )
);

drop policy if exists "bake_items_admin_delete"
  on public.bake_schedule_items;

create policy "bake_items_admin_delete"
on public.bake_schedule_items
for delete
to authenticated
using (
  exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and lower(coalesce(p.role, '')) in (
        'owner',
        'admin',
        'manager',
        'seller',
        'baker',
        'pastrychef'
      )
    )
);

grant select on public.bake_schedules to authenticated;
grant select on public.bake_schedule_items to authenticated;
grant insert, update, delete on public.bake_schedules to authenticated;
grant insert, delete on public.bake_schedule_items to authenticated;


-- ============================================================
-- ЕДИНАЯ ФОРМА ПРЕДЗАКАЗА
--
-- payload:
-- [
--   {
--     "date": "2026-08-25",
--     "items": [
--       {
--         "product_id": "...",
--         "quantity": 2
--       }
--     ]
--   }
-- ]
--
-- На выходе создаются ОТДЕЛЬНЫЕ orders по каждой дате.
-- ============================================================

create or replace function public.create_preorders_from_bake_schedule(
  p_payload jsonb,
  p_payment_method text default 'onlineSbp',
  p_comment text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_cart_id uuid;
  v_day jsonb;
  v_item jsonb;
  v_date date;
  v_product_id uuid;
  v_quantity integer;

  v_result record;

  v_orders jsonb := '[]'::jsonb;
  v_day_orders jsonb;

begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'Пользователь не авторизован';
  end if;

  if p_payload is null
     or jsonb_typeof(p_payload) <> 'array'
     or jsonb_array_length(p_payload) = 0 then
    raise exception 'Предзаказ пуст';
  end if;

  select id
  into v_cart_id
  from public.carts
  where user_id = v_user_id
  limit 1;

  if v_cart_id is null then
    insert into public.carts(user_id)
    values (v_user_id)
    returning id into v_cart_id;
  end if;

  /*
   * Каждая дата превращается в отдельный обычный order.
   * Используем существующую create_order_from_cart,
   * поэтому существующая логика:
   * - нумерации;
   * - расчёта суммы;
   * - скидки;
   * - создания order_items;
   * - статусов
   * остаётся единой.
   */

  for v_day in
    select value
    from jsonb_array_elements(p_payload)
  loop

    v_date := (v_day->>'date')::date;

    if v_date is null then
      raise exception 'Не указана дата предзаказа';
    end if;

    delete from public.cart_items
    where cart_id = v_cart_id;

    for v_item in
      select value
      from jsonb_array_elements(
        coalesce(v_day->'items', '[]'::jsonb)
      )
    loop

      v_product_id := (v_item->>'product_id')::uuid;
      v_quantity := (v_item->>'quantity')::integer;

      if v_product_id is null then
        raise exception 'Не указан товар';
      end if;

      if v_quantity is null or v_quantity <= 0 then
        raise exception 'Некорректное количество товара';
      end if;

      insert into public.cart_items (
        cart_id,
        product_id,
        quantity,
        unit_price,
        weight_label
      )
      select
        v_cart_id,
        p.id,
        v_quantity,
        p.price,
        p.weight_label
      from public.products p
      where p.id = v_product_id
        and coalesce(p.is_available, true) = true;

      if not found then
        raise exception 'Товар недоступен для предзаказа: %', v_product_id;
      end if;

    end loop;

    if not exists (
      select 1
      from public.cart_items
      where cart_id = v_cart_id
    ) then
      raise exception 'Для % не выбраны товары', v_date;
    end if;

    /*
     * Самовывоз.
     * Время здесь намеренно пустое:
     * график запеков определяет ДАТУ,
     * а не график выдачи.
     */
    /*
     * Создаём обычный заказ через существующую
     * create_order_from_cart(), чтобы не дублировать:
     * - нумерацию заказа;
     * - расчёт суммы;
     * - скидку за самовывоз;
     * - создание order_items;
     * - статусы заказа.
     *
     * Параметры передаём по именам, как и в CheckoutScreen.
     *
     * График запеков определяет дату предзаказа.
     * Время здесь техническое и не является временем выдачи:
     * существующая create_order_from_cart() требует непустой
     * pickup_time_slot.
     */
    select *
    into v_result
    from public.create_order_from_cart(
      p_delivery_method   => 'pickup',
      p_payment_method    => p_payment_method,
      p_pickup_date      => v_date,
      p_pickup_time_slot => null,
      p_delivery_address => null,
      p_comment          => p_comment
    );

    -- Предзаказ из графика запеков всегда является предзаказом,
    -- независимо от текущего значения products.in_stock.
    --
    -- Время получения здесь не задаётся:
    -- пользователь выбирает только дату запека.
    update public.orders
    set
      is_preorder = true,
      pickup_time_slot = null
    where id = v_result.order_id;

    v_day_orders := jsonb_build_object(
      'date', v_date,
      'order_id', v_result.order_id,
      'order_number', v_result.order_number,
      'items_total', v_result.items_total,
      'pickup_discount', v_result.pickup_discount,
      'delivery_cost', v_result.delivery_cost,
      'total', v_result.total
    );

    v_orders := v_orders || jsonb_build_array(v_day_orders);

  end loop;

  delete from public.cart_items
  where cart_id = v_cart_id;

  return v_orders;

exception
  when others then

    /*
     * Не оставляем временные позиции графика в корзине.
     */
    if v_cart_id is not null then
      delete from public.cart_items
      where cart_id = v_cart_id;
    end if;

    raise;
end;
$$;

revoke all on function public.create_preorders_from_bake_schedule(
  jsonb,
  text,
  text
) from public;

grant execute on function public.create_preorders_from_bake_schedule(
  jsonb,
  text,
  text
) to authenticated;

