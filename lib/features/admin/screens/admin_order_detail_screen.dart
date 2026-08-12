import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import 'admin_orders_screen.dart';

class AdminOrderDetailScreen extends StatelessWidget {
  final AdminOrder order;
  const AdminOrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle,
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: const Icon(Icons.chevron_left, color: AppColors.primaryBrown),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Text('Заказ ${order.number}', style: AppTextStyles.screenTitle)),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _section('Клиент', [
                    _row('Имя', order.customer),
                    _row('Тип', order.type),
                  ]),
                  const SizedBox(height: 12),
                  _itemsSection(order.items),
                  const SizedBox(height: 12),
                  _section('Статус', [
                    _row('Текущий статус', order.status),
                    _row('Создан', order.time),
                  ]),
                  const SizedBox(height: 12),
                  _section('Оплата', [
                    _row('Сумма заказа', '${order.total.toStringAsFixed(0)} ₽'),
                    _row('Оплата', 'Оплачено'),
                  ]),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBrown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: const Text('Изменить статус'),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.divider),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.rowLabel.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );

  /// Состав заказа — раньше на этом экране не было видно ЧТО именно
  /// заказали, только итоговую сумму. Список позиций с количеством и
  /// ценой за штуку, плюс сумма по строке — как в чеке.
  Widget _itemsSection(List<AdminOrderItem> items) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.divider),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Состав заказа', style: AppTextStyles.rowLabel.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Text('Нет данных о составе заказа', style: AppTextStyles.rowLabelMuted)
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(top: 1, right: 10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${item.quantity}×',
                      style: AppTextStyles.rowLabelMuted.copyWith(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Expanded(
                    child: Text(item.name, style: AppTextStyles.rowLabel.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${item.lineTotal.toStringAsFixed(0)} ₽',
                    style: AppTextStyles.rowLabel.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: AppTextStyles.rowLabelMuted)),
        const SizedBox(width: 12),
        Flexible(child: Text(value, textAlign: TextAlign.right, style: AppTextStyles.rowLabel.copyWith(fontWeight: FontWeight.w600))),
      ],
    ),
  );
}
