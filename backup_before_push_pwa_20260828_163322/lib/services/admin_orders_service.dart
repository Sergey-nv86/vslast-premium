import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/admin/screens/admin_orders_screen.dart';
import '../services/bakery_service.dart';

class AdminOrdersService {
  AdminOrdersService._();

  static final AdminOrdersService instance = AdminOrdersService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<AdminOrder>> fetchOrders() async {
    final authUser = _supabase.auth.currentUser;
    final session = _supabase.auth.currentSession;

    debugPrint('ADMIN AUTH USER: ${authUser?.id}');
    debugPrint('ADMIN AUTH EMAIL: ${authUser?.email}');
    debugPrint('ADMIN AUTH SESSION: ${session != null}');

    debugPrint('ADMIN ORDERS: начинаем загрузку заказов');

    final response = await _supabase
        .from('orders')
        .select('''
          id,
          order_number,
          user_id,
          status,
          delivery_method,
          payment_method,
          pickup_date,
          pickup_time_slot,
          delivery_address,
          delivery_cost,
          comment,
          items_total,
          pickup_discount,
          total,
          created_at,
          updated_at,
          order_items (
            id,
            product_id,
            product_name,
            unit_price,
            quantity,
            weight_label,
            line_total,
            products:product_id (
              id,
              image_url,
              gallery_images
            )
          )
        ''')
        .order('created_at', ascending: false);

    debugPrint('ADMIN ORDERS: response = $response');

    final rows = List<Map<String, dynamic>>.from(response);
    debugPrint('ADMIN ORDERS: получено строк = ${rows.length}');

    final userIds = rows
        .map((row) => row['user_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final profilesById = <String, Map<String, dynamic>>{};

    if (userIds.isNotEmpty) {
      debugPrint('ADMIN PROFILES: userIds = $userIds');
      final profilesResponse = await _supabase
          .from('profiles')
          .select('id, display_name, first_name, last_name, phone, email')
          .inFilter('id', userIds);

      debugPrint('ADMIN PROFILES: response = $profilesResponse');

      for (final profile in profilesResponse) {
        final map = Map<String, dynamic>.from(profile as Map);
        final id = map['id']?.toString();
        if (id != null && id.isNotEmpty) {
          profilesById[id] = map;
        }
      }
    }

    final bakery = await BakeryService.instance.getActiveBakery();

    debugPrint(
      'ADMIN BAKERY: '
      'name=${bakery?.name}, '
      'city=${bakery?.city}, '
      'address=${bakery?.address}',
    );

    return rows.map((row) {
      final userId = row['user_id']?.toString() ?? '';
      return _mapOrder(row, profile: profilesById[userId], bakery: bakery);
    }).toList();
  }

  /// Возвращает невыданные заказы клиента по номеру карты лояльности.
  ///
  /// QR клиента содержит card_number.
  /// Сначала находим user_id в loyalty_accounts,
  /// затем загружаем только активные заказы этого клиента.
  Future<List<AdminOrder>> fetchActiveOrdersByCardNumber(
    String cardNumber,
  ) async {
    final normalizedCardNumber = cardNumber.trim().toUpperCase();

    if (normalizedCardNumber.isEmpty) {
      throw Exception('Не указан номер карты клиента');
    }

    debugPrint(
      'ADMIN QR ORDERS: поиск клиента по карте '
      'card_number=$normalizedCardNumber',
    );

    final account = await _supabase
        .from('loyalty_accounts')
        .select('id, user_id, card_number')
        .eq('card_number', normalizedCardNumber)
        .maybeSingle();

    if (account == null) {
      debugPrint(
        'ADMIN QR ORDERS: карта не найдена '
        'card_number=$normalizedCardNumber',
      );

      throw Exception('Карта $normalizedCardNumber не найдена');
    }

    final userId = account['user_id']?.toString().trim() ?? '';

    if (userId.isEmpty) {
      throw Exception('Для карты $normalizedCardNumber не найден клиент');
    }

    debugPrint(
      'ADMIN QR ORDERS: карта найдена, '
      'user_id=$userId',
    );

    return fetchActiveOrdersByCustomer(userId);
  }

  /// Возвращает только невыданные/незавершённые заказы конкретного клиента.
  ///
  /// Используется после сканирования QR-кода клиента.
  /// QR содержит номер карты loyalty_accounts.card_number.
  /// После определения user_id загружаются только активные заказы этого клиента.
  Future<List<AdminOrder>> fetchActiveOrdersByCustomer(String userId) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      throw Exception('Не указан клиент');
    }

    debugPrint(
      'ADMIN QR ORDERS: загрузка активных заказов клиента '
      'user_id=$normalizedUserId',
    );

    final response = await _supabase
        .from('orders')
        .select('''
          id,
          order_number,
          user_id,
          status,
          delivery_method,
          payment_method,
          pickup_date,
          pickup_time_slot,
          delivery_address,
          delivery_cost,
          comment,
          items_total,
          pickup_discount,
          total,
          created_at,
          updated_at,
          order_items (
            id,
            product_id,
            product_name,
            unit_price,
            quantity,
            weight_label,
            line_total,
            products:product_id (
              id,
              image_url,
              gallery_images
            )
          )
        ''')
        .eq('user_id', normalizedUserId)
        .order('created_at', ascending: false);

    final rows = List<Map<String, dynamic>>.from(response);

    debugPrint('ADMIN QR ORDERS: заказов клиента = ${rows.length}');

    const finishedStatuses = {
      'completed',
      'cancelled',
      'canceled',
      'rejected',
      'issued',
      'picked_up',
      'pickedup',
      'delivered',
    };

    final activeRows = rows.where((row) {
      final status = row['status']?.toString().trim().toLowerCase() ?? '';
      return !finishedStatuses.contains(status);
    }).toList();

    debugPrint('ADMIN QR ORDERS: активных заказов = ${activeRows.length}');

    if (activeRows.isEmpty) {
      return [];
    }

    final profileResponse = await _supabase
        .from('profiles')
        .select('id, display_name, first_name, last_name, phone, email')
        .eq('id', normalizedUserId)
        .maybeSingle();

    final profile = profileResponse == null
        ? null
        : Map<String, dynamic>.from(profileResponse);

    final bakery = await BakeryService.instance.getActiveBakery();

    return activeRows
        .map((row) => _mapOrder(row, profile: profile, bakery: bakery))
        .toList();
  }

  /// Статистика заказов для главного экрана администратора.
  ///
  /// total — незавершённые заказы, которые должны быть получены сегодня.
  /// newOrders — новые заказы на сегодня.
  Future<Map<String, int>> fetchOrderStats() async {
    debugPrint('ADMIN DASHBOARD ORDERS: загрузка всех незавершённых заказов');

    final response = await _supabase.from('orders').select('id, status');

    final finishedStatuses = {'completed', 'cancelled', 'canceled', 'rejected'};

    const newStatuses = {
      'new',
      'processing',
      'pending',
      'pending_confirmation',
      'awaiting_confirmation',
      'awaiting_payment',
      'awaitingpayment',
    };

    final statusCounts = <String, int>{};
    int total = 0;
    int newOrders = 0;

    for (final raw in response) {
      final row = Map<String, dynamic>.from(raw as Map);
      final status = row['status']?.toString().trim().toLowerCase() ?? '';

      statusCounts[status] = (statusCounts[status] ?? 0) + 1;

      if (finishedStatuses.contains(status)) {
        continue;
      }

      total++;

      if (newStatuses.contains(status)) {
        newOrders++;
      }
    }

    debugPrint('ADMIN DASHBOARD STATUS COUNTS: $statusCounts');
    debugPrint('ADMIN DASHBOARD ORDERS: all unfinished=$total, new=$newOrders');

    return {'total': total, 'new': newOrders};
  }

  AdminOrder _mapOrder(
    Map<String, dynamic> row, {
    Map<String, dynamic>? profile,
    Bakery? bakery,
  }) {
    final rawItems = row['order_items'];

    final items = rawItems is List
        ? rawItems
              .map((item) => Map<String, dynamic>.from(item as Map))
              .map(_mapItem)
              .toList()
        : <AdminOrderItem>[];

    final customerProfile = profile ?? const <String, dynamic>{};

    final displayName =
        customerProfile['display_name']?.toString().trim() ?? '';

    final firstName = customerProfile['first_name']?.toString().trim() ?? '';

    final lastName = customerProfile['last_name']?.toString().trim() ?? '';

    final customerName = displayName.isNotEmpty
        ? displayName
        : [firstName, lastName].where((value) => value.isNotEmpty).join(' ');

    final customerPhone = customerProfile['phone']?.toString().trim() ?? '';

    final deliveryMethod = row['delivery_method']?.toString() ?? 'pickup';

    final pickupDate = row['pickup_date']?.toString() ?? '';

    final pickupTimeSlot = row['pickup_time_slot']?.toString() ?? '';

    final status = row['status']?.toString() ?? 'processing';

    final pickupAddressTitle = bakery != null
        ? bakery.name
        : 'Пекарня «Всласть»';

    final pickupAddressSubtitle = bakery != null
        ? [
            if (bakery.city.isNotEmpty) bakery.city,
            if (bakery.address.isNotEmpty) bakery.address,
          ].join(', ')
        : 'Адрес не указан';

    return AdminOrder(
      id: row['id']?.toString() ?? '',
      number: '#${_toInt(row['order_number'])}',

      customer: customerName.isNotEmpty ? customerName : 'Клиент',

      phone: customerPhone,

      customerType: 'Клиент',
      customerOrderCount: 1,

      time: _formatCreatedAt(row['created_at']),

      type: _buildType(deliveryMethod, pickupTimeSlot),

      receiveTimeDetail: _buildReceiveTimeDetail(
        deliveryMethod,
        pickupDate,
        pickupTimeSlot,
      ),

      pickupDate: DateTime.tryParse(pickupDate),

      // Предзаказ — это тип заказа, а не отдельный статус.
      // Реальный статус БД сохраняем без подмены:
      // processing -> Новый
      // confirmed -> Подтверждён
      // completed -> Выполнен
      status: _mapStatus(status),

      total: _toDouble(row['total']),

      discount: _toDouble(row['pickup_discount']),

      comment: _nullableString(row['comment']),

      isPreorder: _isPreorder(pickupDate, row['created_at']),

      items: items,
      pickupAddressTitle: pickupAddressTitle,
      pickupAddressSubtitle: pickupAddressSubtitle,
    );
  }

  AdminOrderItem _mapItem(Map<String, dynamic> row) {
    final rawProduct = row['products'];

    final product = rawProduct is Map
        ? Map<String, dynamic>.from(rawProduct)
        : <String, dynamic>{};

    final imageUrl = product['image_url']?.toString().trim() ?? '';

    final name = row['product_name']?.toString().trim() ?? 'Товар';

    final weight = row['weight_label']?.toString().trim() ?? '';

    final quantity = _toInt(row['quantity']);
    final unitPrice = _toDouble(row['unit_price']);
    final lineTotal = _toDouble(row['line_total']);

    debugPrint(
      'ADMIN ORDER ITEM: '
      'name=$name, '
      'quantity=$quantity, '
      'unitPrice=$unitPrice, '
      'lineTotal=$lineTotal',
    );

    final calculatedLineTotal = unitPrice * quantity;

    if ((lineTotal - calculatedLineTotal).abs() > 0.01) {
      debugPrint(
        'WARNING: line_total отличается от расчёта: '
        'db=$lineTotal '
        'calculated=$calculatedLineTotal',
      );
    }

    return AdminOrderItem(
      name: name.isNotEmpty ? name : 'Товар',
      weight: weight,
      quantity: quantity,
      price: unitPrice,
      imageUrl: imageUrl,
    );
  }

  String? _nullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final result = value.toString().trim();

    if (result.isEmpty) {
      return null;
    }

    return result;
  }

  String _mapStatus(String status) {
    switch (status) {
      case 'processing':
        return 'Новый';

      case 'confirmed':
        return 'Подтверждён';

      case 'awaitingPayment':
      case 'awaiting_payment':
        return 'Ожидает оплаты';

      case 'paid':
        return 'Оплачен';

      case 'ready':
        return 'Готов';

      case 'in_progress':
      case 'inProgress':
      case 'working':
        return 'В работе';

      case 'completed':
      case 'done':
        return 'Выполнен';

      case 'cancelled':
      case 'canceled':
        return 'Отменён';

      default:
        return 'Новый';
    }
  }

  String _buildType(String deliveryMethod, String pickupTimeSlot) {
    if (deliveryMethod == 'pickup') {
      if (pickupTimeSlot.isNotEmpty) {
        return 'Самовывоз · $pickupTimeSlot';
      }

      return 'Самовывоз';
    }

    return 'Доставка';
  }

  String _buildReceiveTimeDetail(
    String deliveryMethod,
    String pickupDate,
    String pickupTimeSlot,
  ) {
    if (deliveryMethod == 'pickup') {
      if (pickupDate.isNotEmpty && pickupTimeSlot.isNotEmpty) {
        return '${_formatDate(pickupDate)}, '
            'с $pickupTimeSlot';
      }

      if (pickupDate.isNotEmpty) {
        return _formatDate(pickupDate);
      }

      return '';
    }

    return 'Доставка';
  }

  bool _isPreorder(String pickupDate, dynamic createdAt) {
    if (pickupDate.isEmpty || createdAt == null) {
      return false;
    }

    final pickup = DateTime.tryParse(pickupDate);

    final created = DateTime.tryParse(createdAt.toString());

    if (pickup == null || created == null) {
      return false;
    }

    final localCreated = created.toLocal();

    final createdDate = DateTime(
      localCreated.year,
      localCreated.month,
      localCreated.day,
    );

    return pickup.isAfter(createdDate);
  }

  String _formatCreatedAt(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');

    if (date == null) {
      return '';
    }

    final local = date.toLocal();

    final day = local.day.toString().padLeft(2, '0');

    final month = local.month.toString().padLeft(2, '0');

    final hour = local.hour.toString().padLeft(2, '0');

    final minute = local.minute.toString().padLeft(2, '0');

    return '$day.$month, $hour:$minute';
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    final year = date.year.toString();

    return '$day.$month.$year';
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

  double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  /// Изменяет статус реального заказа в Supabase.
  ///
  /// Рабочий цикл:
  /// processing -> confirmed -> completed
  ///
  /// Важно: UPDATE выполняется с SELECT изменённой строки.
  /// Это позволяет обнаружить ситуацию, когда RLS не разрешает
  /// обновление и Supabase возвращает 0 изменённых строк без ошибки.
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final normalizedOrderId = orderId.trim();
    final normalizedStatus = status.trim();

    if (normalizedOrderId.isEmpty) {
      throw Exception('Не указан id заказа');
    }

    if (normalizedStatus.isEmpty) {
      throw Exception('Не указан новый статус заказа');
    }

    debugPrint(
      'ADMIN ORDER STATUS UPDATE START: '
      'id=$normalizedOrderId, status=$normalizedStatus',
    );

    final currentUser = _supabase.auth.currentUser;

    debugPrint(
      'ADMIN AUTH DEBUG: '
      'userId=${currentUser?.id}, '
      'email=${currentUser?.email}, '
      'phone=${currentUser?.phone}',
    );

    try {
      final result = await _supabase
          .from('orders')
          .update({
            'status': normalizedStatus,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', normalizedOrderId)
          .select('id,status')
          .maybeSingle();

      debugPrint('ADMIN ORDER STATUS UPDATE RESPONSE: $result');

      if (result == null) {
        throw Exception(
          'Supabase не изменил заказ. '
          'Возможна проблема с RLS UPDATE policy '
          'или неверный id заказа.',
        );
      }

      final savedId = result['id']?.toString() ?? '';
      final savedStatus = result['status']?.toString() ?? '';

      debugPrint(
        'ADMIN ORDER STATUS UPDATE SAVED: '
        'id=$savedId, status=$savedStatus',
      );

      if (savedStatus != normalizedStatus) {
        throw Exception(
          'Статус не сохранён. '
          'Ожидался "$normalizedStatus", получен "$savedStatus".',
        );
      }
    } on PostgrestException catch (e) {
      debugPrint(
        'ADMIN ORDER STATUS POSTGREST ERROR: '
        'code=${e.code}, message=${e.message}, '
        'details=${e.details}, hint=${e.hint}',
      );

      throw Exception('Ошибка Supabase: ${e.message}');
    } catch (e) {
      debugPrint('ADMIN ORDER STATUS ERROR: $e');
      rethrow;
    }
  }
}
