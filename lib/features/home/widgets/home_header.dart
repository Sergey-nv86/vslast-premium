import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/location_provider.dart';
import '../../../screens/auth_screen.dart';
import '../../../screens/catalog_screen.dart';
import '../../../screens/favorite_screen.dart';
import '../../../screens/orders_screen.dart';
import '../../../screens/profile_screen.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/product_image.dart';

/// Премиальная шапка Главной: продуктовый hero, персональное приветствие
/// и быстрый CTA в каталог. Сервисное меню профиля сохранено.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  void _openProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.xs),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: AppSpacing.sm),
            _ProfileMenuTile(icon: Icons.person_outline, label: 'Профиль', onTap: () {
              Navigator.pop(sheetContext);
              final auth = context.read<AuthProvider>();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => auth.isLoggedIn ? const ProfileScreen() : const AuthScreen(initialMode: AuthMode.login)));
            }),
            _ProfileMenuTile(icon: Icons.favorite_border, label: 'Избранное', onTap: () {
              Navigator.pop(sheetContext);
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FavoriteScreen()));
            }),
            _ProfileMenuTile(icon: Icons.location_on_outlined, label: 'Город', value: context.read<LocationProvider>().city, onTap: () {
              Navigator.pop(sheetContext);
              _pickCity(context);
            }),
            _ProfileMenuTile(icon: Icons.receipt_long_outlined, label: 'Мои заказы', onTap: () {
              Navigator.pop(sheetContext);
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrdersScreen()));
            }),
            const SizedBox(height: AppSpacing.xs),
          ],
        ),
      ),
    );
  }

  void _pickCity(BuildContext context) {
    final location = context.read<LocationProvider>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.xs),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Align(alignment: Alignment.centerLeft, child: Text('Ваш город', style: AppTextStyles.sectionLabel)),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final city in LocationProvider.availableCities)
              ListTile(
                title: Text(city, style: AppTextStyles.rowLabel),
                trailing: city == location.city ? const Icon(Icons.check, color: AppColors.caramel) : null,
                onTap: () { location.setCity(city); Navigator.pop(sheetContext); },
              ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ),
      ),
    );
  }

  String _greeting(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final displayName = auth.displayName.trim();
    final name = displayName.isNotEmpty && displayName != 'Пользователь' ? displayName.split(' ').first : '';
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
    context.watch<AuthProvider>();
    final top = MediaQuery.of(context).padding.top;
    const photoHeight = 160.0;

    return SizedBox(
      width: double.infinity,
      height: top + photoHeight,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ProductImage(imageUrl: 'assets/images/banner.png', fit: BoxFit.cover, iconSize: 40),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [AppColors.primaryBrown.withValues(alpha: .78), AppColors.primaryBrown.withValues(alpha: .18), Colors.transparent],
                    stops: const [0, .52, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.lg,
              top: top + 18,
              right: 78,
              child: Text(_greeting(context), style: AppTextStyles.screenTitleSmall.copyWith(color: Colors.white, fontSize: 22, height: 1.05, shadows: const [Shadow(blurRadius: 8, offset: Offset(0, 2))])),
            ),
            Positioned(
              left: AppSpacing.lg,
              bottom: 16,
              child: Text('Свежий хлеб и выпечка\nкаждый день.', style: AppTextStyles.rowLabelMuted.copyWith(color: Colors.white.withValues(alpha: .94), fontSize: 13, height: 1.25)),
            ),
            Positioned(
              right: AppSpacing.lg,
              top: top + 10,
              child: Material(
                color: Colors.white.withValues(alpha: .94),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _openProfileMenu(context),
                  child: const SizedBox(width: 40, height: 40, child: Icon(Icons.person_outline, size: 20, color: AppColors.textPrimary)),
                ),
              ),
            ),
            Positioned(
              right: AppSpacing.lg,
              bottom: 16,
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CatalogScreen())),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.cardBackground,
                  foregroundColor: AppColors.textPrimary,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button)),
                ),
                child: const Text('Выбрать'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _ProfileMenuTile({required this.icon, required this.label, required this.onTap, this.value});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(width: 36, height: 36, decoration: const BoxDecoration(color: AppColors.cream, shape: BoxShape.circle), child: Icon(icon, size: 18, color: AppColors.textPrimary)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(label, style: AppTextStyles.rowLabel)),
            if (value != null) ...[Text(value!, style: AppTextStyles.rowLabelMuted), const SizedBox(width: AppSpacing.xs)],
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
