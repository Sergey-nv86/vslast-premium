import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/permission.dart';
import '../../../models/user_role.dart';
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
  return MaterialPageRoute<void>(builder: (_) => const AdminEntryScreen());
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
