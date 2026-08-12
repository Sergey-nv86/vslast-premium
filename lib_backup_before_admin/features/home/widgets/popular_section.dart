import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/mock_products.dart';
import '../../../models/product.dart';
import '../../../screens/product_detail_screen.dart';
import '../../../theme/app_theme.dart';

/// Блок "Популярное". Раньше карточки были декоративными (свои
/// image/title/price без связи с товаром, без onTap) — отсюда и не
/// открывалась карточка товара по нажатию. Теперь ссылаемся на реальные
/// Product из mockProducts — переход на ProductDetailScreen работает, и
/// цена/фото/название больше не могут разойтись с каталогом.
class PopularSection extends StatelessWidget {
  const PopularSection({super.key});

  static final List<Product> _items = [
    mockProducts.firstWhere((p) => p.id == 'eclair_chocolate'),
    mockProducts.firstWhere((p) => p.id == 'dacquoise'),
    mockProducts.firstWhere((p) => p.id == 'lemon_basil_tart'),
    mockProducts.firstWhere((p) => p.id == 'ciabatta'),
    mockProducts.firstWhere((p) => p.id == 'grain_bun'),
  ];

  void _openProductDetails(BuildContext context, Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                "Популярное",
                style: GoogleFonts.alice(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              const Text(
                "Все",
                style: TextStyle(
                  color: AppColors.linkAccent,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.linkAccent),
            ],
          ),
        ),

        const SizedBox(height: 8),

        SizedBox(
          height: 114,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) => _PopularItem(
              product: _items[index],
              onTap: () => _openProductDetails(context, _items[index]),
            ),
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
        width: 76,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 76,
                height: 76,
                child: Image.asset(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.surfaceMuted,
                    child: const Icon(Icons.bakery_dining_outlined,
                        size: 22, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              product.inStock ? "${product.price} ₽" : "Под заказ",
              style: const TextStyle(
                fontSize: 10,
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
