import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/bake_schedule/screens/bake_schedule_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/promotions/screens/promotions_screen.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/tab_navigation_controller.dart';
import '../screens/auth_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/profile_screen.dart';
import '../theme/app_theme.dart';
import '../theme/premium_design_system.dart';
import 'catalog_screen.dart';
import 'loyalty_screen.dart';

class DesktopMainScreen extends StatefulWidget {
  final List<Product> products;
  final bool isLoading;

  const DesktopMainScreen({
    super.key,
    required this.products,
    required this.isLoading,
  });

  @override
  State<DesktopMainScreen> createState() => _DesktopMainScreenState();
}

class _DesktopMainScreenState extends State<DesktopMainScreen> {
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = List<Widget>.generate(5, (_) => const SizedBox.shrink());
    _pages[0] = HomeScreen(
      products: widget.products,
      isLoading: widget.isLoading,
    );
  }

  @override
  void didUpdateWidget(covariant DesktopMainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.products != widget.products ||
        oldWidget.isLoading != widget.isLoading) {
      _pages[0] = HomeScreen(
        products: widget.products,
        isLoading: widget.isLoading,
      );
    }
  }

  Widget _pageFor(int index) {
    final existing = _pages[index];
    if (existing is! SizedBox || index == 0) return existing;

    final Widget page = switch (index) {
      1 => const CatalogScreen(),
      2 => const BakeScheduleScreen(),
      3 => const PromotionsScreen(),
      4 => const LoyaltyScreen(),
      _ => const SizedBox.shrink(),
    };
    _pages[index] = page;
    return page;
  }

  List<Widget> _buildPages() =>
      List<Widget>.generate(5, _pageFor);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 1200;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          _AdaptiveSidebar(compact: compact),
          Expanded(
            child: ColoredBox(
              color: AppColors.background,
              child: IndexedStack(
                index: context.watch<TabNavigationController>().currentIndex,
                children: [
                  ..._buildPages(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdaptiveSidebar extends StatelessWidget {
  final bool compact;

  const _AdaptiveSidebar({required this.compact});

  static const _items = <({IconData icon, String label})>[
    (icon: Icons.home_outlined, label: 'Главная'),
    (icon: Icons.grid_view_outlined, label: 'Каталог'),
    (icon: Icons.schedule_outlined, label: 'Запеки'),
    (icon: Icons.local_offer_outlined, label: 'Акции'),
    (icon: Icons.workspace_premium_outlined, label: 'Лояльность'),
  ];

  void _openProfile(BuildContext context) {
    final auth = context.read<AuthProvider>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => auth.isLoggedIn
            ? const ProfileScreen()
            : const AuthScreen(initialMode: AuthMode.login),
      ),
    );
  }

  void _openCart(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CartScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = context.watch<TabNavigationController>().currentIndex;
    final cart = context.watch<CartProvider>();

    return Container(
      width: compact ? 88 : 248,
      decoration: const BoxDecoration(
        color: VslastColors.surface,
        border: Border(
          right: BorderSide(color: VslastColors.divider),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 8 : 24,
                22,
                compact ? 8 : 20,
                18,
              ),
              child: compact
                  ? const Text(
                      'В',
                      style: TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: VslastColors.textPrimary,
                      ),
                    )
                  : const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'ВСЛАСТЬ',
                        style: TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.2,
                          color: VslastColors.textPrimary,
                        ),
                      ),
                    ),
            ),
            if (!compact)
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 20, 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ремесленная пекарня · Нижневартовск',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: VslastColors.textSecondary,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final selected = currentIndex == index;

                  return Tooltip(
                    message: compact ? item.label : '',
                    child: Semantics(
                      button: true,
                      selected: selected,
                      label: item.label,
                      child: InkWell(
                        onTap: () => context
                            .read<TabNavigationController>()
                            .setIndex(index),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          height: 52,
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 0 : 14,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? VslastColors.accentLight
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: compact
                                ? MainAxisAlignment.center
                                : MainAxisAlignment.start,
                            children: [
                              Icon(
                                item.icon,
                                size: 21,
                                color: selected
                                    ? VslastColors.textPrimary
                                    : VslastColors.textSecondary,
                              ),
                              if (!compact) ...[
                                const SizedBox(width: 13),
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: selected
                                        ? VslastColors.textPrimary
                                        : VslastColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 10 : 18,
                10,
                compact ? 10 : 18,
                14,
              ),
              child: Column(
                children: [
                  _SidebarAction(
                    compact: compact,
                    icon: Icons.shopping_bag_outlined,
                    label: 'Корзина',
                    badge: cart.totalCount == 0 ? null : '\${cart.totalCount}',
                    onTap: () => _openCart(context),
                  ),
                  const SizedBox(height: 6),
                  _SidebarAction(
                    compact: compact,
                    icon: Icons.person_outline,
                    label: 'Профиль',
                    onTap: () => _openProfile(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarAction extends StatelessWidget {
  final bool compact;
  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback onTap;

  const _SidebarAction({
    required this.compact,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: compact ? label : '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 12),
          decoration: BoxDecoration(
            border: Border.all(color: VslastColors.divider),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment:
                compact ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 20, color: VslastColors.textPrimary),
                  if (badge != null)
                    Positioned(
                      top: -8,
                      right: -10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.caramel,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (!compact) ...[
                const SizedBox(width: 10),
                Text(
                  label,
                  style: AppTextStyles.rowLabel,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
