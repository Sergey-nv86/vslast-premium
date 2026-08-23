import 'package:flutter/material.dart';
import '../models/order_list_item.dart';
import '../theme/app_theme.dart';

class OrderStatusPill extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isPending = status == OrderStatus.processing;
    final bg = isPending
        ? AppColors.statusPendingBg
        : AppColors.statusSuccessBg;
    final fg = isPending
        ? AppColors.statusPendingText
        : AppColors.statusSuccessText;
    final icon = isPending ? Icons.sync : Icons.check_circle;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: AppTextStyles.statusPillLabel.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}
