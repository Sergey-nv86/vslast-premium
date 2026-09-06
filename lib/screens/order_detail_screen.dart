import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../services/orders_service.dart';
import '../theme/app_theme.dart';
import '../providers/tab_navigation_controller.dart';
import '../widgets/receipt_item_tile.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Future<OrderSummary> _orderFuture;

  @override
  void initState() {
    super.initState();
    _orderFuture = OrdersService.instance.fetchOrderById(widget.orderId);
  }

  Future<void> _reload() async {
    setState(() {
      _orderFuture = OrdersService.instance.fetchOrderById(widget.orderId);
    });

    await _orderFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Детали заказа'),
      ),
      body: FutureBuilder<OrderSummary>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final user = Supabase.instance.client.auth.currentUser;
            final session = Supabase.instance.client.auth.currentSession;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 20),
                const Text(
                  'ДИАГНОСТИКА PUSH',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                SelectableText(
                  'orderId:\n${widget.orderId}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  'currentUser:\n${user?.id ?? 'NULL'}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  'sessionUser:\n${session?.user.id ?? 'NULL'}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  'ОШИБКА:\n${snapshot.error}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _reload,
                  child: const Text('Повторить запрос'),
                ),
              ],
            );
          }

          final order = snapshot.data;

          if (order == null) {
            return _ErrorState(message: 'Заказ не найден', onRetry: _reload);
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: _OrderDetailContent(order: order),
          );
        },
      ),
    );
  }
}

class _OrderDetailContent extends StatelessWidget {
  final OrderSummary order;

  const _OrderDetailContent({required this.order});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _OrderHeader(order: order),
        const SizedBox(height: 16),

        _StatusCard(order: order),
        const SizedBox(height: 20),

        _SectionCard(
          title: 'Состав заказа',
          child: order.items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Товары не найдены'),
                )
              : Column(
                  children: [
                    for (int i = 0; i < order.items.length; i++) ...[
                      ReceiptItemTile(item: order.items[i]),
                      if (i < order.items.length - 1) const Divider(height: 1),
                    ],
                  ],
                ),
        ),

        const SizedBox(height: 16),

        _SectionCard(
          title: 'Стоимость',
          child: Column(
            children: [
              _TotalRow(title: 'Товары', value: order.itemsTotal),

              if (order.pickupDiscount > 0)
                _TotalRow(
                  title: 'Скидка за самовывоз',
                  value: -order.pickupDiscount,
                ),

              if (order.deliveryCost > 0)
                _TotalRow(title: 'Доставка', value: order.deliveryCost),

              const Divider(height: 24),

              _TotalRow(title: 'Итого', value: order.total, isTotal: true),
            ],
          ),
        ),

        const SizedBox(height: 16),

        _SectionCard(
          title: 'Получение',
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.storefront_outlined,
                title: 'Способ получения',
                value: order.deliveryMethod.title,
              ),
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                title: 'Дата',
                value: _formatDate(order.pickupDate),
              ),

              if (order.pickupTimeSlot.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                _InfoRow(
                  icon: Icons.schedule_outlined,
                  title: 'Время',
                  value: order.pickupTimeSlot,
                ),
              ],

              if (order.deliveryAddress != null &&
                  order.deliveryAddress!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  title: 'Адрес доставки',
                  value: order.deliveryAddress!,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        _SectionCard(
          title: 'Оплата',
          child: _InfoRow(
            icon: Icons.payments_outlined,
            title: 'Способ оплаты',
            value: order.paymentMethod.title,
          ),
        ),

        if (order.comment != null && order.comment!.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Комментарий',
            child: Text(
              order.comment!,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          ),
        ],

        const SizedBox(height: 24),

        OutlinedButton.icon(
          onPressed: () {
            context.read<TabNavigationController>().goToHome();

            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back),
          label: const Text('Вернуться к заказам'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}.'
        '${local.month.toString().padLeft(2, '0')}.'
        '${local.year}';
  }
}

class _OrderHeader extends StatelessWidget {
  final OrderSummary order;

  const _OrderHeader({required this.order});

  @override
  Widget build(BuildContext context) {
    final date = order.createdAt.toLocal();

    final dateText =
        '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Заказ №${order.orderNumber}',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          dateText,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final OrderSummary order;

  const _StatusCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.receipt_long_outlined, size: 25),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Заказ оформлен',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '№${order.orderNumber}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 21, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 3),
              Text(value, style: const TextStyle(fontSize: 15, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String title;
  final int value;
  final bool isTotal;

  const _TotalRow({
    required this.title,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final valueText = value < 0
        ? '−${formatPrice(value.abs())}'
        : formatPrice(value);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: isTotal ? 16 : 15,
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            valueText,
            style: TextStyle(
              fontSize: isTotal ? 17 : 15,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Не удалось загрузить заказ',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}
