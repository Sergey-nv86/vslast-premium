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
      backgroundColor: const Color(0xFFFAF8F5),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFC4956A),
          backgroundColor: Colors.white,
          onRefresh: _reload,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 360;
                      return _OrdersHeader(
                        unreadNotifications: unreadNotifications,
                        compact: compact,
                      );
                    },
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: FutureBuilder<List<OrderListItem>>(
                        future: _ordersFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const _OrdersLoadingState();
                          }

                          if (snapshot.hasError) {
                            return _OrdersErrorState(onRetry: _reload);
                          }

                          final orders = snapshot.data ?? [];

                          if (orders.isEmpty) {
                            return const _EmptyOrdersState();
                          }

                          return Column(
                            children: [
                              _OrdersSummary(count: orders.length),
                              const SizedBox(height: 16),
                              ...orders.asMap().entries.map(
                                (entry) => Padding(
                                  padding: EdgeInsets.only(
                                    bottom: entry.key == orders.length - 1 ? 0 : 16,
                                  ),
                                  child: OrderHistoryCard(
                                    order: entry.value,
                                    // Детальный экран подключим следующим этапом.
                                    onTap: () {},
                                    // Реальная оплата СБП будет подключена отдельно.
                                    onPay: () {},
                                    // QR будет подключён отдельно.
                                    onShowQr: () {},
                                    // Повтор заказа подключим отдельно.
                                    onRepeat: () {},
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
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

class _OrdersHeader extends StatelessWidget {
  final int unreadNotifications;
  final bool compact;

  const _OrdersHeader({
    required this.unreadNotifications,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _RoundButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 16),
            child: Column(
              children: [
                Text(
                  'Мои заказы',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.screenTitleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'История покупок',
                  style: AppTextStyles.rowLabelMuted.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        _RoundButton(
          icon: Icons.notifications_none_rounded,
          badgeCount: unreadNotifications,
          onTap: () {
            // TODO: подключить экран уведомлений.
          },
        ),
      ],
    );
  }
}

class _OrdersSummary extends StatelessWidget {
  final int count;

  const _OrdersSummary({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6D3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFC4956A).withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 20,
              color: Color(0xFFC4956A),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _ordersCountLabel(count),
              style: AppTextStyles.rowLabel.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryBrown,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: Color(0xFFC4956A),
          ),
        ],
      ),
    );
  }

  String _ordersCountLabel(int value) {
    final mod10 = value % 10;
    final mod100 = value % 100;
    if (mod10 == 1 && mod100 != 11) return '$value заказ';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) {
      return '$value заказа';
    }
    return '$value заказов';
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
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFC4956A).withValues(alpha: 0.16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.035),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, size: 21, color: AppColors.primaryBrown),
            ),
            if (badgeCount != null && badgeCount! > 0)
              Positioned(
                right: -3,
                top: -3,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFB5423F),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badgeCount',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.statusPillLabel.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
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

class _OrdersLoadingState extends StatelessWidget {
  const _OrdersLoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC4956A).withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFFC4956A),
            ),
          ),
          const SizedBox(height: 16),
          Text('Загружаем заказы…', style: AppTextStyles.rowLabelMuted),
          const SizedBox(height: 4),
          Text(
            'Подождите немного',
            style: AppTextStyles.rowLabelMuted.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _OrdersErrorState extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _OrdersErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFB5423F).withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFB5423F).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_off_outlined,
              size: 25,
              color: Color(0xFFB5423F),
            ),
          ),
          const SizedBox(height: 14),
          Text('Не удалось загрузить заказы', style: AppTextStyles.sectionLabel),
          const SizedBox(height: 8),
          Text(
            'Проверьте подключение к интернету и попробуйте снова.',
            textAlign: TextAlign.center,
            style: AppTextStyles.rowLabelMuted,
          ),
          const SizedBox(height: 18),
          _ActionButton(label: 'Повторить', onTap: onRetry),
        ],
      ),
    );
  }
}

class _EmptyOrdersState extends StatelessWidget {
  const _EmptyOrdersState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC4956A).withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFFF5E6D3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 28,
              color: Color(0xFFC4956A),
            ),
          ),
          const SizedBox(height: 16),
          Text('Заказов пока нет', style: AppTextStyles.sectionLabel),
          const SizedBox(height: 8),
          Text(
            'Ваши покупки появятся здесь после оформления первого заказа.',
            textAlign: TextAlign.center,
            style: AppTextStyles.rowLabelMuted,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Future<void> Function() onTap;

  const _ActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: () => onTap(),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFFC4956A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
