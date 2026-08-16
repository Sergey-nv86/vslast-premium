import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../theme/app_theme.dart';
import '../utils/toast.dart';
import '../screens/preorder_screen.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  /// Открытие карточки товара (экран «Карточка товара»).
  final ValueChanged<Product> onOpenDetails;

  /// Масштаб степпера количества (кнопка "+" / "−N+"). По умолчанию 1.0 —
  /// используется одинаково на Главной, в «Каталоге» и в «Избранном».
  final double controlScale;

  const ProductCard({
    super.key,
    required this.product,
    required this.onOpenDetails,
    this.controlScale = 1.0,
  });

  Color _badgeColor(ProductBadge badge) {
    switch (badge) {
      case ProductBadge.hit:
        return AppColors.badgeHit;
      case ProductBadge.newItem:
        return AppColors.badgeNew;
      case ProductBadge.promo:
        return AppColors.badgePromo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final favorites = context.watch<FavoritesProvider>();
    final quantity = cart.quantityOf(product);
    final isFavorite = favorites.isFavorite(product);
    // Высота строки "цена + кнопка" растёт вместе с controlScale, чтобы
    // увеличенный степпер не обрезался фиксированной высотой строки.
    final priceRowHeight = controlScale <= 1.0 ? 26.0 : 26.0 * controlScale + 6.0;

    // Карточка больше не в белой "плашке" с тенью — фото (со скруглёнными
    // углами) и текст лежат прямо на фоне экрана, как в референсе.
    // Высота текстового блока ниже подобрана под увеличенный шрифт
    // (см. AppTextStyles.productName/productPrice) — при дальнейшем
    // изменении шрифтов не забудьте обновить _cardTextBlockHeight в
    // showcase_section.dart и catalog_screen.dart (см. комментарий там же).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Изображение + бейдж + избранное. Только эта область открывает
        // карточку товара, чтобы не конфликтовать с нажатием на сердечко.
        GestureDetector(
          onTap: () => onOpenDetails(product),
          behavior: HitTestBehavior.opaque,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.surfaceMuted,
                      child: const Icon(Icons.bakery_dining_outlined,
                          size: 36, color: AppColors.textSecondary),
                    ),
                  ),
                  if (product.badge != null)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: _badgeColor(product.badge!),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.badge!.label,
                          style: AppTextStyles.badgeLabel,
                        ),
                      ),
                    ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _FavoriteButton(
                      isFavorite: isFavorite,
                      onTap: () {
                        final wasFavorite = isFavorite;
                        favorites.toggle(product);
                        FadeToast.show(
                          context,
                          wasFavorite ? 'Удалено из избранного' : 'Добавлено в избранное',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          // Внимание: сумма высот этого блока (паддинги + название + цена)
          // рассчитана под _cardTextBlockHeight в showcase_section.dart,
          // catalog_screen.dart и favorite_screen.dart. При изменении
          // паддингов/шрифтов здесь — обновите константу везде.
          padding: const EdgeInsets.fromLTRB(2, 8, 2, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => onOpenDetails(product),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  height: 36,
                  child: Text(
                    product.name,
                    style: AppTextStyles.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              SizedBox(
                height: priceRowHeight,
                child: !product.inStock
                    ? SizedBox(
                        width: double.infinity,
                        child: _PreorderButton(
                          controlScale: controlScale,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PreorderScreen(product: product),
                              ),
                            );
                          },
                        ),
                      )
                    : quantity == 0
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  formatPrice(product.price),
                                  style: AppTextStyles.productPrice,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _RoundIconButton(
                                icon: Icons.add,
                                controlScale: controlScale,
                                onTap: () => cart.add(product),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  formatPrice(product.price),
                                  style: AppTextStyles.productPrice,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _QuantityStepper(
                                quantity: quantity,
                                controlScale: controlScale,
                                onDecrement: () => cart.decrement(product),
                                onIncrement: () => cart.increment(product),
                              ),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onTap;

  const _FavoriteButton({required this.isFavorite, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Раньше сердечко сидело в белом круглом "пятне" и слишком перетягивало
    // внимание на фото товара. Теперь — просто иконка (чуть крупнее и с
    // мягкой тенью вместо подложки), она остаётся читаемой на любом фоне,
    // но не выглядит отдельным элементом интерфейса.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 24,
        height: 24,
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          size: 18,
          color: isFavorite ? AppColors.badgePromo : Colors.white,
          shadows: const [
            Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double controlScale;

  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.controlScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final size = 26.0 * controlScale;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.primaryBrown,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 14.0 * controlScale, color: AppColors.textOnPrimary),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final double controlScale;

  const _QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    this.controlScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.symmetric(horizontal: 1 * controlScale, vertical: 1 * controlScale),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
              icon: Icons.remove, onTap: onDecrement, filled: false, controlScale: controlScale),
          SizedBox(
            width: 14.0 * controlScale,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppTextStyles.productName.copyWith(fontSize: 11.0 * controlScale),
            ),
          ),
          _StepperButton(
              icon: Icons.add, onTap: onIncrement, filled: true, controlScale: controlScale),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final double controlScale;

  const _StepperButton({
    required this.icon,
    required this.onTap,
    required this.filled,
    this.controlScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final size = 18.0 * controlScale;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: filled ? AppColors.primaryBrown : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 10.0 * controlScale,
          color: filled ? AppColors.textOnPrimary : AppColors.primaryBrown,
        ),
      ),
    );
  }
}

class _PreorderButton extends StatelessWidget {
  final VoidCallback onTap;
  final double controlScale;

  const _PreorderButton({required this.onTap, this.controlScale = 1.0});

  @override
  Widget build(BuildContext context) {
    final height = controlScale <= 1.0 ? 26.0 : 26.0 * controlScale + 6.0;
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryBrown,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Text('Предзаказ',
              style: AppTextStyles.preorderButton.copyWith(fontSize: 11.0 * controlScale.clamp(1.0, 1.3))),
        ),
      ),
    );
  }
}
