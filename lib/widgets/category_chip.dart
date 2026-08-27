import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  IconData _iconForLabel() {
    switch (label.toLowerCase()) {
      case 'хлеб':
        return Icons.bakery_dining_outlined;
      case 'выпечка':
        return Icons.cookie_outlined;
      case 'торты':
        return Icons.cake_outlined;
      case 'десерты':
        return Icons.icecream_outlined;
      case 'кофе':
        return Icons.coffee_outlined;
      case 'все':
      default:
        return Icons.apps_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? AppColors.textPrimary
        : AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentLight : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.divider,
              width: 1,
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x12C4956A),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_iconForLabel(), size: 17, color: foreground),
              const SizedBox(width: 7),
              Text(
                label,
                style: AppTextStyles.categoryChip.copyWith(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
