#!/bin/zsh
set -e

echo "=============================================="
echo " Всласть — подключение экрана Отзывы"
echo "=============================================="

if [ ! -d "lib" ]; then
  echo "ОШИБКА: запустите из корня Flutter-проекта vslast_premium."
  exit 1
fi

TARGET="lib/screens/product_detail_screen.dart"

if [ ! -f "$TARGET" ]; then
  echo "ОШИБКА: не найден $TARGET"
  exit 1
fi

BACKUP="${TARGET}.before_reviews_link_$(date +%Y%m%d_%H%M%S).bak"
cp "$TARGET" "$BACKUP"
echo "✓ Резервная копия: $BACKUP"

python3 - <<'PY'
from pathlib import Path
import re

path = Path("lib/screens/product_detail_screen.dart")
text = path.read_text()

# 1. Добавляем импорт ReviewsScreen, если его ещё нет.
if "reviews_screen.dart" not in text:
    lines = text.splitlines()
    insert_at = 0
    while insert_at < len(lines) and (
        lines[insert_at].startswith("import ") or
        lines[insert_at].strip() == ""
    ):
        insert_at += 1

    # Вставляем после flutter/import-блока.
    import_line = "import 'reviews_screen.dart';"
    lines.insert(insert_at, import_line)
    text = "\n".join(lines) + ("\n" if text.endswith("\n") else "")

# 2. Подключаем переход с рейтинга/количества отзывов.
pattern = re.compile(
    r"""(?P<indent>\s*)if\s*\(product\.rating\s*!=\s*null\)\s*\.\.\.\[\s*
        _RatingRow\(\s*
        rating:\s*product\.rating!\s*,\s*
        reviewsCount:\s*product\.reviewsCount\s*,\s*
        \)\s*,\s*
        \]""",
    re.VERBOSE,
)

replacement = r""" \g<indent>if (product.rating != null) ...[
\g<indent>  GestureDetector(
\g<indent>    behavior: HitTestBehavior.opaque,
\g<indent>    onTap: () {
\g<indent>      Navigator.of(context).push(
\g<indent>        MaterialPageRoute(
\g<indent>          builder: (_) => ReviewsScreen(
\g<indent>            productName: product.name,
\g<indent>            productPrice: '${product.price} ₽',
\g<indent>            rating: product.rating!,
\g<indent>            reviewCount: product.reviewsCount ?? 0,
\g<indent>          ),
\g<indent>        ),
\g<indent>      );
\g<indent>    },
\g<indent>    child: _RatingRow(
\g<indent>      rating: product.rating!,
\g<indent>      reviewsCount: product.reviewsCount,
\g<indent>    ),
\g<indent>  ),
\g<indent>]"""

new_text, count = pattern.subn(replacement, text, count=1)

if count == 0:
    print("ОШИБКА: не найден ожидаемый блок _RatingRow в product_detail_screen.dart.")
    print("Файл НЕ изменён. Резервная копия сохранена.")
    raise SystemExit(2)

path.write_text(new_text)
print("✓ Переход на экран Отзывы подключён.")
PY

echo
echo "Проверяем форматирование..."
dart format "$TARGET" >/dev/null

echo "✓ Готово."
echo
echo "Теперь выполните:"
echo "  flutter analyze lib/screens/product_detail_screen.dart"
echo "  flutter run"
echo
echo "После запуска нажмите на строку рейтинга / «64 отзывов»."
