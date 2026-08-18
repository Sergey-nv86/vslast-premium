import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/location_provider.dart';
import '../../../screens/auth_screen.dart';
import '../../../screens/favorite_screen.dart';
import '../../../screens/orders_screen.dart';
import '../../../screens/profile_screen.dart';
import '../../../theme/app_theme.dart';

/// Шапка «Главной»: фото-баннер, приветствие и иконка профиля.
/// Строку поиска отсюда убрали по вашей просьбе — если понадобится
/// вернуть, поищите её в истории версий этого файла.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  void _openProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            _ProfileMenuTile(
              icon: Icons.person_outline,
              label: 'Профиль',
              onTap: () {
                Navigator.pop(sheetContext);
                // Вход нужен только один раз: если пользователь уже
                // входил раньше (AuthProvider.isLoggedIn сохраняется на
                // устройстве) — сразу открываем «Профиль», а не форму
                // входа. Иначе — «Регистрацию», данных ещё нет.
                final auth = context.read<AuthProvider>();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => auth.isLoggedIn
                        ? const ProfileScreen()
                        : const AuthScreen(initialMode: AuthMode.login),
                  ),
                );
              },
            ),
            _ProfileMenuTile(
              icon: Icons.favorite_border,
              label: 'Избранное',
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FavoriteScreen()),
                );
              },
            ),
            _ProfileMenuTile(
              icon: Icons.location_on_outlined,
              label: 'Город',
              value: context.read<LocationProvider>().city,
              onTap: () {
                Navigator.pop(sheetContext);
                _pickCity(context);
              },
            ),
            _ProfileMenuTile(
              icon: Icons.receipt_long_outlined,
              label: 'Мои заказы',
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OrdersScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _pickCity(BuildContext context) {
    final location = context.read<LocationProvider>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Ваш город', style: AppTextStyles.sectionLabel),
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (final city in LocationProvider.availableCities)
              ListTile(
                title: Text(city, style: AppTextStyles.rowLabel),
                trailing: city == location.city
                    ? const Icon(Icons.check, color: AppColors.primaryBrown)
                    : null,
                onTap: () {
                  location.setCity(city);
                  Navigator.pop(sheetContext);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _greeting(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final displayName = auth.displayName.trim();

    final name = displayName.isNotEmpty && displayName != 'Пользователь'
        ? displayName.split(' ').first
        : '';

    final hour = DateTime.now().hour;

    final greeting = switch (hour) {
      >= 5 && < 12 => 'Доброе утро',
      >= 12 && < 18 => 'Добрый день',
      >= 18 => 'Добрый вечер',
      _ => 'Доброй ночи',
    };

    return name.isEmpty ? greeting : '$greeting,\n$name!';
  }

  @override
  Widget build(BuildContext context) {
    // HomeHeader должен перестраиваться сразу после смены пользователя.
    context.watch<AuthProvider>();

    final top = MediaQuery.of(context).padding.top;
    const double photoHeight = 140;

    return SizedBox(
      width: double.infinity,
      height: top + photoHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/hero_banner.jpg',
              fit: BoxFit.cover,
            ),
          ),

          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 260,
              height: top + photoHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white.withOpacity(.55),
                    Colors.white.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            left: 22,
            top: top + 16,
            right: 96,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(context),
                  style: GoogleFonts.alice(
                    color: AppColors.primaryBrown,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Испечено с любовью\nдля Вас.',
                  style: AppTextStyles.rowLabelMuted.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            right: 22,
            top: top + 6,
            child: GestureDetector(
              onTap: () => _openProfileMenu(context),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.94),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 15,
                  color: AppColors.linkAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _ProfileMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: AppColors.primaryBrown),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: AppTextStyles.rowLabel)),
            if (value != null) ...[
              Text(value!, style: AppTextStyles.rowLabelMuted),
              const SizedBox(width: 6),
            ],
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
