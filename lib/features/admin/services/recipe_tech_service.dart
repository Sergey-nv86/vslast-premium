import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

class RecipeTechService {
  RecipeTechService._();
  static final instance = RecipeTechService._();

  final SupabaseClient _db = Supabase.instance.client;

  Future<Map<String, dynamic>> analyze(List<({String mimeType, List<int> bytes})> photos) async {
    final images = photos.map((photo) => {
      'mime_type': photo.mimeType,
      'data': base64Encode(photo.bytes),
    }).toList();

    final response = await _db.functions.invoke(
      'recipe-tech-card',
      body: {'images': images},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    if (response.status < 200 || response.status >= 300 || data['error'] != null) {
      throw Exception(data['error'] ?? 'Ошибка анализа рецепта');
    }
    return data;
  }

  Future<void> saveIngredientPrice({
    required String ingredientId,
    required double purchasePrice,
    required double purchaseQuantity,
    required String purchaseUnit,
  }) async {
    if (purchasePrice < 0 || purchaseQuantity <= 0) {
      throw ArgumentError('Цена должна быть неотрицательной, количество — больше нуля');
    }
    await _db.from('ingredient_prices').upsert({
      'ingredient_id': ingredientId,
      'purchase_price': purchasePrice,
      'purchase_quantity': purchaseQuantity,
      'purchase_unit': purchaseUnit,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'updated_by': _db.auth.currentUser?.id,
    });
  }

  Future<void> saveCard({
    required String name,
    required String technology,
    required num? yieldQuantity,
    required String? yieldUnit,
    required List<Map<String, dynamic>> items,
    required num? totalCost,
    required Map<String, dynamic>? nutritionPer100,
    required String nutritionStatus,
    required String calculationStatus,
    required int photoCount,
  }) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) throw Exception('Требуется авторизация Supabase');

    final card = await _db.from('recipe_tech_cards').insert({
      'name': name,
      'technology': technology,
      'yield_quantity': yieldQuantity,
      'yield_unit': yieldUnit,
      'total_cost': totalCost,
      'calories_per_100': nutritionPer100?['calories'],
      'protein_per_100': nutritionPer100?['protein'],
      'fat_per_100': nutritionPer100?['fat'],
      'carbs_per_100': nutritionPer100?['carbs'],
      'nutrition_status': nutritionStatus,
      'calculation_status': calculationStatus,
      'source_photo_count': photoCount,
      'created_by': userId,
    }).select('id').single();

    final cardId = card['id'].toString();
    final rows = items.asMap().entries.map((entry) {
      final item = entry.value;
      return {
        'recipe_id': cardId,
        'ingredient_id': item['ingredient_id'],
        'ingredient_name_snapshot': item['ingredient_name'],
        'quantity': item['quantity'],
        'unit': item['unit'],
        'line_cost': item['line_cost'],
        'notes': item['notes'],
        'sort_order': entry.key,
      };
    }).toList();

    if (rows.isNotEmpty) {
      await _db.from('recipe_tech_card_items').insert(rows);
    }
  }
}
