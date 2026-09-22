import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/permission.dart';
import '../../../models/user_role.dart';
import '../../../providers/auth_provider.dart';
import '../guards/admin_guard.dart';
import 'admin_dashboard_screen.dart';
import 'admin_settings_screen.dart';

class AdminEntryScreen extends StatelessWidget {
  const AdminEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminGuard(
      permission: Permission.viewDashboard,
      child: Stack(
        children: [
          const AdminDashboardScreen(),
          Positioned(
            right: 18,
            bottom: 18,
            child: SafeArea(
              child: FloatingActionButton.extended(
                heroTag: 'admin-settings',
                backgroundColor: const Color(0xFF8B5E3C),
                foregroundColor: Colors.white,
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Настройки'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminSettingsScreen()),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Route<void> adminEntryRoute() {
  return MaterialPageRoute<void>(builder: (_) => const AdminEntryScreen());
}

void openAdminMode(BuildContext context) {
  Navigator.of(context).push(adminEntryRoute());
}

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
