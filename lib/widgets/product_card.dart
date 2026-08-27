import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../screens/preorder_screen.dart';
import '../theme/app_theme.dart';
import '../utils/toast.dart';
import 'product_image.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final ValueChanged<Product> onOpenDetails;
  final double controlScale;

  const ProductCard({
    super.key,
    required this.product,
    required this.onOpenDetails,
    this.controlScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final favorites = context.watch<FavoritesProvider>();
    final quantity = cart.quantityOf(product);
    final isFavorite = favorites.isFavorite(product);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => onOpenDetails(product),
          behavior: HitTestBehavior.opaque,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.cover,
                    iconSize: 36,
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _Badge(product: product),
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
                          wasFavorite
                              ? 'Удалено из избранного'
                              : 'Добавлено в избранное',
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
          padding: const EdgeInsets.fromLTRB(2, 10, 2, 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => onOpenDetails(product),
                child: Text(
                  product.name,
                  style: AppTextStyles.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      _weightLabel(product),
                      style: AppTextStyles.rowLabelMuted.copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('·', style: AppTextStyles.rowLabelMuted),
                  const SizedBox(width: 6),
                  Text(
                    formatPrice(product.price),
                    style: AppTextStyles.productPrice.copyWith(fontSize: 16),
                    maxLines: 1,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (!product.inStock)
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PreorderScreen(product: product),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: const Text('На завтра'),
                  ),
                )
              else if (quantity == 0)
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton.icon(
                    onPressed: () => cart.add(product),
                    icon: const Icon(Icons.add_shopping_cart_outlined, size: 17),
                    label: const Text('В корзину'),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: _QuantityStepper(
                    quantity: quantity,
                    onDecrement: () => cart.decrement(product),
                    onIncrement: () => cart.increment(product),
                    scale: controlScale,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _weightLabel(Product product) {
    final label = product.weightLabel?.trim();
    if (label != null && label.isNotEmpty) return label;
    return product.isWeighed ? 'Весовой товар' : 'Порция';
  }
}

class _Badge extends StatelessWidget {
  final Product product;
  const _Badge({required this.product});

  @override
  Widget build(BuildContext context) {
    final badge = product.badge;
    if (badge == null) return const SizedBox.shrink();
    final label = switch (badge) {
      ProductBadge.hit => 'Хит недели',
      ProductBadge.newItem => 'Новинка',
      ProductBadge.promo => 'Акция',
    };
    final icon = switch (badge) {
      ProductBadge.hit => Icons.local_fire_department_outlined,
      ProductBadge.newItem => Icons.auto_awesome_outlined,
      ProductBadge.promo => Icons.local_offer_outlined,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accentLight.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textPrimary),
          const SizedBox(width: 5),
          Text(label, style: AppTextStyles.badgeLabel),
        ],
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onTap;
  const _FavoriteButton({required this.isFavorite, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .92),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            size: 19,
            color: isFavorite ? AppColors.danger : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final double scale;

  const _QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final height = 44.0 * scale.clamp(.9, 1.15);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StepButton(icon: Icons.remove, onTap: onDecrement),
          Text('$quantity', style: AppTextStyles.rowValue),
          _StepButton(icon: Icons.add, onTap: onIncrement, filled: true),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  const _StepButton({required this.icon, required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.textPrimary : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 17,
            color: filled ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
