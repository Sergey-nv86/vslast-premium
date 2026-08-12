import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_role.dart';
import '../features/admin/screens/admin_entry_screen.dart';
import '../theme/app_theme.dart';

/// Экран «Профиль» — показывается вместо «Вход/Регистрация», когда
/// пользователь уже входил в приложение раньше (AuthProvider.isLoggedIn).
/// Сейчас это минимальная заглушка с данными и кнопкой «Выйти» — по мере
/// появления бэкенда замените на реальные данные пользователя, историю,
/// настройки и т.д.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.divider, width: 1),
                      ),
                      child: const Icon(Icons.chevron_left,
                          size: 24, color: AppColors.primaryBrown),
                    ),
                  ),
                  Expanded(child: Text('Профиль', style: AppTextStyles.screenTitle)),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.person, size: 40, color: AppColors.primaryBrown),
              ),
              const SizedBox(height: 16),
              Text(
                auth.displayName.isNotEmpty ? auth.displayName : 'Гость Всласть',
                style: AppTextStyles.authHeading,
              ),
              const SizedBox(height: 4),
              Text('Вы вошли в приложение', style: AppTextStyles.rowLabelMuted),
              const SizedBox(height: 32),
              // TODO: здесь разместите реальные данные пользователя —
              // телефон, email, адреса доставки, способы оплаты и т.д.
              if (auth.canAccessAdmin) ...[
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
              // DEV ONLY — удалить после подключения backend auth.
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
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) Navigator.of(context).maybePop();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.primaryBrown, width: 1.4),
                    ),
                    alignment: Alignment.center,
                    child: Text('Выйти',
                        style: AppTextStyles.rowLabel.copyWith(color: AppColors.primaryBrown)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
