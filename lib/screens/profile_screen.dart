import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_role.dart';
import '../features/admin/screens/admin_entry_screen.dart';
import '../theme/app_theme.dart';
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
  final PushNotificationService _pushService =
      PushNotificationService.instance;

  bool _notificationsLoading = true;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationState();
  }

  Future<void> _loadNotificationState() async {
    try {
      final enabled =
          await _pushService.isNotificationPermissionGranted();

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

        final success =
            await _pushService.requestPermissionAndRegister();

        if (!mounted) return;

        setState(() {
          _notificationsEnabled = success;
          _notificationsLoading = false;
        });

        debugPrint(
          'PROFILE: notifications enable result=$success',
        );
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
              if (!auth.canAccessAdmin) ...[const SizedBox(height: 8)],
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
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.divider,
                  ),
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

              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.divider,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.surfaceMuted,
                    child: Icon(
                      Icons.key_outlined,
                      color: AppColors.primaryBrown,
                    ),
                  ),
                  title: Text(
                    'Показать FCM token',
                    style: AppTextStyles.rowLabel.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Временная диагностика push',
                    style: AppTextStyles.rowLabelMuted,
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.primaryBrown,
                  ),
                  onTap: () async {
                    final token =
                        await _pushService.getCurrentFcmToken();

                    if (!context.mounted) return;

                    await showDialog<void>(
                      context: context,
                      builder: (dialogContext) {
                        return AlertDialog(
                          title: const Text('FCM token'),
                          content: SelectableText(
                            token ?? 'FCM token не получен',
                          ),
                          actions: [
                            if (token != null && token.isNotEmpty)
                              TextButton(
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: token),
                                  );

                                  if (!dialogContext.mounted) return;

                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'FCM token скопирован',
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Копировать'),
                              ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              child: const Text('Закрыть'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

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
