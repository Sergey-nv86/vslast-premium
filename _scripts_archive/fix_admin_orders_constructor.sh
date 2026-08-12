#!/bin/bash
set -e

FILE="lib/features/admin/screens/admin_dashboard_screen.dart"

if [ ! -f "$FILE" ]; then
  echo "ОШИБКА: не найден $FILE"
  exit 1
fi

cp "$FILE" "${FILE}.backup_before_orders_constructor_fix"

python3 - "$FILE" <<'PY'
from pathlib import Path
import sys

p = Path(sys.argv[1])
s = p.read_text(encoding="utf-8")

old = """  const _Title(this.title, [this.action, this.onTap]);"""

new = """  const _Title(
    this.title, [
    this.action,
  ], {
    this.onTap,
  });"""

if old not in s:
    print("ОШИБКА: ожидаемый конструктор _Title не найден.")
    print("Показываю текущую строку конструктора:")
    for line in s.splitlines():
        if "const _Title" in line:
            print(line)
    sys.exit(2)

s = s.replace(old, new, 1)

p.write_text(s, encoding="utf-8")
print("OK: конструктор _Title исправлен.")
print(f"Резервная копия: {p}.backup_before_orders_constructor_fix")
PY

echo
echo "Теперь выполни:"
echo "flutter analyze lib/features/admin"
