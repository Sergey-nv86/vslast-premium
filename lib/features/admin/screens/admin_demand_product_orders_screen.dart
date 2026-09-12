import 'package:flutter/material.dart';

import '../services/admin_clients_service.dart';

class AdminDemandProductOrdersScreen extends StatefulWidget {
  final String productId;
  final String productName;

  const AdminDemandProductOrdersScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<AdminDemandProductOrdersScreen> createState() =>
      _AdminDemandProductOrdersScreenState();
}

class _DemandOrderRow {
  final String orderId;
  final String orderNumber;
  final String clientId;
  final String status;
  final DateTime? createdAt;
  final int quantity;
  final double total;

  const _DemandOrderRow({
    required this.orderId,
    required this.orderNumber,
    required this.clientId,
    required this.status,
    required this.createdAt,
    required this.quantity,
    required this.total,
  });
}

class _AdminDemandProductOrdersScreenState
    extends State<AdminDemandProductOrdersScreen> {
  bool _loading = true;
  String? _error;
  List<_DemandOrderRow> _orders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Дата не указана';
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day.$month.${local.year} · $hour:$minute';
  }

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

  String _statusLabel(String value) {
    switch (value.toLowerCase()) {
      case 'new':
      case 'pending':
      case 'pending_confirmation':
        return 'Новый';
      case 'processing':
        return 'В работе';
      case 'confirmed':
        return 'Подтверждён';
      case 'completed':
        return 'Выполнен';
      case 'cancelled':
      case 'canceled':
        return 'Отменён';
      case 'rejected':
        return 'Отклонён';
      default:
        return value.isEmpty ? 'Без статуса' : value;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final supabase = AdminClientsService.instance.supabase;

      final itemsResponse = await supabase
          .from('order_items')
          .select('id,order_id,quantity')
          .eq('product_id', widget.productId);

      final quantityByOrder = <String, int>{};

      for (final raw in itemsResponse) {
        final item = Map<String, dynamic>.from(raw);
        final orderId = item['order_id']?.toString().trim() ?? '';
        final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
        if (orderId.isEmpty || quantity <= 0) continue;
        quantityByOrder[orderId] = (quantityByOrder[orderId] ?? 0) + quantity;
      }

      if (quantityByOrder.isEmpty) {
        if (!mounted) return;
        setState(() {
          _orders = [];
          _loading = false;
        });
        return;
      }

      final orderIds = quantityByOrder.keys.toList();
      final ordersResponse = await supabase
          .from('orders')
          .select('id,order_number,status,created_at,client_id,user_id,total')
          .inFilter('id', orderIds)
          .order('created_at', ascending: false);

      final rows = <_DemandOrderRow>[];

      for (final raw in ordersResponse) {
        final order = Map<String, dynamic>.from(raw);
        final status = order['status']?.toString().trim() ?? '';
        final normalizedStatus = status.toLowerCase();

        if (normalizedStatus == 'cancelled' ||
            normalizedStatus == 'canceled' ||
            normalizedStatus == 'rejected') {
          continue;
        }

        final orderId = order['id']?.toString().trim() ?? '';
        if (orderId.isEmpty) continue;

        final clientId = order['client_id']?.toString().trim() ?? '';
        final orderNumber = order['order_number']?.toString().trim() ?? '';
        final total = (order['total'] as num?)?.toDouble() ?? 0;
        final createdAt = DateTime.tryParse(
          order['created_at']?.toString() ?? '',
        );

        rows.add(
          _DemandOrderRow(
            orderId: orderId,
            orderNumber: orderNumber.isEmpty ? orderId : '#$orderNumber',
            clientId: clientId.isEmpty ? 'Клиент' : 'Клиент $clientId',
            status: status,
            createdAt: createdAt,
            quantity: quantityByOrder[orderId] ?? 0,
            total: total,
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        _orders = rows;
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('DEMAND PRODUCT ORDERS ERROR: $e');
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
        title: Text(
          widget.productName,
          style: const TextStyle(color: dark, fontWeight: FontWeight.w700),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                children: const [
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
                    'Не удалось загрузить заказы',
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
                            Icons.shopping_cart_outlined,
                            color: Color(0xFF9A4D20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${_orders.length} ${_orders.length == 1 ? 'заказ' : 'заказов'} с этим товаром',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: dark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_orders.isEmpty)
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
                            'Активных заказов нет',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: dark,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._orders.map(
                      (order) => Container(
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
                                Icons.receipt_long_outlined,
                                color: brown,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${order.orderNumber} · ${order.clientId}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: dark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${order.quantity} ${order.quantity == 1 ? 'единица' : 'единиц'} · ${_statusLabel(order.status)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: muted,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${_formatDate(order.createdAt)} · ${_formatRubles(order.total)}',
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
