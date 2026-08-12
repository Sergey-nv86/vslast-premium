#!/bin/bash
set -e

PROJECT_ROOT="$(pwd)"
AUTH="lib/providers/auth_provider.dart"
GUARD_DIR="lib/features/admin/guards"
GUARD="$GUARD_DIR/admin_guard.dart"

mkdir -p "$GUARD_DIR"

# Backup current provider before a surgical edit.
if [ -f "$AUTH" ]; then
  cp "$AUTH" "${AUTH}.backup_before_admin_guard"
else
  echo "ERROR: $AUTH not found. Run this script from the vslast-premium project root."
  exit 1
fi

python3 - <<'PY'
from pathlib import Path

p = Path("lib/providers/auth_provider.dart")
s = p.read_text(encoding="utf-8")

# Add compatibility methods only if they are missing.
if "void markLoggedIn(" not in s:
    marker = "  Future<void> signOut() async {"
    insert = """  /// Compatibility method for the existing client auth flow.
  /// Replace with real authentication/session restoration when backend auth is connected.
  void markLoggedIn() {
    if (_user != null) return;
    _user = AuthUser(
      id: 'demo-customer',
      displayName: 'Пользователь',
      phone: '',
      role: UserRole.customer,
      permissions: RolePermissions.forRole(UserRole.customer),
    );
    notifyListeners();
  }

"""
    if marker not in s:
        raise SystemExit("Could not find signOut() marker in AuthProvider.")
    s = s.replace(marker, insert + marker, 1)

if "Future<void> logout(" not in s:
    marker = "  Future<void> signOut() async {"
    insert = """  /// Compatibility alias used by the existing profile screen.
  Future<void> logout() => signOut();

"""
    if marker not in s:
        raise SystemExit("Could not find signOut() marker in AuthProvider.")
    s = s.replace(marker, insert + marker, 1)

p.write_text(s, encoding="utf-8")
PY

cat > "$GUARD" <<'DART'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/permission.dart';
import '../../../providers/auth_provider.dart';

/// Protects an admin screen from users without the required permission.
///
/// The UI check is only a convenience. Real authorization must also be
/// enforced by the backend when API integration is added.
class AdminGuard extends StatelessWidget {
  final Widget child;
  final Permission permission;

  const AdminGuard({
    super.key,
    required this.child,
    this.permission = Permission.viewDashboard,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn) {
      return const _AccessDenied(
        title: 'Требуется авторизация',
        message: 'Войдите в приложение, чтобы открыть раздел администратора.',
      );
    }

    if (!auth.canAccessAdmin || !auth.hasPermission(permission)) {
      return const _AccessDenied(
        title: 'Нет доступа',
        message: 'У вашей роли нет разрешения на этот раздел.',
      );
    }

    return child;
  }
}

class _AccessDenied extends StatelessWidget {
  final String title;
  final String message;

  const _AccessDenied({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F4EE),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 52,
                color: Color(0xFF8B5E3C),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3B281F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF806F65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
DART

echo
echo "AdminGuard created: $GUARD"
echo "AuthProvider backup: ${AUTH}.backup_before_admin_guard"
echo
echo "Analyze:"
echo "flutter analyze lib/features/admin/guards/admin_guard.dart lib/providers/auth_provider.dart"
echo
echo "IMPORTANT:"
echo "This script does NOT alter main.dart or existing navigation."
echo "The next step is to connect AdminGuard + AdminDashboardScreen to the actual router/navigation."
