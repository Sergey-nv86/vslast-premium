#!/bin/bash
set -e

FILE="lib/features/admin/screens/admin_dashboard_screen.dart"

if [ ! -f "$FILE" ]; then
  echo "ОШИБКА: не найден $FILE"
  exit 1
fi

cp "$FILE" "${FILE}.backup_before_orders_tap_fix"

python3 - "$FILE" <<'PY'
from pathlib import Path
import sys

p = Path(sys.argv[1])
s = p.read_text(encoding="utf-8")

# Ensure the orders screen import exists.
imp = "import 'admin_orders_screen.dart';"
if imp not in s:
    lines = s.splitlines()
    last = max((i for i, line in enumerate(lines) if line.startswith("import ")), default=-1)
    lines.insert(last + 1, imp)
    s = "\n".join(lines) + "\n"

# The actual dashboard currently uses this exact call.
old_call = "const _Title('Заказы', 'Все заказы'),"
new_call = """_Title(
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

if old_call in s:
    s = s.replace(old_call, new_call, 1)
elif "onTap: ()" not in s or "AdminOrdersScreen()" not in s:
    print("ОШИБКА: не найден ожидаемый вызов _Title для секции «Заказы».")
    sys.exit(2)

# Replace the exact current _Title implementation.
old_title = """class _Title extends StatelessWidget {
  final String title;
  final String? action;
  const _Title(this.title, [this.action]);

  @override
  Widget build(BuildContext context) => Row(children: [
    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AdminDashboardScreen.dark)),
    const Spacer(),
    if (action != null) Text(action!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AdminDashboardScreen.brown)),
  ]);
}"""

new_title = """class _Title extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;

  const _Title(this.title, [this.action, this.onTap]);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AdminDashboardScreen.dark,
        ),
      ),
      const Spacer(),
      if (action != null)
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(
              action!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AdminDashboardScreen.brown,
              ),
            ),
          ),
        ),
    ],
  );
}"""

if old_title not in s:
    print("ОШИБКА: текущая реализация _Title отличается от ожидаемой.")
    print("Файл не изменён.")
    sys.exit(3)

s = s.replace(old_title, new_title, 1)

p.write_text(s, encoding="utf-8")
print("OK: «Все заказы» теперь кликабельно и открывает AdminOrdersScreen.")
print(f"Резервная копия: {p}.backup_before_orders_tap_fix")
PY

echo
echo "Проверка:"
echo "flutter analyze lib/features/admin"
