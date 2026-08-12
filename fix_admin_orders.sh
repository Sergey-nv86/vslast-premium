#!/bin/bash
set -e

ADMIN_DIR="lib/features/admin"
SCREEN="$ADMIN_DIR/screens/admin_orders_screen.dart"
DETAIL="$ADMIN_DIR/screens/admin_order_detail_screen.dart"
HELPER="$ADMIN_DIR/screens/admin_orders_route.dart"

mkdir -p "$ADMIN_DIR/screens"

cat > "$SCREEN" <<'DART'
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import 'admin_order_detail_screen.dart';

enum AdminOrderFilter { all, newOrders, preorder, inProgress, ready }

class AdminOrder {
  final String number;
  final String customer;
  final String time;
  final String type;
  final String status;
  final double total;
  final bool isPreorder;

  const AdminOrder({
    required this.number,
    required this.customer,
    required this.time,
    required this.type,
    required this.status,
    required this.total,
    this.isPreorder = false,
  });
}

const _demoOrders = <AdminOrder>[
  AdminOrder(number: '#1047', customer: 'Анна Петрова', time: 'сегодня, 05:21', type: 'Доставка', status: 'Новый', total: 4850),
  AdminOrder(number: '#1046', customer: 'Михаил Иванов', time: 'сегодня, 05:08', type: 'Самовывоз · 09:30', status: 'Предзаказ', total: 7200, isPreorder: true),
  AdminOrder(number: '#1045', customer: 'Елена Смирнова', time: 'сегодня, 04:56', type: 'Доставка', status: 'В работе', total: 3150),
  AdminOrder(number: '#1044', customer: 'Ольга Кузнецова', time: 'сегодня, 04:42', type: 'Самовывоз · 08:45', status: 'Готов', total: 5400),
  AdminOrder(number: '#1043', customer: 'Александр Соколов', time: 'сегодня, 04:17', type: 'Доставка', status: 'В работе', total: 2680),
];

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  AdminOrderFilter _filter = AdminOrderFilter.all;
  String _searchQuery = '';

  List<AdminOrder> get _orders => _demoOrders.where((o) {
    final q = _searchQuery.trim().toLowerCase();
    final matchesFilter = switch (_filter) {
      AdminOrderFilter.all => true,
      AdminOrderFilter.newOrders => o.status == 'Новый',
      AdminOrderFilter.preorder => o.status == 'Предзаказ',
      AdminOrderFilter.inProgress => o.status == 'В работе',
      AdminOrderFilter.ready => o.status == 'Готов',
    };
    final matchesSearch = q.isEmpty ||
        o.number.toLowerCase().contains(q) ||
        o.customer.toLowerCase().contains(q);
    return matchesFilter && matchesSearch;
  }).toList();

  String _label(AdminOrderFilter f) => switch (f) {
    AdminOrderFilter.all => 'Все',
    AdminOrderFilter.newOrders => 'Новые 7',
    AdminOrderFilter.preorder => 'Предзаказы 12',
    AdminOrderFilter.inProgress => 'В работе 15',
    AdminOrderFilter.ready => 'Готовы 5',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header()),
            SliverToBoxAdapter(child: _buildSearch()),
            SliverToBoxAdapter(child: _filters()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              sliver: SliverList.separated(
                itemCount: _orders.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _OrderCard(order: _orders[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() => Padding(
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Заказы', style: AppTextStyles.screenTitle),
              const SizedBox(height: 2),
              Text('47 заказов сегодня', style: AppTextStyles.rowLabelMuted),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.tune_rounded, color: AppColors.primaryBrown),
        ),
      ],
    ),
  );

  Widget _buildSearch() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
    child: TextField(
      onChanged: (v) => setState(() => _searchQuery = v),
      decoration: InputDecoration(
        hintText: 'Номер заказа или клиент',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.divider),
        ),
      ),
    ),
  );

  Widget _filters() => SizedBox(
    height: 50,
    child: ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      scrollDirection: Axis.horizontal,
      itemCount: AdminOrderFilter.values.length,
      separatorBuilder: (context, index) => const SizedBox(width: 8),
      itemBuilder: (context, i) {
        final f = AdminOrderFilter.values[i];
        final selected = f == _filter;
        return ChoiceChip(
          label: Text(_label(f)),
          selected: selected,
          onSelected: (selected) => setState(() => _filter = f),
          selectedColor: AppColors.primaryBrown,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppColors.primaryBrown,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(color: AppColors.divider),
        );
      },
    ),
  );
}

class _OrderCard extends StatelessWidget {
  final AdminOrder order;
  const _OrderCard({required this.order});

  Color get _statusColor => switch (order.status) {
    'Новый' => AppColors.primaryBrown,
    'Предзаказ' => const Color(0xFF7A5A8A),
    'В работе' => const Color(0xFF8B6A35),
    'Готов' => const Color(0xFF52755D),
    _ => AppColors.primaryBrown,
  };

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AdminOrderDetailScreen(order: order),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(order.number, style: AppTextStyles.rowLabel.copyWith(fontWeight: FontWeight.w700, fontSize: 17)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(order.status, style: TextStyle(color: _statusColor, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                const Spacer(),
                Text('${order.total.toStringAsFixed(0)} ₽', style: AppTextStyles.rowLabel.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 10),
            Text(order.customer, style: AppTextStyles.rowLabel.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(order.isPreorder ? Icons.event_available_outlined : Icons.local_shipping_outlined, size: 16, color: AppColors.primaryBrown),
                const SizedBox(width: 6),
                Expanded(child: Text(order.type, style: AppTextStyles.rowLabelMuted)),
                Text(order.time, style: AppTextStyles.rowLabelMuted.copyWith(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
DART

cat > "$DETAIL" <<'DART'
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
DART

cat > "$HELPER" <<'DART'
import 'package:flutter/material.dart';
import 'admin_orders_screen.dart';

void openAdminOrders(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
  );
}
DART

echo
echo "Создан экран Заказы и карточка заказа."
echo
echo "Проверка:"
echo "flutter analyze lib/features/admin"
echo
echo "Для подключения кнопки «Все заказы» в Dashboard используйте:"
echo "openAdminOrders(context)"
