import 'package:supabase_flutter/supabase_flutter.dart';

class Bakery {
  final String id;
  final String name;
  final String city;
  final String address;
  final bool isActive;

  const Bakery({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.isActive,
  });

  String get title => '$name, $address';

  String get subtitle => 'Пекарня-кондитерская «$name»';

  factory Bakery.fromSupabase(Map<String, dynamic> row) {
    return Bakery(
      id: row['id']?.toString() ?? '',
      name: row['name']?.toString().trim() ?? '',
      city: row['city']?.toString().trim() ?? '',
      address: row['address']?.toString().trim() ?? '',
      isActive: row['is_active'] == true,
    );
  }
}

class BakeryService {
  BakeryService._();

  static final BakeryService instance = BakeryService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Bakery?> getActiveBakery() async {
    final response = await _supabase
        .from('bakeries')
        .select('id, name, city, address, is_active')
        .eq('is_active', true)
        .order('name')
        .limit(1);

    if (response.isEmpty) {
      return null;
    }

    return Bakery.fromSupabase(Map<String, dynamic>.from(response.first));
  }
}
