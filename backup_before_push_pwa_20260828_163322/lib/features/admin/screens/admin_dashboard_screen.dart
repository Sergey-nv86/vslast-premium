import 'package:flutter/material.dart';
import 'admin_demand_without_stock_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_orders_calendar_screen.dart';
import 'admin_bake_schedule_screen.dart';
import 'admin_products_screen.dart';
import 'admin_promotions_screen.dart';

import '../../../screens/main_screen.dart';
import 'admin_loyalty_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _loadOrderStats();
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
                child: _Metric('Активные клиенты', '128', Icons.people_outline),
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
          const SizedBox(height: 20),
          const _Title('Активность клиентов'),
          const SizedBox(height: 10),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  children: [
                    Text(
                      '128',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: dark,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text('активных клиентов', style: TextStyle(color: muted)),
                  ],
                ),
                SizedBox(height: 14),
                _Activity(Icons.menu_book_outlined, 'Смотрят каталог', '23'),
                _Activity(
                  Icons.shopping_bag_outlined,
                  'Добавили в корзину',
                  '16',
                ),
                _Activity(Icons.credit_card_outlined, 'Оформляют заказ', '7'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminPromotionsScreen()),
            ),
            child: _Card(
              color: const Color(0xFFFFF8F1),
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
            child: _Card(
              color: const Color(0xFFFFF8F1),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0xFFF4E2D2),
                    child: Icon(
                      Icons.priority_high_rounded,
                      color: Color(0xFF9A4D20),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        Text(
                          'Спрос без наличия',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: dark,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          '14 товаров ожидают клиенты',
                          style: TextStyle(fontSize: 13, color: muted),
                        ),
                        SizedBox(height: 3),
                        Text(
                          '18 450 ₽ потенциального спроса',
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
          const SizedBox(height: 20),
          const _Title('Последние заказы'),
          const SizedBox(height: 10),
          const _Recent(
            '#1055',
            'Мария Смирнова',
            'Сегодня · 13:00',
            '3 750 ₽',
            'В работе',
          ),
          const _Recent(
            '#1054',
            'Алексей Петров',
            'Сегодня · 12:30',
            '2 490 ₽',
            'Готов к выдаче',
          ),
          const _Recent(
            '#1053',
            'Елена Иванова',
            'Сегодня · 12:00',
            '1 860 ₽',
            'Новый',
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
  final Color color;
  const _Card({required this.child, this.color = Colors.white});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AdminDashboardScreen.border),
    ),
    child: child,
  );
}

class _Activity extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _Activity(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 9),
    child: Row(
      children: [
        Icon(icon, size: 18, color: AdminDashboardScreen.brown),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF5F5048)),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AdminDashboardScreen.dark,
          ),
        ),
      ],
    ),
  );
}

class _Recent extends StatelessWidget {
  final String number, customer, time, amount, status;
  const _Recent(
    this.number,
    this.customer,
    this.time,
    this.amount,
    this.status,
  );
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AdminDashboardScreen.border),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          backgroundColor: Color(0xFFF1E8E0),
          child: Icon(
            Icons.receipt_long_outlined,
            size: 19,
            color: AdminDashboardScreen.brown,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$number · $customer',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AdminDashboardScreen.dark,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 12,
                  color: AdminDashboardScreen.muted,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                status,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AdminDashboardScreen.brown,
                ),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AdminDashboardScreen.dark,
          ),
        ),
      ],
    ),
  );
}
