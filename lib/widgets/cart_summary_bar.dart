import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Контекстная floating-корзина.
/// Используется на Главной и в Каталоге.
/// Вертикальное положение задаётся экраном-владельцем.
class CartSummaryBar extends StatelessWidget {
  final int itemsCount;
  final int totalSum;
  final VoidCallback onTap;

  const CartSummaryBar({
    super.key,
    required this.itemsCount,
    required this.totalSum,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.caramel.withValues(alpha: .45)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 18,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AppColors.cream,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 20,
                color: AppColors.caramel,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$itemsCount ${pluralizeItems(itemsCount)} · ${formatPrice(totalSum)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cartBarText,
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.primaryBrown,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Корзина',
                        style: AppTextStyles.cartBarButton.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
