-- Global switch for the availability state shown on the Home screen.
-- When disabled, Home keeps all active products visible but treats them as
-- unavailable, so ProductCard offers Preorder instead of Add to cart.

alter table public.order_settings
  add column if not exists home_availability_enabled boolean not null default true;

update public.order_settings
set home_availability_enabled = true
where id = 1
  and home_availability_enabled is null;
