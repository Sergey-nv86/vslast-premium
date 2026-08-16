#!/bin/bash
set -euo pipefail

FILE="lib/screens/catalog_screen.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Не найден $FILE"
  echo "Запустите скрипт из корня vslast_premium."
  exit 1
fi

STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP="${FILE}.before_sliver_geometry_${STAMP}.bak"
cp "$FILE" "$BACKUP"

python3 - "$FILE" <<'PY'
from pathlib import Path
import re
import sys

p = Path(sys.argv[1])
s = p.read_text(encoding="utf-8")

# Flutter error:
# layoutExtent = 76.0, paintExtent = 75.0.
# The pinned header delegate must have exactly the same extent as the
# widget it lays out. We standardize the catalog pinned bar to 75 px.

# 1) Normalize the catalog pinned-bar height constant if present.
patterns = [
    (r'(static\s+const\s+double\s+_pinnedBarHeight\s*=\s*)76(?:\.0)?\s*;', r'\g<1>75.0;'),
    (r'(static\s+const\s+double\s+_categoryBarHeight\s*=\s*)76(?:\.0)?\s*;', r'\g<1>75.0;'),
]
for pat, repl in patterns:
    s, n = re.subn(pat, repl, s, count=1)

# 2) If the SliverPersistentHeader is hard-coded to 76, normalize it.
s = re.sub(
    r'(SliverPersistentHeader\s*\(\s*pinned\s*:\s*true,\s*delegate\s*:\s*_[A-Za-z0-9_]*Delegate\(\s*height\s*:\s*)76(?:\.0)?',
    r'\g<1>75.0',
    s,
    count=1,
    flags=re.S,
)

# 3) Make the delegate report a fixed, internally consistent extent.
# This handles delegates that currently expose min/max through `height`.
delegate = re.search(
    r'class\s+(_[A-Za-z0-9_]*CategoryBarDelegate)\s+extends\s+SliverPersistentHeaderDelegate\s*\{',
    s,
)
if delegate:
    start = delegate.end()
    # Limit replacement to the delegate class body.
    next_class = s.find('\nclass ', start)
    body_end = next_class if next_class != -1 else len(s)
    body = s[start:body_end]

    body = re.sub(
        r'@override\s+double\s+get\s+minExtent\s*=>\s*height\s*;',
        '@override\n  double get minExtent => height;',
        body,
        count=1,
        flags=re.S,
    )
    body = re.sub(
        r'@override\s+double\s+get\s+maxExtent\s*=>\s*height\s*;',
        '@override\n  double get maxExtent => height;',
        body,
        count=1,
        flags=re.S,
    )

    # Guard against a child being smaller than the declared extent.
    # The header child is forced to exactly `height`.
    body = re.sub(
        r'(return\s+Material\s*\([^;]*?child:\s*)child(\s*,?\s*\)\s*;)',
        r'\1SizedBox(height: height, child: child)\2',
        body,
        count=1,
        flags=re.S,
    )

    s = s[:start] + body + s[body_end:]

p.write_text(s, encoding="utf-8")
print("OK: исправлен SliverPersistentHeader в catalog_screen.dart")
print("Backup создан рядом с файлом.")
PY

echo
echo "Форматирование..."
dart format "$FILE"

echo
echo "Анализ каталога..."
flutter analyze "$FILE"

echo
echo "Готово."
echo "Резервная копия: $BACKUP"
echo
echo "Запуск:"
echo "  flutter clean"
echo "  flutter pub get"
echo "  flutter run"
