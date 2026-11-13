import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecipeTechService {
  RecipeTechService._();
  static final instance = RecipeTechService._();
  final SupabaseClient _db = Supabase.instance.client;

  Future<Map<String, dynamic>> analyze(List<Map<String, dynamic>> images) async {
    final response = await _db.functions.invoke('recipe-tech-card', body: {'images': images});
    final data = Map<String, dynamic>.from(response.data as Map);
    if (response.status < 200 || response.status >= 300 || data['error'] != null) {
      throw Exception(data['error'] ?? 'Ошибка анализа рецепта');
    }
    return data;
  }

  Future<Map<String, dynamic>?> instancePriceLookup(String id) async {
    final row = await _db.from('ingredient_prices').select('price_per_base_unit').eq('ingredient_id', id).maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  Future<void> saveIngredientPrice({required String ingredientId, required double purchasePrice, required double purchaseQuantity, required String purchaseUnit}) async {
    if (purchasePrice < 0 || purchaseQuantity <= 0) throw ArgumentError('Проверьте цену и количество');
    await _db.from('ingredient_prices').upsert({
      'ingredient_id': ingredientId, 'purchase_price': purchasePrice,
      'purchase_quantity': purchaseQuantity, 'purchase_unit': purchaseUnit,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'updated_by': _db.auth.currentUser?.id,
    });
  }

  Future<void> saveCard({required String name, required String technology, required String? storageConditions, required String? qualityDescription, required num? yieldQuantity, required String? yieldUnit, required List<Map<String, dynamic>> items, required num? totalCost, required Map<String, dynamic>? nutritionPer100, required String nutritionStatus, required String calculationStatus, required int photoCount}) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) throw Exception('Требуется авторизация');
    final card = await _db.from('recipe_tech_cards').insert({
      'name': name, 'technology': technology, 'storage_conditions': storageConditions, 'quality_description': qualityDescription, 'yield_quantity': yieldQuantity, 'yield_unit': yieldUnit,
      'total_cost': totalCost, 'calories_per_100': nutritionPer100?['calories'],
      'protein_per_100': nutritionPer100?['protein'], 'fat_per_100': nutritionPer100?['fat'],
      'carbs_per_100': nutritionPer100?['carbs'], 'nutrition_status': nutritionStatus,
      'calculation_status': calculationStatus, 'source_photo_count': photoCount, 'created_by': userId,
    }).select('id').single();
    final id = card['id'].toString();
    final rows = items.asMap().entries.map((entry) {
      final item = entry.value;
      return {
        'recipe_id': id, 'ingredient_id': item['ingredient_id'],
        'ingredient_name_snapshot': item['ingredient_name'], 'quantity': item['quantity'], 'net_quantity': item['net_quantity'], 'loss_percent': item['loss_percent'],
        'unit': item['unit'], 'line_cost': item['line_cost'], 'notes': item['notes'],
        'sort_order': entry.key,
      };
    }).toList();
    if (rows.isNotEmpty) await _db.from('recipe_tech_card_items').insert(rows);
  }
}
