#!/usr/bin/env bash
# apply_fixes.sh — v4. Патчит ТОЛЬКО home_screen.dart и showcase_section.dart,
# поверх состояния, в котором сейчас ваш проект (fresh lib_3.zip + прошлый
# apply_fixes.sh уже применены). Остальные фиксы (product_card.dart,
# order_confirmation_screen.dart, loyalty_screen.dart, диалог в
# delivery_address_screen.dart) не трогает — они уже стоят.
#
# Использование:
#   1) Положите файл в корень Flutter-проекта (где pubspec.yaml и папка lib/).
#   2) cd в корень проекта.
#   3) bash apply_fixes.sh
#
# Что меняет в этой версии (v4) — исправляет то, что сломала v3:
#   - "Сегодня на витрине" снова прокручивается САМА (Expanded + свой
#     скролл, без ограничения в 4 карточки) — весь экран больше не
#     прокручивается целиком.
#   - Область витрины теперь ВСЕГДА одного размера — не зависит от
#     корзины вообще (ни Padding, ни доля Expanded не меняются).
#   - Плашка "Перейти в корзину" — отдельный слой (Positioned) поверх
#     экрана, прижат к низу и наложен на "Популярное" (не расталкивает
#     контент, не сжимает витрину).
#
# Патчи — unified diff (git apply -p1). Если файлы уже отличаются от
# ожидаемого состояния, патч не применится чисто — скрипт сообщит и
# ничего не сломает.

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

PATCH_1="$TMP_PATCH_DIR/04_home_screen_v4.patch"
cat > "$PATCH_1" << 'PATCH_EOF_1'
--- a/lib/features/home/screens/home_screen.dart	2026-08-12 00:50:05.340462368 +0000
+++ b/lib/features/home/screens/home_screen.dart	2026-08-12 04:12:08.004022657 +0000
@@ -10,24 +10,18 @@
 
 /// Главная.
 ///
-/// "Сегодня на витрине" (см. ShowcaseSection) теперь фиксированной высоты —
-/// показывает ровно 4 товара, без собственной прокрутки и без Expanded.
-/// Раньше блок был "резиновым" (Expanded, тянул всё свободное место) и при
-/// появлении плашки корзины сжимался — это выглядело как "пустая часть
-/// экрана"/съехавший ряд карточек. Теперь высота витрины не зависит вообще
-/// ни от чего на этом экране.
+/// Экран НЕ прокручивается целиком — прокручивается только сама витрина
+/// "Сегодня на витрине" (см. ShowcaseSection), у неё собственный
+/// вертикальный скролл внутри Expanded. Высота этой области ВСЕГДА
+/// постоянна и не зависит от корзины — ни Padding, ни доля Expanded
+/// никогда не меняются из-за появления/исчезновения плашки корзины.
+/// Именно смена этой высоты раньше вызывала "прыжки"/"пустую часть
+/// экрана" при добавлении товара во время скролла.
 ///
-/// Вся страница ниже шапки — один SingleChildScrollView. Раньше это уже
-/// пробовали и отказались, потому что витрина тогда показывала ВСЕ товары
-/// в наличии и росла бесконечно вместе с ними, утаскивая "Популярное" вниз
-/// за экран. Сейчас витрина ограничена 4 товарами и сама не растёт, так что
-/// обычный вертикальный скролл снова безопасен: он нужен только на случай,
-/// если появившаяся плашка "Перейти в корзину" не помещается по высоте —
-/// тогда экран просто прокручивается на её высоту, ничего не сжимая.
-///
-/// Плашка "Перейти в корзину" (CartSummaryBar) стоит СРАЗУ ПОСЛЕ витрины и
-/// ПЕРЕД "Популярное" — появляется через AnimatedSize и просто отодвигает
-/// "Популярное" вниз, не перекрывая и не сжимая ничего.
+/// Плашка "Перейти в корзину" (CartSummaryBar) — не часть обычного потока
+/// Column, а отдельный слой поверх экрана (Positioned внутри Stack),
+/// прижатый к низу и наложенный на "Популярное". Она не участвует в
+/// расчёте размеров остального контента вообще, поэтому ничего не сжимает.
 class HomeScreen extends StatelessWidget {
   const HomeScreen({super.key});
 
@@ -44,38 +38,39 @@
     return SafeArea(
       top: false,
       bottom: false,
-      child: SingleChildScrollView(
-        child: Column(
-          crossAxisAlignment: CrossAxisAlignment.start,
-          children: [
-            const HomeHeader(),
-            const SizedBox(height: 12),
-            const Padding(
-              padding: EdgeInsets.symmetric(horizontal: 18),
-              child: ShowcaseSection(),
-            ),
-            AnimatedSize(
-              duration: const Duration(milliseconds: 220),
-              curve: Curves.easeOut,
-              alignment: Alignment.topCenter,
-              child: cart.isEmpty
-                  ? const SizedBox(width: double.infinity, height: 6)
-                  : Padding(
-                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
-                      child: CartSummaryBar(
-                        itemsCount: cart.totalCount,
-                        totalSum: cart.totalSum,
-                        onTap: () => _openCart(context),
-                      ),
-                    ),
-            ),
-            const Padding(
-              padding: EdgeInsets.symmetric(horizontal: 18),
-              child: PopularSection(),
+      child: Stack(
+        children: [
+          Column(
+            crossAxisAlignment: CrossAxisAlignment.start,
+            children: [
+              const HomeHeader(),
+              const SizedBox(height: 12),
+              const Expanded(
+                child: Padding(
+                  padding: EdgeInsets.symmetric(horizontal: 18),
+                  child: ShowcaseSection(),
+                ),
+              ),
+              const SizedBox(height: 6),
+              const Padding(
+                padding: EdgeInsets.symmetric(horizontal: 18),
+                child: PopularSection(),
+              ),
+              const SizedBox(height: 8),
+            ],
+          ),
+          if (!cart.isEmpty)
+            Positioned(
+              left: 18,
+              right: 18,
+              bottom: 8,
+              child: CartSummaryBar(
+                itemsCount: cart.totalCount,
+                totalSum: cart.totalSum,
+                onTap: () => _openCart(context),
+              ),
             ),
-            const SizedBox(height: 8),
-          ],
-        ),
+        ],
       ),
     );
   }
PATCH_EOF_1
apply_one "home_screen.dart (Stack + Positioned: плашка слоем поверх Популярное, витрина не сжимается)" "$PATCH_1"

PATCH_2="$TMP_PATCH_DIR/05_showcase_section_v4.patch"
cat > "$PATCH_2" << 'PATCH_EOF_2'
--- a/lib/features/home/widgets/showcase_section.dart	2026-08-12 00:50:05.348530216 +0000
+++ b/lib/features/home/widgets/showcase_section.dart	2026-08-12 04:12:30.628718737 +0000
@@ -7,25 +7,16 @@
 import '../../../theme/app_theme.dart';
 import '../../../widgets/product_card.dart';
 
-/// Блок "Сегодня на витрине". Раньше был "резиновым" (Expanded + свой
-/// внутренний скролл по ВСЕМ товарам в наличии) — из-за этого его высота
-/// зависела от свободного места в родительском Column, и когда снизу
-/// появлялась плашка "Перейти в корзину", это место сокращалось, а сам
-/// блок дополнительно "прыгал" из-за сохранённой прокрутки внутренней
-/// GridView (см. баг с "пустой частью экрана").
-///
-/// Теперь блок показывает фиксированную витрину — [_maxItems] товаров
-/// (2 ряда, как и было визуально всегда), без собственной прокрутки.
-/// Больше товаров — по кнопке "Все" в "Каталог". Высота блока целиком
-/// определяется его содержимым и никогда не меняется от состояния
-/// корзины или чего-либо ещё на экране.
+/// Блок "Сегодня на витрине". Родитель (HomeScreen) даёт ему фиксированную
+/// область через Expanded, и эта область ВСЕГДА одного размера — не
+/// зависит от корзины (см. home_screen.dart). Внутри — все товары в
+/// наличии, с собственной вертикальной прокруткой (видно 2 ряда, дальше —
+/// скроллом). "Все" сверху ведёт в полный "Каталог".
 class ShowcaseSection extends StatelessWidget {
   const ShowcaseSection({super.key});
 
-  static const int _maxItems = 4;
-
   static final List<Product> _highlighted =
-      mockProducts.where((p) => p.inStock).take(_maxItems).toList();
+      mockProducts.where((p) => p.inStock).toList();
 
   static const double _cardTextBlockHeight = 80;
   static const double _gridSpacing = 10;
@@ -40,7 +31,6 @@
   Widget build(BuildContext context) {
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
-      mainAxisSize: MainAxisSize.min,
       children: [
         Row(
           children: [
@@ -83,26 +73,27 @@
           ],
         ),
         const SizedBox(height: 8),
-        LayoutBuilder(
-          builder: (context, constraints) {
-            final itemWidth = (constraints.maxWidth - _gridSpacing) / 2;
-            return GridView.builder(
-              padding: EdgeInsets.zero,
-              shrinkWrap: true,
-              physics: const NeverScrollableScrollPhysics(),
-              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
-                crossAxisCount: 2,
-                mainAxisSpacing: _gridSpacing,
-                crossAxisSpacing: _gridSpacing,
-                mainAxisExtent: itemWidth + _cardTextBlockHeight,
-              ),
-              itemCount: _highlighted.length,
-              itemBuilder: (context, index) => ProductCard(
-                product: _highlighted[index],
-                onOpenDetails: (p) => _openProductDetails(context, p),
-              ),
-            );
-          },
+        Expanded(
+          child: LayoutBuilder(
+            builder: (context, constraints) {
+              final itemWidth = (constraints.maxWidth - _gridSpacing) / 2;
+              return GridView.builder(
+                padding: EdgeInsets.zero,
+                physics: const BouncingScrollPhysics(),
+                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
+                  crossAxisCount: 2,
+                  mainAxisSpacing: _gridSpacing,
+                  crossAxisSpacing: _gridSpacing,
+                  mainAxisExtent: itemWidth + _cardTextBlockHeight,
+                ),
+                itemCount: _highlighted.length,
+                itemBuilder: (context, index) => ProductCard(
+                  product: _highlighted[index],
+                  onOpenDetails: (p) => _openProductDetails(context, p),
+                ),
+              );
+            },
+          ),
         ),
       ],
     );
PATCH_EOF_2
apply_one "showcase_section.dart (витрина снова со своим скроллом, без лимита 4 шт.)" "$PATCH_2"

echo ""
echo "Готово. Проверьте: flutter analyze, затем пересоберите проект."
