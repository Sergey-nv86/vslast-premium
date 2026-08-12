#!/bin/bash
set -e

PROFILE="lib/screens/profile_screen.dart"
ROLE="lib/models/user_role.dart"

echo "Fixing Admin Profile..."

if [ ! -f "$PROFILE" ]; then
  echo "ERROR: $PROFILE not found"
  exit 1
fi

if [ ! -f "$ROLE" ]; then
  echo "ERROR: $ROLE not found"
  exit 1
fi

cp "$PROFILE" "${PROFILE}.backup_before_fix"

python3 - <<'PY'
from pathlib import Path

# ---------- user_role.dart ----------
p = Path("lib/models/user_role.dart")
s = p.read_text(encoding="utf-8")

if "extension UserRoleX" not in s:
    s += r'''

extension UserRoleX on UserRole {
  String get value => switch (this) {
    UserRole.owner => 'owner',
    UserRole.admin => 'admin',
    UserRole.manager => 'manager',
    UserRole.seller => 'seller',
    UserRole.baker => 'baker',
    UserRole.pastryChef => 'pastry_chef',
    UserRole.customer => 'customer',
  };

  String get title => switch (this) {
    UserRole.owner => 'Владелец',
    UserRole.admin => 'Администратор',
    UserRole.manager => 'Управляющий',
    UserRole.seller => 'Продавец',
    UserRole.baker => 'Пекарь',
    UserRole.pastryChef => 'Кондитер',
    UserRole.customer => 'Клиент',
  };

  bool get canAccessAdmin => this != UserRole.customer;
}
'''
    p.write_text(s, encoding="utf-8")
    print("Added UserRoleX.")

# ---------- profile_screen.dart ----------
p = Path("lib/screens/profile_screen.dart")
s = p.read_text(encoding="utf-8")

old = """auth.displayName?.isNotEmpty == true ? auth.displayName! : 'Гость Всласть'"""

new = """auth.displayName.isNotEmpty ? auth.displayName : 'Гость Всласть'"""

if old in s:
    s = s.replace(old, new, 1)
    p.write_text(s, encoding="utf-8")
    print("Fixed nullable displayName usage.")
else:
    print("displayName expression already fixed or not found.")

PY

echo
echo "Fix completed."
echo
echo "Run:"
echo "flutter analyze lib/screens/profile_screen.dart lib/features/admin"
