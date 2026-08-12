#!/bin/bash
set -e

FILE="lib/features/admin/screens/admin_dashboard_screen.dart"

if [ ! -f "$FILE" ]; then
  echo "ОШИБКА: не найден $FILE"
  exit 1
fi

cp "$FILE" "${FILE}.backup_before_orders_title_repair"

python3 - "$FILE" <<'PY'
from pathlib import Path
import re
import sys

p = Path(sys.argv[1])
s = p.read_text(encoding="utf-8")

# 1. Ensure the orders screen import exists.
imp = "import 'admin_orders_screen.dart';"
if imp not in s:
    lines = s.splitlines()
    last_import = max(
        (i for i, line in enumerate(lines) if line.startswith("import ")),
        default=-1,
    )
    lines.insert(last_import + 1, imp)
    s = "\n".join(lines) + "\n"

# 2. Replace the complete _Title class, regardless of its currently
#    partially-corrupted constructor/body.
start = s.find("class _Title extends StatelessWidget {")
end = s.find("class _Card extends StatelessWidget {", start)

if start == -1 or end == -1:
    print("ОШИБКА: не удалось найти границы классов _Title / _Card.")
    sys.exit(2)

new_title = """class _Title extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;

  const _Title(
    this.title, [
    this.action,
  ], {
    this.onTap,
  });

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
            padding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 4,
            ),
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
}

"""

s = s[:start] + new_title + s[end:]

# 3. Ensure the actual "Заказы / Все заказы" call has the named callback.
pattern = re.compile(
    r"const _Title\(\s*'Заказы',\s*'Все заказы',\s*\)",
    re.MULTILINE,
)

replacement = """_Title(
            'Заказы',
            'Все заказы',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AdminOrdersScreen(),
                ),
              );
            },
          )"""

s, count = pattern.subn(replacement, s, count=1)

if count == 0:
    # If an earlier script already converted it, verify the required
    # AdminOrdersScreen navigation exists. Otherwise stop safely.
    if "builder: (_) => const AdminOrdersScreen()" not in s:
        print("ОШИБКА: не найден вызов секции «Заказы / Все заказы».")
        sys.exit(3)

p.write_text(s, encoding="utf-8")

print("OK: _Title полностью восстановлен.")
print("OK: «Все заказы» подключён к AdminOrdersScreen.")
print(f"Резервная копия: {p}.backup_before_orders_title_repair")
PY

echo
echo "Теперь выполни:"
echo "flutter analyze lib/features/admin"
