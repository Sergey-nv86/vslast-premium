import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/product_service.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/cart_summary_bar.dart';
import '../widgets/category_chip.dart';
import '../widgets/product_card.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';

class CatalogScreen extends StatefulWidget {
  final bool autofocusSearch;
  const CatalogScreen({super.key, this.autofocusSearch = false});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  static const double _horizontalPadding = 20;
  static const double _searchHeight = 68;
  static const double _categoryHeight = 52;
  static const double _pinnedHeaderHeight = _searchHeight + _categoryHeight;
  static const double _gridCrossAxisSpacing = 12;
  static const double _gridMainAxisSpacing = 16;
  static const double _cardTextBlockHeight = 112;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _viewportKey = GlobalKey();

  ProductCategory? _activeCategory;
  List<Product> _products = [];
  bool _isLoading = true;
  Object? _loadError;

  List<ProductCategory> get _shownCategories {
    final query = _searchController.text.trim().toLowerCase();
    return ProductCategory.values.where((category) {
      return _products.any((product) {
        if (product.category != category) return false;
        return query.isEmpty || product.name.toLowerCase().contains(query);
      });
    }).toList();
  }

  List<Product> _productsFor(ProductCategory category) {
    final query = _searchController.text.trim().toLowerCase();
    return _products.where((product) {
      if (product.category != category) return false;
      return query.isEmpty || product.name.toLowerCase().contains(query);
    }).toList();
  }

  int _crossAxisCount(double width) {
    if (width >= 1200) return 4;
    if (width >= 760) return 3;
    return 2;
  }

  double _itemWidth(double width) {
    final count = _crossAxisCount(width);
    return (width -
            _horizontalPadding * 2 -
            _gridCrossAxisSpacing * (count - 1)) /
        count;
  }

  Map<ProductCategory, double> _categoryOffsets(double viewportWidth) {
    final count = _crossAxisCount(viewportWidth);
    final itemWidth = _itemWidth(viewportWidth);
    double y = _pinnedHeaderHeight + 2;
    final result = <ProductCategory, double>{};
    for (final category in _shownCategories) {
      result[category] = y;
      final products = _productsFor(category);
      final rows = (products.length + count - 1) ~/ count;
      final gridHeight = rows == 0
          ? 0.0
          : rows * (itemWidth + _cardTextBlockHeight) +
                (rows - 1) * _gridMainAxisSpacing;
      y += 42 + gridHeight + 18;
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
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final products = await ProductService.instance.getProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateActiveCategory();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error;
      });
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
    setState(() => _activeCategory = null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateActiveCategory();
    });
  }

  void _updateActiveCategory() {
    if (!mounted || !_scrollController.hasClients || _isLoading) return;
    final categories = _shownCategories;
    if (categories.isEmpty) {
      if (_activeCategory != null) setState(() => _activeCategory = null);
      return;
    }
    final width =
        _viewportKey.currentContext?.size?.width ??
        MediaQuery.sizeOf(context).width;
    final offsets = _categoryOffsets(width);
    final probe = _scrollController.offset + _pinnedHeaderHeight;
    ProductCategory active = categories.first;
    for (final category in categories) {
      final y = offsets[category];
      if (y != null && y <= probe) {
        active = category;
      } else {
        break;
      }
    }
    if (active != _activeCategory) setState(() => _activeCategory = active);
  }

  void _scrollToCategory(ProductCategory category) {
    if (!_scrollController.hasClients || !_shownCategories.contains(category)) {
      return;
    }
    final width =
        _viewportKey.currentContext?.size?.width ??
        MediaQuery.sizeOf(context).width;
    final categoryY = _categoryOffsets(width)[category];
    if (categoryY == null) return;
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
          if (mounted) _updateActiveCategory();
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

  SliverGridDelegateWithFixedCrossAxisCount _gridDelegate(
    BuildContext context,
  ) {
    final width = MediaQuery.sizeOf(context).width;
    final count = _crossAxisCount(width);
    final itemWidth = _itemWidth(width);
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: count,
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
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                if (_isLoading)
                  const SliverToBoxAdapter(child: _CatalogLoadingState())
                else if (_loadError != null)
                  SliverToBoxAdapter(
                    child: _CatalogErrorState(onRetry: _loadProducts),
                  )
                else if (categories.isEmpty)
                  const SliverToBoxAdapter(child: _CatalogEmptyState())
                else
                  for (final category in categories) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          _horizontalPadding,
                          8,
                          _horizontalPadding,
                          10,
                        ),
                        child: Text(
                          category.label,
                          style: AppTextStyles.sectionTitle,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        _horizontalPadding,
                        0,
                        _horizontalPadding,
                        category == categories.last && cart.isEmpty ? 28 : 18,
                      ),
                      sliver: Builder(
                        builder: (context) {
                          final products = _productsFor(category);
                          return SliverGrid(
                            gridDelegate: _gridDelegate(context),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => ProductCard(
                                product: products[index],
                                onOpenDetails: _openProductDetails,
                              ),
                              childCount: products.length,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                const SliverToBoxAdapter(child: SizedBox(height: 112)),
              ],
            ),
            if (!cart.isEmpty)
              Positioned(
                left: 16,
                right: 16,
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
      elevation: overlapsContent ? 1 : 0,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: ClipRect(child: child),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CatalogPinnedHeaderDelegate oldDelegate) =>
      oldDelegate.height != height || oldDelegate.child != child;
}

class _SearchHeader extends StatelessWidget {
  final TextEditingController controller;
  final bool autofocus;

  const _SearchHeader({required this.controller, required this.autofocus});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E4E0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1A1A1A),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          return Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: autofocus,
                  textInputAction: TextInputAction.search,
                  style: AppTextStyles.searchHint.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 15,
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
              if (value.text.isNotEmpty)
                IconButton(
                  tooltip: 'Очистить',
                  onPressed: controller.clear,
                  icon: const Icon(
                    Icons.close,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                )
              else
                const SizedBox(width: 4),
            ],
          );
        },
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
      padding: const EdgeInsets.symmetric(horizontal: 18),
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            CategoryChip(
              label: 'Все',
              selected: activeCategory == null,
              onTap: onAllTap,
            ),
            const SizedBox(width: 8),
            for (final category in categories) ...[
              CategoryChip(
                label: category.label,
                selected: activeCategory == category,
                onTap: () => onCategoryTap(category),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _CatalogLoadingState extends StatelessWidget {
  const _CatalogLoadingState();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _CatalogScreenState._horizontalPadding,
        8,
        _CatalogScreenState._horizontalPadding,
        24,
      ),
      child: Column(
        children: List.generate(
          3,
          (index) => Container(
            height: 180,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _CatalogErrorState({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 72, 24, 72),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Не удалось загрузить каталог',
            style: AppTextStyles.sectionTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Проверьте соединение и попробуйте ещё раз.',
            style: AppTextStyles.bodySecondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    );
  }
}

class _CatalogEmptyState extends StatelessWidget {
  const _CatalogEmptyState();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 72, 24, 72),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 52,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text('Ничего не найдено', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 8),
          Text(
            'Попробуйте изменить запрос или выбрать другую категорию.',
            style: AppTextStyles.bodySecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
