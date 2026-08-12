#!/bin/bash
set -e

FILE="lib/features/admin/screens/admin_dashboard_screen.dart"
BACKUP="${FILE}.backup_before_orders_link"

if [ ! -f "$FILE" ]; then
  echo "ОШИБКА: не найден $FILE"
  exit 1
fi

cp "$FILE" "$BACKUP"

python3 - "$FILE" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

# Add the Orders screen import if it is not already present.
import_line = "import 'admin_orders_screen.dart';"
if import_line not in text:
    lines = text.splitlines()
    # Put local screen imports after the last existing import.
    last_import = -1
    for i, line in enumerate(lines):
        if line.startswith("import "):
            last_import = i
    if last_import >= 0:
        lines.insert(last_import + 1, import_line)
    else:
        lines.insert(0, import_line)
    text = "\n".join(lines) + ("\n" if text.endswith("\n") else "")

# We support the common Dashboard implementation where "Все заказы"
# is represented by a Text widget followed by a nearby onTap.
needle = "Text('Все заказы'"
if needle not in text:
    needle = 'Text("Все заказы"'

if needle not in text:
    print("ОШИБКА: не найден текст «Все заказы» в AdminDashboardScreen.")
    print("Файл сохранён без изменений, резервная копия создана:")
    print(f"  {path}.backup_before_orders_link")
    sys.exit(2)

pos = text.find(needle)

# Find the nearest onTap before the label, if the dashboard uses
# a GestureDetector/InkWell callback immediately around the section.
before = text[:pos]
on_tap_pos = before.rfind("onTap:")
if on_tap_pos == -1 or pos - on_tap_pos > 1800:
    print("ОШИБКА: не удалось безопасно определить onTap для «Все заказы».")
    print("Файл сохранён без изменений, резервная копия создана:")
    print(f"  {path}.backup_before_orders_link")
    sys.exit(3)

# Locate the callback value after onTap.
callback_start = on_tap_pos + len("onTap:")
callback_end = text.find("\n", callback_start)
if callback_end == -1:
    callback_end = len(text)

callback = text[callback_start:callback_end].strip()

# Replace only simple empty callbacks. If the existing callback contains
# business logic, don't overwrite it.
if callback not in ("() {}", "() => {}", "() => null, "null"):
    print("ОШИБКА: «Все заказы» уже имеет непустой onTap.")
    print("Чтобы не потерять существующую логику, автоматическая замена остановлена.")
    print("Резервная копия:")
    print(f"  {path}.backup_before_orders_link")
    sys.exit(4)

indent = text[on_tap_pos:text.find("onTap:", on_tap_pos)].split("\n")[-1]
replacement = "() => Navigator.of(context).push(\n" + \
              "                MaterialPageRoute(\n" + \
              "                  builder: (_) => const AdminOrdersScreen(),\n" + \
              "                ),\n" + \
              "              )"

# Preserve the existing "onTap:" and replace only its callback.
text = text[:callback_start] + " " + replacement + text[callback_end:]

path.write_text(text, encoding="utf-8")
print("Готово: «Все заказы» подключён к AdminOrdersScreen.")
print(f"Резервная копия: {path}.backup_before_orders_link")
PY

echo
echo "Проверка:"
echo "flutter analyze lib/features/admin"
echo
echo "После успешного analyze:"
echo "flutter run -d 8C2FA6FA-466A-4899-8436-10F473EEFB2E"
