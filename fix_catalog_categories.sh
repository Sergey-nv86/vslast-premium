#!/bin/bash
set -euo pipefail

FILE="lib/screens/catalog_screen.dart"

if [[ ! -f "$FILE" ]]; then
  echo "ОШИБКА: не найден $FILE"
  echo "Запусти скрипт из корня проекта vslast_premium."
  exit 1
fi

STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP="${FILE}.before_category_switch_${STAMP}.bak"
cp "$FILE" "$BACKUP"

auto_python=''
python3 - "$FILE" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
s = path.read_text(encoding="utf-8")

# 1. Добавляем расчёт реальных позиций заголовков категорий.
anchor = """  List<Product> _productsFor(ProductCategory category) {\n    final query = _searchController.text.trim().toLowerCase();\n\n    return mockProducts.where((product) {\n      if (product.category != category) return false;\n      if (query.isEmpty) return true;\n      return product.name.toLowerCase().contains(query);\n    }).toList();\n  }\n"""

helper = anchor + r'''

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
      final rows = (products.length + _gridCrossAxisCount - 1) ~/
          _gridCrossAxisCount;

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
'''

if "Map<ProductCategory, double> _categoryOffsets" not in s:
    if anchor not in s:
        raise SystemExit("ОШИБКА: не найден блок _productsFor().")
    s = s.replace(anchor, helper, 1)

# 2. Полностью заменяем scroll-spy.
pattern = re.compile(
    r"  void _updateActiveCategory\(\) \{.*?\n  \}\n\n  void _scrollToCategory",
    re.S,
)
replacement = r'''  void _updateActiveCategory() {
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
    final probe =
        _scrollController.offset + _pinnedHeaderHeight;

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

  void _scrollToCategory'''

if not pattern.search(s):
    raise SystemExit("ОШИБКА: не найден _updateActiveCategory().")
s = pattern.sub(replacement, s, count=1)

# 3. Полностью заменяем переход по чипу.
pattern = re.compile(
    r"  void _scrollToCategory\(ProductCategory category\) \{.*?\n  \}\n\n  void _scrollToTop",
    re.S,
)
replacement = r'''  void _scrollToCategory(ProductCategory category) {
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

  void _scrollToTop'''

if not pattern.search(s):
    raise SystemExit("ОШИБКА: не найден _scrollToCategory().")
s = pattern.sub(replacement, s, count=1)

# 4. Убираем старые GlobalKey — они больше не участвуют в логике.
s = re.sub(
    r"\n  final Map<ProductCategory, GlobalKey> _sectionKeys = \{.*?\n  \};\n",
    "\n",
    s,
    count=1,
    flags=re.S,
)

# 5. Убираем key у заголовков секций.
s = re.sub(
    r"(\n\s*)key: _sectionKeys\[category\],",
    "",
    s,
    count=1,
)

path.write_text(s, encoding="utf-8")
PY

dart format "$FILE"
flutter analyze "$FILE"

echo
echo "ГОТОВО."
echo "Резервная копия: $BACKUP"
echo
echo "Теперь запусти:"
echo "  flutter clean"
echo "  flutter pub get"
echo "  flutter run"
