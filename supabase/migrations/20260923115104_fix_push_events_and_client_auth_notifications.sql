-- Vslast Premium: complete push event coverage and exact navigation metadata.

create or replace function public.notification_content_for_push(
  p_event_type text,
  p_payload jsonb
)
returns table(title text, body text)
language plpgsql
immutable
as $$
declare
  v_order_number text := nullif(p_payload->>'order_number','');
  v_status text := coalesce(p_payload->>'status','');
  v_old_status text := coalesce(p_payload->>'old_status','');
  v_preorder boolean := coalesce((p_payload->>'is_preorder')::boolean, false);
  v_number text := case when v_order_number is null then '' else '№' || v_order_number end;
  v_bonus_amount text := coalesce(p_payload->>'bonus_amount','0');
  v_client_id text := coalesce(nullif(p_payload->>'client_id',''),'');
  v_product_name text := coalesce(p_payload->>'product_name','Товар');
  v_assortment_date text := coalesce(p_payload->>'assortment_date','');
begin
  case p_event_type
    when 'client_registered_admin' then
      title := 'Новый клиент';
      body := 'Клиент ' || v_client_id || ' зарегистрировался и вошёл в приложение';
    when 'client_login_admin' then
      title := 'Вход клиента';
      body := 'Клиент ' || v_client_id || ' вошёл в приложение';

    when 'order_created' then
      title := case when v_preorder then 'Предзаказ оформлен' else 'Заказ оформлен' end;
      body := case
        when v_preorder then case when v_number='' then 'Ваш предзаказ принят' else 'Предзаказ '||v_number||' принят' end
        else case when v_number='' then 'Ваш заказ принят' else 'Заказ '||v_number||' принят' end
      end;
    when 'new_order_admin' then
      title := 'Новый заказ';
      body := case when v_number='' then 'Поступил новый заказ' else 'Поступил новый заказ '||v_number end;
    when 'new_preorder_admin' then
      title := 'Новый предзаказ';
      body := case when v_number='' then 'Поступил новый предзаказ' else 'Поступил новый предзаказ '||v_number end;
    when 'order_confirmed' then
      title := 'Заказ подтверждён';
      body := case when v_number='' then 'Ваш заказ подтверждён' else 'Заказ '||v_number||' подтверждён' end;
    when 'order_completed' then
      title := 'Заказ выполнен';
      body := case when v_number='' then 'Ваш заказ выполнен' else 'Заказ '||v_number||' выполнен' end;
    when 'order_status_changed' then
      if v_status='confirmed' and v_old_status='pending_confirmation' then
        title := 'Заказ подтверждён';
      elsif v_status='completed' then
        title := 'Заказ выполнен';
      elsif v_status in ('cancelled','canceled') then
        title := 'Заказ отменён';
      else
        title := 'Статус заказа изменён';
      end if;
      body := case when v_number='' then title else title || ' — ' || v_number end;
    when 'order_changed' then
      title := 'Заказ изменён';
      body := case when v_number='' then 'Данные заказа изменены' else 'Изменён заказ '||v_number end;
    when 'order_ready' then
      title := 'Заказ готов';
      body := case when v_number='' then 'Ваш заказ готов к получению' else 'Заказ '||v_number||' готов к получению' end;
    when 'preorder_confirmed' then
      title := 'Предзаказ подтверждён';
      body := case when v_number='' then 'Ваш предзаказ подтверждён' else 'Предзаказ '||v_number||' подтверждён' end;
    when 'order_cancelled' then
      title := 'Заказ отменён';
      body := case when v_number='' then 'Ваш заказ отменён' else 'Ваш заказ '||v_number||' отменён' end;
    when 'pickup_reminder' then
      title := 'Напоминание о получении';
      body := case when v_number='' then 'До получения заказа около часа' else 'Заказ '||v_number||' можно будет забрать примерно через час' end;

    when 'chat_message' then
      title := 'Новое сообщение в чате «Всласть»';
      body := coalesce(p_payload->>'message_preview','У вас новое сообщение в чате.');
    when 'chat_message_admin' then
      title := 'Новое сообщение в чате «Всласть»';
      body := coalesce(p_payload->>'message_preview','Клиент отправил новое сообщение.');

    when 'favorite_product_back_in_stock' then
      title := 'Товар снова в наличии';
      body := v_product_name;
    when 'new_product_published' then
      title := 'Новый товар';
      body := v_product_name || ' появился в каталоге';
    when 'fresh_bakery_published' then
      title := 'Свежая выпечка';
      body := coalesce(p_payload->>'message','В каталоге появилась свежая выпечка');
    when 'promotion_published' then
      title := 'Новая акция';
      body := coalesce(p_payload->>'promotion_title','Появилась новая акция');
    when 'daily_assortment_published' then
      title := 'Витрина обновлена';
      body := case when v_assortment_date='' then 'Сегодняшняя витрина опубликована' else 'Витрина на '||v_assortment_date||' опубликована' end;
    when 'admin_assortment_reminder' then
      title := 'Не опубликована витрина';
      body := case when v_assortment_date='' then 'Опубликуйте сегодняшнюю витрину' else 'Опубликуйте витрину на '||v_assortment_date end;
    when 'admin_assortment_overdue' then
      title := 'Витрина просрочена';
      body := case when v_assortment_date='' then 'Сегодняшняя витрина ещё не опубликована' else 'Витрина на '||v_assortment_date||' ещё не опубликована' end;

    when 'cart_abandoned' then
      title := 'Корзина ждёт вас';
      body := 'Вы оставили товары в корзине — возможно, пора вернуться.';
    when 'crm_inactive' then
      title := 'Мы скучаем';
      body := 'Давно не виделись в «Всласть». Загляните посмотреть свежую выпечку.';
    when 'crm_bonus_granted' then
      title := 'Вам начислены бонусы';
      body := v_bonus_amount || ' бонусов уже на вашем счёте.';
    when 'crm_bonus_redeemed' then
      title := 'Бонусы списаны';
      body := v_bonus_amount || ' бонусов списано с вашего счёта.';
    when 'crm_bonus_expiring' then
      title := 'Бонусы скоро сгорят';
      body := v_bonus_amount || ' бонусов скоро сгорит.';

    else
      title := 'Всласть';
      body := 'Новое уведомление';
  end case;

  return next;
end;
$$;

create or replace function public.enqueue_push_event(
  p_event_type text,
  p_recipient_user_id uuid,
  p_recipient_client_id text,
  p_order_id uuid default null,
  p_payload jsonb default '{}'::jsonb,
  p_dedup_key text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_event_id uuid;
  v_client_id text;
  v_user_id uuid;
begin
  if p_event_type not in (
    'client_registered_admin',
    'client_login_admin',
    'order_created',
    'order_confirmed',
    'order_changed',
    'order_completed',
    'order_status_changed',
    'order_ready',
    'order_cancelled',
    'preorder_confirmed',
    'new_order_admin',
    'new_preorder_admin',
    'promotion_published',
    'new_product_published',
    'fresh_bakery_published',
    'favorite_product_back_in_stock',
    'cart_abandoned',
    'pickup_reminder',
    'daily_assortment_published',
    'admin_assortment_reminder',
    'admin_assortment_overdue',
    'crm_inactive',
    'crm_bonus_granted',
    'crm_bonus_redeemed',
    'crm_bonus_expiring',
    'chat_message',
    'chat_message_admin'
  ) then
    raise exception 'Unsupported push event type: %', p_event_type;
  end if;

  v_user_id := p_recipient_user_id;
  v_client_id := nullif(trim(p_recipient_client_id), '');

  if v_client_id is null and v_user_id is not null then
    select ca.client_id into v_client_id
    from public.client_accounts ca
    where ca.legacy_user_id = v_user_id
      and ca.status = 'active'
    limit 1;
  end if;

  if v_user_id is null and v_client_id is not null then
    select ca.legacy_user_id into v_user_id
    from public.client_accounts ca
    where ca.client_id = v_client_id
      and ca.status = 'active'
    limit 1;
  end if;

  if v_client_id is null and v_user_id is null then
    raise exception 'Push recipient client_id or user_id is required';
  end if;

  if p_dedup_key is not null then
    select id into v_event_id
    from public.push_events
    where push_dedup_key = p_dedup_key
    limit 1;
    if v_event_id is not null then
      return v_event_id;
    end if;
  end if;

  insert into public.push_events (
    event_type, recipient_user_id, recipient_client_id, order_id,
    payload, status, attempts, push_dedup_key
  )
  values (
    p_event_type, v_user_id, v_client_id, p_order_id,
    coalesce(p_payload, '{}'::jsonb), 'pending', 0, p_dedup_key
  )
  on conflict (push_dedup_key) where push_dedup_key is not null
  do nothing
  returning id into v_event_id;

  if v_event_id is null and p_dedup_key is not null then
    select id into v_event_id
    from public.push_events
    where push_dedup_key = p_dedup_key
    limit 1;
  end if;

  return v_event_id;
end;
$$;
