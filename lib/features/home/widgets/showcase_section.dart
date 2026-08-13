import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/mock_products.dart';
import '../../../models/product.dart';
import '../../../screens/product_detail_screen.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/product_card.dart';
import '../models/home_filter_state.dart';
import 'home_filter_sheet.dart';

/// Блок "Сегодня на витрине". Товары сгруппированы по категориям
/// (заголовок раздела + сетка 2 колонки), с собственной прокруткой на
/// всю оставшуюся высоту экрана (Родитель — Expanded в HomeScreen).
///
/// Сверху — панель "Фильтр" + чипы категорий, она НЕ прокручивается
/// вместе со списком. Чипы работают в связке со скроллом в обе стороны
/// ("scroll-spy"): при прокрутке списка активный чип переключается на
/// категорию, чей раздел сейчас вверху; тап по чипу прокручивает список
/// к разделу этой категории. Сама кнопка "Фильтр" открывает модалку с
/// РЕАЛЬНЫМ сужением списка (категории + Хит/Новинка/Акция) — в отличие
/// от чипов, она может скрыть часть разделов целиком.
class ShowcaseSection extends StatefulWidget {
  const ShowcaseSection({super.key});

  @override
  State<ShowcaseSection> createState() => _ShowcaseSectionState();
}

class _ShowcaseSectionState extends State<ShowcaseSection> {
  static const double _cardTextBlockHeight = 80;
  static const double _gridSpacing = 10;
  static const double _horizontalPadding = 18;

  // Небольшой запас от верхнего края скролл-области — заголовок раздела
  // считается "текущим", когда он пересёк эту линию, а не строго линию 0
  // (иначе смена активной категории заметно запаздывает/дёргается).
  static const double _spyThreshold = 12;

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

  /// Определяет, заголовок какого раздела сейчас "текущий" — по позиции
  /// каждого заголовка относительно самого ShowcaseSection (ближайший
  /// общий предок для всех разделов, включая панель чипов над списком).
  void _updateActiveCategory() {
    final selfBox = context.findRenderObject() as RenderBox?;
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

  void _scrollToCategory(ProductCategory category) {
    final ctx = _sectionKeys[category]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignment: 0,
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
    final categories = _categoriesShown;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _filterAndCategoryBar(categories),
        const SizedBox(height: 10),
        Expanded(
          child: categories.isEmpty
              ? _emptyState()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth =
                        (constraints.maxWidth - _horizontalPadding * 2 - _gridSpacing) / 2;
                    return CustomScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      slivers: [
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
                        // (Positioned в HomeScreen) и нижнюю навигацию, чтобы
                        // последний ряд карточек не оказался под ними.
                        const SliverToBoxAdapter(child: SizedBox(height: 90)),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _filterAndCategoryBar(List<ProductCategory> categories) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
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
