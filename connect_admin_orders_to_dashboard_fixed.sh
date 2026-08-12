#!/bin/bash
set -e

FILE="lib/features/admin/screens/admin_dashboard_screen.dart"

if [ ! -f "$FILE" ]; then
  echo "ОШИБКА: не найден $FILE"
  exit 1
fi

cp "$FILE" "${FILE}.backup_before_orders_link"

python3 - "$FILE" <<'PY'
from pathlib import Path
import sys

p = Path(sys.argv[1])
s = p.read_text(encoding="utf-8")

import_line = "import 'admin_orders_screen.dart';"
if import_line not in s:
    lines = s.splitlines()
    last = max((i for i, line in enumerate(lines) if line.startswith("import ")), default=-1)
    lines.insert(last + 1, import_line)
    s = "\n".join(lines) + "\n"

old = "const _Title('Заказы', 'Все заказы'),"

new = """_Title(
            'Заказы',
            'Все заказы',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AdminOrdersScreen(),
                ),
              );
            },
          ),"""

if old not in s:
    print("ОШИБКА: строка _Title('Заказы', 'Все заказы') не найдена.")
    print("Изменения не применены.")
    sys.exit(2)

s = s.replace(old, new, 1)

# Update _Title to accept an optional callback, without changing other usages.
old_class = """class _Title extends StatelessWidget {
  final String title;
  final String? action;

  const _Title(this.title, [this.action]);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: dark)),
        ),
        if (action != null)
          Text(action!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: brown)),
      ],
    );
  }
}"""

new_class = """class _Title extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;

  const _Title(this.title, [this.action, this.onTap]);

  @override
  Widget build(BuildContext context) {
    final actionWidget = action == null
        ? const SizedBox.shrink()
        : Text(
            action!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: brown,
            ),
          );

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: dark,
            ),
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: actionWidget,
            ),
          ),
      ],
    );
  }
}"""

if old_class not in s:
    print("ОШИБКА: текущая реализация _Title отличается от ожидаемой.")
    print("Изменения не применены к _Title.")
    sys.exit(3)

s = s.replace(old_class, new_class, 1)

p.write_text(s, encoding="utf-8")
print("OK: «Все заказы» подключён к AdminOrdersScreen.")
print(f"Резервная копия: {p}.backup_before_orders_link")
PY

echo
echo "Теперь выполни:"
echo "flutter analyze lib/features/admin"
