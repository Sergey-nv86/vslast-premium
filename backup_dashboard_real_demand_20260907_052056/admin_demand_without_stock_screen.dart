import 'package:flutter/material.dart';

import '../services/admin_clients_service.dart';

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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final supabase = AdminClientsService.instance.supabase;

      final productsResponse = await supabase
          .from('products')
          .select('id,name,price,is_available,is_active');

      final products = List<Map<String, dynamic>>.from(productsResponse);

      final unavailable = <String, Map<String, dynamic>>{};

      for (final product in products) {
        final id = product['id']?.toString();
        if (id == null || id.isEmpty) continue;

        final active =
            product['is_active'] == true || product['is_active'] == null;

        final available =
            product['is_available'] == true || product['is_available'] == null;

        if (active && !available) {
          unavailable[id] = product;
        }
      }

      if (unavailable.isEmpty) {
        if (!mounted) return;

        setState(() {
          _items = [];
          _loading = false;
        });

        return;
      }

      final favoritesResponse = await supabase
          .from('favorites')
          .select('product_id');

      final favoriteCounts = <String, int>{};

      for (final row in favoritesResponse) {
        final productId = row['product_id']?.toString();

        if (productId == null || !unavailable.containsKey(productId)) {
          continue;
        }

        favoriteCounts[productId] = (favoriteCounts[productId] ?? 0) + 1;
      }

      final result = <DemandProduct>[];

      for (final entry in unavailable.entries) {
        final favorites = favoriteCounts[entry.key] ?? 0;

        if (favorites <= 0) continue;

        final product = entry.value;

        final price = double.tryParse(product['price']?.toString() ?? '') ?? 0;

        result.add(
          DemandProduct(
            id: entry.key,
            name: product['name']?.toString() ?? 'Без названия',
            price: price,
            favoritesCount: favorites,
          ),
        );
      }

      result.sort((a, b) => b.potentialDemand.compareTo(a.potentialDemand));

      if (!mounted) return;

      setState(() {
        _items = result;
        _loading = false;
      });
    } catch (e) {
      debugPrint('ADMIN DEMAND SCREEN ERROR: $e');

      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  double get _totalDemand =>
      _items.fold<double>(0, (sum, item) => sum + item.potentialDemand);

  String _formatRubles(double value) {
    final rounded = value.round();
    final text = rounded.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write(' ');
      }

      buffer.write(text[i]);
    }

    return '${buffer.toString()} ₽';
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
                                'клиенты добавили в избранное, пока товара нет',
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
                            'Все товары с интересом клиентов доступны.',
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
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
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
                                Icons.favorite_border_rounded,
                                color: brown,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                    '${item.favoritesCount} ${item.favoritesCount == 1 ? 'клиент' : 'клиентов'} в избранном',
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
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
