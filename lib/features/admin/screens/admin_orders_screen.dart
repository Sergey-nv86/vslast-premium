import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../services/admin_orders_service.dart';
import 'admin_order_detail_screen.dart';

enum AdminOrderFilter { all, newOrders, preorders, confirmed, completed }

/// Одна позиция в составе заказа — то, чего раньше не хватало на экране
/// «Заказ #...»: было видно сумму, но не сам список товаров.
class AdminOrderItem {
  final String name;
  final String weight;
  final int quantity;
  final double price;
  final String imageUrl;

  const AdminOrderItem({
    required this.name,
    this.weight = '',
    required this.quantity,
    required this.price,
    this.imageUrl = '',
  });

  double get lineTotal => price * quantity;
}

class AdminOrder {
  final String id;
  final String number;
  final String customer;
  final String phone;
  final String customerType;
  final int customerOrderCount;
  final String time;
  final String type;
  final String receiveTimeDetail;
  final DateTime? pickupDate;
  final String status;
  final double total;
  final double discount;
  final String? comment;
  final bool isPreorder;
  final List<AdminOrderItem> items;
  final String pickupAddressTitle;
  final String pickupAddressSubtitle;

  const AdminOrder({
    required this.id,
    required this.number,
    required this.customer,
    this.phone = '',
    this.customerType = 'Клиент',
    this.customerOrderCount = 1,
    required this.time,
    required this.type,
    this.receiveTimeDetail = '',
    this.pickupDate,
    required this.status,
    required this.total,
    this.discount = 0,
    this.comment,
    this.isPreorder = false,
    this.items = const [],
    this.pickupAddressTitle = '',
    this.pickupAddressSubtitle = '',
  });

  double get itemsTotal => items.fold(0, (sum, i) => sum + i.lineTotal);
  int get itemsCount => items.fold(0, (sum, i) => sum + i.quantity);
}

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  AdminOrderFilter _filter = AdminOrderFilter.all;
  String _searchQuery = '';

  late Future<List<AdminOrder>> _ordersFuture;
  int _todayOrdersCount = 0;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadOrders();
  }

  Future<List<AdminOrder>> _loadOrders() async {
    final orders = await AdminOrdersService.instance.fetchOrders();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _todayOrdersCount = orders.where((order) {
      final parts = order.time.split(',');
      if (parts.isEmpty) return false;

      final dateParts = parts.first.trim().split('.');
      if (dateParts.length != 2) return false;

      final day = int.tryParse(dateParts[0]);
      final month = int.tryParse(dateParts[1]);

      if (day == null || month == null) return false;

      return day == today.day && month == today.month;
    }).length;

    if (mounted) {
      setState(() {});
    }

    return orders;
  }

  Future<void> _reload() async {
    setState(() {
      _ordersFuture = _loadOrders();
    });

    try {
      await _ordersFuture;
    } catch (_) {
      // Ошибка будет показана через FutureBuilder.
    }
  }

  List<AdminOrder> _applyFilters(List<AdminOrder> orders) {
    final q = _searchQuery.trim().toLowerCase();

    return orders.where((o) {
      final matchesFilter = switch (_filter) {
        AdminOrderFilter.all => true,
        AdminOrderFilter.newOrders => o.status == 'Новый' && !o.isPreorder,
        AdminOrderFilter.preorders => o.isPreorder,
        AdminOrderFilter.confirmed =>
          o.status == 'Подтверждён' && !o.isPreorder,
        AdminOrderFilter.completed => o.status == 'Выполнен' && !o.isPreorder,
      };

      final matchesSearch =
          q.isEmpty ||
          o.number.toLowerCase().contains(q) ||
          o.customer.toLowerCase().contains(q);

      return matchesFilter && matchesSearch;
    }).toList();
  }

  String _label(AdminOrderFilter f) => switch (f) {
    AdminOrderFilter.all => 'Все',
    AdminOrderFilter.newOrders => 'Новые',
    AdminOrderFilter.preorders => 'Предзаказы',
    AdminOrderFilter.confirmed => 'Подтверждённые',
    AdminOrderFilter.completed => 'Выполненные',
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
              sliver: FutureBuilder<List<AdminOrder>>(
                future: _ordersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 42,
                              color: AppColors.primaryBrown,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Не удалось загрузить заказы',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error.toString(),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.rowLabelMuted,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _reload,
                              child: const Text('Повторить'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final allOrders = snapshot.data ?? [];

                  final orders = _applyFilters(allOrders);

                  if (orders.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(child: Text('Заказов нет')),
                      ),
                    );
                  }

                  return SliverList.separated(
                    itemCount: orders.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      return _OrderCard(order: orders[i], onChanged: _reload);
                    },
                  );
                },
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Заказы', style: AppTextStyles.screenTitle),
              const SizedBox(height: 2),
              Text(
                '$_todayOrdersCount ${_todayOrdersCount == 1
                    ? 'заказ'
                    : _todayOrdersCount >= 2 && _todayOrdersCount <= 4
                    ? 'заказа'
                    : 'заказов'} сегодня',
                style: AppTextStyles.rowLabelMuted,
              ),
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

String _extractPickupTime(String type) {
  const separator = ' · ';

  final index = type.indexOf(separator);

  if (index == -1) {
    return '';
  }

  return type.substring(index + separator.length).trim();
}

String _formatPickupDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$day.$month.$year';
}

class _OrderCard extends StatelessWidget {
  final AdminOrder order;
  final Future<void> Function() onChanged;
  const _OrderCard({required this.order, required this.onChanged});

  Color get _statusColor => switch (order.status) {
    'Новый' => const Color(0xFFE53935),
    'Предзаказ' => const Color(0xFF7A5A8A),
    'Подтверждён' => const Color(0xFFF9A825),
    'Выполнен' => const Color(0xFF43A047),
    _ => AppColors.primaryBrown,
  };

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        final changed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => AdminOrderDetailScreen(order: order),
          ),
        );

        if (changed == true && context.mounted) {
          await onChanged();
        }
      },
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
                Text(
                  order.number,
                  style: AppTextStyles.rowLabel.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    order.status,
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${order.total.toStringAsFixed(0)} ₽',
                  style: AppTextStyles.rowLabel.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              order.customer,
              style: AppTextStyles.rowLabel.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  order.isPreorder
                      ? Icons.event_available_outlined
                      : Icons.local_shipping_outlined,
                  size: 16,
                  color: AppColors.primaryBrown,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.isPreorder
                            ? order.type.split(' · ').first
                            : order.type,
                        style: AppTextStyles.rowLabelMuted,
                      ),
                      if (order.isPreorder && order.pickupDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _formatPickupDate(order.pickupDate!),
                          style: AppTextStyles.rowLabel.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _extractPickupTime(order.type),
                          style: AppTextStyles.rowLabelMuted.copyWith(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!order.isPreorder)
                  Text(
                    order.time,
                    style: AppTextStyles.rowLabelMuted.copyWith(fontSize: 12),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
