import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import 'admin_order_detail_screen.dart';

enum AdminOrderFilter { all, newOrders, preorder, inProgress, ready }

/// Одна позиция в составе заказа — то, чего раньше не хватало на экране
/// «Заказ #...»: было видно сумму, но не сам список товаров.
class AdminOrderItem {
  final String name;
  final int quantity;
  final double price;

  const AdminOrderItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  double get lineTotal => price * quantity;
}

class AdminOrder {
  final String number;
  final String customer;
  final String time;
  final String type;
  final String status;
  final double total;
  final bool isPreorder;
  final List<AdminOrderItem> items;

  const AdminOrder({
    required this.number,
    required this.customer,
    required this.time,
    required this.type,
    required this.status,
    required this.total,
    this.isPreorder = false,
    this.items = const [],
  });
}

const _demoOrders = <AdminOrder>[
  AdminOrder(
    number: '#1047',
    customer: 'Анна Петрова',
    time: 'сегодня, 05:21',
    type: 'Доставка',
    status: 'Новый',
    total: 4850,
    items: [
      AdminOrderItem(name: 'Хлеб деревенский на закваске', quantity: 2, price: 390),
      AdminOrderItem(name: 'Багет классический', quantity: 1, price: 220),
      AdminOrderItem(name: 'Круассан сливочный', quantity: 3, price: 290),
      AdminOrderItem(name: 'Тарт лимон-безе', quantity: 2, price: 380),
    ],
  ),
  AdminOrder(
    number: '#1046',
    customer: 'Михаил Иванов',
    time: 'сегодня, 05:08',
    type: 'Самовывоз · 09:30',
    status: 'Предзаказ',
    total: 7200,
    isPreorder: true,
    items: [
      AdminOrderItem(name: 'Наполеон', quantity: 2, price: 1450),
      AdminOrderItem(name: 'Чизкейк с вишней', quantity: 1, price: 1250),
      AdminOrderItem(name: 'Булочка зерновая', quantity: 6, price: 210),
      AdminOrderItem(name: 'Бриошь', quantity: 4, price: 290),
    ],
  ),
  AdminOrder(
    number: '#1045',
    customer: 'Елена Смирнова',
    time: 'сегодня, 04:56',
    type: 'Доставка',
    status: 'В работе',
    total: 3150,
    items: [
      AdminOrderItem(name: 'Чиабатта', quantity: 3, price: 450),
      AdminOrderItem(name: 'Эклер шоколадный', quantity: 3, price: 210),
      AdminOrderItem(name: 'Дакуаз', quantity: 2, price: 260),
    ],
  ),
  AdminOrder(
    number: '#1044',
    customer: 'Ольга Кузнецова',
    time: 'сегодня, 04:42',
    type: 'Самовывоз · 08:45',
    status: 'Готов',
    total: 5400,
    items: [
      AdminOrderItem(name: 'Хлеб деревенский на закваске', quantity: 4, price: 390),
      AdminOrderItem(name: 'Тарт лимон-безе', quantity: 2, price: 320),
      AdminOrderItem(name: 'Багет классический', quantity: 5, price: 220),
    ],
  ),
  AdminOrder(
    number: '#1043',
    customer: 'Александр Соколов',
    time: 'сегодня, 04:17',
    type: 'Доставка',
    status: 'В работе',
    total: 2680,
    items: [
      AdminOrderItem(name: 'Песочное пирожное', quantity: 4, price: 250),
      AdminOrderItem(name: 'Круассан сливочный', quantity: 3, price: 290),
      AdminOrderItem(name: 'Багет классический', quantity: 2, price: 220),
    ],
  ),
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
