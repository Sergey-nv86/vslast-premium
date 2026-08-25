-- ============================================================
-- ВСЛАСТЬ — PROMOTIONS
-- Таблицы акций и товаров акций
-- ============================================================

create table if not exists public.promotions (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null default '',
  banner_asset text,
  type text not null default 'collection'
    check (type in ('collection', 'discount', 'specialPrice', 'bundle')),
  discount_percent integer,
  offer_price integer,
  is_available boolean not null default false,
  start_date timestamptz,
  end_date timestamptz,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.promotion_products (
  id uuid primary key default gen_random_uuid(),
  promotion_id uuid not null references public.promotions(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  quantity integer not null default 1,
  special_price integer,
  created_at timestamptz not null default now(),
  unique (promotion_id, product_id)
);

create index if not exists idx_promotions_available
  on public.promotions(is_available);

create index if not exists idx_promotions_sort_order
  on public.promotions(sort_order);

create index if not exists idx_promotion_products_promotion
  on public.promotion_products(promotion_id);

create index if not exists idx_promotion_products_product
  on public.promotion_products(product_id);

alter table public.promotions enable row level security;
alter table public.promotion_products enable row level security;

drop policy if exists "Public can view available promotions"
on public.promotions;

create policy "Public can view available promotions"
on public.promotions
for select
to anon, authenticated
using (
  is_available = true
  and (start_date is null or now() >= start_date)
  and (end_date is null or now() <= end_date)
);

drop policy if exists "Authenticated can manage promotions"
on public.promotions;

create policy "Authenticated can manage promotions"
on public.promotions
for all
to authenticated
using (true)
with check (true);

drop policy if exists "Public can view promotion products"
on public.promotion_products;

create policy "Public can view promotion products"
on public.promotion_products
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.promotions p
    where p.id = promotion_id
      and p.is_available = true
      and (p.start_date is null or now() >= p.start_date)
      and (p.end_date is null or now() <= p.end_date)
  )
);

drop policy if exists "Authenticated can manage promotion products"
on public.promotion_products;

create policy "Authenticated can manage promotion products"
on public.promotion_products
for all
to authenticated
using (true)
with check (true);

grant select on public.promotions to anon, authenticated;
grant select on public.promotion_products to anon, authenticated;
grant all on public.promotions to authenticated;
grant all on public.promotion_products to authenticated;

create or replace function public.set_promotions_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_promotions_updated_at
on public.promotions;

create trigger trg_promotions_updated_at
before update on public.promotions
for each row
execute function public.set_promotions_updated_at();

