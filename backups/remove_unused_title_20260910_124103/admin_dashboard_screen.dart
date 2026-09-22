import 'package:flutter/material.dart';
import 'admin_demand_without_stock_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_orders_calendar_screen.dart';
import 'admin_bake_schedule_screen.dart';
import 'admin_products_screen.dart';
import 'admin_promotions_screen.dart';

import '../../../screens/main_screen.dart';
import 'admin_loyalty_screen.dart';
import 'admin_clients_screen.dart';
import '../services/admin_clients_service.dart';
import '../../../services/admin_orders_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  static const bg = Color(0xFFF8F4EE);
  static const brown = Color(0xFF8B5E3C);
  static const dark = Color(0xFF3B281F);
  static const muted = Color(0xFF806F65);
  static const border = Color(0xFFEADFD5);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const bg = Color(0xFFF8F4EE);
  static const brown = Color(0xFF8B5E3C);
  static const dark = Color(0xFF3B281F);
  static const muted = Color(0xFF806F65);
  static const border = Color(0xFFEADFD5);

  bool _ordersStatsLoading = true;
  int _todayOrdersCount = 0;
  int _todayNewOrdersCount = 0;

  bool _clientsStatsLoading = true;
  int _clientsCount = 0;
  int _newClientsCount = 0;

  int _demandProducts = 0;
  double _demandAmount = 0;

  @override
  void initState() {
    super.initState();
    _loadOrderStats();
    _loadClientStats();
    _loadRealDemandSummary();
  }

  Future<void> _loadClientStats() async {
    try {
      final stats = await AdminClientsService.instance.fetchClientStats();

      if (!mounted) return;

      setState(() {
        _clientsCount = stats['total'] ?? 0;
        _newClientsCount = stats['new'] ?? 0;
        _clientsStatsLoading = false;
      });
    } catch (e) {
      debugPrint('ADMIN DASHBOARD CLIENTS ERROR: $e');

      if (!mounted) return;

      setState(() {
        _clientsStatsLoading = false;
      });
    }
  }

  Future<void> _loadOrderStats() async {
    try {
      final stats = await AdminOrdersService.instance.fetchOrderStats();

      if (!mounted) return;

      setState(() {
        _todayOrdersCount = stats['total'] ?? 0;
        _todayNewOrdersCount = stats['new'] ?? 0;
        _ordersStatsLoading = false;
      });
    } catch (e) {
      debugPrint('ADMIN DASHBOARD ORDERS ERROR: $e');

      if (!mounted) return;

      setState(() {
        _ordersStatsLoading = false;
      });
    }
  }

  Future<void> _loadRealDemandSummary() async {
    try {
      final supabase = AdminClientsService.instance.supabase;

      // --------------------------------------------------
      // 1. Находим активные товары, которых сейчас нет
      //    в наличии.
      // --------------------------------------------------

      final productsResponse = await supabase
          .from('products')
          .select('id,price,in_stock,is_active');

      final unavailableIds = <String>{};

      for (final raw in productsResponse) {
        final product = Map<String, dynamic>.from(raw);

        final id = product['id']?.toString();

        if (id == null || id.isEmpty) continue;

        final isActive = product['is_active'] != false;
        final inStock = product['in_stock'] == true;

        if (isActive && !inStock) {
          unavailableIds.add(id);
        }
      }

      if (unavailableIds.isEmpty) {
        if (!mounted) return;

        setState(() {
          _demandProducts = 0;
          _demandAmount = 0;
        });

        return;
      }

      // --------------------------------------------------
      // 2. Реальный спрос берём из orders + order_items.
      //
      // Предзаказы тоже попадают сюда:
      // create_preorders_from_bake_schedule()
      // создаёт обычный order + order_items,
      // после чего выставляет orders.is_preorder = true.
      //
      // cart_items намеренно НЕ используется.
      // --------------------------------------------------

      final ordersResponse = await supabase.from('orders').select('''
            id,
            status,
            is_preorder,
            order_items (
              product_id,
              quantity,
              unit_price,
              line_total
            )
          ''');

      final demandByProduct = <String, int>{};
      double potentialRub = 0;

      for (final raw in ordersResponse) {
        final order = Map<String, dynamic>.from(raw);

        final status = order['status']?.toString().toLowerCase();

        // Отменённые и отклонённые заказы
        // не являются спросом.
        if (status == 'cancelled' ||
            status == 'canceled' ||
            status == 'rejected') {
          continue;
        }

        final itemsRaw = order['order_items'];

        if (itemsRaw is! List) continue;

        for (final rawItem in itemsRaw) {
          if (rawItem is! Map) continue;

          final item = Map<String, dynamic>.from(rawItem);

          final productId = item['product_id']?.toString();

          if (productId == null || !unavailableIds.contains(productId)) {
            continue;
          }

          final quantity = (item['quantity'] as num?)?.toInt() ?? 0;

          if (quantity <= 0) continue;

          demandByProduct[productId] =
              (demandByProduct[productId] ?? 0) + quantity;

          // Сначала используем зафиксированную сумму позиции.
          // Это важно: цена заказа могла отличаться
          // от текущей цены товара.
          final lineTotal = (item['line_total'] as num?)?.toDouble();

          if (lineTotal != null && lineTotal > 0) {
            potentialRub += lineTotal;
          } else {
            final unitPrice = (item['unit_price'] as num?)?.toDouble() ?? 0;

            potentialRub += unitPrice * quantity;
          }
        }
      }

      // --------------------------------------------------
      // 3. Считаем только товары, по которым действительно
      //    есть спрос.
      //
      // Раньше здесь ошибочно показывались ВСЕ товары
      // без наличия.
      // --------------------------------------------------

      final productsWithDemand = demandByProduct.keys.toSet();

      if (!mounted) return;

      setState(() {
        _demandProducts = productsWithDemand.length;
        _demandAmount = potentialRub;
      });

      debugPrint(
        'REAL DEMAND: '
        'unavailable=${unavailableIds.length}, '
        'productsWithDemand=${productsWithDemand.length}, '
        'potential=${potentialRub.toStringAsFixed(2)} ₽',
      );
    } catch (e, st) {
      debugPrint('REAL DEMAND ERROR: $e');
      debugPrintStack(stackTrace: st);

      if (!mounted) return;

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Всласть',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: dark,
              ),
            ),
            Text(
              'Администратор · Нижневартовск',
              style: TextStyle(fontSize: 13, color: muted),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet<void>(
                  context: context,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  builder: (sheetContext) {
                    return SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Color(0xFFE8D8C8),
                                  child: Icon(
                                    Icons.person_outline,
                                    size: 30,
                                    color: brown,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Сергей',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: dark,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'Администратор · Нижневартовск',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Divider(),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.person_outline,
                                color: brown,
                              ),
                              title: const Text('Профиль'),
                              subtitle: const Text('Настройки аккаунта'),
                              onTap: () {
                                Navigator.of(sheetContext).pop();
                              },
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.shopping_bag_outlined,
                                color: brown,
                              ),
                              title: const Text('Режим пользователя'),
                              subtitle: const Text(
                                'Каталог, заказы и программа лояльности',
                              ),
                              onTap: () {
                                Navigator.of(sheetContext).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const MainScreen(),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.logout, color: brown),
                              title: const Text('Выйти'),
                              onTap: () {
                                Navigator.of(sheetContext).pop();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              child: const CircleAvatar(
                backgroundColor: Color(0xFFE8D8C8),
                child: Icon(Icons.person_outline, color: brown),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          const Text(
            'Сегодня',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: muted,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: _Metric(
                  'Выручка',
                  '184 500 ₽',
                  Icons.trending_up_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminOrdersScreen(),
                    ),
                  ),
                  behavior: HitTestBehavior.opaque,
                  child: _MetricOrders(
                    total: _ordersStatsLoading ? '…' : '$_todayOrdersCount',
                    newOrders: _ordersStatsLoading
                        ? ''
                        : '+$_todayNewOrdersCount',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminClientsScreen(),
                    ),
                  ),
                  behavior: HitTestBehavior.opaque,
                  child: _ClientsMetric(
                    loading: _clientsStatsLoading,
                    total: _clientsCount,
                    newCount: _newClientsCount,
                  ),
                ),
              ),

              SizedBox(width: 10),

              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AdminLoyaltyScreen()),
                  ),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1E8E0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.card_membership_outlined,
                            size: 21,
                            color: brown,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Лояльность',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: dark,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Начисление и списание бонусов',
                                style: TextStyle(fontSize: 11, color: muted),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: muted),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminPromotionsScreen()),
            ),
            child: _Card(
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0xFFF4E2D2),
                    child: Icon(Icons.local_offer_outlined, color: brown),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Акции и спецпредложения',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: dark,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Создание баннеров, скидок и специальных цен',
                          style: TextStyle(fontSize: 13, color: muted),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Управление доступностью для клиентов',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: brown,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: brown),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminProductsScreen()),
            ),
            child: _Card(
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0xFFF1E8E0),
                    child: Icon(Icons.inventory_2_outlined, color: brown),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Товары',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: dark,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: brown),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AdminDemandWithoutStockScreen(),
              ),
            ),
            behavior: HitTestBehavior.opaque,
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1E8E0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_cart_checkout_rounded,
                      color: brown,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Спрос без наличия',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: dark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_demandProducts товаров',
                          style: const TextStyle(fontSize: 12, color: muted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_demandAmount.toStringAsFixed(0)} ₽ потенциального спроса',
                          style: const TextStyle(fontSize: 12, color: muted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: muted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdminOrdersCalendarScreen(),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1E8E0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.calendar_month_outlined,
                          color: brown,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Календарь заказов',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: dark,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Заказы и товары на ближайшую неделю',
                              style: TextStyle(fontSize: 11, color: muted),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: muted),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminBakeScheduleScreen(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1E8E0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bakery_dining_outlined,
                          color: brown,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'График запеков',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: dark,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Хлеб по дням недели',
                              style: TextStyle(fontSize: 11, color: muted),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: muted),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricOrders extends StatelessWidget {
  final String total;
  final String newOrders;

  const _MetricOrders({required this.total, required this.newOrders});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: SizedBox(
        height: 88,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 19,
              color: AdminDashboardScreen.brown,
            ),
            const Spacer(),
            const Text(
              'Заказы',
              style: TextStyle(fontSize: 12, color: AdminDashboardScreen.muted),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  total,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AdminDashboardScreen.dark,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  newOrders,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF52755D),
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'новых',
                  style: TextStyle(
                    fontSize: 11,
                    color: AdminDashboardScreen.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientsMetric extends StatelessWidget {
  final bool loading;
  final int total;
  final int newCount;

  const _ClientsMetric({
    required this.loading,
    required this.total,
    required this.newCount,
  });

  static const brown = Color(0xFF8B5E3C);
  static const dark = Color(0xFF3B281F);
  static const muted = Color(0xFF806F65);
  static const border = Color(0xFFEADFD5);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFF1E8E0),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline, size: 21, color: brown),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Клиенты',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
                const SizedBox(height: 2),
                if (loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: brown,
                    ),
                  )
                else
                  Text(
                    '$total',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: dark,
                    ),
                  ),
                const SizedBox(height: 1),
                if (!loading)
                  Text(
                    '+$newCount за неделю',
                    style: const TextStyle(
                      fontSize: 10,
                      color: brown,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String title, value;
  final IconData icon;
  const _Metric(this.title, this.value, this.icon);
  @override
  Widget build(BuildContext context) {
    final card = _Card(
      child: SizedBox(
        height: 88,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 19, color: AdminDashboardScreen.brown),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AdminDashboardScreen.muted,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: AdminDashboardScreen.dark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return card;
  }
}

class _Title extends StatelessWidget {
  final String title;
  const _Title(this.title);
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AdminDashboardScreen.dark,
        ),
      ),
      const Spacer(),
    ],
  );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AdminDashboardScreen.border),
    ),
    child: child,
  );
}
