#!/usr/bin/env bash
# apply_fixes.sh — фиксы Главной (шапка/scroll-spy/шрифты) + новая вкладка
# "Акции и спецпредложения" вместо "Избранное" (оно осталось доступно
# через меню профиля на Главной).
#
# БАЗА патчей — main после мёржа предыдущего набора (сначала "витрина по
# категориям + фильтр + веб-заглушка карты", затем удаление
# test/widget_test.dart). Если до этого уже накатывали более ранний
# apply_fixes.sh с "Популярное уезжает вверх..." — он тоже входит сюда
# заново (полный патч на home_screen.dart), поэтому этот скрипт СНАЧАЛА
# проверяет, не применён ли он уже (тогда — SKIP, ничего не сломает),
# и только потом применяет.
#
# Использование:
#   1) Положите файл в корень Flutter-проекта (где pubspec.yaml и папка lib/).
#   2) cd в корень проекта.
#   3) bash apply_fixes.sh
#
# Что чинит (баги с прошлого скриншота):
#   1) home_screen.dart — HomeHeader вынесен из CustomScrollView, теперь
#      всегда на месте (раньше уезжал вместе с "Популярное", и прилипшая
#      панель категорий утыкалась в статус-бар при долгом скролле).
#      Добавлен cacheExtent — тап по ещё не проскроленной категории не
#      находил её GlobalKey/RenderBox (ленивая сборка sliver-списков) и
#      молча ничего не делал.
#   2) popular_section.dart — шрифт названия/цены увеличен, карточка
#      чуть крупнее.
#   3) product_card.dart, app_theme.dart, catalog_screen.dart,
#      favorite_screen.dart — карточки товаров без белой подложки (фото
#      и текст на фоне экрана), крупнее шрифт названия/цены — на Главной,
#      в Каталоге и в Избранном одновременно (общий виджет ProductCard).
#
# Что добавляет:
#   4) lib/features/promotions/ — НОВЫЕ файлы: модель Promotion (баннер +
#      список товаров) и экран PromotionsScreen — баннеры на всю ширину
#      экрана, горизонтальный свайп (PageView), под текущим баннером —
#      ассортимент именно этой акции.
#   5) bottom_nav_bar.dart, main_screen.dart — вкладка "Избранное" в
#      нижней навигации заменена на "Акции"; само Избранное осталось
#      доступно через меню профиля на Главной (как и было).
#
# Патчи — unified diff (git apply -p1). Новые файлы просто создаются
# (с проверкой, что не перезаписывают существующие).

set -e

if [ ! -d "lib" ]; then
  echo "Ошибка: папка lib/ не найдена. Запустите скрипт из корня Flutter-проекта." >&2
  exit 1
fi

TMP_PATCH_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_PATCH_DIR"' EXIT

apply_one() {
  local label="$1"
  local patch="$2"

  if git apply --check "$patch" 2>/dev/null; then
    git apply "$patch"
    echo "OK    $label"
  elif git apply --check --reverse "$patch" 2>/dev/null; then
    echo "SKIP  $label — патч уже применён ранее"
  else
    echo "SKIP  $label — не применился чисто (файл отличается от ожидаемого)." >&2
    echo "      Патч сохранён здесь для ручного разбора: /tmp/$(basename "$patch")" >&2
    cp "$patch" "/tmp/$(basename "$patch")"
  fi
}

create_file_if_absent() {
  local path="$1"
  local label="$2"
  local content_var="$3"
  if [ -f "$path" ]; then
    echo "SKIP  $label — файл уже существует, не трогаю"
  else
    mkdir -p "$(dirname "$path")"
    printf '%s\n' "${!content_var}" > "$path"
    echo "OK    $label — создан"
  fi
}

PATCH_1="$TMP_PATCH_DIR/patch_1.diff"
cat > "$PATCH_1" << 'PATCH_EOF_1'
diff --git a/lib/features/home/screens/home_screen.dart b/lib/features/home/screens/home_screen.dart
index e591cd3..997949e 100644
--- a/lib/features/home/screens/home_screen.dart
+++ b/lib/features/home/screens/home_screen.dart
@@ -1,45 +1,165 @@
 import 'package:flutter/material.dart';
+import 'package:google_fonts/google_fonts.dart';
 import 'package:provider/provider.dart';
 
+import '../../../data/mock_products.dart';
+import '../../../models/product.dart';
 import '../../../providers/cart_provider.dart';
 import '../../../screens/cart_screen.dart';
+import '../../../screens/product_detail_screen.dart';
+import '../../../theme/app_theme.dart';
 import '../../../widgets/cart_summary_bar.dart';
+import '../../../widgets/product_card.dart';
+import '../models/home_filter_state.dart';
+import '../widgets/home_filter_sheet.dart';
 import '../widgets/home_header.dart';
 import '../widgets/popular_section.dart';
-import '../widgets/showcase_section.dart';
 
-/// Главная.
+/// Главная — единый CustomScrollView под шапкой (HomeHeader вынесен
+/// отдельно и всегда на месте, не часть скролла). "Популярное" уезжает
+/// вверх вместе с остальным контентом, а панель "Фильтр" + категории —
+/// единственное, что прилипает к верху этой области (SliverPersistentHeader,
+/// pinned: true), заняв ровно то место, откуда уехало "Популярное". Так
+/// был устроен и референс, который прислали на проверку.
 ///
-/// "Популярное" (горизонтальный скролл) — сразу под шапкой. Ниже —
-/// панель "Фильтр" + категории и сама витрина "Сегодня на витрине",
-/// сгруппированная по категориям — вместе они занимают всё оставшееся
-/// место до нижней навигации (Expanded), см. ShowcaseSection: там же
-/// логика scroll-spy (чипы категорий синхронизированы со скроллом) и
-/// модалка "Фильтр".
+/// Товары сгруппированы по категориям (заголовок раздела + сетка 2
+/// колонки). Scroll-spy работает в обе стороны: при прокрутке активный
+/// чип переключается на категорию, чей раздел сейчас под прилипшей
+/// панелью; тап по чипу прокручивает список так, чтобы раздел этой
+/// категории оказался сразу под панелью (не под шапкой, а именно под
+/// прилипшей панелью — see _scrollToCategory).
 ///
-/// Экран НЕ прокручивается целиком — прокручивается только сама витрина
-/// внутри своего Expanded. Высота этой области ВСЕГДА постоянна и не
-/// зависит от корзины — ни Padding, ни доля Expanded никогда не меняются
-/// из-за появления/исчезновения плашки корзины. Именно смена этой высоты
-/// раньше вызывала "прыжки"/"пустую часть экрана" при добавлении товара
-/// во время скролла.
-///
-/// Плашка "Перейти в корзину" (CartSummaryBar) — не часть обычного потока
-/// Column, а отдельный слой поверх экрана (Positioned внутри Stack),
-/// прижатый к низу и наложенный на витрину. Она не участвует в расчёте
-/// размеров остального контента вообще, поэтому ничего не сжимает.
-class HomeScreen extends StatelessWidget {
+/// Плашка "Перейти в корзину" (CartSummaryBar) — отдельный слой поверх
+/// всего (Positioned внутри Stack), не участвует в разметке скролла.
+class HomeScreen extends StatefulWidget {
   const HomeScreen({super.key});
 
+  @override
+  State<HomeScreen> createState() => _HomeScreenState();
+}
+
+class _HomeScreenState extends State<HomeScreen> {
+  static const double _horizontalPadding = 18;
+  static const double _gridSpacing = 10;
+  static const double _cardTextBlockHeight = 84;
+
+  // Высота прилипшей панели "Фильтр" + категории. Используется и для
+  // самого SliverPersistentHeader (minExtent/maxExtent), и как опорная
+  // точка в scroll-spy расчётах (см. _spyThreshold/_scrollToCategory) —
+  // при изменении вёрстки панели ниже (_filterAndCategoryBar) не забудьте
+  // поменять и это значение.
+  static const double _pinnedBarHeight = 56;
+  static const double _spyThreshold = _pinnedBarHeight + 12;
+
+  final GlobalKey _viewportKey = GlobalKey();
+  final ScrollController _scrollController = ScrollController();
+  final Map<ProductCategory, GlobalKey> _sectionKeys = {
+    for (final c in ProductCategory.values) c: GlobalKey(),
+  };
+
+  HomeFilterState _filter = const HomeFilterState();
+  ProductCategory? _activeCategory;
+
+  @override
+  void initState() {
+    super.initState();
+    _scrollController.addListener(_updateActiveCategory);
+    WidgetsBinding.instance.addPostFrameCallback((_) => _updateActiveCategory());
+  }
+
+  @override
+  void dispose() {
+    _scrollController.removeListener(_updateActiveCategory);
+    _scrollController.dispose();
+    super.dispose();
+  }
+
+  List<Product> get _visibleProducts =>
+      mockProducts.where((p) => p.inStock && _filter.matches(p)).toList();
+
+  List<ProductCategory> get _categoriesShown {
+    final present = _visibleProducts.map((p) => p.category).toSet();
+    return ProductCategory.values.where(present.contains).toList();
+  }
+
+  List<Product> _productsFor(ProductCategory category) =>
+      _visibleProducts.where((p) => p.category == category).toList();
+
+  void _openProductDetails(BuildContext context, Product product) {
+    Navigator.of(context).push(
+      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
+    );
+  }
+
   void _openCart(BuildContext context) {
     Navigator.of(context).push(
       MaterialPageRoute(builder: (_) => const CartScreen()),
     );
   }
 
+  /// Определяет, заголовок какого раздела сейчас "под панелью" — по
+  /// позиции каждого заголовка относительно самого CustomScrollView
+  /// (см. _viewportKey). Порог — высота прилипшей панели: как только
+  /// заголовок раздела пересекает эту линию, раздел становится активным.
+  void _updateActiveCategory() {
+    final selfBox = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
+    if (selfBox == null || !selfBox.attached) return;
+
+    ProductCategory? best;
+    double bestOffset = double.negativeInfinity;
+    for (final category in _categoriesShown) {
+      final ctx = _sectionKeys[category]?.currentContext;
+      final box = ctx?.findRenderObject() as RenderBox?;
+      if (box == null || !box.attached) continue;
+      final offset = box.localToGlobal(Offset.zero, ancestor: selfBox).dy;
+      if (offset <= _spyThreshold && offset > bestOffset) {
+        bestOffset = offset;
+        best = category;
+      }
+    }
+    best ??= _categoriesShown.isNotEmpty ? _categoriesShown.first : null;
+    if (best != _activeCategory) setState(() => _activeCategory = best);
+  }
+
+  /// Прокручивает список так, чтобы заголовок раздела оказался СРАЗУ ПОД
+  /// прилипшей панелью — простой Scrollable.ensureVisible(alignment: 0)
+  /// тут не подходит: он прижал бы заголовок к самому верху viewport'а,
+  /// то есть ПОД панель (она пришпилена и рисуется поверх), и заголовок
+  /// оказался бы скрыт под ней. Поэтому считаем целевой scroll-offset
+  /// вручную: текущая позиция заголовка минус высота панели.
+  void _scrollToCategory(ProductCategory category) {
+    final ctx = _sectionKeys[category]?.currentContext;
+    final box = ctx?.findRenderObject() as RenderBox?;
+    final selfBox = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
+    if (box == null || selfBox == null || !_scrollController.hasClients) return;
+
+    final targetLocalY = box.localToGlobal(Offset.zero, ancestor: selfBox).dy;
+    final delta = targetLocalY - _pinnedBarHeight;
+    final targetOffset = (_scrollController.offset + delta).clamp(
+      _scrollController.position.minScrollExtent,
+      _scrollController.position.maxScrollExtent,
+    );
+    _scrollController.animateTo(
+      targetOffset,
+      duration: const Duration(milliseconds: 300),
+      curve: Curves.easeOut,
+    );
+  }
+
+  Future<void> _openFilter() async {
+    final result = await showHomeFilterSheet(context, current: _filter);
+    if (result == null) return;
+    setState(() {
+      _filter = result;
+      _activeCategory = null;
+    });
+    WidgetsBinding.instance.addPostFrameCallback((_) => _updateActiveCategory());
+  }
+
   @override
   Widget build(BuildContext context) {
     final cart = context.watch<CartProvider>();
+    final categories = _categoriesShown;
 
     return SafeArea(
       top: false,
@@ -47,16 +167,102 @@ class HomeScreen extends StatelessWidget {
       child: Stack(
         children: [
           Column(
-            crossAxisAlignment: CrossAxisAlignment.start,
             children: [
+              // HomeHeader теперь ВСЕГДА на месте — не часть скролла.
+              // Раньше он был первым sliver'ом внутри CustomScrollView и
+              // уезжал вверх вместе с "Популярное"; при прокрутке до конца
+              // прилипшая панель категорий утыкалась прямо в статус-бар,
+              // потому что ничего больше не резервировало это место сверху.
+              // Теперь прокручивается только область НИЖЕ шапки (Expanded).
               const HomeHeader(),
-              const SizedBox(height: 12),
-              const Padding(
-                padding: EdgeInsets.symmetric(horizontal: 18),
-                child: PopularSection(),
+              Expanded(
+                child: LayoutBuilder(
+                  builder: (context, constraints) {
+                    final itemWidth =
+                        (constraints.maxWidth - _horizontalPadding * 2 - _gridSpacing) / 2;
+                    return CustomScrollView(
+                      key: _viewportKey,
+                      controller: _scrollController,
+                      physics: const BouncingScrollPhysics(),
+                      // Без большого cacheExtent Flutter лениво строит только
+                      // sliver-элементы рядом с видимой областью — тап по
+                      // ещё не проскроленной категории не находил её
+                      // GlobalKey/RenderBox (оба ещё не существовали) и
+                      // молча ничего не делал. Запаса с лихвой хватает на
+                      // весь список демо-товаров; при заметном росте
+                      // каталога лучше считать смещения разделов
+                      // аналитически, а не увеличивать это число дальше.
+                      cacheExtent: 4000,
+                      slivers: [
+                        const SliverToBoxAdapter(child: SizedBox(height: 12)),
+                        const SliverToBoxAdapter(
+                          child: Padding(
+                            padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
+                            child: PopularSection(),
+                          ),
+                        ),
+                        const SliverToBoxAdapter(child: SizedBox(height: 14)),
+                        SliverPersistentHeader(
+                          pinned: true,
+                          delegate: _CategoryBarDelegate(
+                            height: _pinnedBarHeight,
+                            child: _filterAndCategoryBar(categories),
+                          ),
+                        ),
+                        const SliverToBoxAdapter(child: SizedBox(height: 10)),
+                        if (categories.isEmpty)
+                          SliverFillRemaining(hasScrollBody: false, child: _emptyState())
+                        else ...[
+                          for (final category in categories) ...[
+                            SliverToBoxAdapter(
+                              key: _sectionKeys[category],
+                              child: Padding(
+                                padding: const EdgeInsets.fromLTRB(
+                                  _horizontalPadding, 4, _horizontalPadding, 8,
+                                ),
+                                child: Text(
+                                  category.label,
+                                  style: GoogleFonts.alice(
+                                    fontSize: 16,
+                                    fontWeight: FontWeight.w700,
+                                    color: AppColors.textPrimary,
+                                  ),
+                                ),
+                              ),
+                            ),
+                            Builder(builder: (context) {
+                              final products = _productsFor(category);
+                              return SliverPadding(
+                                padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
+                                sliver: SliverGrid(
+                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
+                                    crossAxisCount: 2,
+                                    mainAxisSpacing: _gridSpacing,
+                                    crossAxisSpacing: _gridSpacing,
+                                    mainAxisExtent: itemWidth + _cardTextBlockHeight,
+                                  ),
+                                  delegate: SliverChildBuilderDelegate(
+                                    (context, index) => ProductCard(
+                                      product: products[index],
+                                      onOpenDetails: (p) => _openProductDetails(context, p),
+                                    ),
+                                    childCount: products.length,
+                                  ),
+                                ),
+                              );
+                            }),
+                            const SliverToBoxAdapter(child: SizedBox(height: 14)),
+                          ],
+                          // Запас снизу — под плавающую плашку "Перейти в
+                          // корзину" и нижнюю навигацию, чтобы последний
+                          // ряд карточек не оказался под ними.
+                          const SliverToBoxAdapter(child: SizedBox(height: 90)),
+                        ],
+                      ],
+                    );
+                  },
+                ),
               ),
-              const SizedBox(height: 14),
-              const Expanded(child: ShowcaseSection()),
             ],
           ),
           if (!cart.isEmpty)
@@ -74,4 +280,145 @@ class HomeScreen extends StatelessWidget {
       ),
     );
   }
+
+  Widget _filterAndCategoryBar(List<ProductCategory> categories) {
+    return Container(
+      color: AppColors.background,
+      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
+      alignment: Alignment.centerLeft,
+      child: SizedBox(
+        height: 40,
+        child: ListView(
+          scrollDirection: Axis.horizontal,
+          physics: const BouncingScrollPhysics(),
+          children: [
+            _FilterPill(active: _filter.isActive, onTap: _openFilter),
+            const SizedBox(width: 8),
+            for (final category in categories) ...[
+              _CategoryChip(
+                label: category.label,
+                selected: _activeCategory == category,
+                onTap: () => _scrollToCategory(category),
+              ),
+              const SizedBox(width: 8),
+            ],
+          ],
+        ),
+      ),
+    );
+  }
+
+  Widget _emptyState() => Center(
+    child: Padding(
+      padding: const EdgeInsets.symmetric(horizontal: 40),
+      child: Column(
+        mainAxisSize: MainAxisSize.min,
+        children: [
+          const Icon(Icons.search_off_rounded, size: 36, color: AppColors.textSecondary),
+          const SizedBox(height: 10),
+          Text(
+            'Ничего не найдено по выбранным фильтрам',
+            textAlign: TextAlign.center,
+            style: AppTextStyles.rowLabelMuted,
+          ),
+          const SizedBox(height: 12),
+          TextButton(
+            onPressed: () => setState(() => _filter = const HomeFilterState()),
+            child: const Text('Сбросить фильтр'),
+          ),
+        ],
+      ),
+    ),
+  );
+}
+
+/// Прилипшая панель "Фильтр" + категории. Занимает ровно то место, откуда
+/// "уезжает" вверх блок "Популярное" — непрозрачный фон обязателен, иначе
+/// сквозь панель будет просвечивать прокручивающийся контент под ней.
+class _CategoryBarDelegate extends SliverPersistentHeaderDelegate {
+  final double height;
+  final Widget child;
+
+  const _CategoryBarDelegate({required this.height, required this.child});
+
+  @override
+  double get minExtent => height;
+
+  @override
+  double get maxExtent => height;
+
+  @override
+  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;
+
+  @override
+  bool shouldRebuild(covariant _CategoryBarDelegate oldDelegate) =>
+      height != oldDelegate.height || child != oldDelegate.child;
+}
+
+class _FilterPill extends StatelessWidget {
+  final bool active;
+  final VoidCallback onTap;
+  const _FilterPill({required this.active, required this.onTap});
+
+  @override
+  Widget build(BuildContext context) {
+    return GestureDetector(
+      onTap: onTap,
+      child: Container(
+        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
+        decoration: BoxDecoration(
+          color: active ? AppColors.primaryBrown : Colors.white,
+          borderRadius: BorderRadius.circular(12),
+          border: Border.all(color: active ? AppColors.primaryBrown : AppColors.divider),
+        ),
+        child: Row(
+          mainAxisSize: MainAxisSize.min,
+          children: [
+            Icon(Icons.tune_rounded, size: 16, color: active ? Colors.white : AppColors.primaryBrown),
+            const SizedBox(width: 6),
+            Text(
+              'Фильтр',
+              style: TextStyle(
+                color: active ? Colors.white : AppColors.primaryBrown,
+                fontWeight: FontWeight.w700,
+                fontSize: 13,
+              ),
+            ),
+          ],
+        ),
+      ),
+    );
+  }
+}
+
+class _CategoryChip extends StatelessWidget {
+  final String label;
+  final bool selected;
+  final VoidCallback onTap;
+  const _CategoryChip({required this.label, required this.selected, required this.onTap});
+
+  @override
+  Widget build(BuildContext context) {
+    return GestureDetector(
+      onTap: onTap,
+      child: AnimatedContainer(
+        duration: const Duration(milliseconds: 150),
+        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
+        decoration: BoxDecoration(
+          color: selected ? AppColors.primaryBrown : Colors.white,
+          borderRadius: BorderRadius.circular(12),
+          border: Border.all(color: selected ? AppColors.primaryBrown : AppColors.divider),
+        ),
+        alignment: Alignment.center,
+        child: Text(
+          label,
+          style: TextStyle(
+            color: selected ? Colors.white : AppColors.textPrimary,
+            fontWeight: FontWeight.w600,
+            fontSize: 13,
+          ),
+        ),
+      ),
+    );
+  }
 }
PATCH_EOF_1
apply_one "home_screen.dart (шапка фиксирована, cacheExtent, прилипающая панель категорий)" "$PATCH_1"

PATCH_2="$TMP_PATCH_DIR/patch_2.diff"
cat > "$PATCH_2" << 'PATCH_EOF_2'
diff --git a/lib/screens/catalog_screen.dart b/lib/screens/catalog_screen.dart
index b01e964..67bf09e 100644
--- a/lib/screens/catalog_screen.dart
+++ b/lib/screens/catalog_screen.dart
@@ -91,7 +91,7 @@ class _CatalogScreenState extends State<CatalogScreen> {
   /// + строка цены/кнопки. Считается явно, а не через childAspectRatio,
   /// чтобы карточка никогда не переполнялась (RenderFlex overflow) —
   /// независимо от плотности пикселей и мелких отличий шрифта на устройстве.
-  static const double _cardTextBlockHeight = 80;
+  static const double _cardTextBlockHeight = 84;
   static const double _gridCrossAxisSpacing = 10;
   static const double _gridMainAxisSpacing = 10;
   static const int _gridCrossAxisCount = 3;
PATCH_EOF_2
apply_one "catalog_screen.dart (_cardTextBlockHeight под увеличенный шрифт)" "$PATCH_2"

PATCH_3="$TMP_PATCH_DIR/patch_3.diff"
cat > "$PATCH_3" << 'PATCH_EOF_3'
diff --git a/lib/screens/favorite_screen.dart b/lib/screens/favorite_screen.dart
index 8863a6b..41a7d31 100644
--- a/lib/screens/favorite_screen.dart
+++ b/lib/screens/favorite_screen.dart
@@ -20,7 +20,7 @@ class FavoriteScreen extends StatelessWidget {
     );
   }
 
-  static const double _cardTextBlockHeight = 80;
+  static const double _cardTextBlockHeight = 84;
   static const double _gridSpacing = 10;
   static const int _crossAxisCount = 3;
 
PATCH_EOF_3
apply_one "favorite_screen.dart (_cardTextBlockHeight под увеличенный шрифт)" "$PATCH_3"

PATCH_4="$TMP_PATCH_DIR/patch_4.diff"
cat > "$PATCH_4" << 'PATCH_EOF_4'
diff --git a/lib/theme/app_theme.dart b/lib/theme/app_theme.dart
index 31122a1..66a7a56 100644
--- a/lib/theme/app_theme.dart
+++ b/lib/theme/app_theme.dart
@@ -92,14 +92,14 @@ class AppTextStyles {
   );
 
   static TextStyle productName = GoogleFonts.jost(
-    fontSize: 13,
-    fontWeight: FontWeight.w400,
+    fontSize: 15,
+    fontWeight: FontWeight.w500,
     color: AppColors.textPrimary,
     height: 1.15,
   );
 
   static TextStyle productPrice = GoogleFonts.jost(
-    fontSize: 15,
+    fontSize: 17,
     fontWeight: FontWeight.w700,
     color: AppColors.textPrimary,
   );
PATCH_EOF_4
apply_one "app_theme.dart (шрифты названия/цены товара крупнее)" "$PATCH_4"

PATCH_5="$TMP_PATCH_DIR/patch_5.diff"
cat > "$PATCH_5" << 'PATCH_EOF_5'
diff --git a/lib/widgets/product_card.dart b/lib/widgets/product_card.dart
index a0321f6..9d807a0 100644
--- a/lib/widgets/product_card.dart
+++ b/lib/widgets/product_card.dart
@@ -14,8 +14,7 @@ class ProductCard extends StatelessWidget {
   final ValueChanged<Product> onOpenDetails;
 
   /// Масштаб степпера количества (кнопка "+" / "−N+"). По умолчанию 1.0 —
-  /// как в «Каталоге» и «Избранном». На Главной, в блоке «Сегодня на
-  /// витрине», используется 1.7 — там по вашей просьбе кнопки крупнее.
+  /// используется одинаково на Главной, в «Каталоге» и в «Избранном».
   final double controlScale;
 
   const ProductCard({
@@ -46,23 +45,22 @@ class ProductCard extends StatelessWidget {
     // увеличенный степпер не обрезался фиксированной высотой строки.
     final priceRowHeight = controlScale <= 1.0 ? 26.0 : 26.0 * controlScale + 6.0;
 
-    return Container(
-      decoration: BoxDecoration(
-        color: AppColors.cardBackground,
-        borderRadius: BorderRadius.circular(16),
-        boxShadow: const [
-          BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 3)),
-        ],
-      ),
-      clipBehavior: Clip.antiAlias,
-      child: Column(
-        crossAxisAlignment: CrossAxisAlignment.start,
-        children: [
-          // Изображение + бейдж + избранное. Только эта область открывает
-          // карточку товара, чтобы не конфликтовать с нажатием на сердечко.
-          GestureDetector(
-            onTap: () => onOpenDetails(product),
-            behavior: HitTestBehavior.opaque,
+    // Карточка больше не в белой "плашке" с тенью — фото (со скруглёнными
+    // углами) и текст лежат прямо на фоне экрана, как в референсе.
+    // Высота текстового блока ниже подобрана под увеличенный шрифт
+    // (см. AppTextStyles.productName/productPrice) — при дальнейшем
+    // изменении шрифтов не забудьте обновить _cardTextBlockHeight в
+    // showcase_section.dart и catalog_screen.dart (см. комментарий там же).
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.start,
+      children: [
+        // Изображение + бейдж + избранное. Только эта область открывает
+        // карточку товара, чтобы не конфликтовать с нажатием на сердечко.
+        GestureDetector(
+          onTap: () => onOpenDetails(product),
+          behavior: HitTestBehavior.opaque,
+          child: ClipRRect(
+            borderRadius: BorderRadius.circular(16),
             child: AspectRatio(
               aspectRatio: 1,
               child: Stack(
@@ -113,90 +111,91 @@ class ProductCard extends StatelessWidget {
               ),
             ),
           ),
-          Padding(
-            // Внимание: сумма высот этого блока (паддинги + название + цена)
-            // рассчитана под _cardTextBlockHeight = 80 в catalog_screen.dart.
-            // При изменении паддингов/шрифтов здесь — обновите константу там же.
-            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
-            child: Column(
-              crossAxisAlignment: CrossAxisAlignment.start,
-              children: [
-                GestureDetector(
-                  onTap: () => onOpenDetails(product),
-                  behavior: HitTestBehavior.opaque,
-                  child: SizedBox(
-                    height: 30,
-                    child: Text(
-                      product.name,
-                      style: AppTextStyles.productName,
-                      maxLines: 2,
-                      overflow: TextOverflow.ellipsis,
-                    ),
+        ),
+        Padding(
+          // Внимание: сумма высот этого блока (паддинги + название + цена)
+          // рассчитана под _cardTextBlockHeight в showcase_section.dart,
+          // catalog_screen.dart и favorite_screen.dart. При изменении
+          // паддингов/шрифтов здесь — обновите константу везде.
+          padding: const EdgeInsets.fromLTRB(2, 8, 2, 4),
+          child: Column(
+            crossAxisAlignment: CrossAxisAlignment.start,
+            children: [
+              GestureDetector(
+                onTap: () => onOpenDetails(product),
+                behavior: HitTestBehavior.opaque,
+                child: SizedBox(
+                  height: 36,
+                  child: Text(
+                    product.name,
+                    style: AppTextStyles.productName,
+                    maxLines: 2,
+                    overflow: TextOverflow.ellipsis,
                   ),
                 ),
-                const SizedBox(height: 4),
-                SizedBox(
-                  height: priceRowHeight,
-                  child: !product.inStock
-                      ? SizedBox(
-                          width: double.infinity,
-                          child: _PreorderButton(
-                            controlScale: controlScale,
-                            onTap: () {
-                              Navigator.of(context).push(
-                                MaterialPageRoute(
-                                  builder: (_) => PreorderScreen(product: product),
-                                ),
-                              );
-                            },
-                          ),
-                        )
-                      : quantity == 0
-                          ? Row(
-                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
-                              children: [
-                                Flexible(
-                                  child: Text(
-                                    formatPrice(product.price),
-                                    style: AppTextStyles.productPrice,
-                                    maxLines: 1,
-                                    softWrap: false,
-                                    overflow: TextOverflow.ellipsis,
-                                  ),
-                                ),
-                                _RoundIconButton(
-                                  icon: Icons.add,
-                                  controlScale: controlScale,
-                                  onTap: () => cart.add(product),
-                                ),
-                              ],
-                            )
-                          : Row(
-                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
-                              children: [
-                                Flexible(
-                                  child: Text(
-                                    formatPrice(product.price),
-                                    style: AppTextStyles.productPrice,
-                                    maxLines: 1,
-                                    softWrap: false,
-                                    overflow: TextOverflow.ellipsis,
-                                  ),
+              ),
+              const SizedBox(height: 5),
+              SizedBox(
+                height: priceRowHeight,
+                child: !product.inStock
+                    ? SizedBox(
+                        width: double.infinity,
+                        child: _PreorderButton(
+                          controlScale: controlScale,
+                          onTap: () {
+                            Navigator.of(context).push(
+                              MaterialPageRoute(
+                                builder: (_) => PreorderScreen(product: product),
+                              ),
+                            );
+                          },
+                        ),
+                      )
+                    : quantity == 0
+                        ? Row(
+                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
+                            children: [
+                              Flexible(
+                                child: Text(
+                                  formatPrice(product.price),
+                                  style: AppTextStyles.productPrice,
+                                  maxLines: 1,
+                                  softWrap: false,
+                                  overflow: TextOverflow.ellipsis,
                                 ),
-                                _QuantityStepper(
-                                  quantity: quantity,
-                                  controlScale: controlScale,
-                                  onDecrement: () => cart.decrement(product),
-                                  onIncrement: () => cart.increment(product),
+                              ),
+                              _RoundIconButton(
+                                icon: Icons.add,
+                                controlScale: controlScale,
+                                onTap: () => cart.add(product),
+                              ),
+                            ],
+                          )
+                        : Row(
+                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
+                            children: [
+                              Flexible(
+                                child: Text(
+                                  formatPrice(product.price),
+                                  style: AppTextStyles.productPrice,
+                                  maxLines: 1,
+                                  softWrap: false,
+                                  overflow: TextOverflow.ellipsis,
                                 ),
-                              ],
-                            ),
-                ),
-              ],
-            ),
+                              ),
+                              _QuantityStepper(
+                                quantity: quantity,
+                                controlScale: controlScale,
+                                onDecrement: () => cart.decrement(product),
+                                onIncrement: () => cart.increment(product),
+                              ),
+                            ],
+                          ),
+              ),
+            ],
           ),
-        ],
-      ),
+        ),
+      ],
     );
   }
 }
PATCH_EOF_5
apply_one "product_card.dart (без белой подложки, фото+текст на фоне экрана)" "$PATCH_5"

PATCH_6="$TMP_PATCH_DIR/patch_6.diff"
cat > "$PATCH_6" << 'PATCH_EOF_6'
diff --git a/lib/features/home/widgets/popular_section.dart b/lib/features/home/widgets/popular_section.dart
index 328ce6c..0854013 100644
--- a/lib/features/home/widgets/popular_section.dart
+++ b/lib/features/home/widgets/popular_section.dart
@@ -62,7 +62,7 @@ class PopularSection extends StatelessWidget {
         const SizedBox(height: 8),
 
         SizedBox(
-          height: 114,
+          height: 128,
           child: ListView.separated(
             scrollDirection: Axis.horizontal,
             physics: const BouncingScrollPhysics(),
@@ -91,15 +91,15 @@ class _PopularItem extends StatelessWidget {
       onTap: onTap,
       behavior: HitTestBehavior.opaque,
       child: SizedBox(
-        width: 76,
+        width: 84,
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             ClipRRect(
               borderRadius: BorderRadius.circular(12),
               child: SizedBox(
-                width: 76,
-                height: 76,
+                width: 84,
+                height: 84,
                 child: Image.asset(
                   product.imageUrl,
                   fit: BoxFit.cover,
@@ -111,13 +111,13 @@ class _PopularItem extends StatelessWidget {
                 ),
               ),
             ),
-            const SizedBox(height: 5),
+            const SizedBox(height: 6),
             Text(
               product.name,
               maxLines: 1,
               overflow: TextOverflow.ellipsis,
               style: const TextStyle(
-                fontSize: 10.5,
+                fontSize: 12.5,
                 fontWeight: FontWeight.w600,
                 color: AppColors.textPrimary,
               ),
@@ -125,7 +125,7 @@ class _PopularItem extends StatelessWidget {
             Text(
               product.inStock ? "${product.price} ₽" : "Под заказ",
               style: const TextStyle(
-                fontSize: 10,
+                fontSize: 12,
                 fontWeight: FontWeight.w600,
                 color: AppColors.textSecondary,
               ),
PATCH_EOF_6
apply_one "popular_section.dart (крупнее шрифт и карточки)" "$PATCH_6"

PATCH_7="$TMP_PATCH_DIR/patch_7.diff"
cat > "$PATCH_7" << 'PATCH_EOF_7'
diff --git a/lib/features/home/widgets/bottom_nav_bar.dart b/lib/features/home/widgets/bottom_nav_bar.dart
index 042e15c..83a6559 100644
--- a/lib/features/home/widgets/bottom_nav_bar.dart
+++ b/lib/features/home/widgets/bottom_nav_bar.dart
@@ -38,8 +38,8 @@ class PremiumBottomNavBar extends StatelessWidget {
           _item(icon: 'assets/icons/catalog.svg', label: 'Каталог', index: 1),
           _item(icon: 'assets/icons/premium.svg', label: 'Карта', index: 2),
           _item(
-            icon: 'assets/icons/favorite.svg',
-            label: 'Избранное',
+            icon: 'assets/icons/discount.svg',
+            label: 'Акции',
             index: 3,
           ),
           _item(icon: 'assets/icons/add.svg', label: 'Корзина', index: 4),
PATCH_EOF_7
apply_one "bottom_nav_bar.dart (вкладка Акции вместо Избранное)" "$PATCH_7"

PATCH_8="$TMP_PATCH_DIR/patch_8.diff"
cat > "$PATCH_8" << 'PATCH_EOF_8'
diff --git a/lib/screens/main_screen.dart b/lib/screens/main_screen.dart
index 7089ac6..a538925 100644
--- a/lib/screens/main_screen.dart
+++ b/lib/screens/main_screen.dart
@@ -2,10 +2,10 @@ import 'package:flutter/material.dart';
 import 'package:provider/provider.dart';
 
 import '../features/home/screens/home_screen.dart';
+import '../features/promotions/screens/promotions_screen.dart';
 import '../providers/tab_navigation_controller.dart';
 import 'catalog_screen.dart';
 import 'loyalty_screen.dart';
-import 'favorite_screen.dart';
 import 'cart_screen.dart';
 
 import '../features/home/widgets/bottom_nav_bar.dart';
@@ -30,7 +30,7 @@ class MainScreen extends StatelessWidget {
           HomeScreen(),
           CatalogScreen(),
           LoyaltyScreen(),
-          FavoriteScreen(),
+          PromotionsScreen(),
           CartScreen(),
         ],
       ),
PATCH_EOF_8
apply_one "main_screen.dart (подключение PromotionsScreen)" "$PATCH_8"

NEWFILE_1_CONTENT=$(cat << 'NEWFILE_EOF_1'
import 'package:flutter/material.dart';

/// Одна акция/спецпредложение — баннер + список товаров-участников
/// (id из mockProducts, тот же каталог, что и везде в приложении).
///
/// Пока баннер рисуется цветом/градиентом + иконкой, а не фотографией —
/// специальных промо-фото пока нет в assets, а плейсхолдер поверх чужого
/// товарного фото выглядел бы недостоверно. Когда появятся баннерные
/// изображения — добавьте поле imageAsset и переключите _PromoBanner на
/// Image.asset, ничего в остальной логике экрана менять не придётся.
class Promotion {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> productIds;

  const Promotion({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.productIds,
  });
}

const mockPromotions = <Promotion>[
  Promotion(
    id: 'back_to_school',
    title: 'Скоро в школу',
    subtitle: 'Сладкий стол для линейки и первых дней учёбы',
    icon: Icons.school_outlined,
    color: Color(0xFF6B7FB8),
    productIds: ['napoleon_cake', 'cheesecake_cherry', 'eclair_chocolate', 'dacquoise'],
  ),
  Promotion(
    id: 'ciabatta_discount',
    title: 'Скидка на чиабатту −15%',
    subtitle: 'Только на этой неделе',
    icon: Icons.local_offer_outlined,
    color: Color(0xFFB5804A),
    productIds: ['ciabatta'],
  ),
  Promotion(
    id: 'weekend_breakfast',
    title: 'Выходные с завтраком',
    subtitle: 'Свежая выпечка к утреннему кофе',
    icon: Icons.free_breakfast_outlined,
    color: Color(0xFF7A9B76),
    productIds: ['croissant_butter', 'brioche', 'grain_bun'],
  ),
];
NEWFILE_EOF_1
)
create_file_if_absent "lib/features/promotions/models/promotion.dart" "promotion.dart" NEWFILE_1_CONTENT

NEWFILE_2_CONTENT=$(cat << 'NEWFILE_EOF_2'
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
            padding: const EdgeInsets.fromLTRB(_horizontalPadding, 16, _horizontalPadding, 4),
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
                padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
                child: _PromoBanner(promotion: mockPromotions[i]),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _DotsIndicator(count: mockPromotions.length, activeIndex: _activeIndex),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
            child: Text(
              'Ассортимент к акции',
              style: AppTextStyles.rowLabel.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: products.isEmpty
                ? _emptyState()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth =
                          (constraints.maxWidth - _horizontalPadding * 2 - _gridSpacing) / 2;
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          _horizontalPadding, 0, _horizontalPadding, 90,
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
NEWFILE_EOF_2
)
create_file_if_absent "lib/features/promotions/screens/promotions_screen.dart" "promotions_screen.dart" NEWFILE_2_CONTENT

OLD_FILE="lib/features/home/widgets/showcase_section.dart"
if [ -f "$OLD_FILE" ]; then
  rm "$OLD_FILE"
  echo "OK    showcase_section.dart — удалён (логика перенесена в home_screen.dart)"
else
  echo "SKIP  showcase_section.dart — уже отсутствует"
fi

echo ""
echo "Готово. Проверьте: flutter analyze, затем пересоберите проект."
