import 'package:flutter/material.dart';

import '../../../models/product.dart';
import '../../../screens/product_detail_screen.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/product_image.dart';

/// Компактный блок «Популярное» на Главной.
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
        const SizedBox(height: 8),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 3),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
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
      width: 122,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 98,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ProductImage(
                          imageUrl: product.imageUrl,
                          fit: BoxFit.cover,
                          iconSize: 22,
                        ),
                        if (product.badge != null)
                          Positioned(
                            top: 5,
                            left: 5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
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
                                style: AppTextStyles.badgeLabel.copyWith(fontSize: 9),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.productName.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 1),
                Text(
                  '${_weight(product)} · ${formatPrice(product.price)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.rowLabelMuted.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
