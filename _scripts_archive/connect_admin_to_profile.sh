#!/bin/bash
set -e

PROFILE="lib/screens/profile_screen.dart"

if [ ! -f "$PROFILE" ]; then
  echo "ERROR: $PROFILE not found."
  exit 1
fi

if [ ! -f "lib/features/admin/screens/admin_entry_screen.dart" ]; then
  echo "ERROR: AdminEntryScreen not found."
  echo "Run connect_admin_dashboard.sh first."
  exit 1
fi

# Backup the existing client profile screen.
cp "$PROFILE" "${PROFILE}.backup_before_admin_mode"

python3 - <<'PY'
from pathlib import Path

p = Path("lib/screens/profile_screen.dart")
s = p.read_text(encoding="utf-8")

# Add AdminEntryScreen import.
auth_import = "import '../providers/auth_provider.dart';"
admin_import = "import '../features/admin/screens/admin_entry_screen.dart';"

if admin_import not in s:
    s = s.replace(auth_import, auth_import + "\n" + admin_import, 1)

# Replace the spacer before logout with an Admin section + spacer.
old = """              const Spacer(),
              SizedBox(
                width: double.infinity,
"""

new = """              if (auth.canAccessAdmin) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.surfaceMuted,
                      child: Icon(
                        Icons.admin_panel_settings_outlined,
                        color: AppColors.primaryBrown,
                      ),
                    ),
                    title: Text(
                      'Администрирование',
                      style: AppTextStyles.rowLabel.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      auth.role?.title ?? 'Доступ администратора',
                      style: AppTextStyles.rowLabelMuted,
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.primaryBrown,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminEntryScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (!auth.canAccessAdmin) ...[
                const SizedBox(height: 8),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
"""

if old not in s:
    raise SystemExit("Could not find the expected logout section in profile_screen.dart.")

s = s.replace(old, new, 1)

p.write_text(s, encoding="utf-8")
PY

echo
echo "ProfileScreen updated."
echo "Backup:"
echo "  ${PROFILE}.backup_before_admin_mode"
echo
echo "Admin Mode is shown only when AuthProvider.canAccessAdmin == true."
echo
echo "Run:"
echo "  flutter analyze lib/screens/profile_screen.dart lib/features/admin"
echo
echo "IMPORTANT:"
echo "The current real login must eventually populate AuthProvider with the backend role."
echo "No production bypass was added."
