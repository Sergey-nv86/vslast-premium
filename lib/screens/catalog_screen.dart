import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/product_service.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/tab_navigation_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/cart_summary_bar.dart';
import '../widgets/category_chip.dart';
import '../widgets/product_card.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';

/// Каталог «Всласть».
///
/// Верхний заголовок «Каталог» уезжает при прокрутке.
/// SearchBar + CategoryBar закреплены одним общим
/// SliverPersistentHeader.
///
/// Использование одного pinned-header вместо двух соседних pinned headers
/// устраняет конфликт SliverGeometry:
/// layoutExtent > paintExtent.
class CatalogScreen extends StatefulWidget {
  final bool autofocusSearch;

  const CatalogScreen({super.key, this.autofocusSearch = false});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  static const double _horizontalPadding = 20;
  static const double _topHeaderHeight = 70;
  static const double _searchHeight = 76;
  static const double _categoryHeight = 54;
  static const double _pinnedHeaderHeight = _searchHeight + _categoryHeight;

  static const double _gridCrossAxisSpacing = 10;
  static const double _gridMainAxisSpacing = 10;
  static const int _gridCrossAxisCount = 3;

  /// Высота текста карточки + цена/кнопка.
  static const double _cardTextBlockHeight = 80;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _viewportKey = GlobalKey();

  ProductCategory? _activeCategory;

  List<Product> _products = [];

  List<ProductCategory> get _shownCategories {
    final query = _searchController.text.trim().toLowerCase();

    return ProductCategory.values.where((category) {
      return _products.any((product) {
        if (product.category != category) return false;
        if (query.isEmpty) return true;
        return product.name.toLowerCase().contains(query);
      });
    }).toList();
  }

  List<Product> _productsFor(ProductCategory category) {
    final query = _searchController.text.trim().toLowerCase();

    return _products.where((product) {
      if (product.category != category) return false;
      if (query.isEmpty) return true;
      return product.name.toLowerCase().contains(query);
    }).toList();
  }

  /// Расчётная позиция каждого заголовка категории в координатах
  /// CustomScrollView.
  ///
  /// Не используем GlobalKey/RenderBox: SliverGrid ленивый, поэтому
  /// дальние заголовки могут отсутствовать в render tree.
  Map<ProductCategory, double> _categoryOffsets(double viewportWidth) {
    final itemWidth =
        (viewportWidth -
            _horizontalPadding * 2 -
            _gridCrossAxisSpacing * (_gridCrossAxisCount - 1)) /
        _gridCrossAxisCount;

    // До первого заголовка:
    // 70 — «Каталог», 130 — pinned Search + CategoryBar, 2 — spacer.
    double y = _topHeaderHeight + _pinnedHeaderHeight + 2;

    final result = <ProductCategory, double>{};

    for (final category in _shownCategories) {
      result[category] = y;

      final products = _productsFor(category);
      final rows =
          (products.length + _gridCrossAxisCount - 1) ~/ _gridCrossAxisCount;

      final gridHeight = rows == 0
          ? 0.0
          : rows * (itemWidth + _cardTextBlockHeight) +
                (rows - 1) * _gridMainAxisSpacing;

      // Заголовок: Padding(top 8 + bottom 8) + строка текста ~22.
      const sectionHeaderHeight = 38.0;

      // После каждой сетки в текущем build есть bottom padding 14.
      y += sectionHeaderHeight + gridHeight + 14;
    }

    return result;
  }

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_updateActiveCategory);
    _searchController.addListener(_onSearchChanged);

    _loadProducts();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateActiveCategory();
    });
  }

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
    } catch (error) {
      if (!mounted) return;

      setState(() {});
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateActiveCategory);
    _searchController.removeListener(_onSearchChanged);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) return;

    setState(() {
      _activeCategory = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateActiveCategory();
    });
  }

  void _updateActiveCategory() {
    if (!mounted || !_scrollController.hasClients) return;

    final categories = _shownCategories;
    if (categories.isEmpty) {
      if (_activeCategory != null) {
        setState(() => _activeCategory = null);
      }
      return;
    }

    final viewportWidth =
        _viewportKey.currentContext?.size?.width ??
        MediaQuery.sizeOf(context).width;

    final offsets = _categoryOffsets(viewportWidth);

    // Верхняя граница контента, которая видна ПОД pinned Search + CategoryBar.
    final probe = _scrollController.offset + _pinnedHeaderHeight;

    ProductCategory active = categories.first;

    for (final category in categories) {
      final y = offsets[category];
      if (y == null) continue;
      if (y <= probe) {
        active = category;
      } else {
        break;
      }
    }

    if (active != _activeCategory) {
      setState(() => _activeCategory = active);
    }
  }

  void _scrollToCategory(ProductCategory category) {
    if (!_scrollController.hasClients) return;
    if (!_shownCategories.contains(category)) return;

    final viewportWidth =
        _viewportKey.currentContext?.size?.width ??
        MediaQuery.sizeOf(context).width;

    final categoryY = _categoryOffsets(viewportWidth)[category];
    if (categoryY == null) return;

    // Ставим заголовок категории непосредственно под pinned CategoryBar.
    final target = (categoryY - _pinnedHeaderHeight).clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );

    setState(() => _activeCategory = category);

    _scrollController
        .animateTo(
          target.toDouble(),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        )
        .then((_) {
          if (!mounted) return;
          _updateActiveCategory();
        });
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _openProductDetails(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  void _openCart() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CartScreen()));
  }

  void _goHome() {
    final navigator = Navigator.of(context);

    if (navigator.canPop()) {
      navigator.pop();
    } else {
      context.read<TabNavigationController>().goToHome();
    }
  }

  SliverGridDelegateWithFixedCrossAxisCount _gridDelegate(
    BuildContext context,
  ) {
    final width = MediaQuery.sizeOf(context).width;

    final itemWidth =
        (width -
            _horizontalPadding * 2 -
            _gridCrossAxisSpacing * (_gridCrossAxisCount - 1)) /
        _gridCrossAxisCount;

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: _gridCrossAxisCount,
      mainAxisSpacing: _gridMainAxisSpacing,
      crossAxisSpacing: _gridCrossAxisSpacing,
      mainAxisExtent: itemWidth + _cardTextBlockHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final categories = _shownCategories;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        key: _viewportKey,
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // «Каталог» — обычный верхний блок.
                // Он уезжает при вертикальной прокрутке.
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: _topHeaderHeight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        _horizontalPadding,
                        8,
                        _horizontalPadding,
                        18,
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _goHome,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: 44,
                              height: 44,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.divider,
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.chevron_left,
                                size: 24,
                                color: AppColors.primaryBrown,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Каталог',
                              style: AppTextStyles.screenTitle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Search + категории закрепляются ВМЕСТЕ.
                //
                // Это принципиально: не используем два соседних
                // SliverPersistentHeader. Именно их комбинация давала
                // layoutExtent=76 / paintExtent=75.
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _CatalogPinnedHeaderDelegate(
                    height: _pinnedHeaderHeight,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: _searchHeight,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              _horizontalPadding,
                              8,
                              _horizontalPadding,
                              12,
                            ),
                            child: _SearchHeader(
                              controller: _searchController,
                              autofocus: widget.autofocusSearch,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: _categoryHeight,
                          child: _CategoryBar(
                            categories: categories,
                            activeCategory: _activeCategory,
                            onCategoryTap: _scrollToCategory,
                            onAllTap: _scrollToTop,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 2)),

                if (categories.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 80),
                      child: _EmptyState(),
                    ),
                  )
                else
                  for (final category in categories) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          _horizontalPadding,
                          8,
                          _horizontalPadding,
                          8,
                        ),
                        child: Text(
                          category.label,
                          style: AppTextStyles.productName.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        _horizontalPadding,
                        0,
                        _horizontalPadding,
                        category == categories.last && cart.isEmpty ? 24 : 14,
                      ),
                      sliver: Builder(
                        builder: (context) {
                          final products = _productsFor(category);

                          return SliverGrid(
                            gridDelegate: _gridDelegate(context),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              return ProductCard(
                                product: products[index],
                                onOpenDetails: _openProductDetails,
                              );
                            }, childCount: products.length),
                          );
                        },
                      ),
                    ),
                  ],

                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            ),

            if (!cart.isEmpty)
              Positioned(
                left: 18,
                right: 18,
                bottom: 8,
                child: CartSummaryBar(
                  itemsCount: cart.totalCount,
                  totalSum: cart.totalSum,
                  onTap: _openCart,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Единый pinned-header каталога.
///
/// minExtent и maxExtent всегда одинаковы.
/// Внутренний SizedBox имеет ровно ту же высоту.
///
/// Это предотвращает Flutter-ошибку:
/// SliverGeometry is not valid:
/// "layoutExtent" exceeds the "paintExtent".
class _CatalogPinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  const _CatalogPinnedHeaderDelegate({
    required this.height,
    required this.child,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: AppColors.background,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: ClipRect(child: child),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CatalogPinnedHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

class _SearchHeader extends StatelessWidget {
  final TextEditingController controller;
  final bool autofocus;

  const _SearchHeader({required this.controller, required this.autofocus});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 22, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              style: AppTextStyles.searchHint.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                hintText: 'Поиск хлеба, тортов, десертов...',
                hintStyle: AppTextStyles.searchHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final List<ProductCategory> categories;
  final ProductCategory? activeCategory;
  final ValueChanged<ProductCategory> onCategoryTap;
  final VoidCallback onAllTap;

  const _CategoryBar({
    required this.categories,
    required this.activeCategory,
    required this.onCategoryTap,
    required this.onAllTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(
        _CatalogScreenState._horizontalPadding,
        7,
        0,
        7,
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(right: 20),
        children: [
          CategoryChip(
            label: 'Все',
            selected: activeCategory == null,
            onTap: onAllTap,
          ),
          const SizedBox(width: 6),
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: CategoryChip(
                label: category.label,
                selected: activeCategory == category,
                onTap: () => onCategoryTap(category),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.search_off_rounded,
          size: 52,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: 14),
        Text(
          'Ничего не найдено',
          style: AppTextStyles.productName.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Попробуйте изменить запрос.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
