import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../theme/app_theme.dart';
import '../utils/toast.dart';
import 'preorder_screen.dart';

/// Экран «Карточка товара». Открывается с любой карточки товара в
/// приложении (Каталог, Избранное, «Сегодня на витрине»...) — передайте
/// сюда сам [Product], больше ничего не нужно, экран сам подписан на
/// CartProvider/FavoritesProvider.
class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final PageController _galleryController = PageController();
  int _galleryIndex = 0;

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final cart = context.watch<CartProvider>();
    final favorites = context.watch<FavoritesProvider>();
    final isFavorite = favorites.isFavorite(product);
    final quantity = cart.quantityOf(product);
    final gallery = product.gallery;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _GalleryHeader(
                  images: gallery,
                  controller: _galleryController,
                  currentIndex: _galleryIndex,
                  onPageChanged: (i) => setState(() => _galleryIndex = i),
                  isFavorite: isFavorite,
                  onBack: () => Navigator.of(context).maybePop(),
                  onToggleFavorite: () {
                    final wasFavorite = isFavorite;
                    favorites.toggle(product);
                    FadeToast.show(
                      context,
                      wasFavorite ? 'Удалено из избранного' : 'Добавлено в избранное',
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  transform: Matrix4.translationValues(0, -24, 0),
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.badge != null) _BadgeRow(badge: product.badge!),
                      if (product.badge != null) const SizedBox(height: 14),

                      Text(product.name, style: AppTextStyles.productDetailTitle),
                      const SizedBox(height: 10),

                      if (product.rating != null) ...[
                        _RatingRow(
                          rating: product.rating!,
                          reviewsCount: product.reviewsCount,
                        ),
                        const SizedBox(height: 16),
                      ],

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(formatPrice(product.price),
                              style: AppTextStyles.productDetailPrice),
                          const SizedBox(width: 8),
                          Text('за ${product.weightLabel}',
                              style: AppTextStyles.rowLabelMuted),
                        ],
                      ),

                      if (product.description != null) ...[
                        const SizedBox(height: 16),
                        Text(product.description!, style: AppTextStyles.descriptionText),
                      ],

                      if (product.hasNutritionInfo) ...[
                        const SizedBox(height: 22),
                        _NutritionCard(product: product),
                      ],

                      const SizedBox(height: 14),
                      _InfoRow(
                        icon: Icons.inventory_2_outlined,
                        label: 'Вес',
                        value: product.weightLabel,
                      ),

                      if (product.composition != null) ...[
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.eco_outlined,
                          label: 'Состав',
                          value: product.composition!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: _BottomActionBar(
                  product: product,
                  quantity: quantity,
                  onAdd: () => cart.add(product),
                  onIncrement: () => cart.increment(product),
                  onDecrement: () => cart.decrement(product),
                  onNotifyMe: () {
                    FadeToast.show(
                      context,
                      'Сообщим, когда товар появится в наличии',
                      icon: Icons.notifications_active,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryHeader extends StatelessWidget {
  final List<String> images;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onToggleFavorite;

  const _GalleryHeader({
    required this.images,
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
    required this.isFavorite,
    required this.onBack,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: top + 380,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: controller,
            onPageChanged: onPageChanged,
            itemCount: images.length,
            itemBuilder: (context, index) => Image.asset(
              images[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.surfaceMuted,
                child: const Icon(Icons.bakery_dining_outlined,
                    size: 48, color: AppColors.textSecondary),
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: top + 12,
            child: _RoundSquareButton(icon: Icons.arrow_back, onTap: onBack),
          ),
          Positioned(
            right: 16,
            top: top + 12,
            child: _RoundSquareButton(
              icon: isFavorite ? Icons.favorite : Icons.favorite_border,
              iconColor: isFavorite ? AppColors.badgePromo : AppColors.primaryBrown,
              onTap: onToggleFavorite,
            ),
          ),
          if (images.length > 1)
            Positioned(
              right: 16,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.image_outlined, size: 15, color: AppColors.primaryBrown),
                    const SizedBox(width: 5),
                    Text('${currentIndex + 1} / ${images.length}',
                        style: AppTextStyles.rowValue),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoundSquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  const _RoundSquareButton({
    required this.icon,
    required this.onTap,
    this.iconColor = AppColors.primaryBrown,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  final ProductBadge badge;

  const _BadgeRow({required this.badge});

  Color _bg(ProductBadge b) {
    switch (b) {
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
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _bg(badge),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badge == ProductBadge.hit) ...[
                const Icon(Icons.local_fire_department, size: 13, color: Colors.white),
                const SizedBox(width: 4),
              ],
              Text(badge.label,
                  style: AppTextStyles.statusPillLabel.copyWith(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RatingRow extends StatelessWidget {
  final double rating;
  final int? reviewsCount;

  const _RatingRow({required this.rating, this.reviewsCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 18, color: AppColors.accentGradientEnd),
        const SizedBox(width: 4),
        Text(rating.toStringAsFixed(1), style: AppTextStyles.ratingValue),
        if (reviewsCount != null) ...[
          const SizedBox(width: 8),
          Text('($reviewsCount)', style: AppTextStyles.rowLabelMuted),
          const SizedBox(width: 8),
          Text('•', style: AppTextStyles.rowLabelMuted),
          const SizedBox(width: 8),
          Text('$reviewsCount отзывов', style: AppTextStyles.rowLabelMuted),
        ],
      ],
    );
  }
}

class _NutritionCard extends StatelessWidget {
  final Product product;

  const _NutritionCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('КБЖУ на 100 г', style: AppTextStyles.sectionLabel.copyWith(fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _NutritionItem(
                  icon: Icons.local_fire_department_outlined,
                  label: 'Ккал',
                  value: product.caloriesPer100g?.toString() ?? '—',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NutritionItem(
                  icon: Icons.water_drop_outlined,
                  label: 'Белки',
                  value: product.proteinPer100g == null
                      ? '—'
                      : '${product.proteinPer100g!.toStringAsFixed(1)} г',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NutritionItem(
                  icon: Icons.eco_outlined,
                  label: 'Жиры',
                  value: product.fatPer100g == null
                      ? '—'
                      : '${product.fatPer100g!.toStringAsFixed(1)} г',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NutritionItem(
                  icon: Icons.grain,
                  label: 'Углеводы',
                  value: product.carbsPer100g == null
                      ? '—'
                      : '${product.carbsPer100g!.toStringAsFixed(1)} г',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NutritionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _NutritionItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: AppColors.primaryBrown),
              const SizedBox(width: 4),
              Flexible(
                child: Text(label,
                    style: AppTextStyles.nutritionLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.nutritionValue),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 19, color: AppColors.primaryBrown),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.sectionLabel.copyWith(fontSize: 14)),
                const SizedBox(height: 3),
                Text(value, style: AppTextStyles.rowLabelMuted.copyWith(height: 1.4)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final Product product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onNotifyMe;

  const _BottomActionBar({
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
    required this.onNotifyMe,
  });

  @override
  Widget build(BuildContext context) {
    if (!product.inStock) {
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PreorderScreen(product: product)),
                );
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accentGradientStart, AppColors.accentGradientEnd],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Предзаказ', style: AppTextStyles.cartBarButton),
                    const SizedBox(height: 2),
                    Text('Товара временно нет в наличии',
                        style: AppTextStyles.rowLabelMuted.copyWith(
                            color: Colors.white.withOpacity(0.9), fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onNotifyMe,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accentGradientEnd, width: 1.2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_none,
                      size: 18, color: AppColors.accentGradientEnd),
                  const SizedBox(height: 2),
                  Text('Уведомить\nо наличии',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.rowValue
                          .copyWith(color: AppColors.accentGradientEnd, fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (quantity == 0) {
      return GestureDetector(
        onTap: onAdd,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 17),
          decoration: BoxDecoration(
            color: AppColors.primaryBrown,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_bag_outlined, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text('Добавить в корзину · ${formatPrice(product.price)}',
                  style: AppTextStyles.cartBarButton),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryBrown,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Text('В корзине', style: AppTextStyles.cartBarButton.copyWith(fontSize: 14)),
          const Spacer(),
          _StepperControl(onDecrement: onDecrement, onIncrement: onIncrement, quantity: quantity),
          const SizedBox(width: 14),
          Text(formatPrice(product.price * quantity), style: AppTextStyles.cartBarButton),
        ],
      ),
    );
  }
}

class _StepperControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _StepperControl({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _button(Icons.remove, onDecrement),
        SizedBox(
          width: 28,
          child: Text('$quantity',
              textAlign: TextAlign.center,
              style: AppTextStyles.cartBarButton.copyWith(fontSize: 15)),
        ),
        _button(Icons.add, onIncrement),
      ],
    );
  }

  Widget _button(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}
