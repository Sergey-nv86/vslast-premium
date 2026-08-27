import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/location_provider.dart';
import '../../../screens/auth_screen.dart';
import '../../../screens/favorite_screen.dart';
import '../../../screens/orders_screen.dart';
import '../../../screens/profile_screen.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/product_image.dart';

/// Премиальная шапка Главной: hero-баннер, персональное приветствие и меню профиля.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  void _openProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet))),
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: AppSpacing.xs),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: AppSpacing.sm),
          _ProfileMenuTile(icon: Icons.person_outline, label: 'Профиль', onTap: () { Navigator.pop(sheetContext); final auth = context.read<AuthProvider>(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => auth.isLoggedIn ? const ProfileScreen() : const AuthScreen(initialMode: AuthMode.login))); }),
          _ProfileMenuTile(icon: Icons.favorite_border, label: 'Избранное', onTap: () { Navigator.pop(sheetContext); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FavoriteScreen())); }),
          _ProfileMenuTile(icon: Icons.location_on_outlined, label: 'Город', value: context.read<LocationProvider>().city, onTap: () { Navigator.pop(sheetContext); _pickCity(context); }),
          _ProfileMenuTile(icon: Icons.receipt_long_outlined, label: 'Мои заказы', onTap: () { Navigator.pop(sheetContext); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrdersScreen())); }),
          const SizedBox(height: AppSpacing.xs),
        ]),
      ),
    );
  }

  void _pickCity(BuildContext context) {
    final location = context.read<LocationProvider>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet))),
      builder: (sheetContext) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: AppSpacing.xs),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: AppSpacing.md),
        Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg), child: Align(alignment: Alignment.centerLeft, child: Text('Ваш город', style: AppTextStyles.sectionLabel))),
        const SizedBox(height: AppSpacing.xs),
        for (final city in LocationProvider.availableCities)
          ListTile(title: Text(city, style: AppTextStyles.rowLabel), trailing: city == location.city ? const Icon(Icons.check, color: AppColors.caramel) : null, onTap: () { location.setCity(city); Navigator.pop(sheetContext); }),
        const SizedBox(height: AppSpacing.xs),
      ])),
    );
  }

  String _greeting(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final displayName = auth.displayName.trim();
    final name = displayName.isNotEmpty && displayName != 'Пользователь' ? displayName.split(' ').first : '';
    final hour = DateTime.now().hour;
    final greeting = switch (hour) { >= 5 && < 12 => 'Доброе утро', >= 12 && < 18 => 'Добрый день', >= 18 => 'Добрый вечер', _ => 'Доброй ночи' };
    return name.isEmpty ? greeting : '$greeting,\n$name!';
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    const photoHeight = 160.0;
    return SizedBox(
      width: double.infinity,
      height: top + photoHeight,
      child: Stack(fit: StackFit.expand, children: [
        const ProductImage(imageUrl: 'assets/images/hero_banner.jpg', fit: BoxFit.cover, iconSize: 40),
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomLeft, end: Alignment.topRight, colors: [Colors.white.withValues(alpha: .84), Colors.white.withValues(alpha: .30), Colors.transparent], stops: const [0, .52, 1])))),
        Positioned(left: AppSpacing.lg, top: top + 18, right: 70, child: Text(_greeting(context), style: AppTextStyles.screenTitleSmall.copyWith(color: AppColors.primaryBrown, fontSize: 22, height: 1.05))),
        Positioned(left: AppSpacing.lg, bottom: 16, right: AppSpacing.lg, child: Text('Испечено с любовью для Вас', style: AppTextStyles.rowLabelMuted.copyWith(color: AppColors.primaryBrown, fontSize: 13, fontWeight: FontWeight.w600))),
        Positioned(right: AppSpacing.lg, top: top + 10, child: Material(color: Colors.white.withValues(alpha: .94), shape: const CircleBorder(), child: InkWell(customBorder: const CircleBorder(), onTap: () => _openProfileMenu(context), child: const SizedBox(width: 40, height: 40, child: Icon(Icons.person_outline, size: 20, color: AppColors.primaryBrown)))),
      ]),
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
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm), child: Row(children: [Container(width: 36, height: 36, decoration: const BoxDecoration(color: AppColors.cream, shape: BoxShape.circle), child: Icon(icon, size: 18, color: AppColors.primaryBrown)), const SizedBox(width: AppSpacing.sm), Expanded(child: Text(label, style: AppTextStyles.rowLabel)), if (value != null) ...[Text(value!, style: AppTextStyles.rowLabelMuted), const SizedBox(width: AppSpacing.xs)], const Icon(Icons.chevron_right, color: AppColors.textSecondary)]));
}
