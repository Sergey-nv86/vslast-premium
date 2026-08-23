import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../services/admin_orders_service.dart';
import '../../../utils/toast.dart';
import 'admin_orders_screen.dart';

class AdminOrderDetailScreen extends StatelessWidget {
  final AdminOrder order;

  const AdminOrderDetailScreen({super.key, required this.order});

  Color get _statusColor => switch (order.status) {
    'Новый' => const Color(0xFFE53935),
    'Подтверждён' => const Color(0xFFF9A825),
    'Предзаказ' => const Color(0xFF7A5A8A),
    'Выполнен' => const Color(0xFF43A047),
    _ => AppColors.primaryBrown,
  };

  String get _primaryActionLabel => switch (order.status) {
    'Новый' => 'Подтвердить заказ',
    'Подтверждён' => 'Заказ выполнен',
    _ => '',
  };

  String? get _nextStatus => switch (order.status) {
    'Новый' => 'confirmed',
    'Подтверждён' => 'completed',
    _ => null,
  };

  String get _initials {
    final parts = order.customer.trim().split(RegExp(r'\s+'));

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    }

    return (parts[0].isNotEmpty ? parts[0][0] : '') +
        (parts[1].isNotEmpty ? parts[1][0] : '').toUpperCase();
  }

  bool get _isPickup => order.type.startsWith('Самовывоз');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header(context)),
            SliverToBoxAdapter(child: _statusRow()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _clientCard(context),
                  const SizedBox(height: 12),
                  _receiveCard(),
                  const SizedBox(height: 12),
                  _itemsCard(),
                  const SizedBox(height: 12),
                  _totalsCard(),
                  if (order.comment != null &&
                      order.comment!.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _commentCard(),
                  ],
                  const SizedBox(height: 20),
                  _actionButtons(context),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(
                Icons.chevron_left,
                color: AppColors.primaryBrown,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Заказ ${order.number}',
              style: AppTextStyles.screenTitle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  order.status,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(order.time, style: AppTextStyles.rowLabelMuted),
        ],
      ),
    );
  }

  Widget _clientCard(BuildContext context) {
    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Text(
              _initials,
              style: AppTextStyles.rowLabel.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.customer,
                  style: AppTextStyles.rowLabel.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                if (order.phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(order.phone, style: AppTextStyles.rowLabelMuted),
                ],
                const SizedBox(height: 2),
                Text(
                  '${order.customerType} · ${order.customerOrderCount} '
                  '${_ordersWord(order.customerOrderCount)}',
                  style: AppTextStyles.rowLabelMuted.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          if (order.phone.isNotEmpty)
            GestureDetector(
              onTap: () => FadeToast.show(
                context,
                'Звонок ${order.phone}',
                icon: Icons.call,
              ),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.call_outlined,
                  size: 18,
                  color: AppColors.primaryBrown,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _ordersWord(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;

    if (mod100 >= 11 && mod100 <= 14) {
      return 'заказов';
    }

    if (mod10 == 1) {
      return 'заказ';
    }

    if (mod10 >= 2 && mod10 <= 4) {
      return 'заказа';
    }

    return 'заказов';
  }

  Widget _receiveCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Способ получения', style: AppTextStyles.rowLabelMuted),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isPickup
                      ? Icons.shopping_bag_outlined
                      : Icons.local_shipping_outlined,
                  size: 19,
                  color: AppColors.primaryBrown,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isPickup ? 'Самовывоз' : 'Доставка',
                      style: AppTextStyles.rowLabel.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (order.receiveTimeDetail.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        order.receiveTimeDetail,
                        style: AppTextStyles.rowLabelMuted,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (_isPickup) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 14),
            Text('Адрес пекарни', style: AppTextStyles.rowLabelMuted),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    size: 19,
                    color: AppColors.primaryBrown,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.pickupAddressTitle,
                        style: AppTextStyles.rowLabel.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.pickupAddressSubtitle,
                        style: AppTextStyles.rowLabelMuted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _itemsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Состав заказа',
            style: AppTextStyles.rowLabel.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          if (order.items.isEmpty)
            Text(
              'Нет данных о составе заказа',
              style: AppTextStyles.rowLabelMuted,
            )
          else
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: _productImage(item.imageUrl),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: AppTextStyles.rowLabel.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (item.weight.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.weight,
                              style: AppTextStyles.rowLabelMuted.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item.quantity} шт.',
                          style: AppTextStyles.rowLabelMuted.copyWith(
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.lineTotal.toStringAsFixed(0)} ₽',
                          style: AppTextStyles.rowLabel.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _productImage(String imageUrl) {
    final url = imageUrl.trim();

    if (url.isEmpty) {
      return _imagePlaceholder();
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _imagePlaceholder();
        },
      );
    }

    return Image.asset(
      url,
      width: 52,
      height: 52,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _imagePlaceholder();
      },
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.surfaceMuted,
      alignment: Alignment.center,
      child: const Icon(
        Icons.bakery_dining_outlined,
        size: 22,
        color: AppColors.primaryBrown,
      ),
    );
  }

  Widget _totalsCard() {
    return _card(
      child: Column(
        children: [
          _totalsRow(
            'Товары (${order.itemsCount} шт.)',
            '${order.itemsTotal.toStringAsFixed(0)} ₽',
          ),
          if (order.discount > 0) ...[
            const SizedBox(height: 8),
            _totalsRow(
              'Скидка',
              '−${order.discount.toStringAsFixed(0)} ₽',
              valueColor: const Color(0xFFB5544A),
            ),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          _totalsRow(
            'Итого',
            '${order.total.toStringAsFixed(0)} ₽',
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _totalsRow(
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: bold
                ? AppTextStyles.rowLabel.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  )
                : AppTextStyles.rowLabelMuted,
          ),
        ),
        Text(
          value,
          style: bold
              ? AppTextStyles.rowLabel.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                )
              : AppTextStyles.rowLabel.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
        ),
      ],
    );
  }

  Widget _commentCard() {
    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 16,
              color: AppColors.primaryBrown,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Комментарий клиента',
                  style: AppTextStyles.rowLabelMuted.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(order.comment!, style: AppTextStyles.rowLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButtons(BuildContext context) {
    final nextStatus = _nextStatus;

    if (nextStatus == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _changeStatus(context, nextStatus),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBrown,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(_primaryActionLabel),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryBrown,
              side: const BorderSide(color: AppColors.divider),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text('Изменить заказ'),
          ),
        ),
      ],
    );
  }

  Future<void> _changeStatus(BuildContext context, String nextStatus) async {
    try {
      await AdminOrdersService.instance.updateOrderStatus(
        orderId: order.id,
        status: nextStatus,
      );

      if (!context.mounted) return;

      FadeToast.show(
        context,
        nextStatus == 'confirmed' ? 'Заказ подтверждён' : 'Заказ выполнен',
        icon: Icons.check_circle_outline,
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!context.mounted) return;

      FadeToast.show(
        context,
        'Не удалось изменить статус заказа',
        icon: Icons.error_outline,
      );
    }
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: child,
    );
  }
}
