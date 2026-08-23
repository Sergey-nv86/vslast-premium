import '../../../widgets/product_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/product.dart';
import '../../../screens/product_detail_screen.dart';
import '../../../theme/app_theme.dart';

/// Блок "Популярное".
///
/// Данные приходят из HomeScreen:
/// Supabase → ProductService → HomeScreen → PopularSection.
///
/// UI намеренно сохранён прежним.
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
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                'Популярное',
                style: GoogleFonts.alice(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              const Text(
                'Все',
                style: TextStyle(
                  color: AppColors.linkAccent,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(
                Icons.arrow_forward_ios,
                size: 10,
                color: AppColors.linkAccent,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 84,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 84,
                height: 84,
                child: ProductImage(
                  imageUrl: product.imageUrl,
                  fit: BoxFit.cover,
                  iconSize: 22,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              product.inStock ? '${product.price} ₽' : 'Под заказ',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
