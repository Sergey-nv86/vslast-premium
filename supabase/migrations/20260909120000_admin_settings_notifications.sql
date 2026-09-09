alter table public.order_settings
  add column if not exists delivery_enabled boolean not null default true,
  add column if not exists loyalty_gold_threshold integer not null default 50000,
  add column if not exists loyalty_premium_threshold integer not null default 150000,
  add column if not exists loyalty_silver_bonus_percent numeric(5,2) not null default 1,
  add column if not exists loyalty_gold_bonus_percent numeric(5,2) not null default 3,
  add column if not exists loyalty_premium_bonus_percent numeric(5,2) not null default 5;

update public.order_settings
set delivery_enabled = coalesce(delivery_enabled, true),
    loyalty_gold_threshold = coalesce(loyalty_gold_threshold, 50000),
    loyalty_premium_threshold = coalesce(loyalty_premium_threshold, 150000),
    loyalty_silver_bonus_percent = coalesce(loyalty_silver_bonus_percent, 1),
    loyalty_gold_bonus_percent = coalesce(loyalty_gold_bonus_percent, 3),
    loyalty_premium_bonus_percent = coalesce(loyalty_premium_bonus_percent, 5)
where id = 1;

create index if not exists notification_queue_user_created_idx
  on public.notification_queue(user_id, created_at desc);

alter table public.notification_queue
  add column if not exists read_at timestamptz;

alter table public.notification_queue enable row level security;

drop policy if exists "Users can read own notifications" on public.notification_queue;
create policy "Users can read own notifications"
on public.notification_queue
for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "Users can mark own notifications read" on public.notification_queue;
create policy "Users can mark own notifications read"
on public.notification_queue
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

grant select, update on public.notification_queue to authenticated;

drop policy if exists "Admins can update order settings" on public.order_settings;
create policy "Admins can update order settings"
on public.order_settings
for update
to authenticated
using (is_admin_user())
with check (is_admin_user());

grant update on public.order_settings to authenticated;

create or replace function public.enforce_delivery_enabled()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_enabled boolean;
begin
  if new.delivery_method <> 'delivery' then return new; end if;
  select coalesce(delivery_enabled, true) into v_enabled from public.order_settings where id = 1;
  if coalesce(v_enabled, true) = false then
    raise exception 'Доставка временно недоступна. Пожалуйста, выберите самовывоз.';
  end if;
  return new;
end;
$$;

drop trigger if exists orders_delivery_enabled_guard on public.orders;
create trigger orders_delivery_enabled_guard
before insert or update of delivery_method on public.orders
for each row execute function public.enforce_delivery_enabled();

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
    when 'order_cancelled' then title := 'Заказ отменён'; body := case when v_number='' then 'Ваш заказ отменён' else 'Заказ '||v_number||' отменён' end;
    when 'favorite_product_back_in_stock' then title := 'Товар снова в наличии'; body := coalesce(p_payload->>'product_name','Любимый товар снова доступен');
    when 'cart_abandoned' then title := 'Корзина ждёт вас'; body := 'Вы оставили товары в корзине — возможно, пора вернуться.';
    when 'crm_inactive' then title := 'Мы скучаем'; body := 'Давно не виделись в «Всласть». Загляните посмотреть свежую выпечку.';
    when 'crm_bonus_granted' then title := 'Вам начислены бонусы'; body := coalesce(p_payload->>'bonus_amount','0') || ' бонусов уже на вашем счёте.';
    when 'crm_bonus_expiring' then title := 'Бонусы скоро сгорят'; body := coalesce(p_payload->>'bonus_amount','0') || ' бонусов скоро сгорит.';
    else title := 'Всласть'; body := 'Новое уведомление';
  end case;
  return next;
end;
$$;

create or replace function public.capture_sent_push_as_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare v_content record;
begin
  if new.status = 'sent' and old.status is distinct from 'sent' and new.recipient_user_id is not null then
    select * into v_content from public.notification_content_for_push(new.event_type, coalesce(new.payload,'{}'::jsonb));
    insert into public.notification_queue(user_id,type,title,body,data,scheduled_at,sent_at,attempts)
    values(new.recipient_user_id,new.event_type,v_content.title,v_content.body,
      coalesce(new.payload,'{}'::jsonb) || jsonb_build_object('push_event_id',new.id,'order_id',new.order_id),now(),now(),1);
  end if;
  return new;
end;
$$;

drop trigger if exists push_events_sent_notification on public.push_events;
create trigger push_events_sent_notification
after update of status on public.push_events
for each row execute function public.capture_sent_push_as_notification();

create or replace function public.admin_loyalty_accrue(p_card_number text,p_purchase_amount integer,p_description text default null)
returns jsonb language plpgsql security definer set search_path = public
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
  v_bonus_percent:=case v_old_level when 'premium' then v_settings.loyalty_premium_bonus_percent when 'gold' then v_settings.loyalty_gold_bonus_percent else v_settings.loyalty_silver_bonus_percent end;
  if v_bonus_percent<0 or v_bonus_percent>100 then raise exception 'Некорректный процент бонусов: %',v_bonus_percent; end if;
  v_bonus_amount:=floor(p_purchase_amount::numeric*v_bonus_percent/100)::integer;
  v_new_balance:=v_old_balance+v_bonus_amount;
  v_new_cumulative:=v_old_cumulative+p_purchase_amount;
  if v_new_cumulative>=v_settings.loyalty_premium_threshold then v_new_level:='premium'; elsif v_new_cumulative>=v_settings.loyalty_gold_threshold then v_new_level:='gold'; else v_new_level:='silver'; end if;
  update public.loyalty_accounts set bonus_balance=v_new_balance,cumulative_purchases=v_new_cumulative,level=v_new_level,updated_at=now() where id=v_account.id;
  insert into public.loyalty_transactions(user_id,type,amount,description,order_id) values(v_account.user_id,'accrual',v_bonus_amount,coalesce(nullif(trim(p_description),''),'Начисление бонусов за покупку на '||p_purchase_amount::text||' ₽'),null);
  return jsonb_build_object('success',true,'operation','accrual','card_number',v_account.card_number,'user_id',v_account.user_id,'purchase_amount',p_purchase_amount,'bonus_percent',v_bonus_percent,'bonus_amount',v_bonus_amount,'old_balance',v_old_balance,'new_balance',v_new_balance,'old_cumulative_purchases',v_old_cumulative,'new_cumulative_purchases',v_new_cumulative,'old_level',v_old_level,'new_level',v_new_level);
end;
$$;
