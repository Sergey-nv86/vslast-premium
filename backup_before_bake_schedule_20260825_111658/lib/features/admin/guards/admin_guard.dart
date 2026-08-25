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

  const _AccessDenied({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4EE),
      appBar: AppBar(backgroundColor: const Color(0xFFF8F4EE), elevation: 0),
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
                style: const TextStyle(fontSize: 14, color: Color(0xFF806F65)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
