import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Карточка-переключатель для «Способ получения» и «Способ оплаты».
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primaryBrown : AppColors.divider,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 22, color: AppColors.primaryBrown),
                const SizedBox(height: 10),
                Text(title, style: AppTextStyles.optionTitle),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.optionSubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            if (selected)
              const Positioned(
                top: 0,
                right: 0,
                child: Icon(Icons.check_circle,
                    size: 18, color: AppColors.primaryBrown),
              ),
          ],
        ),
      ),
    );
  }
}
