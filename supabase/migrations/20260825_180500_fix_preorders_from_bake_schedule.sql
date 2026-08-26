-- ============================================================
-- FIX: PREORDERS FROM BAKE SCHEDULE
--
-- Предзаказ из графика запеков:
-- 1. определяет ДАТУ получения;
-- 2. НЕ определяет время получения;
-- 3. pickup_time_slot = NULL;
-- 4. всегда получает is_preorder = true;
-- 5. использует существующую create_order_from_cart()
--    для единой логики расчёта заказа.
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
        raise exception
          'Товар недоступен для предзаказа: %',
          v_product_id;
      end if;

    end loop;

    if not exists (
      select 1
      from public.cart_items
      where cart_id = v_cart_id
    ) then
      raise exception
        'Для % не выбраны товары',
        v_date;
    end if;

    /*
     * График запеков задаёт только дату.
     *
     * Время получения НЕ задаётся.
     *
     * create_order_from_cart() допускает NULL
     * в p_pickup_time_slot.
     */

    select *
    into v_result
    from public.create_order_from_cart(
      p_delivery_method   => 'pickup',
      p_payment_method    => p_payment_method,
      p_pickup_date       => v_date,
      p_pickup_time_slot  => null,
      p_delivery_address  => null,
      p_comment           => p_comment
    );

    /*
     * Заказ, созданный именно из графика запеков,
     * всегда является предзаказом.
     *
     * Даже если все товары сейчас имеют in_stock = true.
     */

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
      'total', v_result.total,
      'is_preorder', true
    );

    v_orders :=
      v_orders || jsonb_build_array(v_day_orders);

  end loop;

  delete from public.cart_items
  where cart_id = v_cart_id;

  return v_orders;

exception
  when others then

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
