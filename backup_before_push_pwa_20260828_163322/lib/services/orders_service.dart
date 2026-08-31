import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/order_list_item.dart';

class OrdersService {
  OrdersService._();

  static final OrdersService instance = OrdersService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<OrderListItem>> fetchMyOrders() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Пользователь не авторизован');
    }

    final ordersResponse = await _supabase
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
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    final orders = List<Map<String, dynamic>>.from(ordersResponse);

    return orders.map(_mapOrder).toList();
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

  OrderStatus _mapStatus(String? status) {
    switch (status) {
      case 'completed':
      case 'done':
        return OrderStatus.completed;

      case 'awaiting_payment':
      case 'awaitingPayment':
      case 'confirmed':
        return OrderStatus.awaitingPayment;

      case 'processing':
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

      case 'processing':
      default:
        if (deliveryMethod == 'delivery') {
          return 'Заказ отправлен администратору.\nОжидает подтверждения доставки.';
        }

        return 'Заказ отправлен администратору.\nОжидает подтверждения.';
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  /// Временная заглушка для изображения.
  ///
  /// На следующем этапе подключим фотографию первого товара
  /// из products / storage, не меняя UI карточки.
  static const String _imagePlaceholder = 'assets/images/bread_country.jpg';
}
