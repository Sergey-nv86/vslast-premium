import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../models/order.dart';
import '../models/order_list_item.dart';
import '../models/product.dart';

class OrdersService {
  OrdersService._();

  static final OrdersService instance = OrdersService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<OrderListItem>> fetchMyOrders() async {
    final totalStarted = DateTime.now();
    debugPrint('[Orders] START fetchMyOrders');
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Пользователь не авторизован');
    }

    // Для списка заказов загружаем только необходимые данные.
    // Полные order_items и детали заказа загружаются отдельно
    // при открытии конкретного заказа.
    final ordersResponse = await _supabase
        .from('orders')
        .select('''
          id,
          order_number,
          status,
          delivery_method,
          payment_method,
          total,
          created_at
        ''')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(30);

    final supabaseMs =
        DateTime.now().difference(totalStarted).inMilliseconds;

    debugPrint(
      '[Orders] Supabase response: $supabaseMs ms',
    );

    final mappingStarted = DateTime.now();

    final orders = List<Map<String, dynamic>>.from(ordersResponse);
    final result = orders.map(_mapOrder).toList();

    final mappingMs =
        DateTime.now().difference(mappingStarted).inMilliseconds;

    final totalMs =
        DateTime.now().difference(totalStarted).inMilliseconds;

    debugPrint(
      '[Orders] mapping: $mappingMs ms, '
      'total: $totalMs ms, '
      'orders: ${result.length}',
    );

    return result;
  }

  /// Загружает полный заказ текущего пользователя по номеру заказа.
  ///
  /// Используется экраном «Мои заказы», пока OrderListItem
  /// хранит номер заказа без UUID.
  Future<OrderSummary> fetchOrderByNumber(int orderNumber) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Пользователь не авторизован');
    }

    final response = await _supabase
        .from('orders')
        .select('''
          id,
          order_number,
          status,
          delivery_method,
          payment_method,
          items_total,
          pickup_discount,
          delivery_cost,
          total,
          pickup_date,
          pickup_time_slot,
          delivery_address,
          comment,
          created_at,
          order_items (
            id,
            product_id,
            product_name,
            unit_price,
            quantity,
            weight_label,
            line_total
          )
        ''')
        .eq('order_number', orderNumber)
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) {
      throw Exception('Заказ №$orderNumber не найден');
    }

    return _mapOrderSummary(Map<String, dynamic>.from(response));
  }

  /// Загружает полный заказ текущего пользователя по UUID.
  ///
  /// Используется:
  /// - экраном деталей заказа;
  /// - переходом из push-уведомления.
  Future<OrderSummary> fetchOrderById(String orderId) async {
    final user = _supabase.auth.currentUser;
    final sessionUserId = _supabase.auth.currentSession?.user.id;

    debugPrint(
      '[ORDER DEBUG] fetchOrderById '
      'orderId=$orderId '
      'currentUser=${user?.id} '
      'sessionUser=$sessionUserId',
    );

    if (user == null) {
      throw Exception('Пользователь не авторизован');
    }

    try {
      final response = await _supabase
          .from('orders')
          .select('''
            id,
            order_number,
            status,
            delivery_method,
            payment_method,
            items_total,
            pickup_discount,
            delivery_cost,
            total,
            pickup_date,
            pickup_time_slot,
            delivery_address,
            comment,
            created_at,
            order_items (
              id,
              product_id,
              product_name,
              unit_price,
              quantity,
              weight_label,
              line_total
            )
          ''')
          .eq('id', orderId)
          .maybeSingle();

      debugPrint('[ORDER DEBUG] full response=$response');

      if (response == null) {
        final probe = await _supabase
            .from('orders')
            .select('id, order_number, user_id, status, created_at')
            .eq('id', orderId)
            .maybeSingle();

        debugPrint('[ORDER DEBUG] parent-only probe=$probe');

        throw Exception('Заказ не найден');
      }

      return _mapOrderSummary(Map<String, dynamic>.from(response));
    } catch (error, stackTrace) {
      debugPrint('[ORDER DEBUG] ERROR: $error');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  OrderListItem _mapOrder(Map<String, dynamic> row) {
    final rawItems = row['order_items'];

    final items = rawItems is List
        ? List<Map<String, dynamic>>.from(
            rawItems.map((item) => Map<String, dynamic>.from(item as Map)),
          )
        : <Map<String, dynamic>>[];

    final itemsCount = items.fold<int>(
      0,
      (sum, item) => sum + _toInt(item['quantity']),
    );

    final title = _buildTitle(items);

    return OrderListItem(
      orderId: row['id'].toString(),
      number: _toInt(row['order_number']),
      title: title,
      status: _mapStatus(row['status']?.toString()),
      placedAt: DateTime.parse(row['created_at'].toString()).toLocal(),
      itemsCount: itemsCount,
      totalPrice: _toInt(row['total']),
      statusDescription: _buildStatusDescription(
        row['status']?.toString(),
        row['delivery_method']?.toString(),
        row['payment_method']?.toString(),
      ),
      imageUrl: _imagePlaceholder,
    );
  }

  OrderSummary _mapOrderSummary(Map<String, dynamic> row) {
    final rawItems = row['order_items'];

    final items = rawItems is List
        ? List<Map<String, dynamic>>.from(
            rawItems.map((item) => Map<String, dynamic>.from(item as Map)),
          )
        : <Map<String, dynamic>>[];

    final orderItems = items.map(_mapOrderItem).toList();

    return OrderSummary(
      orderId: row['id'].toString(),
      orderNumber: _toInt(row['order_number']),
      createdAt: DateTime.parse(row['created_at'].toString()).toLocal(),
      items: orderItems,
      comment: row['comment']?.toString(),
      deliveryMethod: _mapDeliveryMethod(row['delivery_method']?.toString()),
      pickupDate: _parseDate(row['pickup_date']),
      pickupTimeSlot: row['pickup_time_slot']?.toString() ?? '',
      paymentMethod: _mapPaymentMethod(row['payment_method']?.toString()),
      deliveryAddress: row['delivery_address']?.toString(),
      itemsTotal: _toInt(row['items_total']),
      pickupDiscount: _toInt(row['pickup_discount']),
      deliveryCost: _toInt(row['delivery_cost']),
      total: _toInt(row['total']),
    );
  }

  OrderItemSnapshot _mapOrderItem(Map<String, dynamic> item) {
    final product = Product(
      id: item['product_id']?.toString() ?? '',
      name: item['product_name']?.toString() ?? 'Товар',
      price: _toInt(item['unit_price']),
      imageUrl: _imagePlaceholder,
      category: ProductCategory.bread,
      weightLabel: item['weight_label']?.toString() ?? '1 шт',
    );

    return OrderItemSnapshot(
      product: product,
      quantity: _toInt(item['quantity']),
    );
  }

  DeliveryMethod _mapDeliveryMethod(String? value) {
    switch (value) {
      case 'delivery':
        return DeliveryMethod.delivery;
      case 'pickup':
      default:
        return DeliveryMethod.pickup;
    }
  }

  PaymentMethod _mapPaymentMethod(String? value) {
    switch (value) {
      case 'onlineSbp':
      case 'online_sbp':
        return PaymentMethod.onlineSbp;
      case 'cash':
      default:
        return PaymentMethod.cash;
    }
  }

  DateTime _parseDate(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }

    final parsed = DateTime.tryParse(value.toString());

    return parsed ?? DateTime.now();
  }

  OrderStatus _mapStatus(String? status) {
    switch (status) {
      case 'completed':
      case 'done':
        return OrderStatus.completed;

      case 'awaiting_payment':
      case 'awaitingPayment':
      case 'confirmed':
        return OrderStatus.awaitingPayment;

      case 'pending_confirmation':
      case 'processing':
      case 'new':
      case 'pending':
      case 'awaiting_confirmation':
      default:
        return OrderStatus.processing;
    }
  }

  String _buildTitle(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return 'Заказ';
    }

    final names = items
        .map((item) => item['product_name']?.toString().trim())
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .toList();

    if (names.isEmpty) {
      return 'Заказ';
    }

    if (names.length == 1) {
      return names.first;
    }

    if (names.length == 2) {
      return '${names[0]} + ${names[1]}';
    }

    return '${names[0]} + ${names[1]} и ещё ${names.length - 2}';
  }

  String _buildStatusDescription(
    String? status,
    String? deliveryMethod,
    String? paymentMethod,
  ) {
    switch (status) {
      case 'awaiting_payment':
      case 'awaitingPayment':
      case 'confirmed':
        if (paymentMethod == 'onlineSbp') {
          return 'Заказ подтвержден.\nОжидается оплата по СБП.';
        }

        return 'Заказ подтвержден.\nОжидается оплата при получении.';

      case 'completed':
      case 'done':
        return 'Спасибо за покупку!';

      case 'pending_confirmation':
      case 'processing':
      case 'new':
      case 'pending':
      case 'awaiting_confirmation':
      default:
        if (deliveryMethod == 'delivery') {
          return 'Заказ отправлен администратору.\nОжидает подтверждения доставки.';
        }

        return 'Заказ отправлен администратору.\nОжидает подтверждения.';
    }
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static const String _imagePlaceholder = 'assets/images/bread_country.jpg';
}
