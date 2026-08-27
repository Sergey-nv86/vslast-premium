import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Контекстная floating-корзина. Не занимает место в нижней навигации.
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
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        elevation: 0,
        shadowColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: AppColors.divider),
            boxShadow: AppShadows.card,
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
                  color: AppColors.textPrimary,
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
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Корзина', style: AppTextStyles.cartBarButton),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                      ],
                    ),
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
