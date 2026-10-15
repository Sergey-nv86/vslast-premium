-- Performance indexes for the hot catalog query.
-- Home/Catalog filter active products and order them by creation date.
create index if not exists products_is_active_created_at_idx
  on public.products (is_active, created_at);

-- Helps category-filtered catalog/admin reads while retaining created_at ordering.
create index if not exists products_is_active_category_created_at_idx
  on public.products (is_active, category_id, created_at);
