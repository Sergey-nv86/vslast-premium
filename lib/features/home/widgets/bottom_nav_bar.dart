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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: 80,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            _item(icon: 'assets/icons/home.svg', label: 'Главная', index: 0),

            _item(icon: 'assets/icons/catalog.svg', label: 'Каталог', index: 1),

            _loyaltyButton(),

            _item(
              icon: 'assets/icons/favorite.svg',
              label: 'Избранное',
              index: 3,
            ),

            _item(icon: 'assets/icons/add.svg', label: 'Корзина', index: 4),
          ],
        ),
      ),
    );
  }

  Widget _item({
    required String icon,
    required String label,
    required int index,
  }) {
    final selected = currentIndex == index;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF7B4A22).withOpacity(.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              SvgPicture.asset(
                icon,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  selected ? const Color(0xFF7B4A22) : const Color(0xFF9A948E),
                  BlendMode.srcIn,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? const Color(0xFF7B4A22)
                      : const Color(0xFF9A948E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loyaltyButton() {
    final selected = currentIndex == 2;

    return SizedBox(
      width: 84,
      child: GestureDetector(
        onTap: () => onTap(2),
        child: Column(
          children: [
            Transform.translate(
              offset: const Offset(0, -10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF7B4A22),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF7B4A22,
                      ).withOpacity(selected ? .40 : .28),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SvgPicture.asset(
                    'assets/icons/premium.svg',
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),

            Transform.translate(
              offset: const Offset(0, -6),
              child: Text(
                'Карта',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? const Color(0xFF7B4A22)
                      : const Color(0xFF9A948E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
