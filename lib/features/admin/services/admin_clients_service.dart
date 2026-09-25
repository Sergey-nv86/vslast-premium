import 'package:supabase_flutter/supabase_flutter.dart';

class AdminClient {
  final String id;
  final String name;
  final String phone;
  final DateTime? registeredAt;
  final DateTime? lastActionAt;
  final double bonusBalance;

  const AdminClient({
    required this.id,
    required this.name,
    required this.phone,
    required this.registeredAt,
    required this.lastActionAt,
    required this.bonusBalance,
  });
}

class AdminClientOrder {
  final String id;
  final String number;
  final DateTime? date;
  final String status;
  final double amount;

  const AdminClientOrder({
    required this.id,
    required this.number,
    required this.date,
    required this.status,
    required this.amount,
  });
}

class AdminClientDetails {
  final AdminClient client;
  final List<AdminClientOrder> orders;
  final double totalPurchases;
  final DateTime? lastOrderAt;

  const AdminClientDetails({
    required this.client,
    required this.orders,
    required this.totalPurchases,
    required this.lastOrderAt,
  });

  int get ordersCount => orders.length;
}

class AdminClientsService {
  AdminClientsService._();

  static final AdminClientsService instance = AdminClientsService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  SupabaseClient get supabase => _supabase;

  Future<Map<String, int>> fetchClientStats() async {
    final weekAgoIso = DateTime.now()
        .subtract(const Duration(days: 7))
        .toUtc()
        .toIso8601String();

    final totalResponse = await _supabase
        .from('profiles')
        .select('id')
        .eq('role', 'customer')
        .count();

    final newResponse = await _supabase
        .from('profiles')
        .select('id')
        .eq('role', 'customer')
        .gte('created_at', weekAgoIso)
        .count();

    return {
      'total': totalResponse.count,
      'new': newResponse.count,
    };
  }

  Future<List<AdminClient>> fetchClients() async {
    final profilesResponse = await _supabase
        .from('profiles')
        .select('id, first_name, last_name, display_name, phone, created_at, updated_at, role')
        .eq('role', 'customer');

    final profiles = List<Map<String, dynamic>>.from(profilesResponse);

    final customers = profiles.where(_isCustomer).toList();

    final customerIds = customers
        .map((profile) => profile['id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();

    final bonusByUserId = <String, double>{};

    if (customerIds.isNotEmpty) {
      final loyaltyResponse = await _supabase
          .from('loyalty_accounts')
          .select('user_id, bonus_balance')
          .inFilter('user_id', customerIds);

      for (final account in loyaltyResponse) {
        final row = Map<String, dynamic>.from(account as Map);
        final userId = row['user_id']?.toString();
        if (userId == null || userId.isEmpty) continue;

        bonusByUserId[userId] = _number(row['bonus_balance']) ?? 0;
      }
    }

    // Только поля, необходимые для определения последнего действия.
    final ordersResponse = await _supabase
        .from('orders')
        .select('user_id, client_id, created_at, updated_at');

    final orders = List<Map<String, dynamic>>.from(ordersResponse);

    final Map<String, DateTime> lastOrderByUser = {};

    for (final order in orders) {
      final userId = _userIdFromOrder(order);

      if (userId == null) continue;

      final actionAt = _orderActionDate(order);

      if (actionAt == null) continue;

      final previous = lastOrderByUser[userId];

      if (previous == null || actionAt.isAfter(previous)) {
        lastOrderByUser[userId] = actionAt;
      }
    }

    final result = <AdminClient>[];

    for (final profile in customers) {
      final id = profile['id']?.toString();

      if (id == null || id.isEmpty) continue;

      final registeredAt = _dateFrom(profile['created_at']);

      final profileUpdatedAt = _dateFrom(profile['updated_at']);

      DateTime? lastActionAt = registeredAt;

      if (profileUpdatedAt != null &&
          (lastActionAt == null || profileUpdatedAt.isAfter(lastActionAt))) {
        lastActionAt = profileUpdatedAt;
      }

      final lastOrderAt = lastOrderByUser[id];

      if (lastOrderAt != null &&
          (lastActionAt == null || lastOrderAt.isAfter(lastActionAt))) {
        lastActionAt = lastOrderAt;
      }

      result.add(
        AdminClient(
          id: id,
          name: _profileName(profile),
          phone: _profilePhone(profile),
          registeredAt: registeredAt,
          lastActionAt: lastActionAt,
          bonusBalance: bonusByUserId[id] ?? 0,
        ),
      );
    }

    result.sort((a, b) {
      final aDate = a.lastActionAt;
      final bDate = b.lastActionAt;

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return bDate.compareTo(aDate);
    });

    return result;
  }

  Future<AdminClientDetails> fetchClientDetails(String clientId) async {
    final profileResponse = await _supabase
        .from('profiles')
        .select('id, first_name, last_name, display_name, phone, email, city, birth_date, role, is_active, created_at, updated_at')
        .eq('id', clientId)
        .maybeSingle();

    if (profileResponse == null) {
      throw Exception('Клиент не найден');
    }

    final profile = Map<String, dynamic>.from(profileResponse);

    final loyaltyResponse = await _supabase
        .from('loyalty_accounts')
        .select('bonus_balance')
        .eq('user_id', clientId)
        .maybeSingle();

    final bonusBalance = loyaltyResponse == null
        ? 0.0
        : (_number(loyaltyResponse['bonus_balance']) ?? 0);

    // Загружаем только историю этого клиента, а не всю таблицу orders.
    final ordersResponse = await _supabase
        .from('orders')
        .select(
          'id, user_id, client_id, status, total, created_at, '
          'order_number, pickup_date',
        )
        .or('user_id.eq.$clientId,client_id.eq.$clientId')
        .order('created_at', ascending: false);

    final clientOrders = List<Map<String, dynamic>>.from(ordersResponse);

    final parsedOrders = <AdminClientOrder>[];

    for (final order in clientOrders) {
      final date = _orderDate(order);

      parsedOrders.add(
        AdminClientOrder(
          id: order['id']?.toString() ?? '',
          number: _orderNumber(order),
          date: date,
          status: _orderStatus(order),
          amount: _orderAmount(order),
        ),
      );
    }

    parsedOrders.sort((a, b) {
      final aDate = a.date;
      final bDate = b.date;

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return bDate.compareTo(aDate);
    });

    double totalPurchases = 0;

    for (final order in parsedOrders) {
      if (_isCancelled(order.status)) continue;

      totalPurchases += order.amount;
    }

    final lastOrderAt = parsedOrders.isEmpty ? null : parsedOrders.first.date;

    final registeredAt = _dateFrom(profile['created_at']);

    final profileUpdatedAt = _dateFrom(profile['updated_at']);

    DateTime? lastActionAt = registeredAt;

    if (profileUpdatedAt != null &&
        (lastActionAt == null || profileUpdatedAt.isAfter(lastActionAt))) {
      lastActionAt = profileUpdatedAt;
    }

    if (lastOrderAt != null &&
        (lastActionAt == null || lastOrderAt.isAfter(lastActionAt))) {
      lastActionAt = lastOrderAt;
    }

    final client = AdminClient(
      id: clientId,
      name: _profileName(profile),
      phone: _profilePhone(profile),
      registeredAt: registeredAt,
      lastActionAt: lastActionAt,
      bonusBalance: bonusBalance,
    );

    return AdminClientDetails(
      client: client,
      orders: parsedOrders,
      totalPurchases: totalPurchases,
      lastOrderAt: lastOrderAt,
    );
  }

  bool _isCustomer(Map<String, dynamic> profile) {
    final role = profile['role']?.toString().trim().toLowerCase();

    if (role != null && role.isNotEmpty) {
      return role == 'customer';
    }

    return true;
  }

  String? _userIdFromOrder(Map<String, dynamic> order) {
    final candidates = [
      order['user_id'],
      order['customer_id'],
      order['profile_id'],
    ];

    for (final value in candidates) {
      final id = value?.toString();

      if (id != null && id.isNotEmpty) {
        return id;
      }
    }

    return null;
  }

  DateTime? _orderActionDate(Map<String, dynamic> order) {
    final created = _dateFrom(order['created_at']);
    final updated = _dateFrom(order['updated_at']);

    if (created == null) return updated;
    if (updated == null) return created;

    return updated.isAfter(created) ? updated : created;
  }

  DateTime? _orderDate(Map<String, dynamic> order) {
    final candidates = [
      order['created_at'],
      order['order_date'],
      order['pickup_date'],
    ];

    for (final value in candidates) {
      final date = _dateFrom(value);

      if (date != null) {
        return date;
      }
    }

    return null;
  }

  String _orderNumber(Map<String, dynamic> order) {
    final candidates = [
      order['order_number'],
      order['number'],
      order['order_no'],
    ];

    for (final value in candidates) {
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }

    return '—';
  }

  String _orderStatus(Map<String, dynamic> order) {
    final value = order['status'];

    if (value == null) {
      return 'Не указан';
    }

    return value.toString();
  }

  double _orderAmount(Map<String, dynamic> order) {
    final candidates = [
      order['total'],
      order['total_amount'],
      order['amount'],
      order['grand_total'],
      order['final_total'],
    ];

    for (final value in candidates) {
      final parsed = _number(value);

      if (parsed != null) {
        return parsed;
      }
    }

    return 0;
  }

  bool _isCancelled(String status) {
    final normalized = status.trim().toLowerCase();

    return normalized.contains('cancel') ||
        normalized.contains('отмен') ||
        normalized == 'cancelled' ||
        normalized == 'canceled';
  }

  String _profileName(Map<String, dynamic> profile) {
    final fullName = profile['full_name']?.toString().trim();

    if (fullName != null && fullName.isNotEmpty) {
      return fullName;
    }

    final name = profile['name']?.toString().trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    final firstName = profile['first_name']?.toString().trim() ?? '';

    final lastName = profile['last_name']?.toString().trim() ?? '';

    final combined = '$firstName $lastName'.trim();

    if (combined.isNotEmpty) {
      return combined;
    }

    return 'Клиент';
  }

  String _profilePhone(Map<String, dynamic> profile) {
    final phone = profile['phone']?.toString().trim();

    if (phone != null && phone.isNotEmpty) {
      return phone;
    }

    return 'Телефон не указан';
  }

  double? _number(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString().replaceAll(',', '.'));
  }

  DateTime? _dateFrom(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value.toString());
  }
}
