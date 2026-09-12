import 'package:flutter/material.dart';

import '../services/admin_clients_service.dart';
import 'admin_demand_product_orders_screen.dart';

class DemandProduct {
  final String id;
  final String name;
  final double price;
  final int favoritesCount;

  const DemandProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.favoritesCount,
  });

  double get potentialDemand => price * favoritesCount;
}

class AdminDemandWithoutStockScreen extends StatefulWidget {
  const AdminDemandWithoutStockScreen({super.key});

  @override
  State<AdminDemandWithoutStockScreen> createState() =>
      _AdminDemandWithoutStockScreenState();
}

class _AdminDemandWithoutStockScreenState
    extends State<AdminDemandWithoutStockScreen> {
  bool _loading = true;
  String? _error;
  List<DemandProduct> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  double get _totalDemand =>
      _items.fold<double>(0, (sum, item) => sum + item.potentialDemand);

  String _formatRubles(double value) {
    final rounded = value.round();
    final digits = rounded.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }

    return '${buffer.toString()} ₽';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final supabase = AdminClientsService.instance.supabase;

      final productsResponse = await supabase
          .from('products')
          .select('id,name,price,in_stock,is_active');

      final unavailableProducts = <String, DemandProduct>{};

      for (final raw in productsResponse) {
        final product = Map<String, dynamic>.from(raw);
        final id = product['id']?.toString();

        if (id == null || id.isEmpty) continue;

        final isActive = product['is_active'] != false;
        final inStock = product['in_stock'] == true;

        if (!isActive || inStock) continue;

        unavailableProducts[id] = DemandProduct(
          id: id,
          name: product['name']?.toString() ?? 'Без названия',
          price: (product['price'] as num?)?.toDouble() ?? 0,
          favoritesCount: 0,
        );
      }

      if (unavailableProducts.isEmpty) {
        if (!mounted) return;

        setState(() {
          _items = [];
          _loading = false;
        });

        return;
      }

      final ordersResponse = await supabase.from('orders').select('''
            id,
            status,
            is_preorder,
            order_items (
              product_id,
              quantity
            )
          ''');

      final demandByProduct = <String, int>{};

      for (final raw in ordersResponse) {
        final order = Map<String, dynamic>.from(raw);
        final status = order['status']?.toString().toLowerCase();

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

          if (productId == null ||
              !unavailableProducts.containsKey(productId)) {
            continue;
          }

          final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
          if (quantity <= 0) continue;

          demandByProduct[productId] =
              (demandByProduct[productId] ?? 0) + quantity;
        }
      }

      final result = <DemandProduct>[];

      for (final entry in demandByProduct.entries) {
        final product = unavailableProducts[entry.key];
        if (product == null) continue;

        result.add(
          DemandProduct(
            id: product.id,
            name: product.name,
            price: product.price,
            favoritesCount: entry.value,
          ),
        );
      }

      result.sort((a, b) => b.potentialDemand.compareTo(a.potentialDemand));

      if (!mounted) return;

      setState(() {
        _items = result;
        _loading = false;
      });

      debugPrint(
        'DEMAND SCREEN: '
        'unavailable=${unavailableProducts.length}, '
        'withDemand=${result.length}',
      );
    } catch (e, st) {
      debugPrint('DEMAND WITHOUT STOCK ERROR: $e');
      debugPrintStack(stackTrace: st);

      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF8F4EE);
    const brown = Color(0xFF8B5E3C);
    const dark = Color(0xFF3B281F);
    const muted = Color(0xFF806F65);
    const border = Color(0xFFEADFD5);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Спрос без наличия',
          style: TextStyle(color: dark, fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                children: [
                  SizedBox(height: 260),
                  Center(child: CircularProgressIndicator(color: brown)),
                ],
              )
            : _error != null
            ? ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 80),
                  const Icon(Icons.error_outline, size: 48, color: brown),
                  const SizedBox(height: 16),
                  const Text(
                    'Не удалось загрузить данные',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: dark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: muted),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _load,
                    style: FilledButton.styleFrom(backgroundColor: brown),
                    child: const Text('Повторить'),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFFF4E2D2),
                          child: Icon(
                            Icons.priority_high_rounded,
                            color: Color(0xFF9A4D20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_items.length} ${_items.length == 1 ? 'товар' : 'товаров'}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: dark,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'реальный спрос по заказам, пока товара нет',
                                style: TextStyle(fontSize: 12, color: muted),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${_formatRubles(_totalDemand)} потенциального спроса',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: brown,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 70),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 52,
                            color: Color(0xFF52755D),
                          ),
                          SizedBox(height: 14),
                          Text(
                            'Сейчас спроса без наличия нет',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: dark,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Все товары с реальным спросом доступны.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: muted),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._items.map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AdminDemandProductOrdersScreen(
                                    productId: item.id,
                                    productName: item.name,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF1E8E0),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.shopping_cart_outlined,
                                      color: brown,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: dark,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          '${item.favoritesCount} ${item.favoritesCount == 1 ? 'единица' : 'единиц'} в заказах',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: muted,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${_formatRubles(item.price)} · ${_formatRubles(item.potentialDemand)} спроса',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: brown,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: muted,
                                  ),
                                ],
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
