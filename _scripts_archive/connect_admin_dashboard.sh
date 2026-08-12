#!/bin/bash
set -e

ROOT="$(pwd)"
ADMIN_DIR="lib/features/admin"
SCREEN_DIR="$ADMIN_DIR/screens"
ENTRY="$SCREEN_DIR/admin_entry_screen.dart"

mkdir -p "$SCREEN_DIR"

if [ ! -f "$SCREEN_DIR/admin_dashboard_screen.dart" ]; then
  echo "ERROR: $SCREEN_DIR/admin_dashboard_screen.dart not found."
  echo "First install the AdminDashboardScreen script."
  exit 1
fi

if [ ! -f "lib/features/admin/guards/admin_guard.dart" ]; then
  echo "ERROR: lib/features/admin/guards/admin_guard.dart not found."
  echo "First run connect_admin_guard.sh."
  exit 1
fi

cat > "$ENTRY" <<'DART'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/permission.dart';
import '../../../providers/auth_provider.dart';
import '../guards/admin_guard.dart';
import 'admin_dashboard_screen.dart';

/// Entry point for Admin Mode.
///
/// It does not perform authentication itself. It asks AuthProvider for the
/// current session and AdminGuard decides whether the user may enter.
class AdminEntryScreen extends StatelessWidget {
  const AdminEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminGuard(
      permission: Permission.viewDashboard,
      child: const AdminDashboardScreen(),
    );
  }
}

/// Convenient route factory for the existing Navigator-based navigation.
Route<void> adminEntryRoute() {
  return MaterialPageRoute<void>(
    builder: (_) => const AdminEntryScreen(),
  );
}

/// Opens Admin Mode from an existing screen.
///
/// Example:
/// openAdminMode(context);
void openAdminMode(BuildContext context) {
  Navigator.of(context).push(adminEntryRoute());
}

/// Development helper: signs in the current session as owner and opens Admin.
/// Do not use this helper in production. It exists only to test the Admin UI
/// before the real backend authentication is connected.
Future<void> openAdminModeAsMockOwner(BuildContext context) async {
  final auth = context.read<AuthProvider>();

  await auth.signInMock(
    role: UserRole.owner,
    id: 'demo-owner',
    displayName: 'Сергей',
    phone: '+7 900 000-00-00',
  );

  if (!context.mounted) return;

  openAdminMode(context);
}
DART

# Add the missing UserRole import because the development helper uses it.
python3 - <<'PY'
from pathlib import Path

p = Path("lib/features/admin/screens/admin_entry_screen.dart")
s = p.read_text(encoding="utf-8")

needle = "import '../../../models/permission.dart';"
replacement = "import '../../../models/permission.dart';\nimport '../../../models/user_role.dart';"

if needle not in s:
    raise SystemExit("Expected import marker was not found.")

s = s.replace(needle, replacement, 1)
p.write_text(s, encoding="utf-8")
PY

echo
echo "AdminEntryScreen created:"
echo "  $ENTRY"
echo
echo "Architecture:"
echo "  AuthProvider -> AdminGuard -> AdminDashboardScreen"
echo
echo "Analyze:"
echo "  flutter analyze $ENTRY lib/features/admin/guards/admin_guard.dart lib/features/admin/screens/admin_dashboard_screen.dart"
echo
echo "To open from an existing screen:"
echo "  openAdminMode(context);"
echo
echo "For development-only testing:"
echo "  openAdminModeAsMockOwner(context);"
echo
echo "NOTE: mock owner login is for development only and must not be used in production."
