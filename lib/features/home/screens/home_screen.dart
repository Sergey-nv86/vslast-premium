import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../data/mock_products.dart';
import '../../../models/product.dart';
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

/// Главная — единый CustomScrollView (раньше "Популярное" и витрина были
/// раздельными: одна часть экрана не прокручивалась, другая скроллилась
/// внутри своего Expanded). Так был устроен и референс, который прислали
/// на проверку: "Популярное" уезжает вверх вместе с шапкой, а панель
/// "Фильтр" + категории — единственное, что прилипает к верху экрана
/// (SliverPersistentHeader, pinned: true), заняв ровно то место, откуда
/// уехало "Популярное".
///
/// Товары сгруппированы по категориям (заголовок раздела + сетка 2
/// колонки). Scroll-spy работает в обе стороны: при прокрутке активный
/// чип переключается на категорию, чей раздел сейчас под прилипшей
/// панелью; тап по чипу прокручивает список так, чтобы раздел этой
/// категории оказался сразу под панелью (не под шапкой, а именно под
/// прилипшей панелью — see _scrollToCategory).
///
/// Плашка "Перейти в корзину" (CartSummaryBar) — отдельный слой поверх
/// всего (Positioned внутри Stack), не участвует в разметке скролла.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _horizontalPadding = 18;
  static const double _gridSpacing = 10;
  static const double _cardTextBlockHeight = 84;

  // Высота прилипшей панели "Фильтр" + категории. Используется и для
  // самого SliverPersistentHeader (minExtent/maxExtent), и как опорная
  // точка в scroll-spy расчётах (см. _spyThreshold/_scrollToCategory) —
  // при изменении вёрстки панели ниже (_filterAndCategoryBar) не забудьте
  // поменять и это значение.
  static const double _pinnedBarHeight = 56;
  static const double _spyThreshold = _pinnedBarHeight + 12;

  final GlobalKey _viewportKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  final Map<ProductCategory, GlobalKey> _sectionKeys = {
    for (final c in ProductCategory.values) c: GlobalKey(),
  };

  HomeFilterState _filter = const HomeFilterState();
  ProductCategory? _activeCategory;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateActiveCategory);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateActiveCategory());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateActiveCategory);
    _scrollController.dispose();
    super.dispose();
  }

  List<Product> get _visibleProducts =>
      mockProducts.where((p) => p.inStock && _filter.matches(p)).toList();

  List<ProductCategory> get _categoriesShown {
    final present = _visibleProducts.map((p) => p.category).toSet();
    return ProductCategory.values.where(present.contains).toList();
  }

  List<Product> _productsFor(ProductCategory category) =>
      _visibleProducts.where((p) => p.category == category).toList();

  void _openProductDetails(BuildContext context, Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  void _openCart(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }

  /// Определяет, заголовок какого раздела сейчас "под панелью" — по
  /// позиции каждого заголовка относительно самого CustomScrollView
  /// (см. _viewportKey). Порог — высота прилипшей панели: как только
  /// заголовок раздела пересекает эту линию, раздел становится активным.
  void _updateActiveCategory() {
    final selfBox = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (selfBox == null || !selfBox.attached) return;

    ProductCategory? best;
    double bestOffset = double.negativeInfinity;
    for (final category in _categoriesShown) {
      final ctx = _sectionKeys[category]?.currentContext;
      final box = ctx?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      final offset = box.localToGlobal(Offset.zero, ancestor: selfBox).dy;
      if (offset <= _spyThreshold && offset > bestOffset) {
        bestOffset = offset;
        best = category;
      }
    }
    best ??= _categoriesShown.isNotEmpty ? _categoriesShown.first : null;
    if (best != _activeCategory) setState(() => _activeCategory = best);
  }

  /// Прокручивает список так, чтобы заголовок раздела оказался СРАЗУ ПОД
  /// прилипшей панелью — простой Scrollable.ensureVisible(alignment: 0)
  /// тут не подходит: он прижал бы заголовок к самому верху viewport'а,
  /// то есть ПОД панель (она пришпилена и рисуется поверх), и заголовок
  /// оказался бы скрыт под ней. Поэтому считаем целевой scroll-offset
  /// вручную: текущая позиция заголовка минус высота панели.
  void _scrollToCategory(ProductCategory category) {
    final ctx = _sectionKeys[category]?.currentContext;
    final box = ctx?.findRenderObject() as RenderBox?;
    final selfBox = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || selfBox == null || !_scrollController.hasClients) return;

    final targetLocalY = box.localToGlobal(Offset.zero, ancestor: selfBox).dy;
    final delta = targetLocalY - _pinnedBarHeight;
    final targetOffset = (_scrollController.offset + delta).clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _openFilter() async {
    final result = await showHomeFilterSheet(context, current: _filter);
    if (result == null) return;
    setState(() {
      _filter = result;
      _activeCategory = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateActiveCategory());
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final categories = _categoriesShown;

    return SafeArea(
      top: false,
      bottom: false,
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth =
                  (constraints.maxWidth - _horizontalPadding * 2 - _gridSpacing) / 2;
              return CustomScrollView(
                key: _viewportKey,
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: HomeHeader()),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
                      child: PopularSection(),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 14)),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _CategoryBarDelegate(
                      height: _pinnedBarHeight,
                      child: _filterAndCategoryBar(categories),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),
                  if (categories.isEmpty)
                    SliverFillRemaining(hasScrollBody: false, child: _emptyState())
                  else ...[
                    for (final category in categories) ...[
                      SliverToBoxAdapter(
                        key: _sectionKeys[category],
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            _horizontalPadding, 4, _horizontalPadding, 8,
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
                      Builder(builder: (context) {
                        final products = _productsFor(category);
                        return SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
                          sliver: SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: _gridSpacing,
                              crossAxisSpacing: _gridSpacing,
                              mainAxisExtent: itemWidth + _cardTextBlockHeight,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => ProductCard(
                                product: products[index],
                                onOpenDetails: (p) => _openProductDetails(context, p),
                              ),
                              childCount: products.length,
                            ),
                          ),
                        );
                      }),
                      const SliverToBoxAdapter(child: SizedBox(height: 14)),
                    ],
                    // Запас снизу — под плавающую плашку "Перейти в корзину"
                    // и нижнюю навигацию, чтобы последний ряд карточек не
                    // оказался под ними.
                    const SliverToBoxAdapter(child: SizedBox(height: 90)),
                  ],
                ],
              );
            },
          ),
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
          const Icon(Icons.search_off_rounded, size: 36, color: AppColors.textSecondary),
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

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
          border: Border.all(color: active ? AppColors.primaryBrown : AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune_rounded, size: 16, color: active ? Colors.white : AppColors.primaryBrown),
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
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

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
          border: Border.all(color: selected ? AppColors.primaryBrown : AppColors.divider),
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
