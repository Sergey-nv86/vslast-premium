#!/bin/zsh

set -e

echo "=============================================="
echo " Всласть — подключение экрана Отзывы"
echo "=============================================="

FILE="lib/screens/product_detail_screen.dart"

if [ ! -f "$FILE" ]; then
  echo "ОШИБКА: не найден $FILE"
  echo "Запусти скрипт из корня проекта vslast_premium."
  exit 1
fi

STAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP="${FILE}.before_reviews_link_${STAMP}.bak"

cp "$FILE" "$BACKUP"
echo "✓ Резервная копия: $BACKUP"

python3 - <<'PY'
from pathlib import Path

path = Path("lib/screens/product_detail_screen.dart")
text = path.read_text()

reviews_import = "import 'reviews_screen.dart';"

if reviews_import not in text:
    marker = "import 'preorder_screen.dart';"

    if marker not in text:
        raise SystemExit(
            "ОШИБКА: не найден импорт preorder_screen.dart.\n"
            "Файл НЕ изменён."
        )

    text = text.replace(
        marker,
        marker + "\n" + reviews_import,
        1,
    )

old = """                        _RatingRow(
                          rating: product.rating!,
                          reviewsCount: product.reviewsCount,
                        ),"""

new = """                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ReviewsScreen(
                                  productName: product.name,
                                  imageUrl: product.imageUrl,
                                  rating: product.rating!,
                                  reviewCount: product.reviewsCount ?? 0,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 2,
                            ),
                            child: _RatingRow(
                              rating: product.rating!,
                              reviewsCount: product.reviewsCount,
                            ),
                          ),
                        ),"""

if old not in text:
    raise SystemExit(
        "ОШИБКА: не найден точный блок _RatingRow.\n"
        "Файл НЕ изменён."
    )

text = text.replace(old, new, 1)
path.write_text(text)
PY

echo "✓ Переход на экран «Отзывы» подключён."

echo
echo "Форматирование..."
flutter format "$FILE"

echo
echo "Анализ..."
flutter analyze "$FILE"

echo
echo "=============================================="
echo " ГОТОВО"
echo "=============================================="
echo
echo "Теперь запусти:"
echo "  flutter run"
