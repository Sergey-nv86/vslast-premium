import 'package:flutter/material.dart';
import 'admin_demand_without_stock_screen.dart';
import 'admin_orders_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static const bg = Color(0xFFF8F4EE);
  static const brown = Color(0xFF8B5E3C);
  static const dark = Color(0xFF3B281F);
  static const muted = Color(0xFF806F65);
  static const border = Color(0xFFEADFD5);

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
            Text('Всласть', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: dark)),
            Text('Администратор · Нижневартовск', style: TextStyle(fontSize: 13, color: muted)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              // Раньше эта иконка ничего не делала (просто аватар без onTap).
              // По просьбе — тап открывает "Заказы".
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
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
          const Text('Сегодня', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: muted)),
          const SizedBox(height: 14),
          Row(children: const [
            Expanded(child: _Metric('Выручка', '184 500 ₽', Icons.trending_up_rounded)),
            SizedBox(width: 10),
            Expanded(child: _Metric('Заказы', '47', Icons.receipt_long_outlined)),
          ]),
          const SizedBox(height: 10),
          Row(children: const [
            Expanded(child: _Metric('Активные клиенты', '128', Icons.people_outline)),
            SizedBox(width: 10),
            Expanded(child: _Metric('Средний чек', '3 926 ₽', Icons.payments_outlined)),
          ]),
          const SizedBox(height: 24),
          _Title(
            'Заказы',
            action: 'Все заказы',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AdminOrdersScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _Card(child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _OrderStat('7', 'Новые'),
              _OrderStat('12', 'Предзаказы'),
              _OrderStat('15', 'В работе'),
              _OrderStat('5', 'Готовы'),
            ],
          )),
          const SizedBox(height: 20),
          const _Title('Активность клиентов'),
          const SizedBox(height: 10),
          _Card(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Row(children: [
                Text('128', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: dark)),
                SizedBox(width: 10),
                Text('активных клиентов', style: TextStyle(color: muted)),
              ]),
              SizedBox(height: 14),
              _Activity(Icons.menu_book_outlined, 'Смотрят каталог', '23'),
              _Activity(Icons.shopping_bag_outlined, 'Добавили в корзину', '16'),
              _Activity(Icons.credit_card_outlined, 'Оформляют заказ', '7'),
            ],
          )),
          const SizedBox(height: 20),
          // Раньше карточка была некликабельной. Теперь открывает список
          // товаров без остатка, на которые есть спрос (избранное/предзаказ).
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminDemandWithoutStockScreen()),
              );
            },
            child: _Card(
              color: const Color(0xFFFFF8F1),
              child: const Row(children: [
                CircleAvatar(
                  backgroundColor: Color(0xFFF4E2D2),
                  child: Icon(Icons.priority_high_rounded, color: Color(0xFF9A4D20)),
                ),
                SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Спрос без наличия', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: dark)),
                    SizedBox(height: 5),
                    Text('14 товаров ожидают клиенты', style: TextStyle(fontSize: 13, color: muted)),
                    SizedBox(height: 3),
                    Text('18 450 ₽ потенциального спроса', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: brown)),
                  ],
                )),
                Icon(Icons.chevron_right_rounded, color: brown),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          const _Title('Последние заказы'),
          const SizedBox(height: 10),
          const _Recent('#1055', 'Мария Смирнова', 'Сегодня · 13:00', '3 750 ₽', 'В работе'),
          const _Recent('#1054', 'Алексей Петров', 'Сегодня · 12:30', '2 490 ₽', 'Готов к выдаче'),
          const _Recent('#1053', 'Елена Иванова', 'Сегодня · 12:00', '1 860 ₽', 'Новый'),
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
  Widget build(BuildContext context) => _Card(
    child: SizedBox(
      height: 88,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 19, color: AdminDashboardScreen.brown),
        const Spacer(),
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AdminDashboardScreen.muted)),
        const SizedBox(height: 4),
        FittedBox(alignment: Alignment.centerLeft, child: Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: AdminDashboardScreen.dark))),
      ]),
    ),
  );
}

class _Title extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;

  // Раньше здесь было одновременно [this.action] (опциональный позиционный)
  // и {this.onTap} (именованный) в одном конструкторе — Dart такое не
  // разрешает синтаксически (можно использовать только один вид
  // опциональных параметров на конструктор). Оба теперь именованные.
  const _Title(
    this.title, {
    this.action,
    this.onTap,
  });

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
      if (action != null)
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 4,
            ),
            child: Text(
              action!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AdminDashboardScreen.brown,
              ),
            ),
          ),
        ),
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
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18), border: Border.all(color: AdminDashboardScreen.border)),
    child: child,
  );
}

class _OrderStat extends StatelessWidget {
  final String value, label;
  const _OrderStat(this.value, this.label);

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AdminDashboardScreen.dark)),
    const SizedBox(height: 4),
    Text(label, style: const TextStyle(fontSize: 11, color: AdminDashboardScreen.muted)),
  ]);
}

class _Activity extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _Activity(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 9),
    child: Row(children: [
      Icon(icon, size: 18, color: AdminDashboardScreen.brown),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF5F5048)))),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: AdminDashboardScreen.dark)),
    ]),
  );
}

class _Recent extends StatelessWidget {
  final String number, customer, time, amount, status;
  const _Recent(this.number, this.customer, this.time, this.amount, this.status);

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AdminDashboardScreen.border)),
    child: Row(children: [
      const CircleAvatar(
        backgroundColor: Color(0xFFF1E8E0),
        child: Icon(Icons.receipt_long_outlined, size: 19, color: AdminDashboardScreen.brown),
      ),
      const SizedBox(width: 11),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$number · $customer', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AdminDashboardScreen.dark)),
        const SizedBox(height: 3),
        Text(time, style: const TextStyle(fontSize: 12, color: AdminDashboardScreen.muted)),
        const SizedBox(height: 5),
        Text(status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AdminDashboardScreen.brown)),
      ])),
      Text(amount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AdminDashboardScreen.dark)),
    ]),
  );
}
