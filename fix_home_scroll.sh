#!/bin/bash
set -euo pipefail

# Всласть — исправление поведения Главной:
# 1) HomeHeader фиксируется сверху.
# 2) PopularSection прокручивается и уезжает вверх.
# 3) Filter + Categories становятся pinned сразу под HomeHeader.
# 4) Scroll-spy категорий работает относительно viewport каталога.
#
# Запуск:
#   cd /Users/sukolesnikov/Projects/vslast_premium
#   bash fix_home_scroll.sh
#
# Скрипт делает резервную копию home_screen.dart перед изменением.

PROJECT_DIR="${1:-$(pwd)}"
FILE="$PROJECT_DIR/lib/features/home/screens/home_screen.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Не найден файл:"
  echo "   $FILE"
  echo
  echo "Запустите скрипт из корня проекта vslast_premium"
  echo "или передайте путь к проекту первым аргументом:"
  echo "   bash fix_home_scroll.sh /Users/sukolesnikov/Projects/vslast_premium"
  exit 1
fi

BACKUP="$FILE.before_fixed_scroll.bak"
cp "$FILE" "$BACKUP"

python3 - "$FILE" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

# ---------- 1. Константы ----------
old = """  static const double _horizontalPadding = 18;
  static const double _gridSpacing = 10;
  static const double _cardTextBlockHeight = 84;

  // Высота прилипшей панели "Фильтр" + категории. Используется и для
  // самого SliverPersistentHeader (minExtent/maxExtent), и как опорная
  // точка в scroll-spy расчётах (см. _spyThreshold/_scrollToCategory) —
  // при изменении вёрстки панели ниже (_filterAndCategoryBar) не забудьте
  // поменять и это значение.
  static const double _pinnedBarHeight = 56;
  static const double _spyThreshold = _pinnedBarHeight + 12;
"""

new = """  static const double _horizontalPadding = 18;
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
"""
if old not in text:
    raise SystemExit("ОШИБКА 1: блок констант не найден — файл отличается от ожидаемой версии.")
text = text.replace(old, new, 1)

# ---------- 2. Комментарий класса ----------
old = """/// Главная — единый CustomScrollView (раньше "Популярное" и витрина были
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
"""
new = """/// Главная:
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
"""
if old not in text:
    raise SystemExit("ОШИБКА 2: комментарий HomeScreen не найден.")
text = text.replace(old, new, 1)

# ---------- 3. build(): заменить структуру Stack / CustomScrollView ----------
old = """    return SafeArea(
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
"""
new = """    final headerHeight =
        MediaQuery.of(context).padding.top + _headerPhotoHeight;

    return SafeArea(
      top: false,
      bottom: false,
      child: Stack(
        children: [
          // ВАЖНО: HomeHeader больше НЕ является sliver.
          // Он физически лежит поверх CustomScrollView и поэтому никогда
          // не уезжает при вертикальной прокрутке.
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: HomeHeader(),
          ),

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
                    (constraints.maxWidth - _horizontalPadding * 2 - _gridSpacing) / 2;
                return CustomScrollView(
                  key: _viewportKey,
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    // PopularSection специально НЕ pinned.
                    // Он уезжает вверх при прокрутке.
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
                        child: PopularSection(),
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
                        }),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 14),
                        ),
                      ],

                      // Запас снизу — под плавающую плашку "Перейти в корзину"
                      // и нижнюю навигацию.
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 90),
                      ),
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
"""
if old not in text:
    raise SystemExit("ОШИБКА 3: текущая структура build()/CustomScrollView не найдена.")
text = text.replace(old, new, 1)

# ---------- 4. Обновить комментарий scroll-spy ----------
old = """  /// Определяет, заголовок какого раздела сейчас "под панелью" — по
  /// позиции каждого заголовка относительно самого CustomScrollView
  /// (см. _viewportKey). Порог — высота прилипшей панели: как только
  /// заголовок раздела пересекает эту линию, раздел становится активным.
"""
new = """  /// Определяет, заголовок какого раздела сейчас находится под
  /// pinned CategoryBar.
  ///
  /// ВАЖНО: _viewportKey теперь принадлежит CustomScrollView, который
  /// начинается сразу под постоянным HomeHeader. Поэтому координаты
  /// здесь НЕ нужно дополнительно смещать на высоту HomeHeader.
"""
if old not in text:
    raise SystemExit("ОШИБКА 4: комментарий scroll-spy не найден.")
text = text.replace(old, new, 1)

# ---------- 5. Обновить комментарий scroll-to-category ----------
old = """  /// Прокручивает список так, чтобы заголовок раздела оказался СРАЗУ ПОД
  /// прилипшей панелью — простой Scrollable.ensureVisible(alignment: 0)
  /// тут не подходит: он прижал бы заголовок к самому верху viewport'а,
  /// то есть ПОД панель (она пришпилена и рисуется поверх), и заголовок
  /// оказался бы скрыт под ней. Поэтому считаем целевой scroll-offset
  /// вручную: текущая позиция заголовка минус высота панели.
"""
new = """  /// Прокручивает список так, чтобы заголовок раздела оказался СРАЗУ
  /// ПОД pinned CategoryBar.
  ///
  /// CustomScrollView начинается под постоянным HomeHeader, поэтому
  /// достаточно вычесть только высоту CategoryBar.
"""
if old not in text:
    raise SystemExit("ОШИБКА 5: комментарий scroll-to-category не найден.")
text = text.replace(old, new, 1)

path.write_text(text, encoding="utf-8")
PY

# Форматируем только изменённый файл.
if command -v dart >/dev/null 2>&1; then
  dart format "$FILE" >/dev/null
elif command -v flutter >/dev/null 2>&1; then
  flutter format "$FILE" >/dev/null 2>&1 || true
fi

echo
echo "✅ Изменения внесены."
echo
echo "Изменён:"
echo "  $FILE"
echo
echo "Резервная копия:"
echo "  $BACKUP"
echo
echo "Теперь выполни:"
echo "  flutter analyze"
echo "  flutter build web"
echo
echo "Для проверки в Chrome:"
echo "  flutter run -d chrome"
echo
echo "Для локальной проверки iOS:"
echo "  flutter run -d 'iPhone 16 Pro'"
echo
echo "ВАЖНО: скрипт меняет только home_screen.dart."
