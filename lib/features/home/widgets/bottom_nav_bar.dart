import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../theme/premium_design_system.dart';

class PremiumBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const PremiumBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = <_NavItem>[
    _NavItem('assets/icons/home.svg', 'Главная'),
    _NavItem('assets/icons/catalog.svg', 'Каталог'),
    _NavItem('assets/icons/schedule.svg', 'Запеки'),
    _NavItem('assets/icons/discount.svg', 'Акции'),
    _NavItem('assets/icons/premium.svg', 'Лояльность'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: VslastColors.surface,
        boxShadow: [
          BoxShadow(
            color: VslastColors.shadow,
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        8,
        8,
        8,
        bottomInset > 0 ? bottomInset + 6 : 10,
      ),
      child: Row(
        children: [
          for (var index = 0; index < _items.length; index++)
            Expanded(
              child: _item(
                context,
                item: _items[index],
                index: index,
              ),
            ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required _NavItem item,
    required int index,
  }) {
    final selected = currentIndex == index;
    final color = selected
        ? VslastColors.textPrimary
        : VslastColors.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(VslastRadii.button),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
          decoration: BoxDecoration(
            color: selected ? VslastColors.accentLight : Colors.transparent,
            borderRadius: BorderRadius.circular(VslastRadii.button),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.04 : 1,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: _icon(item.icon, color),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  height: 14 / 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _icon(String path, Color color) {
    return SizedBox(
      width: 22,
      height: 22,
      child: SvgPicture.asset(
        path,
        width: 22,
        height: 22,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }
}

class _NavItem {
  final String icon;
  final String label;

  const _NavItem(this.icon, this.label);
}
