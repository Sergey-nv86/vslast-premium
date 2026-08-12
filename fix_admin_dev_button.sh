#!/bin/bash
set -e

PROFILE="lib/screens/profile_screen.dart"

cp "$PROFILE" "${PROFILE}.backup_before_dev_fix"

python3 - <<'PY'
from pathlib import Path

p = Path("lib/screens/profile_screen.dart")
s = p.read_text(encoding="utf-8")

old = """              // DEV ONLY — удалить после подключения backend auth.
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

new = """              // DEV ONLY — удалить после подключения backend auth.
              if (!auth.canAccessAdmin) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: const Text('DEV: переключиться на OWNER'),
                    onPressed: () async {
                      await context.read<AuthProvider>().switchMockRole(
                        UserRole.owner,
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

if old not in s:
    raise SystemExit(
        "Старый DEV-блок не найден. "
        "Покажи текущий фрагмент ProfileScreen."
    )

s = s.replace(old, new, 1)

p.write_text(s, encoding="utf-8")
print("OK: DEV button now uses switchMockRole(UserRole.owner)")
PY

echo
echo "Done."
echo
echo "Check:"
echo "flutter analyze lib/screens/profile_screen.dart lib/features/admin"
