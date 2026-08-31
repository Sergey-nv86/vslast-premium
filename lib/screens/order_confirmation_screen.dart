import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/order.dart';
import '../providers/tab_navigation_controller.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import '../widgets/receipt_item_tile.dart';
import 'orders_screen.dart';

/// Экран «Подтверждение заказа». Полностью работает от переданного
/// в конструктор [order] — снимка заказа, зафиксированного в момент
/// нажатия «Заказать» на экране «Оформление заказа». Корзина к этому
/// моменту уже очищена, поэтому экран не зависит от CartProvider.
class OrderConfirmationScreen extends StatelessWidget {
  final OrderSummary order;

  const OrderConfirmationScreen({super.key, required this.order});

  /// И стрелка "назад", и кнопка "Перейти в мои заказы" ведут на экран
  /// «Мои заказы» — раньше обе уводили в «Каталог», хотя корзина уже
  /// очищена и возвращаться в чекаут смысла нет. Сначала сбрасываем стек
  /// до MainScreen и переключаем активную вкладку на "Главная" (иначе
  /// IndexedStack оставит прежнюю вкладку), затем поверх пушим "Мои заказы" —
  /// так системное "назад" с этого экрана корректно вернёт на Главную.
  Future<void> _contactByOrder(BuildContext context) async {
    const phone = '+79129399754';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFAF8F5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Связаться с нами',
            style: TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 22,
              height: 1.15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
            ),
          ),
          content: const Text(
            'По вопросам вашего заказа позвоните нам:',
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: Color(0xFF6B6560),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0xFFE8E4E0)),
                  ),
                  child: const Text(
                    '+7 912 939-97-54',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      final uri = Uri(scheme: 'tel', path: phone);

                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5E6D3),
                      foregroundColor: const Color(0xFF1A1A1A),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Позвонить',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text(
                    'Закрыть',
                    style: TextStyle(color: Color(0xFF6B6560), fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _goToOrders(BuildContext context) {
    context.read<TabNavigationController>().goToHome();
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const OrdersScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _goToOrders(context),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 44,
                        height: 44,
                        margin: const EdgeInsets.only(right: 12, top: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.divider,
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.chevron_left,
                          size: 24,
                          color: AppColors.primaryBrown,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Заказ принят!',
                            style: AppTextStyles.screenTitleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Спасибо, что выбрали Всласть ❤️',
                            style: const TextStyle(
                              fontFamily: 'PlayfairDisplay',
                              fontSize: 16.0,
                              height: 1.25,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B6560),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(child: _StatusCard(order: order)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Состав заказа',
                            style: AppTextStyles.sectionLabel,
                          ),
                          Text(
                            '${order.itemsCount} ${pluralizeItems(order.itemsCount)}',
                            style: AppTextStyles.sectionCounter,
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1, color: AppColors.divider),
                      ),
                      for (var i = 0; i < order.items.length; i++) ...[
                        ReceiptItemTile(item: order.items[i]),
                        if (i != order.items.length - 1)
                          const Divider(height: 1, color: AppColors.divider),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      _TotalRow(
                        label: 'Товары',
                        value: formatPrice(order.itemsTotal),
                      ),
                      if (order.pickupDiscount > 0) ...[
                        const Divider(height: 20, color: AppColors.divider),
                        _TotalRow(
                          label: 'Скидка за самовывоз',
                          value: '−${formatPrice(order.pickupDiscount)}',
                          valueColor: AppColors.primaryBrown,
                        ),
                      ],
                      if (order.deliveryCost > 0) ...[
                        const Divider(height: 20, color: AppColors.divider),
                        _TotalRow(
                          label: 'Доставка',
                          value: formatPrice(order.deliveryCost),
                        ),
                      ],
                      const Divider(height: 24, color: AppColors.divider),
                      _TotalRow(
                        label: 'Итого',
                        value: formatPrice(order.total),
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.event_outlined,
                        label: 'Когда забрать',
                        value:
                            '${formatRuDate(order.pickupDate)}, ${order.pickupTimeSlot}',
                      ),
                      const Divider(height: 1, color: AppColors.divider),
                      _InfoRow(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Способ получения',
                        value: order.deliveryAddress == null
                            ? order.deliveryMethod.title
                            : '${order.deliveryMethod.title}, ${order.deliveryAddress}',
                      ),
                      const Divider(height: 1, color: AppColors.divider),
                      _InfoRow(
                        icon: Icons.credit_card,
                        label: 'Способ оплаты',
                        value: order.paymentMethod.title,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: () => _contactByOrder(context),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 18,
                          color: AppColors.primaryBrown,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Связаться с нами по заказу',
                            style: AppTextStyles.rowLabel,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () => _goToOrders(context),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5E6D3),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Перейти в мои заказы',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
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

class _StatusCard extends StatelessWidget {
  final OrderSummary order;

  const _StatusCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 220,
            height: 90,
            child: Image.asset(
              'assets/images/logo_light.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.bakery_dining_outlined,
                  size: 40,
                  color: AppColors.primaryBrown,
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Ваш заказ №${order.orderNumber}',
            style: AppTextStyles.sectionLabel,
          ),
          const SizedBox(height: 2),
          Text(
            'от ${formatRuDateTime(order.createdAt)}',
            style: AppTextStyles.rowLabelMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'Мы получили ваш заказ и передали его на подтверждение администратору.',
            textAlign: TextAlign.center,
            style: AppTextStyles.rowLabelMuted,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time,
                  size: 18,
                  color: AppColors.primaryBrown,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ожидайте подтверждения',
                      style: AppTextStyles.rowLabel,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Мы свяжемся с вами в ближайшее время и сообщим статус заказа.',
                      style: AppTextStyles.rowLabelMuted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryBrown),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: AppTextStyles.rowLabelMuted)),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.rowValue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _TotalRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = bold
        ? AppTextStyles.rowLabel
        : AppTextStyles.rowLabelMuted;

    final valueStyle = bold
        ? AppTextStyles.sectionLabel
        : AppTextStyles.rowValue;

    return Row(
      children: [
        Expanded(child: Text(label, style: labelStyle)),
        const SizedBox(width: 12),
        Text(value, style: valueStyle.copyWith(color: valueColor)),
      ],
    );
  }
}
