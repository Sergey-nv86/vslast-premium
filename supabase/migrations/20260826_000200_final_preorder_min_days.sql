-- ============================================================
-- Всласть
-- FINAL FIX: предзаказ разрешён начиная с сегодняшнего дня.
--
-- preorder_min_days:
--   0 = сегодня
--   1 = завтра
--   2 = послезавтра
--
-- Важно:
-- старая миграция 20260825_181500_fix_preorders_min_days.sql
-- не изменяется, так как она является исторической миграцией.
-- ============================================================

-- 1. Устанавливаем фактическую настройку:
--    предзаказ разрешён с сегодняшней даты.
UPDATE public.order_settings
SET preorder_min_days = 0
WHERE id = 1;


-- 2. Если настройка отсутствует или NULL,
--    RPC также должна разрешать предзаказ с сегодняшнего дня.
--
-- Получаем текущую функцию и заменяем только fallback
-- с 2 на 0.

CREATE OR REPLACE FUNCTION public.create_preorders_from_bake_schedule(
  p_payload jsonb,
  p_payment_method text DEFAULT 'onlineSbp',
  p_comment text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
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
  v_preorder_min_days integer := 0;
BEGIN

  -- ==========================================================
  -- 1. Авторизация
  -- ==========================================================

  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Пользователь не авторизован';
  END IF;


  -- ==========================================================
  -- 2. Payload
  -- ==========================================================

  IF p_payload IS NULL
     OR jsonb_typeof(p_payload) <> 'array'
     OR jsonb_array_length(p_payload) = 0 THEN
    RAISE EXCEPTION 'Предзаказ пуст';
  END IF;


  -- ==========================================================
  -- 3. Настройка минимального срока предзаказа
  -- ==========================================================

  SELECT COALESCE(os.preorder_min_days, 0)
  INTO v_preorder_min_days
  FROM public.order_settings os
  WHERE os.id = 1;

  IF v_preorder_min_days < 0 THEN
    v_preorder_min_days := 0;
  END IF;


  -- ==========================================================
  -- 4. Корзина
  -- ==========================================================

  SELECT c.id
  INTO v_cart_id
  FROM public.carts c
  WHERE c.user_id = v_user_id
  LIMIT 1;

  IF v_cart_id IS NULL THEN
    INSERT INTO public.carts(user_id)
    VALUES (v_user_id)
    RETURNING id INTO v_cart_id;
  END IF;


  -- ==========================================================
  -- 5. Отдельный order на каждую дату
  -- ==========================================================

  FOR v_day IN
    SELECT value
    FROM jsonb_array_elements(p_payload)
  LOOP

    v_date := (v_day->>'date')::date;

    IF v_date IS NULL THEN
      RAISE EXCEPTION 'Не указана дата предзаказа';
    END IF;


    -- ========================================================
    -- КЛЮЧЕВАЯ ПРОВЕРКА ДАТЫ
    --
    -- При preorder_min_days = 0:
    -- сегодня разрешено.
    -- вчера запрещено.
    -- ========================================================

    IF v_date < current_date + v_preorder_min_days THEN
      RAISE EXCEPTION
        'Предзаказ можно оформить не ранее чем через % дн. Доступная дата — %',
        v_preorder_min_days,
        current_date + v_preorder_min_days;
    END IF;


    -- ========================================================
    -- Очищаем временную серверную корзину
    -- ========================================================

    DELETE FROM public.cart_items
    WHERE cart_id = v_cart_id;


    -- ========================================================
    -- Добавляем товары конкретной даты
    -- ========================================================

    FOR v_item IN
      SELECT value
      FROM jsonb_array_elements(
        COALESCE(v_day->'items', '[]'::jsonb)
      )
    LOOP

      v_product_id := (v_item->>'product_id')::uuid;
      v_quantity := (v_item->>'quantity')::integer;

      IF v_product_id IS NULL THEN
        RAISE EXCEPTION 'Не указан product_id';
      END IF;

      IF v_quantity IS NULL OR v_quantity <= 0 THEN
        RAISE EXCEPTION 'Некорректное количество товара';
      END IF;

      INSERT INTO public.cart_items(
        cart_id,
        product_id,
        quantity
      )
      VALUES (
        v_cart_id,
        v_product_id,
        v_quantity
      );

    END LOOP;


    -- ========================================================
    -- Создаём обычный заказ через существующую RPC.
    --
    -- Дата получения передаётся отдельно после создания.
    -- ========================================================

    SELECT *
    INTO v_result
    FROM public.create_order_from_cart(
      p_delivery_method := 'pickup',
      p_payment_method := p_payment_method,
      p_comment := p_comment,
      p_delivery_address := NULL
    );


    -- ========================================================
    -- Обновляем созданный заказ:
    -- дата получения + признак предзаказа.
    -- ========================================================

    UPDATE public.orders
    SET
      pickup_date = v_date,
      is_preorder = true
    WHERE id = v_result.order_id;


    v_day_orders := jsonb_build_object(
      'order_id', v_result.order_id,
      'order_number', v_result.order_number,
      'date', v_date,
      'is_preorder', true
    );

    v_orders := v_orders || jsonb_build_array(v_day_orders);

  END LOOP;


  RETURN v_orders;

END;
$function$;


-- ============================================================
-- Права доступа
-- ============================================================

REVOKE ALL
ON FUNCTION public.create_preorders_from_bake_schedule(
  jsonb,
  text,
  text
)
FROM PUBLIC;

GRANT EXECUTE
ON FUNCTION public.create_preorders_from_bake_schedule(
  jsonb,
  text,
  text
)
TO authenticated;

