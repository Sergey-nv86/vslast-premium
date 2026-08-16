#!/bin/bash

set -e

FILE="lib/screens/catalog_screen.dart"

echo "=============================================="
echo " Всласть — исправление pinned Catalog/Search"
echo "=============================================="
echo

# Проверяем, что запускаем из корня Flutter-проекта
if [ ! -f "pubspec.yaml" ]; then
  echo "ОШИБКА: pubspec.yaml не найден."
  echo "Запусти этот скрипт из корня проекта vslast_premium."
  exit 1
fi

if [ ! -f "$FILE" ]; then
  echo "ОШИБКА: $FILE не найден."
  exit 1
fi

# ------------------------------------------------
# 1. BACKUP
# ------------------------------------------------

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP="${FILE}.before_catalog_pinned_${TIMESTAMP}.bak"

cp "$FILE" "$BACKUP"

echo "✓ Резервная копия:"
echo "  $BACKUP"
echo

# ------------------------------------------------
# 2. PYTHON MODIFICATION
# ------------------------------------------------

python3 <<'PY'
from pathlib import Path
import re
import sys

file = Path("lib/screens/catalog_screen.dart")
text = file.read_text(encoding="utf-8")

original = text

# ============================================================
# A. ЗАМЕНА ВЫСОТ
# ============================================================

old = """  static const double _searchHeaderHeight = 76;
  static const double _categoryHeaderHeight = 54;"""

new = """  static const double _catalogHeaderHeight = 132;
  static const double _categoryHeaderHeight = 54;"""

if old in text:
    text = text.replace(old, new, 1)
    print("✓ Высоты header обновлены")
else:
    if "_catalogHeaderHeight" in text:
        print("✓ _catalogHeaderHeight уже существует")
    else:
        print("ОШИБКА: не найден блок высот header.")
        sys.exit(1)


# ============================================================
# B. ЗАМЕНА РАСЧЁТА CATEGORY BAR BOTTOM
# ============================================================

old = """final categoryBarBottom =
        _searchHeaderHeight + _categoryHeaderHeight;"""

new = """final categoryBarBottom =
        _catalogHeaderHeight + _categoryHeaderHeight;"""

if old in text:
    text = text.replace(old, new, 1)
    print("✓ Исправлен scroll-spy")
else:
    # Возможно форматирование уже отличается
    pattern = r"""final categoryBarBottom\s*=\s*
\s*_searchHeaderHeight\s*\+\s*_categoryHeaderHeight;"""

    replacement = """final categoryBarBottom =
        _catalogHeaderHeight + _categoryHeaderHeight;"""

    text2, count = re.subn(pattern, replacement, text, count=1)

    if count:
        text = text2
        print("✓ Исправлен scroll-spy (regex)")
    elif "_catalogHeaderHeight + _categoryHeaderHeight" in text:
        print("✓ scroll-spy уже исправлен")
    else:
        print("ПРЕДУПРЕЖДЕНИЕ: строка categoryBarBottom не найдена.")


# ============================================================
# C. ЗАМЕНА targetDelta
# ============================================================

old = """final targetDelta =
        currentY - (_searchHeaderHeight + _categoryHeaderHeight);"""

new = """final targetDelta =
        currentY - (_catalogHeaderHeight + _categoryHeaderHeight);"""

if old in text:
    text = text.replace(old, new, 1)
    print("✓ Исправлен targetDelta")
else:
    pattern = r"""final targetDelta\s*=\s*
\s*currentY\s*-\s*\(_searchHeaderHeight\s*\+\s*_categoryHeaderHeight\);"""

    replacement = """final targetDelta =
        currentY - (_catalogHeaderHeight + _categoryHeaderHeight);"""

    text2, count = re.subn(pattern, replacement, text, count=1)

    if count:
        text = text2
        print("✓ Исправлен targetDelta (regex)")
    elif "_catalogHeaderHeight + _categoryHeaderHeight" in text:
        print("✓ targetDelta уже исправлен")
    else:
        print("ПРЕДУПРЕЖДЕНИЕ: targetDelta не найден.")


# ============================================================
# D. ЗАМЕНЯЕМ БЛОК SEARCH + CATEGORY
# ============================================================

# Ищем блок начиная с SEARCH — pinned
# и заканчивая SizedBox(height: 2)
#
# Это позволяет не зависеть от точного количества пробелов.

pattern = re.compile(
    r"""                // SEARCH — pinned\.
                SliverPersistentHeader\(
                  pinned: true,
                  delegate: _PinnedHeaderDelegate\(
                    height: _searchHeaderHeight,
                    child: _SearchHeader\(
                      controller: _searchController,
                      autofocus: widget\.autofocusSearch,
                    \),
                  \),
                \),

                // CATEGORY BAR — pinned непосредственно под SearchBar\.
                SliverPersistentHeader\(
                  pinned: true,
                  delegate: _PinnedHeaderDelegate\(
                    height: _categoryHeaderHeight,
                    child: _CategoryBar\(
                      categories: categories,
                      activeCategory: _activeCategory,
                      onCategoryTap: _scrollToCategory,
                      onAllTap: _scrollToTop,
                    \),
                  \),
                \),

                const SliverToBoxAdapter\(child: SizedBox\(height: 2\)\),""",
    re.MULTILINE
)

replacement = """                // CATALOG + SEARCH — pinned.
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PinnedHeaderDelegate(
                    height: _catalogHeaderHeight,
                    child: _CatalogHeader(
                      controller: _searchController,
                      autofocus: widget.autofocusSearch,
                    ),
                  ),
                ),

                // CATEGORY BAR — pinned непосредственно под Catalog + Search.
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PinnedHeaderDelegate(
                    height: _categoryHeaderHeight,
                    child: _CategoryBar(
                      categories: categories,
                      activeCategory: _activeCategory,
                      onCategoryTap: _scrollToCategory,
                      onAllTap: _scrollToTop,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 2))"""

text2, count = pattern.subn(replacement, text, count=1)

if count:
    text = text2
    print("✓ Search + Category заменены на новую структуру")
else:
    # Проверяем, возможно скрипт уже запускался
    if "_CatalogHeader(" in text:
        print("✓ Новая структура Catalog + Search уже установлена")
    else:
        print("ОШИБКА: исходный блок SEARCH/CATEGORY не найден.")
        print("Изменения до этого момента не отменяются.")
        file.write_text(text, encoding="utf-8")
        sys.exit(1)


# ============================================================
# E. УДАЛЯЕМ СТАРЫЙ _SearchHeader
# ============================================================

pattern = re.compile(
    r"""
class\ _SearchHeader\ extends\ StatelessWidget\ \{
.*?
\}

class\ _CategoryBar
""",
    re.DOTALL | re.VERBOSE
)

match = pattern.search(text)

if match:
    replacement = "class _CategoryBar"
    text = text[:match.start()] + replacement + text[match.end():]
    print("✓ Старый _SearchHeader удалён")
else:
    if "class _SearchHeader" not in text:
        print("✓ Старый _SearchHeader уже отсутствует")
    else:
        print("ПРЕДУПРЕЖДЕНИЕ: не удалось автоматически удалить _SearchHeader")


# ============================================================
# F. ДОБАВЛЯЕМ НОВЫЙ _CatalogHeader
# ============================================================

catalog_header = r'''
class _CatalogHeader extends StatelessWidget {
  final TextEditingController controller;
  final bool autofocus;

  const _CatalogHeader({
    required this.controller,
    required this.autofocus,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          _CatalogScreenState._horizontalPadding,
          10,
          _CatalogScreenState._horizontalPadding,
          12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Каталог',
              style: AppTextStyles.screenTitle,
            ),

            const SizedBox(height: 12),

            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      size: 22,
                      color: AppColors.textSecondary,
                    ),

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
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          hintText: 'Поиск хлеба, тортов, десертов...',
                          hintStyle: AppTextStyles.searchHint,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

'''

if "class _CatalogHeader extends StatelessWidget" in text:
    print("✓ _CatalogHeader уже существует")
else:
    marker = "class _CategoryBar"

    if marker not in text:
        print("ОШИБКА: не найден класс _CategoryBar.")
        sys.exit(1)

    text = text.replace(
        marker,
        catalog_header + marker,
        1,
    )

    print("✓ Добавлен _CatalogHeader")


# ============================================================
# G. УДАЛЯЕМ СТАРЫЙ ОДИНОЧНЫЙ CATALOG HEADER
# ============================================================

# Ищем старый блок с Row / Назад / Каталог.
#
# В текущем файле он находится непосредственно перед:
# const SliverToBoxAdapter(child: SizedBox(height: 18));

old_catalog_pattern = re.compile(
    r"""                SliverToBoxAdapter\(
                  child: Padding\(
                    padding: const EdgeInsets\.fromLTRB\(
                      .*?
                    \),
                    child: Row\(
                      children: \[
                        .*?
                        Expanded\(
                          child: Text\(
                            'Каталог',
                            style: AppTextStyles\.screenTitle,
                          \),
                        \),
                      \],
                    \),
                  \),
                \),

                const SliverToBoxAdapter\(child: SizedBox\(height: 18\)\),""",
    re.DOTALL
)

text2, count = old_catalog_pattern.subn(
    """                const SliverToBoxAdapter(child: SizedBox(height: 18)), """,
    text,
    count=1,
)

if count:
    text = text2
    print("✓ Старый обычный Catalog header удалён")
else:
    print("ℹ Старый Catalog header не найден — возможно уже удалён")


# ============================================================
# H. УБИРАЕМ ВОЗМОЖНЫЙ ЛИШНИЙ ПУСТОЙ SPACE ПЕРЕД PINNED
# ============================================================

# Если старый Catalog уже удалён, не оставляем огромный отступ.
text = text.replace(
    """                const SliverToBoxAdapter(child: SizedBox(height: 18)), 

                // CATALOG + SEARCH — pinned.""",
    """                // CATALOG + SEARCH — pinned."""
)

text = text.replace(
    """                const SliverToBoxAdapter(child: SizedBox(height: 18)),

                // CATALOG + SEARCH — pinned.""",
    """                // CATALOG + SEARCH — pinned."""
)


# ============================================================
# I. ПРОВЕРЯЕМ, ЧТО СТАРЫХ ССЫЛОК НЕ ОСТАЛОСЬ
# ============================================================

if "_searchHeaderHeight" in text:
    print("ОШИБКА: в файле осталась ссылка на _searchHeaderHeight.")
    sys.exit(1)

if "class _SearchHeader" in text:
    print("ОШИБКА: в файле остался старый _SearchHeader.")
    sys.exit(1)

# ============================================================
# J. ПРОВЕРЯЕМ НОВУЮ СТРУКТУРУ
# ============================================================

required = [
    "_catalogHeaderHeight",
    "_CatalogHeader",
    "_categoryHeaderHeight",
    "height: _catalogHeaderHeight",
    "height: _categoryHeaderHeight",
]

missing = [item for item in required if item not in text]

if missing:
    print("ОШИБКА: не найдены обязательные элементы:")
    for item in missing:
        print("  -", item)
    sys.exit(1)


# ============================================================
# K. СОХРАНЕНИЕ
# ============================================================

if text == original:
    print("ℹ Файл не изменился.")
else:
    file.write_text(text, encoding="utf-8")
    print("✓ catalog_screen.dart сохранён")

PY

echo

# ------------------------------------------------
# 3. FORMAT
# ------------------------------------------------

echo "=============================================="
echo "Форматирование..."
echo "=============================================="

dart format "$FILE"

echo

# ------------------------------------------------
# 4. ANALYZE
# ------------------------------------------------

echo "=============================================="
echo "Flutter analyze..."
echo "=============================================="

if flutter analyze "$FILE"; then
  echo
  echo "=============================================="
  echo "✓ ГОТОВО"
  echo "=============================================="
  echo
  echo "Резервная копия:"
  echo "  $BACKUP"
  echo
  echo "Теперь запускай:"
  echo
  echo "  flutter run"
  echo
else
  echo
  echo "=============================================="
  echo "⚠ ANALYZE НАШЁЛ ОШИБКИ"
  echo "=============================================="
  echo
  echo "Исходный файл сохранён здесь:"
  echo "  $BACKUP"
  echo
  exit 1
fi
