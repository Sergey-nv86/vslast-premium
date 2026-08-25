import 'package:flutter/material.dart';

import '../models/order_list_item.dart';
import '../services/orders_service.dart';
import '../theme/app_theme.dart';
import '../widgets/order_history_card.dart';

/// Экран «Мои заказы».
///
/// UI/UX сохраняется утверждённым.
/// Источник данных — Supabase orders.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<OrderListItem>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = OrdersService.instance.fetchMyOrders();
  }

  Future<void> _reload() async {
    setState(() {
      _ordersFuture = OrdersService.instance.fetchMyOrders();
    });

    try {
      await _ordersFuture;
    } catch (_) {
      // Ошибка будет показана в состоянии экрана.
    }
  }

  @override
  Widget build(BuildContext context) {
    const unreadNotifications = 2;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    _RoundButton(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.of(
                        context,
                      ).popUntil((route) => route.isFirst),
                    ),
                    Expanded(
                      child: Text(
                        'Мои заказы',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.screenTitleSmall,
                      ),
                    ),
                    _RoundButton(
                      icon: Icons.notifications_none,
                      badgeCount: unreadNotifications,
                      onTap: () {
                        // TODO: подключить экран уведомлений.
                      },
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              sliver: FutureBuilder<List<OrderListItem>>(
                future: _ordersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: _OrdersLoadingState(),
                    );
                  }

                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: _OrdersErrorState(onRetry: _reload),
                    );
                  }

                  final orders = snapshot.data ?? [];

                  if (orders.isEmpty) {
                    return const SliverToBoxAdapter(child: _EmptyOrdersState());
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final order = orders[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: OrderHistoryCard(
                          order: order,

                          // Детальный экран подключим следующим этапом.
                          onTap: () {},

                          // Реальная оплата СБП будет подключена отдельно.
                          onPay: () {},

                          // QR будет подключён отдельно.
                          onShowQr: () {},

                          // Повтор заказа подключим отдельно.
                          onRepeat: () {},
                        ),
                      );
                    }, childCount: orders.length),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int? badgeCount;

  const _RoundButton({
    required this.icon,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider, width: 1),
            ),
            child: Icon(icon, size: 22, color: AppColors.primaryBrown),
          ),
          if (badgeCount != null && badgeCount! > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: const BoxDecoration(
                  color: AppColors.badgeHit,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badgeCount',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.statusPillLabel.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrdersLoadingState extends StatelessWidget {
  const _OrdersLoadingState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: 14),
            Text('Загружаем заказы…', style: AppTextStyles.rowLabelMuted),
          ],
        ),
      ),
    );
  }
}

class _OrdersErrorState extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _OrdersErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 40,
            color: AppColors.textSecondary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            'Не удалось загрузить заказы',
            style: AppTextStyles.sectionLabel,
          ),
          const SizedBox(height: 8),
          Text(
            'Проверьте подключение к интернету.',
            textAlign: TextAlign.center,
            style: AppTextStyles.rowLabelMuted,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onRetry,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryBrown, width: 1.2),
              ),
              child: Text(
                'Повторить',
                style: AppTextStyles.rowLabel.copyWith(
                  color: AppColors.primaryBrown,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyOrdersState extends StatelessWidget {
  const _EmptyOrdersState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 40,
            color: AppColors.textSecondary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text('Заказов пока нет', style: AppTextStyles.sectionLabel),
        ],
      ),
    );
  }
}
