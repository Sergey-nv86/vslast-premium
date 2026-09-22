import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../features/admin/screens/admin_entry_screen.dart';
import '../theme/app_theme.dart';
import '../core/build_info.dart';
import '../services/push_notification_service.dart';

/// Экран «Профиль» — показывается вместо «Вход/Регистрация», когда
/// пользователь уже входил в приложение раньше (AuthProvider.isLoggedIn).
/// Сейчас это минимальная заглушка с данными и кнопкой «Выйти» — по мере
/// появления бэкенда замените на реальные данные пользователя, историю,
/// настройки и т.д.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final PushNotificationService _pushService = PushNotificationService.instance;

  bool _notificationsLoading = true;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationState();
  }

  Future<void> _loadNotificationState() async {
    try {
      final enabled = await _pushService.isNotificationPermissionGranted();

      if (enabled) {
        debugPrint(
          'PROFILE: notification permission already granted, '
          'registering existing Web Push token',
        );

        await _pushService.registerExistingPermissionToken();
      }

      if (!mounted) return;

      setState(() {
        _notificationsEnabled = enabled;
        _notificationsLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('PROFILE notification state error: $error');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _notificationsEnabled = false;
        _notificationsLoading = false;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    if (_notificationsLoading) return;

    setState(() {
      _notificationsLoading = true;
    });

    try {
      if (value) {
        debugPrint('PROFILE: enabling notifications');

        final success = await _pushService.requestPermissionAndRegister();

        if (!mounted) return;

        setState(() {
          _notificationsEnabled = success;
          _notificationsLoading = false;
        });

        debugPrint('PROFILE: notifications enable result=$success');

        if (!success) {
          final diagnostic =
              _pushService.lastPushDiagnostic ??
              'Web Push не был включён. Причина не определена.';

          debugPrint('PROFILE PUSH DIAGNOSTIC: $diagnostic');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(diagnostic),
              duration: const Duration(seconds: 7),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Уведомления включены'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        debugPrint('PROFILE: disabling notifications');

        await _pushService.disableCurrentDevice();

        if (!mounted) return;

        setState(() {
          _notificationsEnabled = false;
          _notificationsLoading = false;
        });

        debugPrint('PROFILE: notifications disabled');
      }
    } catch (error, stackTrace) {
      debugPrint('PROFILE notification toggle error: $error');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _notificationsLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // PushNotificationService — глобальный singleton.
    // Не отменяем его listeners при закрытии экрана Профиль.
    super.dispose();
  }

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
                      child: const Icon(
                        Icons.chevron_left,
                        size: 24,
                        color: AppColors.primaryBrown,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text('Профиль', style: AppTextStyles.screenTitle),
                  ),
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
                child: const Icon(
                  Icons.person,
                  size: 40,
                  color: AppColors.primaryBrown,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                auth.displayName.isNotEmpty
                    ? auth.displayName
                    : 'Гость Всласть',
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
                      auth.role?.toString().split('.').last ??
                          'Доступ администратора',
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
              if (!auth.canAccessAdmin) ...[const SizedBox(height: 8)],
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 12),
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
                      Icons.notifications_none_outlined,
                      color: AppColors.primaryBrown,
                    ),
                  ),
                  title: Text(
                    'Уведомления',
                    style: AppTextStyles.rowLabel.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: _notificationsLoading
                      ? Text(
                          'Проверяем состояние…',
                          style: AppTextStyles.rowLabelMuted,
                        )
                      : Text(
                          _notificationsEnabled
                              ? 'Уведомления включены'
                              : 'Уведомления выключены',
                          style: AppTextStyles.rowLabelMuted,
                        ),
                  trailing: Switch(
                    value: _notificationsEnabled,
                    onChanged: _notificationsLoading
                        ? null
                        : _toggleNotifications,
                    activeThumbColor: AppColors.primaryBrown,
                  ),
                ),
              ),

              const Spacer(),
              Center(
                child: Text(
                  'Сборка: $buildLabel',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 10),

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
                      border: Border.all(
                        color: AppColors.primaryBrown,
                        width: 1.4,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Выйти',
                      style: AppTextStyles.rowLabel.copyWith(
                        color: AppColors.primaryBrown,
                      ),
                    ),
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
