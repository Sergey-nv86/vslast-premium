-- Fix client identity propagation for orders and loyalty operations.
-- Keeps legacy user_id linkage intact.

update public.orders o
set client_id = ca.client_id
from public.client_accounts ca
where o.client_id is null
  and o.user_id = ca.legacy_user_id;

create or replace function public.sync_order_client_id()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.client_id is null and new.user_id is not null then
    select ca.client_id
      into new.client_id
    from public.client_accounts ca
    where ca.legacy_user_id = new.user_id
      and ca.status = 'active'
    limit 1;
  end if;

  return new;
end;
$$;

drop trigger if exists orders_sync_client_id on public.orders;
create trigger orders_sync_client_id
before insert or update of user_id on public.orders
for each row
execute function public.sync_order_client_id();

create or replace function public.notification_content_for_push(p_event_type text, p_payload jsonb)
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
begin
  case p_event_type
    when 'order_created' then
      title := case when v_preorder then 'Предзаказ оформлен' else 'Заказ оформлен' end;
      body := case when v_preorder then case when v_number='' then 'Ваш предзаказ принят' else 'Предзаказ '||v_number||' принят' end else case when v_number='' then 'Ваш заказ принят' else 'Заказ '||v_number||' принят' end end;
    when 'new_order_admin' then title := 'Новый заказ'; body := case when v_number='' then 'Поступил новый заказ' else 'Поступил новый заказ '||v_number end;
    when 'new_preorder_admin' then title := 'Новый предзаказ'; body := case when v_number='' then 'Поступил новый предзаказ' else 'Поступил новый предзаказ '||v_number end;
    when 'order_status_changed' then
      if v_status='confirmed' and v_old_status='pending_confirmation' then title := 'Заказ подтверждён';
      elsif v_status='completed' and v_old_status='confirmed' then title := 'Заказ выполнен';
      elsif v_status='cancelled' or v_status='canceled' then title := 'Заказ отменён';
      else title := 'Статус заказа изменён'; end if;
      body := case when v_number='' then title else title || ' — ' || v_number end;
    when 'order_ready' then title := 'Заказ готов'; body := case when v_number='' then 'Ваш заказ готов к получению' else 'Заказ '||v_number||' готов к получению' end;
    when 'preorder_confirmed' then title := 'Предзаказ подтверждён'; body := case when v_number='' then 'Ваш предзаказ подтверждён' else 'Предзаказ '||v_number||' подтверждён' end;
    when 'order_cancelled' then title := 'Заказ отменён'; body := case when v_number='' then 'Ваш заказ отменён' else 'Ваш заказ '||v_number||' отменён' end;
    when 'favorite_product_back_in_stock' then title := 'Товар снова в наличии'; body := coalesce(p_payload->>'product_name','Любимый товар снова доступен');
    when 'cart_abandoned' then title := 'Корзина ждёт вас'; body := 'Вы оставили товары в корзине — возможно, пора вернуться.';
    when 'crm_inactive' then title := 'Мы скучаем'; body := 'Давно не виделись в «Всласть». Загляните посмотреть свежую выпечку.';
    when 'crm_bonus_granted' then title := 'Вам начислены бонусы'; body := v_bonus_amount || ' бонусов уже на вашем счёте.';
    when 'crm_bonus_redeemed' then title := 'Бонусы списаны'; body := v_bonus_amount || ' бонусов списано с вашего счёта.';
    when 'crm_bonus_expiring' then title := 'Бонусы скоро сгорят'; body := v_bonus_amount || ' бонусов скоро сгорит.';
    else title := 'Всласть'; body := 'Новое уведомление';
  end case;
  return next;
end;
$$;

create or replace function public.admin_loyalty_accrue(
  p_card_number text,
  p_purchase_amount integer,
  p_description text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_admin_role text;
  v_account public.loyalty_accounts%rowtype;
  v_settings public.order_settings%rowtype;
  v_old_balance integer;
  v_new_balance integer;
  v_old_cumulative integer;
  v_new_cumulative integer;
  v_old_level text;
  v_new_level text;
  v_bonus_percent numeric;
  v_bonus_amount integer;
begin
  if auth.uid() is null then raise exception 'Пользователь не авторизован'; end if;
  select role into v_admin_role from public.profiles where id=auth.uid();
  if v_admin_role is null or v_admin_role not in ('owner','admin','manager','seller') then raise exception 'Недостаточно прав для операции с бонусами'; end if;
  if p_purchase_amount is null or p_purchase_amount <= 0 then raise exception 'Сумма покупки должна быть больше 0'; end if;
  if p_card_number is null or trim(p_card_number)='' then raise exception 'Не указан номер карты'; end if;

  select * into v_settings from public.order_settings where id=1;
  select * into v_account from public.loyalty_accounts where card_number=trim(p_card_number) for update;
  if not found then raise exception 'Карта лояльности не найдена: %',p_card_number; end if;

  v_old_balance:=coalesce(v_account.bonus_balance,0);
  v_old_cumulative:=coalesce(v_account.cumulative_purchases,0);
  v_old_level:=lower(trim(coalesce(v_account.level,'silver')));
  v_bonus_percent:=case v_old_level
    when 'premium' then v_settings.loyalty_premium_bonus_percent
    when 'gold' then v_settings.loyalty_gold_bonus_percent
    else v_settings.loyalty_silver_bonus_percent
  end;
  if v_bonus_percent<0 or v_bonus_percent>100 then raise exception 'Некорректный процент бонусов: %',v_bonus_percent; end if;

  v_bonus_amount:=floor(p_purchase_amount::numeric*v_bonus_percent/100)::integer;
  v_new_balance:=v_old_balance+v_bonus_amount;
  v_new_cumulative:=v_old_cumulative+p_purchase_amount;
  if v_new_cumulative>=v_settings.loyalty_premium_threshold then v_new_level:='premium';
  elsif v_new_cumulative>=v_settings.loyalty_gold_threshold then v_new_level:='gold';
  else v_new_level:='silver'; end if;

  update public.loyalty_accounts
  set bonus_balance=v_new_balance,cumulative_purchases=v_new_cumulative,level=v_new_level,updated_at=now()
  where id=v_account.id;

  insert into public.loyalty_transactions(user_id,client_id,type,amount,description,order_id)
  values(v_account.user_id,v_account.client_id,'accrual',v_bonus_amount,coalesce(nullif(trim(p_description),''),'Начисление бонусов за покупку на '||p_purchase_amount::text||' ₽'),null);

  insert into public.push_events(event_type,recipient_user_id,recipient_client_id,payload,status,attempts)
  values('crm_bonus_granted',v_account.user_id,v_account.client_id,jsonb_build_object('bonus_amount',v_bonus_amount,'card_number',v_account.card_number,'new_balance',v_new_balance),'pending',0);

  return jsonb_build_object('success',true,'operation','accrual','card_number',v_account.card_number,'user_id',v_account.user_id,'client_id',v_account.client_id,'purchase_amount',p_purchase_amount,'bonus_percent',v_bonus_percent,'bonus_amount',v_bonus_amount,'old_balance',v_old_balance,'new_balance',v_new_balance,'old_cumulative_purchases',v_old_cumulative,'new_cumulative_purchases',v_new_cumulative,'old_level',v_old_level,'new_level',v_new_level);
end;
$$;

create or replace function public.admin_loyalty_redeem(
  p_card_number text,
  p_bonus_amount integer,
  p_description text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_admin_role text;
  v_account public.loyalty_accounts%rowtype;
  v_old_balance integer;
  v_new_balance integer;
begin
  if auth.uid() is null then raise exception 'Пользователь не авторизован'; end if;
  select role into v_admin_role from public.profiles where id=auth.uid();
  if v_admin_role is null or v_admin_role not in ('owner','admin','manager','seller') then raise exception 'Недостаточно прав для операции с бонусами'; end if;
  if p_bonus_amount is null or p_bonus_amount <= 0 then raise exception 'Количество списываемых бонусов должно быть больше 0'; end if;
  if p_card_number is null or trim(p_card_number)='' then raise exception 'Не указан номер карты'; end if;

  select * into v_account from public.loyalty_accounts where card_number=trim(p_card_number) for update;
  if not found then raise exception 'Карта лояльности не найдена: %',p_card_number; end if;

  v_old_balance:=coalesce(v_account.bonus_balance,0);
  if p_bonus_amount>v_old_balance then raise exception 'Недостаточно бонусов. Доступно: %, запрошено: %',v_old_balance,p_bonus_amount; end if;
  v_new_balance:=v_old_balance-p_bonus_amount;

  update public.loyalty_accounts
  set bonus_balance=v_new_balance,updated_at=now()
  where id=v_account.id;

  insert into public.loyalty_transactions(user_id,client_id,type,amount,description,order_id)
  values(v_account.user_id,v_account.client_id,'redemption',-p_bonus_amount,coalesce(nullif(trim(p_description),''),'Списание бонусов'),null);

  insert into public.push_events(event_type,recipient_user_id,recipient_client_id,payload,status,attempts)
  values('crm_bonus_redeemed',v_account.user_id,v_account.client_id,jsonb_build_object('bonus_amount',p_bonus_amount,'card_number',v_account.card_number,'new_balance',v_new_balance),'pending',0);

  return jsonb_build_object('success',true,'operation','redeem','card_number',v_account.card_number,'user_id',v_account.user_id,'client_id',v_account.client_id,'bonus_amount',p_bonus_amount,'old_balance',v_old_balance,'new_balance',v_new_balance,'cumulative_purchases',v_account.cumulative_purchases,'level',v_account.level);
end;
$$;
