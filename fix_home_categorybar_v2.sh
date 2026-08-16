
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

python3 - "$HOME_FILE" "$FILTER_FILE" <<'PY'
import re
import sys
from pathlib import Path

home = Path(sys.argv[1])
flt = Path(sys.argv[2])
s = home.read_text()

anchor = """  List<Product> _productsFor(ProductCategory category) =>
      _visibleProducts.where((p) => p.category == category).toList();
"""
helper = anchor + """
  /// Возвращает Y-позицию заголовка каждой категории в координатах
  /// содержимого CustomScrollView.
  ///
  /// Scroll-spy не зависит от GlobalKey/RenderBox: lazy sliver-элементы
  /// могут ещё не существовать в render tree.
  Map<ProductCategory, double> _categoryHeaderOffsets(double itemWidth) {
    const popularHeight = 152.0; // 16 title + 8 gap + 128 carousel
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
if anchor not in s:
    raise SystemExit("Не найден блок _productsFor.")
s = s.replace(anchor, helper, 1)

pattern = re.compile(r"""  void _updateActiveCategory\(\) \{.*?\n  \}\n\n  /// Прокручивает список""", re.S)
replacement = """  void _updateActiveCategory() {
    if (!_scrollController.hasClients || _categoriesShown.isEmpty) return;

    final viewportWidth = _viewportKey.currentContext?.size?.width ??
        MediaQuery.sizeOf(context).width;
    final itemWidth =
        (viewportWidth - _horizontalPadding * 2 - _gridSpacing) / 2;

    final offsets = _categoryHeaderOffsets(itemWidth);
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

  /// Прокручивает список так, чтобы выбранный заголовок оказался
  /// непосредственно ПОД pinned CategoryBar.
"""
m = pattern.search(s)
if not m:
    raise SystemExit("Не найден _updateActiveCategory.")
s = s[:m.start()] + replacement + s[m.end():]

pattern = re.compile(r"""  void _scrollToCategory\(ProductCategory category\) \{.*?\n  \}\n\n  Future<void> _openFilter\(\) async \{""", re.S)
replacement = """  void _scrollToCategory(ProductCategory category) {
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
m = pattern.search(s)
if not m:
    raise SystemExit("Не найден _scrollToCategory.")
s = s[:m.start()] + replacement + s[m.end():]

old = """  Future<void> _openFilter() async {
    final result = await showHomeFilterSheet(context, current: _filter);
    if (result == null) return;
    setState(() {
      _filter = result;
      _activeCategory = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateActiveCategory());
  }"""
new = """  Future<void> _openFilter() async {
    final result = await showHomeFilterSheet(context, current: _filter);
    if (!mounted || result == null) return;

    setState(() {
      _filter = result;
      _activeCategory = null;
    });

    // После фильтра высота sliver-контента может резко уменьшиться.
    // Начинаем отфильтрованный каталог сверху, а не со старого offset.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.minScrollExtent);
      _updateActiveCategory();
    });
  }"""
if old not in s:
    raise SystemExit("Не найден _openFilter.")
s = s.replace(old, new, 1)

home.write_text(s)

if flt.exists():
    f = flt.read_text()
    f = f.replace(
        """    isScrollControlled: true,
    backgroundColor: Colors.white,""",
        """    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,""",
        1,
    )

    old = """      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: ["""
    new = """      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: ["""
    if old in f:
        f = f.replace(old, new, 1)
        tail = """          ],
        ),
      ),
    );
  }
}"""
        if tail not in f:
            raise SystemExit("Не найден конец Filter BottomSheet.")
        f = f.replace(
            tail,
            """          ],
        ),
      ),
      ),
    );
  }
}""",
            1,
        )
    flt.write_text(f)

print("Патч применён.")
PY

echo
echo "Проверка форматирования..."
dart format lib/features/home/screens/home_screen.dart lib/features/home/widgets/home_filter_sheet.dart

echo
echo "Проверка анализа..."
flutter analyze lib/features/home/screens/home_screen.dart lib/features/home/widgets/home_filter_sheet.dart

echo
echo "ГОТОВО."
echo "Резервные копии созданы рядом с изменёнными файлами."
echo
echo "Теперь запустите:"
echo "  flutter clean"
echo "  flutter pub get"
echo "  flutter run"
