import 'package:flutter/material.dart';

import '../../../models/product.dart';
import '../../../screens/product_detail_screen.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/product_image.dart';

/// Компактный блок «Популярное» на Главной.
class PopularSection extends StatelessWidget {
  final List<Product> products;
  const PopularSection({super.key, required this.products});

  void _openProductDetails(BuildContext context, Product product) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)));

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Популярное', style: AppTextStyles.screenTitleSmall),
      const SizedBox(height: 8),
      SizedBox(height: 142, child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 2),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) => _PopularItem(product: products[index], onTap: () => _openProductDetails(context, products[index])),
      )),
    ]);
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
  Widget build(BuildContext context) => SizedBox(
    width: 108,
    child: Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(padding: const EdgeInsets.all(5), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(height: 84, child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Stack(fit: StackFit.expand, children: [
            ProductImage(imageUrl: product.imageUrl, fit: BoxFit.cover, iconSize: 20),
            if (product.badge != null) Positioned(top: 4, left: 4, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(AppRadii.pill)),
              child: Text(product.badge == ProductBadge.hit ? 'Хит' : product.badge == ProductBadge.newItem ? 'Новинка' : 'Акция', style: AppTextStyles.badgeLabel.copyWith(fontSize: 8)),
            )),
          ]))),
          const SizedBox(height: 4),
          Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.productName.copyWith(fontSize: 11)),
          const SizedBox(height: 1),
          Text('${_weight(product)} · ${formatPrice(product.price)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.rowLabelMuted.copyWith(fontSize: 9)),
        ])),
      ),
    ),
  );
}
