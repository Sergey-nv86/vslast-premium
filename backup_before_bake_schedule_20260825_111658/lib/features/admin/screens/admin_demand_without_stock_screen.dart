import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';

/// Один товар без остатка, на который есть спрос — отмечен в «Избранном»
/// у части клиентов и/или на него оформлен предзаказ.
class DemandProduct {
  final String name;
  final double price;
  final int favoritesCount;
  final int preorderCount;

  const DemandProduct({
    required this.name,
    required this.price,
    required this.favoritesCount,
    required this.preorderCount,
  });

  double get potentialDemand => price * preorderCount;
  bool get hasPreorders => preorderCount > 0;
  bool get hasFavorites => favoritesCount > 0;
}

const _demoDemand = <DemandProduct>[
  DemandProduct(
    name: 'Хлеб деревенский на закваске',
    price: 390,
    favoritesCount: 34,
    preorderCount: 8,
  ),
  DemandProduct(
    name: 'Наполеон',
    price: 1450,
    favoritesCount: 21,
    preorderCount: 5,
  ),
  DemandProduct(
    name: 'Тарт лимон-безе',
    price: 380,
    favoritesCount: 18,
    preorderCount: 3,
  ),
  DemandProduct(
    name: 'Чиабатта',
    price: 450,
    favoritesCount: 12,
    preorderCount: 0,
  ),
  DemandProduct(
    name: 'Булочка зерновая',
    price: 210,
    favoritesCount: 9,
    preorderCount: 1,
  ),
  DemandProduct(
    name: 'Чизкейк с вишней',
    price: 1250,
    favoritesCount: 15,
    preorderCount: 4,
  ),
];

/// «Спрос без наличия» — открывается с Dashboard администратора по тапу
/// на одноимённую карточку. Раньше карточка была некликабельной. Показывает
/// товары, которых нет в наличии, но на которые есть спрос — отмечены в
/// избранном у клиентов и/или на них оформлен предзаказ — с цифрами по
/// каждому, чтобы можно было приоритизировать производство.
class AdminDemandWithoutStockScreen extends StatelessWidget {
  const AdminDemandWithoutStockScreen({super.key});

  static const items = _demoDemand;

  double get _totalPotential =>
      items.fold(0, (sum, item) => sum + item.potentialDemand);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminDashboardScreen.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header(context)),
            SliverToBoxAdapter(child: _summary()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, i) => _DemandCard(item: items[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
              border: Border.all(color: AdminDashboardScreen.border),
            ),
            child: const Icon(
              Icons.chevron_left,
              color: AdminDashboardScreen.brown,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Спрос без наличия',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AdminDashboardScreen.dark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${items.length} товаров ожидают клиенты',
                style: const TextStyle(
                  fontSize: 13,
                  color: AdminDashboardScreen.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _summary() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminDashboardScreen.border),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFF4E2D2),
            child: Icon(Icons.priority_high_rounded, color: Color(0xFF9A4D20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Потенциальный спрос от предзаказов',
                  style: TextStyle(
                    fontSize: 13,
                    color: AdminDashboardScreen.muted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_totalPotential.toStringAsFixed(0)} ₽',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AdminDashboardScreen.brown,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _DemandCard extends StatelessWidget {
  final DemandProduct item;
  const _DemandCard({required this.item});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AdminDashboardScreen.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AdminDashboardScreen.dark,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${item.price.toStringAsFixed(0)} ₽',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AdminDashboardScreen.dark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _stat(
              icon: item.hasFavorites ? Icons.favorite : Icons.favorite_border,
              iconColor: item.hasFavorites
                  ? const Color(0xFFB5544A)
                  : AdminDashboardScreen.muted,
              label: 'В избранном',
              value: '${item.favoritesCount}',
            ),
            const SizedBox(width: 18),
            _stat(
              icon: Icons.event_available_outlined,
              iconColor: item.hasPreorders
                  ? AdminDashboardScreen.brown
                  : AdminDashboardScreen.muted,
              label: 'Предзаказано',
              value: '${item.preorderCount}',
            ),
            if (item.hasPreorders) ...[
              const Spacer(),
              Text(
                '≈ ${item.potentialDemand.toStringAsFixed(0)} ₽',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AdminDashboardScreen.brown,
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );

  Widget _stat({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: iconColor),
      const SizedBox(width: 5),
      Text(
        value,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AdminDashboardScreen.dark,
        ),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: AdminDashboardScreen.muted),
      ),
    ],
  );
}
