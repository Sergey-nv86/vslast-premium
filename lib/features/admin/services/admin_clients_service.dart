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

  Future<Map<String, int>> fetchClientStats() async {
    final response = await _supabase.from('profiles').select('*');

    final rows = List<Map<String, dynamic>>.from(response);

    final customers = rows.where(_isCustomer).toList();

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final newThisWeek = customers.where((profile) {
      final createdAt = _dateFrom(profile['created_at']);

      return createdAt != null && !createdAt.isBefore(weekAgo);
    }).length;

    return {'total': customers.length, 'new': newThisWeek};
  }

  Future<List<AdminClient>> fetchClients() async {
    final profilesResponse = await _supabase.from('profiles').select('*');

    final profiles = List<Map<String, dynamic>>.from(profilesResponse);

    final customers = profiles.where(_isCustomer).toList();

    final ordersResponse = await _supabase.from('orders').select('*');

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
          bonusBalance: _bonusBalance(profile),
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
        .select('*')
        .eq('id', clientId)
        .maybeSingle();

    if (profileResponse == null) {
      throw Exception('Клиент не найден');
    }

    final profile = Map<String, dynamic>.from(profileResponse);

    final ordersResponse = await _supabase.from('orders').select('*');

    final allOrders = List<Map<String, dynamic>>.from(ordersResponse);

    final clientOrders = allOrders.where((order) {
      return _userIdFromOrder(order) == clientId;
    }).toList();

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
      bonusBalance: _bonusBalance(profile),
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

  double _bonusBalance(Map<String, dynamic> profile) {
    final candidates = [
      profile['bonus_balance'],
      profile['bonus_points'],
      profile['loyalty_points'],
      profile['points'],
      profile['bonuses'],
      profile['balance'],
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
