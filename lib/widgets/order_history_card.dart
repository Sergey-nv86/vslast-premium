import 'package:flutter/material.dart';
import '../models/order_list_item.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import 'order_status_pill.dart';

/// Карточка одного заказа в списке «Мои заказы». Набор кнопок внизу
/// зависит от статуса: у «В обработке» — только описание и сумма,
/// у «Подтвержден» — кнопка оплаты по СБП + QR, у «Исполнен» — кнопка
/// «Повторить заказ».
class OrderHistoryCard extends StatelessWidget {
  final OrderListItem order;
  final VoidCallback? onTap;
  final VoidCallback? onPay;
  final VoidCallback? onShowQr;
  final VoidCallback? onRepeat;

  const OrderHistoryCard({
    super.key,
    required this.order,
    this.onTap,
    this.onPay,
    this.onShowQr,
    this.onRepeat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Заказ №${order.number}',
                              style: AppTextStyles.orderNumber,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          OrderStatusPill(status: order.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        order.title,
                        style: AppTextStyles.orderTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${formatRuDateWithYear(order.placedAt)} • ${formatRuTime(order.placedAt)}',
                              style: AppTextStyles.rowLabelMuted,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    switch (order.status) {
      case OrderStatus.processing:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                order.statusDescription,
                style: AppTextStyles.rowLabelMuted,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              formatPrice(order.totalPrice),
              style: AppTextStyles.orderItemPrice,
            ),
          ],
        );

      case OrderStatus.awaitingPayment:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    order.statusDescription,
                    style: AppTextStyles.rowLabelMuted,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  formatPrice(order.totalPrice),
                  style: AppTextStyles.orderItemPrice,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onPay,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.accentGradientStart,
                            AppColors.accentGradientEnd,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(23),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt, size: 18, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'Оплатить по СБП',
                            style: AppTextStyles.cartBarButton,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onShowQr,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.accentGradientEnd,
                        width: 1.4,
                      ),
                    ),
                    child: const Icon(
                      Icons.qr_code_2,
                      size: 22,
                      color: AppColors.accentGradientEnd,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

      case OrderStatus.completed:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                order.statusDescription,
                style: AppTextStyles.rowLabelMuted,
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onRepeat,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryBrown, width: 1.2),
                ),
                child: Text(
                  'Повторить заказ',
                  style: AppTextStyles.rowLabel.copyWith(
                    color: AppColors.primaryBrown,
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }
}
