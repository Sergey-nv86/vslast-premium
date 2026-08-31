import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../services/admin_orders_service.dart';
import 'admin_orders_screen.dart';
import 'admin_order_detail_screen.dart';

class AdminOrdersCalendarScreen extends StatefulWidget {
  const AdminOrdersCalendarScreen({super.key});

  @override
  State<AdminOrdersCalendarScreen> createState() =>
      _AdminOrdersCalendarScreenState();
}

class _AdminOrdersCalendarScreenState extends State<AdminOrdersCalendarScreen> {
  late Future<List<AdminOrder>> _ordersFuture;
  DateTime _selectedDate = _dateOnly(DateTime.now());

  static const _red = Color(0xFFE53935);
  static const _yellow = Color(0xFFF9A825);
  static const _green = Color(0xFF43A047);
  static const _purple = Color(0xFF7A5A8A);

  @override
  void initState() {
    super.initState();
    _ordersFuture = AdminOrdersService.instance.fetchOrders();
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  Future<void> _reload() async {
    setState(() {
      _ordersFuture = AdminOrdersService.instance.fetchOrders();
    });

    try {
      await _ordersFuture;
    } catch (_) {}
  }

  List<DateTime> get _week {
    final today = _dateOnly(DateTime.now());
    return List.generate(10, (index) => today.add(Duration(days: index)));
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime? _orderDate(AdminOrder order) {
    final value = order.pickupDate;

    if (value == null) {
      return null;
    }

    return _dateOnly(value);
  }

  List<AdminOrder> _ordersForDay(List<AdminOrder> orders, DateTime date) {
    return orders.where((order) {
      final orderDate = _orderDate(order);
      return orderDate != null && _sameDay(orderDate, date);
    }).toList();
  }

  bool _countsInProductSummary(AdminOrder order) {
    return order.status != 'Выполнен' && order.status != 'Отменён';
  }

  Map<String, int> _productSummary(List<AdminOrder> orders) {
    final result = <String, int>{};

    for (final order in orders) {
      if (!_countsInProductSummary(order)) {
        continue;
      }

      for (final item in order.items) {
        result[item.name] = (result[item.name] ?? 0) + item.quantity;
      }
    }

    return result;
  }

  String _weekday(DateTime date) {
    const names = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return names[date.weekday - 1];
  }

  String _monthName(DateTime date) {
    const names = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    return names[date.month - 1];
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Новый':
        return _red;
      case 'Подтверждён':
        return _yellow;
      case 'Выполнен':
        return _green;
      case 'Предзаказ':
        return _purple;
      default:
        return AppColors.primaryBrown;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Календарь заказов',
          style: TextStyle(
            color: Color(0xFF3B281F),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: FutureBuilder<List<AdminOrder>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _errorState(snapshot.error);
          }

          final orders = snapshot.data ?? <AdminOrder>[];
          final dayOrders = _ordersForDay(orders, _selectedDate);
          final products = _productSummary(dayOrders);

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _weekCalendar(orders),
                const SizedBox(height: 18),
                _selectedDayHeader(dayOrders),
                const SizedBox(height: 12),
                _productSummaryCard(products),
                const SizedBox(height: 20),
                _ordersHeader(dayOrders),
                const SizedBox(height: 10),
                if (dayOrders.isEmpty)
                  _emptyOrders()
                else
                  ...dayOrders.map(
                    (order) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _orderCard(order),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _weekCalendar(List<AdminOrder> allOrders) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 6,
          mainAxisSpacing: 8,
          mainAxisExtent: 100,
        ),
        itemCount: _week.length,
        itemBuilder: (context, index) {
          final date = _week[index];
          final selected = _sameDay(date, _selectedDate);
          final count = _ordersForDay(allOrders, date).length;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryBrown : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekday(date),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white70
                          : const Color(0xFF806F65),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : const Color(0xFF3B281F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 1,
                    width: double.infinity,
                    color: selected
                        ? Colors.white.withValues(alpha: .30)
                        : AppColors.divider,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    constraints: const BoxConstraints(
                      minWidth: 26,
                      minHeight: 22,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: .18)
                          : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: selected ? Colors.white : AppColors.primaryBrown,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _selectedDayHeader(List<AdminOrder> orders) {
    final activeCount = orders.where(_countsInProductSummary).length;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _sameDay(_selectedDate, DateTime.now())
                    ? 'Сегодня'
                    : '${_selectedDate.day} ${_monthName(_selectedDate)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3B281F),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${orders.length} заказов · $activeCount в работе',
                style: const TextStyle(fontSize: 13, color: Color(0xFF806F65)),
              ),
            ],
          ),
        ),
        const Icon(Icons.storefront_outlined, color: AppColors.primaryBrown),
      ],
    );
  }

  Widget _productSummaryCard(Map<String, int> products) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 21,
                color: AppColors.primaryBrown,
              ),
              SizedBox(width: 9),
              Text(
                'Товары к выдаче',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3B281F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Только активные заказы',
            style: TextStyle(fontSize: 12, color: const Color(0xFF806F65)),
          ),
          const SizedBox(height: 14),
          if (products.isEmpty)
            Text(
              'Нет активных заказов',
              style: TextStyle(color: const Color(0xFF806F65), fontSize: 13),
            )
          else
            ...products.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B281F),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${entry.value} шт.',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryBrown,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ordersHeader(List<AdminOrder> orders) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Заказы',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3B281F),
            ),
          ),
        ),
        Text(
          '${orders.length}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF806F65),
          ),
        ),
      ],
    );
  }

  Widget _orderCard(AdminOrder order) {
    final statusColor = _statusColor(order.status);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          final changed = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => AdminOrderDetailScreen(order: order),
            ),
          );

          if (changed == true && mounted) {
            await _reload();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    order.number,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3B281F),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.customer,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3B281F),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      order.status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_outlined,
                    size: 16,
                    color: Color(0xFF806F65),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      order.receiveTimeDetail.isNotEmpty
                          ? order.receiveTimeDetail
                          : order.type,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF806F65),
                      ),
                    ),
                  ),
                  Text(
                    '${order.total.toStringAsFixed(0)} ₽',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3B281F),
                    ),
                  ),
                ],
              ),
              if (order.items.isNotEmpty) ...[
                const SizedBox(height: 9),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    order.items
                        .map((item) => '${item.name} ×${item.quantity}')
                        .join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF806F65),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyOrders() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 40,
            color: Color(0xFF806F65),
          ),
          SizedBox(height: 10),
          Text(
            'Заказов на этот день нет',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3B281F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 42, color: _red),
            const SizedBox(height: 12),
            Text(
              'Не удалось загрузить календарь заказов',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3B281F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF806F65)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _reload, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}
