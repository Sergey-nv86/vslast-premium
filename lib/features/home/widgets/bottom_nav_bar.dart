import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PremiumBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const PremiumBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const Color _activeColor = Color(0xFF201C1A);
  static const Color _inactiveColor = Color(0xFF8A8177);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(
        top: 10,
        bottom: bottomInset > 0 ? bottomInset : 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF8),
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: .08), width: 1),
        ),
      ),
      child: Row(
        children: [
          _item(icon: 'assets/icons/home.svg', label: 'Главная', index: 0),
          _item(icon: 'assets/icons/catalog.svg', label: 'Каталог', index: 1),
          _item(icon: 'assets/icons/premium.svg', label: 'Карта', index: 2),
          _item(icon: 'assets/icons/discount.svg', label: 'Акции', index: 3),
          _item(icon: 'assets/icons/schedule.svg', label: 'График', index: 4),
        ],
      ),
    );
  }

  Widget _item({
    required String icon,
    required String label,
    required int index,
  }) {
    final selected = currentIndex == index;
    final color = selected ? _activeColor : _inactiveColor;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _boldIcon(icon, color, 23),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _boldIcon(String path, Color color, double size) {
    final colorFilter = ColorFilter.mode(color, BlendMode.srcIn);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          SvgPicture.asset(
            path,
            width: size,
            height: size,
            colorFilter: colorFilter,
          ),
          Positioned(
            left: 0.6,
            top: 0.6,
            child: SvgPicture.asset(
              path,
              width: size,
              height: size,
              colorFilter: colorFilter,
            ),
          ),
        ],
      ),
    );
  }
}
