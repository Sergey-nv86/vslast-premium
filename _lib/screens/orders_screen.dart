import 'package:flutter/material.dart';
import '../data/mock_orders.dart';
import '../models/order_list_item.dart';
import '../theme/app_theme.dart';
import '../widgets/order_history_card.dart';

/// Экран «Мои заказы». Кнопка "назад" ведёт на "Главную" —
/// popUntil((route) => route.isFirst), т.к. этот экран обычно открывается
/// из профиля/нижней панели, а не является частью цепочки покупки.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = mockOrders; // TODO: подставить реальную историю заказов.
    final unreadNotifications = 2; // TODO: подключить реальный счётчик.

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    _RoundButton(
                      icon: Icons.arrow_back,
                      onTap: () =>
                          Navigator.of(context).popUntil((route) => route.isFirst),
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
                        // TODO: открыть экран уведомлений.
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              sliver: orders.isEmpty
                  ? const SliverToBoxAdapter(child: _EmptyOrdersState())
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final order = orders[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: OrderHistoryCard(
                              order: order,
                              onTap: () {
                                // TODO: открыть детальный экран заказа.
                              },
                              onPay: () {
                                // TODO: подключить реальную оплату по СБП.
                              },
                              onShowQr: () {
                                // TODO: показать QR-код для оплаты.
                              },
                              onRepeat: () {
                                // TODO: добавить товары этого заказа обратно в корзину.
                              },
                            ),
                          );
                        },
                        childCount: orders.length,
                      ),
                    ),
            ),
          ],
        ),
      ),
      // Нижняя панель навигации намеренно не реализуется здесь —
      // используется текущая панель проекта.
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int? badgeCount;

  const _RoundButton({required this.icon, required this.onTap, this.badgeCount});

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
                  style: AppTextStyles.statusPillLabel
                      .copyWith(color: Colors.white, fontSize: 10),
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
          Icon(Icons.receipt_long_outlined,
              size: 40, color: AppColors.textSecondary.withOpacity(0.6)),
          const SizedBox(height: 12),
          Text('Заказов пока нет', style: AppTextStyles.sectionLabel),
        ],
      ),
    );
  }
}
