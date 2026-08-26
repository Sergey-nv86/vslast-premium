import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';

class BakeScheduleService {
  BakeScheduleService._();

  static final BakeScheduleService instance = BakeScheduleService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<DateTime, List<Product>>> loadWeek({
    required DateTime startDate,
  }) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day);

    final end = start.add(const Duration(days: 7));

    final schedules = await _supabase
        .from('bake_schedules')
        .select('id,bake_date')
        .gte('bake_date', _date(start))
        .lt('bake_date', _date(end))
        .order('bake_date');

    final result = <DateTime, List<Product>>{};

    for (var i = 0; i < 7; i++) {
      result[start.add(Duration(days: i))] = <Product>[];
    }

    for (final rawSchedule in schedules) {
      final schedule = Map<String, dynamic>.from(rawSchedule);

      final date = DateTime.parse(schedule['bake_date'].toString());

      final scheduleId = schedule['id'].toString();

      final rows = await _supabase
          .from('bake_schedule_items')
          .select('product_id, products:product_id(*)')
          .eq('schedule_id', scheduleId);

      final products = <Product>[];

      for (final raw in rows) {
        final row = Map<String, dynamic>.from(raw);

        final rawProduct = row['products'];

        if (rawProduct is Map) {
          products.add(_productFromMap(Map<String, dynamic>.from(rawProduct)));
        }
      }

      result[DateTime(date.year, date.month, date.day)] = products;
    }

    return result;
  }

  Future<void> setProductsForDate({
    required DateTime date,
    required List<Product> products,
  }) async {
    final normalized = DateTime(date.year, date.month, date.day);

    var schedule = await _supabase
        .from('bake_schedules')
        .select('id')
        .eq('bake_date', _date(normalized))
        .maybeSingle();

    if (products.isEmpty) {
      if (schedule != null) {
        await _supabase
            .from('bake_schedules')
            .delete()
            .eq('id', schedule['id']);
      }

      return;
    }

    schedule ??= await _supabase
        .from('bake_schedules')
        .insert({'bake_date': _date(normalized)})
        .select('id')
        .single();

    final scheduleId = schedule['id'].toString();

    await _supabase
        .from('bake_schedule_items')
        .delete()
        .eq('schedule_id', scheduleId);

    await _supabase
        .from('bake_schedule_items')
        .insert(
          products
              .map(
                (product) => {
                  'schedule_id': scheduleId,
                  'product_id': product.id,
                },
              )
              .toList(),
        );
  }

  Future<List<Map<String, dynamic>>> createPreorders({
    required Map<DateTime, Map<String, int>> selections,
    String? comment,
  }) async {
    final payload = <Map<String, dynamic>>[];

    final dates = selections.keys.toList()..sort();

    for (final date in dates) {
      final items = selections[date] ?? <String, int>{};

      if (items.isEmpty) {
        continue;
      }

      payload.add({
        'date': _date(date),
        'items': items.entries
            .map((entry) => {'product_id': entry.key, 'quantity': entry.value})
            .toList(),
      });
    }

    if (payload.isEmpty) {
      throw Exception('Выберите хлеб для предзаказа');
    }

    // RPC create_preorders_from_bake_schedule()
    // работает только от авторизованного пользователя.
    //
    // Не пытаемся вызывать его без активной Supabase-сессии,
    // иначе PostgreSQL auth.uid() будет NULL.
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Для оформления предзаказа необходимо войти в аккаунт');
    }

    final response = await _supabase.rpc(
      'create_preorders_from_bake_schedule',
      params: {
        'p_payload': payload,
        'p_payment_method': 'onlineSbp',
        'p_comment': comment,
      },
    );

    if (response is List) {
      return response
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    throw Exception('Сервер не вернул предзаказы');
  }

  Product _productFromMap(Map<String, dynamic> raw) {
    ProductCategory category = ProductCategory.bread;

    final categoryRaw = (raw['category'] ?? raw['category_name'] ?? '')
        .toString()
        .toLowerCase();

    if (categoryRaw.contains('торт') || categoryRaw.contains('cake')) {
      category = ProductCategory.cakes;
    } else if (categoryRaw.contains('десерт') ||
        categoryRaw.contains('dessert')) {
      category = ProductCategory.desserts;
    } else if (categoryRaw.contains('выпеч') ||
        categoryRaw.contains('pastry')) {
      category = ProductCategory.pastry;
    }

    ProductBadge? badge;

    final badgeRaw = (raw['badge'] ?? '').toString().toLowerCase();

    if (badgeRaw == 'hit' || badgeRaw == 'хит') {
      badge = ProductBadge.hit;
    } else if (badgeRaw == 'new' ||
        badgeRaw == 'newitem' ||
        badgeRaw == 'новинка') {
      badge = ProductBadge.newItem;
    } else if (badgeRaw == 'promo' || badgeRaw == 'акция') {
      badge = ProductBadge.promo;
    }

    int parseInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    final imageUrl = (raw['image_url'] ?? raw['imageUrl'] ?? raw['image'] ?? '')
        .toString();

    return Product(
      id: raw['id'].toString(),
      name: (raw['name'] ?? '').toString(),
      price: parseInt(raw['price']),
      imageUrl: imageUrl,
      category: category,
      badge: badge,
      inStock: raw['in_stock'] ?? raw['inStock'] ?? true,
      isWeighed: raw['is_weighed'] ?? raw['isWeighed'] ?? false,
      weightLabel: (raw['weight_label'] ?? raw['weightLabel'] ?? '1 шт')
          .toString(),
      description: raw['description']?.toString(),
      caloriesPer100g: raw['calories_per_100g'] == null
          ? null
          : parseInt(raw['calories_per_100g']),
      proteinPer100g: parseDouble(raw['protein_per_100g']),
      fatPer100g: parseDouble(raw['fat_per_100g']),
      carbsPer100g: parseDouble(raw['carbs_per_100g']),
      composition: raw['composition']?.toString(),
    );
  }

  String _date(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');

    return '$y-$m-$d';
  }
}
