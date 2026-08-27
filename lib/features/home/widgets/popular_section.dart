import 'package:flutter/material.dart';

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
        Text('Популярное', style: AppTextStyles.screenTitleSmall),
        const SizedBox(height: 10),
        SizedBox(
          height: 196,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 4),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
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
      width: 136,
      child: Material(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadii.card),
        elevation: 0,
        shadowColor: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 112,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ProductImage(
                          imageUrl: product.imageUrl,
                          fit: BoxFit.cover,
                          iconSize: 24,
                        ),
                        if (product.badge != null)
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cream,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.pill,
                                ),
                              ),
                              child: Text(
                                product.badge == ProductBadge.hit
                                    ? 'Хит'
                                    : product.badge == ProductBadge.newItem
                                        ? 'Новинка'
                                        : 'Акция',
                                style: AppTextStyles.badgeLabel.copyWith(
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.productName.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_weight(product)} · ${formatPrice(product.price)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.rowLabelMuted.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
