import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Premium-карточка выбора для «Способ получения» и «Способ оплаты».
class SelectableOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const SelectableOptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$title. $subtitle',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFF5E6D3)
                : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? const Color(0xFFC4956A) : AppColors.divider,
              width: selected ? 1.2 : 1,
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x0D8B5E3C),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.72)
                            : const Color(0xFFF8F4EE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        icon,
                        size: 21,
                        color: AppColors.primaryBrown,
                      ),
                    ),
                    const SizedBox(height: 11),
                    Text(
                      title,
                      style: AppTextStyles.optionTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.optionSubtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: selected
                      ? Container(
                          key: const ValueKey('selected'),
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryBrown,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          ),
                        )
                      : const SizedBox(
                          key: ValueKey('unselected'),
                          width: 22,
                          height: 22,
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
