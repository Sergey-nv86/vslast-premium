import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/product.dart';
import '../../../screens/product_detail_screen.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/product_image.dart';

/// Premium-блок «Популярное».
/// Данные и навигация остаются прежними: Supabase → HomeScreen → сюда.
class PopularSection extends StatelessWidget {
  final List<Product> products;

  const PopularSection({super.key, required this.products});

  void _openProductDetails(BuildContext context, Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Популярное', style: AppTextStyles.screenTitleSmall),
            const Spacer(),
            Text('Смотреть всё', style: AppTextStyles.linkText),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward, size: 16, color: AppColors.caramel),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 4),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final product = products[index];
              return _PopularItem(
                product: product,
                onTap: () => _openProductDetails(context, product),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PopularItem extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _PopularItem({required this.product, required this.onTap});

  String _weight(Product product) {
    final value = product.weightLabel?.trim();
    if (value != null && value.isNotEmpty) return value;
    return product.isWeighed ? 'Весовой товар' : 'Порция';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Material(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadii.card),
        elevation: 0,
        shadowColor: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ProductImage(imageUrl: product.imageUrl, fit: BoxFit.cover, iconSize: 28),
                        if (product.badge != null)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.cream,
                                borderRadius: BorderRadius.circular(AppRadii.pill),
                              ),
                              child: Text(
                                product.badge == ProductBadge.hit
                                    ? 'Хит'
                                    : product.badge == ProductBadge.newItem
                                        ? 'Новинка'
                                        : 'Акция',
                                style: AppTextStyles.badgeLabel,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.productName,
                ),
                const SizedBox(height: 3),
                Text(
                  '${_weight(product)} · ${formatPrice(product.price)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.rowLabelMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
