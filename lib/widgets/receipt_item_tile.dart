import 'package:flutter/material.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';
import 'product_image.dart';

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
          SizedBox(
            width: 56,
            height: 56,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ProductImage(
                imageUrl: item.product.imageUrl,
                fit: BoxFit.cover,
                iconSize: 20,
                borderRadius: BorderRadius.circular(12),
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
          Text(
            formatPrice(item.lineTotal),
            style: AppTextStyles.orderItemPrice,
          ),
        ],
      ),
    );
  }
}
