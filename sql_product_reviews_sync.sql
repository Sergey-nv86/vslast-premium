-- ============================================================================
-- ВСЛАСТЬ
-- Автоматическая синхронизация products.rating и products.reviews_count
-- с таблицей product_reviews
-- ============================================================================

CREATE OR REPLACE FUNCTION public.sync_product_review_stats()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    target_product_id uuid;
BEGIN
    -- INSERT / UPDATE
    -- Для DELETE NEW отсутствует, поэтому используется OLD.
    target_product_id := COALESCE(NEW.product_id, OLD.product_id);

    UPDATE public.products
    SET
        reviews_count = (
            SELECT COUNT(*)::integer
            FROM public.product_reviews
            WHERE product_id = target_product_id
        ),
        rating = (
            SELECT ROUND(AVG(rating)::numeric, 2)::double precision
            FROM public.product_reviews
            WHERE product_id = target_product_id
        ),
        updated_at = NOW()
    WHERE id = target_product_id;

    -- Если product_id изменился при UPDATE,
    -- пересчитываем также старый товар.
    IF TG_OP = 'UPDATE'
       AND OLD.product_id IS DISTINCT FROM NEW.product_id THEN

        UPDATE public.products
        SET
            reviews_count = (
                SELECT COUNT(*)::integer
                FROM public.product_reviews
                WHERE product_id = OLD.product_id
            ),
            rating = (
                SELECT ROUND(AVG(rating)::numeric, 2)::double precision
                FROM public.product_reviews
                WHERE product_id = OLD.product_id
            ),
            updated_at = NOW()
        WHERE id = OLD.product_id;

    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$;


DROP TRIGGER IF EXISTS trg_sync_product_review_stats
ON public.product_reviews;


CREATE TRIGGER trg_sync_product_review_stats
AFTER INSERT OR UPDATE OR DELETE
ON public.product_reviews
FOR EACH ROW
EXECUTE FUNCTION public.sync_product_review_stats();


-- ============================================================================
-- Первичный пересчёт уже существующих отзывов
-- ============================================================================

UPDATE public.products p
SET
    reviews_count = stats.review_count,
    rating = stats.avg_rating,
    updated_at = NOW()
FROM (
    SELECT
        product_id,
        COUNT(*)::integer AS review_count,
        ROUND(AVG(rating)::numeric, 2)::double precision AS avg_rating
    FROM public.product_reviews
    GROUP BY product_id
) stats
WHERE p.id = stats.product_id;


-- Для товаров без отзывов оставляем NULL.
UPDATE public.products p
SET
    reviews_count = NULL,
    rating = NULL
WHERE NOT EXISTS (
    SELECT 1
    FROM public.product_reviews r
    WHERE r.product_id = p.id
);
