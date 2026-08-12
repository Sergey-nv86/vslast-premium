import 'package:flutter/material.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';

/// Строка товара в составе заказа на экране «Подтверждение заказа».
/// В отличие от [OrderItemTile] — только для чтения, без степпера и удаления,
/// так как заказ на этом этапе уже отправлен.
class ReceiptItemTile extends StatelessWidget {
  final OrderItemSnapshot item;

  const ReceiptItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              item.product.imageUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 56,
                height: 56,
                color: AppColors.surfaceMuted,
                child: const Icon(Icons.bakery_dining_outlined,
                    size: 20, color: AppColors.textSecondary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.product.name,
              style: AppTextStyles.orderItemName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text('${item.quantity} шт.', style: AppTextStyles.receiptQty),
          const SizedBox(width: 12),
          Text(formatPrice(item.lineTotal), style: AppTextStyles.orderItemPrice),
        ],
      ),
    );
  }
}
