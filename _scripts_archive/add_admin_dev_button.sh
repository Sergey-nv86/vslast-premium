#!/bin/bash
set -e

PROFILE="lib/screens/profile_screen.dart"

cp "$PROFILE" "${PROFILE}.backup_before_dev_admin"

python3 - <<'PY'
from pathlib import Path

p = Path("lib/screens/profile_screen.dart")
s = p.read_text(encoding="utf-8")

# Добавляем UserRole import, если его ещё нет.
role_import = "import '../models/user_role.dart';"
if role_import not in s:
    s = s.replace(
        "import '../providers/auth_provider.dart';",
        "import '../providers/auth_provider.dart';\n" + role_import,
        1,
    )

# Добавляем DEV-кнопку перед Spacer, только если её ещё нет.
marker = "              const Spacer(),"

dev_block = """              // DEV ONLY — удалить после подключения backend auth.
              if (!auth.canAccessAdmin) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: const Text('DEV: войти как OWNER'),
                    onPressed: () async {
                      await context.read<AuthProvider>().signInMock(
                        role: UserRole.owner,
                        id: 'dev-owner',
                        displayName: 'Сергей',
                        phone: '+7 900 000-00-00',
                      );

                      if (!context.mounted) return;

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminEntryScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
"""

if "DEV: войти как OWNER" not in s:
    if marker not in s:
        raise SystemExit("Не найдено место для DEV-кнопки.")
    s = s.replace(marker, dev_block + marker, 1)

p.write_text(s, encoding="utf-8")
PY

echo "DEV Admin button added."
echo
echo "Run:"
echo "flutter analyze lib/screens/profile_screen.dart lib/features/admin"
