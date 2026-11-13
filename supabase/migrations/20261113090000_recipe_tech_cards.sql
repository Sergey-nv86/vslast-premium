-- Recipe technology cards, ingredient price directory and AI-assisted calculation.
-- This migration is additive; it does not alter existing product/order tables.

create table if not exists public.ingredients (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  normalized_name text not null unique,
  base_unit text not null default 'g' check (base_unit in ('g', 'ml', 'pcs')),
  calories_per_100 numeric(12,4),
  protein_per_100 numeric(12,4),
  fat_per_100 numeric(12,4),
  carbs_per_100 numeric(12,4),
  nutrition_source text,
  needs_review boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.ingredient_prices (
  ingredient_id uuid primary key references public.ingredients(id) on delete cascade,
  purchase_quantity numeric(14,4) not null check (purchase_quantity > 0),
  purchase_unit text not null check (purchase_unit in ('g', 'kg', 'ml', 'l', 'pcs')),
  purchase_price numeric(14,2) not null check (purchase_price >= 0),
  price_per_base_unit numeric(16,8) generated always as (
    purchase_price / nullif(
      purchase_quantity *
      case purchase_unit when 'kg' then 1000 when 'l' then 1000 else 1 end,
      0
    )
  ) stored,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id)
);

create table if not exists public.recipe_tech_cards (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  technology text not null default '',
  storage_conditions text,
  quality_description text,
  yield_quantity numeric(14,4),
  yield_unit text,
  total_cost numeric(14,2),
  calories_per_100 numeric(12,4),
  protein_per_100 numeric(12,4),
  fat_per_100 numeric(12,4),
  carbs_per_100 numeric(12,4),
  nutrition_status text not null default 'incomplete'
    check (nutrition_status in ('calculated', 'estimated', 'incomplete')),
  source_photo_count integer not null default 0,
  calculation_status text not null default 'draft'
    check (calculation_status in ('draft', 'needs_prices', 'ready')),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.recipe_tech_card_items (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references public.recipe_tech_cards(id) on delete cascade,
  ingredient_id uuid references public.ingredients(id),
  ingredient_name_snapshot text not null,
  quantity numeric(14,4) not null check (quantity >= 0),
  net_quantity numeric(14,4) check (net_quantity is null or net_quantity >= 0),
  loss_percent numeric(8,3) check (loss_percent is null or (loss_percent >= 0 and loss_percent <= 100)),
  unit text not null,
  line_cost numeric(14,2),
  notes text,
  sort_order integer not null default 0
);

create index if not exists recipe_tech_cards_created_by_idx
  on public.recipe_tech_cards(created_by, created_at desc);
create index if not exists recipe_tech_card_items_recipe_idx
  on public.recipe_tech_card_items(recipe_id, sort_order);

alter table public.ingredients enable row level security;
alter table public.ingredient_prices enable row level security;
alter table public.recipe_tech_cards enable row level security;
alter table public.recipe_tech_card_items enable row level security;

drop policy if exists "admin manage ingredients" on public.ingredients;
create policy "admin manage ingredients" on public.ingredients
  for all to authenticated using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('owner','admin','manager','baker','pastry_chef')))
  with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('owner','admin','manager','baker','pastry_chef')));

drop policy if exists "admin manage ingredient prices" on public.ingredient_prices;
create policy "admin manage ingredient prices" on public.ingredient_prices
  for all to authenticated using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('owner','admin','manager','baker','pastry_chef')))
  with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('owner','admin','manager','baker','pastry_chef')));

drop policy if exists "admin manage recipe tech cards" on public.recipe_tech_cards;
create policy "admin manage recipe tech cards" on public.recipe_tech_cards
  for all to authenticated
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('owner','admin','manager','baker','pastry_chef')))
  with check (
    created_by = auth.uid()
    and exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('owner','admin','manager','baker','pastry_chef'))
  );

drop policy if exists "admin manage recipe tech card items" on public.recipe_tech_card_items;
create policy "admin manage recipe tech card items" on public.recipe_tech_card_items
  for all to authenticated using (
    exists (
      select 1 from public.recipe_tech_cards r
      where r.id = recipe_id and exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('owner','admin','manager','baker','pastry_chef'))
    )
  )
  with check (
    exists (
      select 1 from public.recipe_tech_cards r
      where r.id = recipe_id and exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('owner','admin','manager','baker','pastry_chef'))
    )
  );


grant select, insert, update, delete on public.ingredients to authenticated;
grant select, insert, update, delete on public.ingredient_prices to authenticated;
grant select, insert, update, delete on public.recipe_tech_cards to authenticated;
grant select, insert, update, delete on public.recipe_tech_card_items to authenticated;

comment on table public.ingredients is 'Ингредиенты технологических карт Всласть';
comment on table public.ingredient_prices is 'Актуальная закупочная цена ингредиента';
comment on table public.recipe_tech_cards is 'Технологические карты, сформированные и подтверждённые пользователем';

-- Starter nutrition catalog. Values are generic reference averages per 100 g;
-- verify against the actual supplier label before treating them as final.
insert into public.ingredients
  (name, normalized_name, base_unit, calories_per_100, protein_per_100, fat_per_100, carbs_per_100, nutrition_source, needs_review)
values
  ('Мука пшеничная', 'мука пшеничная', 'g', 334, 10.3, 1.1, 70.6, 'Справочное среднее значение; проверить упаковку', true),
  ('Мука цельнозерновая', 'мука цельнозерновая', 'g', 340, 13.2, 2.5, 72.0, 'Справочное среднее значение; проверить упаковку', true),
  ('Сахар', 'сахар', 'g', 400, 0, 0, 100, 'Справочное среднее значение', true),
  ('Масло сливочное 82,5%', 'масло сливочное 82 5', 'g', 748, 0.5, 82.5, 0.8, 'Справочное среднее значение; проверить упаковку', true),
  ('Яйцо куриное', 'яйцо куриное', 'g', 157, 12.7, 10.9, 0.7, 'Справочное среднее значение', true),
  ('Молоко 3,2%', 'молоко 3 2', 'g', 60, 3, 3.2, 4.7, 'Справочное среднее значение; проверить упаковку', true),
  ('Сливки 33%', 'сливки 33', 'g', 322, 2.2, 33, 3, 'Справочное среднее значение; проверить упаковку', true),
  ('Соль', 'соль', 'g', 0, 0, 0, 0, 'Пищевая ценность: 0 ккал', true),
  ('Дрожжи сухие', 'дрожжи сухие', 'g', 325, 40, 7, 41, 'Справочное среднее значение; проверить упаковку', true),
  ('Дрожжи прессованные', 'дрожжи прессованные', 'g', 105, 8, 1.9, 18, 'Справочное среднее значение; проверить упаковку', true),
  ('Какао-порошок', 'какао порошок', 'g', 228, 19.6, 13.7, 57.9, 'Справочное среднее значение; проверить упаковку', true),
  ('Мёд', 'мед', 'g', 304, 0.3, 0, 82.4, 'Справочное среднее значение', true),
  ('Шоколад тёмный', 'шоколад темный', 'g', 598, 7.8, 42.6, 45.9, 'Справочное среднее значение; зависит от какао', true),
  ('Миндальная мука', 'миндальная мука', 'g', 571, 21.2, 50, 21.7, 'Справочное среднее значение; проверить упаковку', true),
  ('Сыр сливочный', 'сыр сливочный', 'g', 342, 5.5, 34.4, 4.1, 'Справочное среднее значение; проверить упаковку', true)
on conflict (normalized_name) do nothing;
