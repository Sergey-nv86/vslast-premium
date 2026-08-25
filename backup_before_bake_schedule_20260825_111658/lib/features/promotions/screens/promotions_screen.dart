import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/product.dart';
import '../../../screens/product_detail_screen.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/product_card.dart';
import '../../admin/models/promotion.dart';
import '../../admin/services/promotion_service.dart';
import '../../admin/models/promotion_store.dart';
import '../../../services/product_service.dart';

/// «Акции и спецпредложения».
///
/// Источник данных — единый PromotionStore, который используется
/// также Админкой.
///
/// UI сохраняем:
/// - баннеры на всю ширину;
/// - горизонтальный свайп;
/// - один баннер на страницу;
/// - индикатор страниц;
/// - ассортимент выбранной акции;
/// - сетка товаров.
///
/// Клиент видит только доступные акции, находящиеся в периоде показа.
class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  static const double _horizontalPadding = 18;
  static const double _gridSpacing = 10;
  static const double _cardTextBlockHeight = 84;

  final PromotionStore _store = PromotionStore.instance;
  final PromotionService _promotionService = PromotionService.instance;
  final ProductService _productService = ProductService.instance;
  final PageController _bannerController = PageController();

  List<Product> _catalogProducts = [];
  bool _loading = true;
  String? _loadError;

  int _activeIndex = 0;

  List<Promotion> get _promotions => _store.available;

  Promotion? get _activePromotion {
    final promotions = _promotions;

    if (promotions.isEmpty) return null;

    if (_activeIndex >= promotions.length) {
      return promotions.last;
    }

    return promotions[_activeIndex];
  }

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    try {
      final results = await Future.wait([
        _promotionService.getPromotions(),
        _productService.getProducts(),
      ]);

      final promotions = results[0] as List<Promotion>;
      final products = results[1] as List<Product>;

      _store
        ..clear()
        ..addAll(promotions);

      if (!mounted) return;

      setState(() {
        _catalogProducts = products;
        _loading = false;
        _loadError = null;

        if (_activeIndex >= _store.available.length) {
          _activeIndex = 0;
        }
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _loadError = error.toString();
      });
    }
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  List<Product> _productsFor(Promotion promotion) {
    return promotion.products
        .map((item) {
          try {
            return _catalogProducts.firstWhere(
              (product) => product.id == item.productId,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<Product>()
        .toList();
  }

  void _openProductDetails(BuildContext context, Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 40,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                'Не удалось загрузить акции',
                textAlign: TextAlign.center,
                style: AppTextStyles.rowLabel.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Проверьте соединение и попробуйте ещё раз.',
                textAlign: TextAlign.center,
                style: AppTextStyles.rowLabelMuted,
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: _loadPromotions,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    final promotions = _promotions;

    if (promotions.isEmpty) {
      return _emptyPromotions();
    }

    final promotion = _activePromotion!;

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
              itemCount: promotions.length,
              onPageChanged: (index) {
                setState(() => _activeIndex = index);
              },
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _horizontalPadding,
                  ),
                  child: _PromoBanner(promotion: promotions[index]),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          _DotsIndicator(count: promotions.length, activeIndex: _activeIndex),

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
                ? _emptyProducts()
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
                        itemBuilder: (context, index) {
                          return ProductCard(
                            product: products[index],
                            onOpenDetails: (product) =>
                                _openProductDetails(context, product),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyPromotions() {
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
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Сейчас нет активных акций и спецпредложений',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.rowLabelMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyProducts() {
    return Center(
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
}

class _PromoBanner extends StatelessWidget {
  final Promotion promotion;

  const _PromoBanner({required this.promotion});

  @override
  Widget build(BuildContext context) {
    final image = _bannerImage();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: image != null
          ? Stack(
              fit: StackFit.expand,
              children: [
                image,
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: .62),
                        Colors.black.withValues(alpha: .08),
                      ],
                    ),
                  ),
                  child: _content(),
                ),
              ],
            )
          : Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: AppColors.primaryBrown,
              child: _content(),
            ),
    );
  }

  Widget? _bannerImage() {
    if (promotion.bannerBytes != null) {
      return Image.memory(
        Uint8List.fromList(promotion.bannerBytes!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    final banner = promotion.bannerAsset;

    if (banner != null && banner.isNotEmpty) {
      if (banner.startsWith('http://') || banner.startsWith('https://')) {
        return Image.network(
          banner,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        );
      }

      return Image.asset(
        banner,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
    }

    return null;
  }

  Widget _content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                promotion.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.alice(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.15,
                ),
              ),
            ),

            const SizedBox(width: 10),

            SizedBox(
              width: 44,
              height: 44,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  shape: BoxShape.circle,
                ),
                child: Icon(_promotionIcon(), size: 22, color: Colors.white),
              ),
            ),
          ],
        ),

        if (promotion.description.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            promotion.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: .9),
              height: 1.25,
            ),
          ),
        ],
      ],
    );
  }

  IconData _promotionIcon() {
    switch (promotion.type) {
      case PromotionType.collection:
        return Icons.auto_awesome_rounded;

      case PromotionType.discount:
        return Icons.percent_rounded;

      case PromotionType.specialPrice:
        return Icons.sell_outlined;

      case PromotionType.bundle:
        return Icons.local_offer_outlined;
    }
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
