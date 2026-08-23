import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/mock_products.dart';
import '../../../models/product.dart';
import '../../../screens/product_detail_screen.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/product_card.dart';
import '../models/promotion.dart';

/// «Акции и спецпредложения» — новая вкладка нижней навигации (заменила
/// «Избранное», которое осталось доступно через меню профиля на Главной).
///
/// Баннеры — на всю ширину экрана, горизонтальный свайп (PageView, один
/// баннер = одна страница, без "подглядывания" соседних — просили "на всю
/// ширину"). Под текущим баннером — ассортимент именно этой акции;
/// пролистали баннер влево — сменился и список товаров под ним.
class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  static const double _horizontalPadding = 18;
  static const double _gridSpacing = 10;
  static const double _cardTextBlockHeight = 84;

  final PageController _bannerController = PageController();
  int _activeIndex = 0;

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  List<Product> _productsFor(Promotion promo) => promo.productIds
      .map((id) {
        try {
          return mockProducts.firstWhere((p) => p.id == id);
        } catch (_) {
          return null;
        }
      })
      .whereType<Product>()
      .toList();

  void _openProductDetails(BuildContext context, Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final promotion = mockPromotions[_activeIndex];
    final products = _productsFor(promotion);

    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              _horizontalPadding,
              16,
              _horizontalPadding,
              4,
            ),
            child: Text(
              'Акции и спецпредложения',
              style: GoogleFonts.alice(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 132,
            child: PageView.builder(
              controller: _bannerController,
              itemCount: mockPromotions.length,
              onPageChanged: (i) => setState(() => _activeIndex = i),
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _horizontalPadding,
                ),
                child: _PromoBanner(promotion: mockPromotions[i]),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _DotsIndicator(
            count: mockPromotions.length,
            activeIndex: _activeIndex,
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
            child: Text(
              'Ассортимент к акции',
              style: AppTextStyles.rowLabel.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: products.isEmpty
                ? _emptyState()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth =
                          (constraints.maxWidth -
                              _horizontalPadding * 2 -
                              _gridSpacing) /
                          2;
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          _horizontalPadding,
                          0,
                          _horizontalPadding,
                          90,
                        ),
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: _gridSpacing,
                          crossAxisSpacing: _gridSpacing,
                          mainAxisExtent: itemWidth + _cardTextBlockHeight,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) => ProductCard(
                          product: products[index],
                          onOpenDetails: (p) => _openProductDetails(context, p),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Text(
        'К этой акции пока нет товаров',
        textAlign: TextAlign.center,
        style: AppTextStyles.rowLabelMuted,
      ),
    ),
  );
}

class _PromoBanner extends StatelessWidget {
  final Promotion promotion;
  const _PromoBanner({required this.promotion});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: promotion.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  promotion.title,
                  style: GoogleFonts.alice(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  promotion.subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: .9),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .18),
              shape: BoxShape.circle,
            ),
            child: Icon(promotion.icon, size: 26, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int activeIndex;
  const _DotsIndicator({required this.count, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? AppColors.primaryBrown : AppColors.divider,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
