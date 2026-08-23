import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/product.dart';
import '../../../services/product_service.dart';
import '../../../providers/cart_provider.dart';
import '../../../screens/cart_screen.dart';
import '../../../screens/product_detail_screen.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/cart_summary_bar.dart';
import '../../../widgets/product_card.dart';
import '../models/home_filter_state.dart';
import '../widgets/home_filter_sheet.dart';
import '../widgets/home_header.dart';
import '../widgets/popular_section.dart';

/// Главная:
///
/// HomeHeader — постоянный верхний слой.
/// Ниже него находится один CustomScrollView:
///   PopularSection → прокручивается и уезжает вверх
///   CategoryBar   → pinned внутри viewport каталога
///   категории + товары
///
/// В результате CategoryBar занимает место PopularSection после его ухода
/// вверх, но всегда остаётся непосредственно под постоянным HomeHeader.
///
/// Scroll-spy переключает активный чип по текущей секции товаров.
/// Плашка "Перейти в корзину" — отдельный слой поверх всего.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _horizontalPadding = 18;
  static const double _gridSpacing = 10;
  static const double _cardTextBlockHeight = 84;

  // HomeHeader теперь является фиксированным слоем над CustomScrollView.
  // Высота должна совпадать с HomeHeader: safe-area top + 140 px фотографии.
  static const double _headerPhotoHeight = 140;

  // Высота прилипшей панели "Фильтр" + категории.
  static const double _pinnedBarHeight = 56;

  // Scroll-spy работает относительно viewport CustomScrollView.
  // Его верх уже находится ПОД постоянным HomeHeader, поэтому здесь
  // учитывается только высота pinned CategoryBar и небольшой запас.
  static const double _spyThreshold = _pinnedBarHeight + 12;

  final GlobalKey _viewportKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  final Map<ProductCategory, GlobalKey> _sectionKeys = {
    for (final c in ProductCategory.values) c: GlobalKey(),
  };

  HomeFilterState _filter = const HomeFilterState();

  List<Product> _products = [];

  ProductCategory? _activeCategory;

  Future<void> _loadProducts() async {
    try {
      final products = await ProductService.instance.getProducts();

      if (!mounted) return;

      setState(() {
        _products = products;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateActiveCategory();
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_updateActiveCategory);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadProducts();
    });
  }

  List<Product> get _popularProducts {
    return _products
        .where(
          (product) => product.inStock && product.badge == ProductBadge.hit,
        )
        .take(5)
        .toList();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateActiveCategory);
    _scrollController.dispose();
    super.dispose();
  }

  List<Product> get _visibleProducts =>
      _products.where((p) => p.inStock && _filter.matches(p)).toList();

  List<ProductCategory> get _categoriesShown {
    final present = _visibleProducts.map((p) => p.category).toSet();
    return ProductCategory.values.where(present.contains).toList();
  }

  List<Product> _productsFor(ProductCategory category) =>
      _visibleProducts.where((p) => p.category == category).toList();

  /// Расчётная позиция заголовков категорий внутри CustomScrollView.
  /// Не использует GlobalKey/RenderBox, поэтому работает с lazy Sliver.
  Map<ProductCategory, double> _categoryHeaderOffsets(double itemWidth) {
    const popularHeight = 152.0;
    const beforePopular = 12.0;
    const afterPopular = 14.0;

    double y =
        beforePopular + popularHeight + afterPopular + _pinnedBarHeight + 10;

    final result = <ProductCategory, double>{};

    for (final category in _categoriesShown) {
      result[category] = y;

      final products = _productsFor(category);
      final rows = (products.length + 1) ~/ 2;

      final gridHeight = rows > 0
          ? rows * (itemWidth + _cardTextBlockHeight) +
                (rows - 1) * _gridSpacing
          : 0.0;

      const sectionTitleHeight = 31.0;
      y += sectionTitleHeight + gridHeight + 14;
    }

    return result;
  }

  void _openProductDetails(BuildContext context, Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  void _openCart(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CartScreen()));
  }

  /// Определяет, заголовок какого раздела сейчас находится под
  /// pinned CategoryBar.
  ///
  /// ВАЖНО: _viewportKey теперь принадлежит CustomScrollView, который
  /// начинается сразу под постоянным HomeHeader. Поэтому координаты
  /// здесь НЕ нужно дополнительно смещать на высоту HomeHeader.
  void _updateActiveCategory() {
    if (!_scrollController.hasClients || _categoriesShown.isEmpty) return;

    final viewportWidth =
        _viewportKey.currentContext?.size?.width ??
        MediaQuery.sizeOf(context).width;

    final itemWidth =
        (viewportWidth - _horizontalPadding * 2 - _gridSpacing) / 2;

    final offsets = _categoryHeaderOffsets(itemWidth);

    // Точка определения активной категории — сразу под pinned CategoryBar.
    final probeY = _scrollController.offset + _spyThreshold;

    ProductCategory? best;
    double bestOffset = double.negativeInfinity;

    for (final category in _categoriesShown) {
      final headerY = offsets[category];
      if (headerY == null) continue;

      if (headerY <= probeY && headerY > bestOffset) {
        bestOffset = headerY;
        best = category;
      }
    }

    best ??= _categoriesShown.first;

    if (best != _activeCategory && mounted) {
      setState(() => _activeCategory = best);
    }
  }

  /// Прокручивает список так, чтобы заголовок раздела оказался СРАЗУ
  /// ПОД pinned CategoryBar.
  ///
  /// CustomScrollView начинается под постоянным HomeHeader, поэтому
  /// достаточно вычесть только высоту CategoryBar.
  void _scrollToCategory(ProductCategory category) {
    if (!_scrollController.hasClients) return;
    if (!_categoriesShown.contains(category)) return;

    final viewportWidth =
        _viewportKey.currentContext?.size?.width ??
        MediaQuery.sizeOf(context).width;

    final itemWidth =
        (viewportWidth - _horizontalPadding * 2 - _gridSpacing) / 2;

    final headerY = _categoryHeaderOffsets(itemWidth)[category];
    if (headerY == null) return;

    final targetOffset = (headerY - _pinnedBarHeight).clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );

    if (_activeCategory != category && mounted) {
      setState(() => _activeCategory = category);
    }

    _scrollController
        .animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        )
        .then((_) {
          if (!mounted) return;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _updateActiveCategory();
          });
        });
  }

  Future<void> _openFilter() async {
    final result = await showHomeFilterSheet(context, current: _filter);

    if (!mounted || result == null) return;

    setState(() {
      _filter = result;
      _activeCategory = null;
    });

    // После изменения фильтра количество товаров и высота Sliver
    // могут измениться. Начинаем отфильтрованный каталог сверху.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      _scrollController.jumpTo(_scrollController.position.minScrollExtent);

      _updateActiveCategory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final categories = _categoriesShown;

    final headerHeight =
        MediaQuery.of(context).padding.top + _headerPhotoHeight;

    return SafeArea(
      top: false,
      bottom: false,
      child: Stack(
        children: [
          // ВАЖНО: HomeHeader больше НЕ является sliver.
          // Он физически лежит поверх CustomScrollView и поэтому никогда
          // не уезжает при вертикальной прокрутке.
          const Positioned(left: 0, right: 0, top: 0, child: HomeHeader()),

          // Единственный вертикальный scroll view начинается сразу под
          // постоянным HomeHeader. Поэтому pinned CategoryBar автоматически
          // прилипает именно к нижней границе HomeHeader, а не к самому
          // верху экрана.
          Positioned(
            left: 0,
            right: 0,
            top: headerHeight,
            bottom: 0,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth =
                    (constraints.maxWidth -
                        _horizontalPadding * 2 -
                        _gridSpacing) /
                    2;
                return CustomScrollView(
                  key: _viewportKey,
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    // PopularSection специально НЕ pinned.
                    // Он уезжает вверх при прокрутке.
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: _horizontalPadding,
                        ),
                        child: PopularSection(products: _popularProducts),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 14)),

                    // CategoryBar pinned внутри viewport, который уже
                    // начинается под HomeHeader.
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _CategoryBarDelegate(
                        height: _pinnedBarHeight,
                        child: _filterAndCategoryBar(categories),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 10)),

                    if (categories.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _emptyState(),
                      )
                    else ...[
                      for (final category in categories) ...[
                        SliverToBoxAdapter(
                          key: _sectionKeys[category],
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              _horizontalPadding,
                              4,
                              _horizontalPadding,
                              8,
                            ),
                            child: Text(
                              category.label,
                              style: GoogleFonts.alice(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        Builder(
                          builder: (context) {
                            final products = _productsFor(category);
                            return SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: _horizontalPadding,
                              ),
                              sliver: SliverGrid(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: _gridSpacing,
                                      crossAxisSpacing: _gridSpacing,
                                      mainAxisExtent:
                                          itemWidth + _cardTextBlockHeight,
                                    ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) => ProductCard(
                                    product: products[index],
                                    onOpenDetails: (p) =>
                                        _openProductDetails(context, p),
                                  ),
                                  childCount: products.length,
                                ),
                              ),
                            );
                          },
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 14)),
                      ],

                      // Запас снизу — под плавающую плашку "Перейти в корзину"
                      // и нижнюю навигацию.
                      const SliverToBoxAdapter(child: SizedBox(height: 90)),
                    ],
                  ],
                );
              },
            ),
          ),

          // Корзина — поверх контента, как и раньше.
          if (!cart.isEmpty)
            Positioned(
              left: 18,
              right: 18,
              bottom: 8,
              child: CartSummaryBar(
                itemsCount: cart.totalCount,
                totalSum: cart.totalSum,
                onTap: () => _openCart(context),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterAndCategoryBar(List<ProductCategory> categories) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          children: [
            _FilterPill(active: _filter.isActive, onTap: _openFilter),
            const SizedBox(width: 8),
            for (final category in categories) ...[
              _CategoryChip(
                label: category.label,
                selected: _activeCategory == category,
                onTap: () => _scrollToCategory(category),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 36,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 10),
          Text(
            'Ничего не найдено по выбранным фильтрам',
            textAlign: TextAlign.center,
            style: AppTextStyles.rowLabelMuted,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _filter = const HomeFilterState()),
            child: const Text('Сбросить фильтр'),
          ),
        ],
      ),
    ),
  );
}

/// Прилипшая панель "Фильтр" + категории. Занимает ровно то место, откуда
/// "уезжает" вверх блок "Популярное" — непрозрачный фон обязателен, иначе
/// сквозь панель будет просвечивать прокручивающийся контент под ней.
class _CategoryBarDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  const _CategoryBarDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;

  @override
  bool shouldRebuild(covariant _CategoryBarDelegate oldDelegate) =>
      height != oldDelegate.height || child != oldDelegate.child;
}

class _FilterPill extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _FilterPill({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryBrown : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? AppColors.primaryBrown : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 16,
              color: active ? Colors.white : AppColors.primaryBrown,
            ),
            const SizedBox(width: 6),
            Text(
              'Фильтр',
              style: TextStyle(
                color: active ? Colors.white : AppColors.primaryBrown,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBrown : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primaryBrown : AppColors.divider,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
