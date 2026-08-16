#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(pwd)"
HOME_FILE="$PROJECT_DIR/lib/features/home/screens/home_screen.dart"
FILTER_FILE="$PROJECT_DIR/lib/features/home/widgets/home_filter_sheet.dart"

if [[ ! -f "$HOME_FILE" ]]; then
  echo "ОШИБКА: не найден $HOME_FILE"
  echo "Запустите скрипт из корня vslast_premium."
  exit 1
fi

STAMP="$(date +%Y%m%d_%H%M%S)"
cp "$HOME_FILE" "$HOME_FILE.bak_$STAMP"
[[ -f "$FILTER_FILE" ]] && cp "$FILTER_FILE" "$FILTER_FILE.bak_$STAMP"

python3 - "$HOME_FILE" <<'PY'
import re
import sys
from pathlib import Path

home = Path(sys.argv[1])
s = home.read_text()

# ------------------------------------------------------------
# 1. Добавляем расчёт позиций заголовков категорий.
# ------------------------------------------------------------
anchor = """  List<Product> _productsFor(ProductCategory category) =>
      _visibleProducts.where((p) => p.category == category).toList();
"""

if "_categoryHeaderOffsets(double itemWidth)" not in s:
    if anchor not in s:
        raise SystemExit("Не найден _productsFor.")
    helper = anchor + """
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
"""
    s = s.replace(anchor, helper, 1)

# ------------------------------------------------------------
# 2. Полностью заменяем _updateActiveCategory.
# ------------------------------------------------------------
update_pattern = re.compile(
    r"  void _updateActiveCategory\(\) \{.*?\n  \}\n\n  /// Прокручивает список",
    re.S,
)

update_replacement = """  void _updateActiveCategory() {
    if (!_scrollController.hasClients || _categoriesShown.isEmpty) return;

    final viewportWidth = _viewportKey.currentContext?.size?.width ??
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

  /// Прокручивает список"""

if not update_pattern.search(s):
    raise SystemExit("Не найден _updateActiveCategory.")
s = update_pattern.sub(update_replacement, s, count=1)

# ------------------------------------------------------------
# 3. Полностью заменяем _scrollToCategory.
# ------------------------------------------------------------
scroll_pattern = re.compile(
    r"  void _scrollToCategory\(ProductCategory category\) \{.*?\n  \}\n\n  Future<void> _openFilter\(\) async \{",
    re.S,
)

scroll_replacement = """  void _scrollToCategory(ProductCategory category) {
    if (!_scrollController.hasClients) return;
    if (!_categoriesShown.contains(category)) return;

    final viewportWidth = _viewportKey.currentContext?.size?.width ??
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

  Future<void> _openFilter() async {"""

if not scroll_pattern.search(s):
    raise SystemExit("Не найден _scrollToCategory.")
s = scroll_pattern.sub(scroll_replacement, s, count=1)

# ------------------------------------------------------------
# 4. Заменяем _openFilter независимо от его текущего тела.
# ------------------------------------------------------------
filter_pattern = re.compile(
    r"  Future<void> _openFilter\(\) async \{.*?\n  \}\n\n(?=\s*(?:Widget _filterAndCategoryBar|Widget _emptyState|@override|Future<|void |Widget ))",
    re.S,
)

filter_replacement = """  Future<void> _openFilter() async {
    final result = await showHomeFilterSheet(
      context,
      current: _filter,
    );

    if (!mounted || result == null) return;

    setState(() {
      _filter = result;
      _activeCategory = null;
    });

    // После изменения фильтра количество товаров и высота Sliver
    // могут измениться. Начинаем отфильтрованный каталог сверху.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      _scrollController.jumpTo(
        _scrollController.position.minScrollExtent,
      );

      _updateActiveCategory();
    });
  }

"""

m = filter_pattern.search(s)
if not m:
    # Fallback: до следующего метода с двумя пробелами.
    filter_pattern = re.compile(
        r"  Future<void> _openFilter\(\) async \{.*?(?=\n  (?:Widget|Future|void|@override)\b)",
        re.S,
    )
    m = filter_pattern.search(s)

if not m:
    raise SystemExit(
        "Не удалось найти _openFilter. Покажите sed -n '/_openFilter/,/filterAndCategoryBar/p' ..."
    )

s = s[:m.start()] + filter_replacement + s[m.end():]

home.write_text(s)
print("home_screen.dart изменён.")
PY

echo
echo "Форматирование..."
dart format lib/features/home/screens/home_screen.dart

echo
echo "Анализ home_screen.dart..."
flutter analyze lib/features/home/screens/home_screen.dart

echo
echo "ГОТОВО."
echo "Резервная копия: $HOME_FILE.bak_$STAMP"
echo
echo "Запустите:"
echo "  flutter clean && flutter pub get && flutter run"
