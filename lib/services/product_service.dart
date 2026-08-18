import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';

class ProductService {
  ProductService._();

  static final ProductService instance = ProductService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Product>> getProducts() async {
    final rows = await _supabase
        .from('products')
        .select('''
          id,
          name,
          price,
          image_url,
          badge,
          in_stock,
          is_weighed,
          weight_label,
          description,
          calories_per_100g,
          protein_per_100g,
          fat_per_100g,
          carbs_per_100g,
          composition,
          rating,
          reviews_count,
          category_id,
          categories (
            name,
            slug
          )
        ''')
        .eq('is_active', true)
        .order('created_at');

    return (rows as List)
        .map((row) => _fromSupabase(Map<String, dynamic>.from(row)))
        .toList();
  }

  Product _fromSupabase(Map<String, dynamic> row) {
    final categoryData = row['categories'];

    final Map<String, dynamic> category =
        categoryData is Map
            ? Map<String, dynamic>.from(categoryData)
            : <String, dynamic>{};

    return Product(
      id: row['id'].toString(),
      name: row['name']?.toString() ?? '',
      price: _toInt(row['price']),
      imageUrl: row['image_url']?.toString() ?? '',
      category: _parseCategory(category['slug']?.toString()),
      badge: _parseBadge(row['badge']?.toString()),
      inStock: row['in_stock'] == true,
      isWeighed: row['is_weighed'] == true,
      weightLabel: row['weight_label']?.toString() ?? '1 шт',
      description: row['description']?.toString(),
      caloriesPer100g: _toNullableInt(row['calories_per_100g']),
      proteinPer100g: _toNullableDouble(row['protein_per_100g']),
      fatPer100g: _toNullableDouble(row['fat_per_100g']),
      carbsPer100g: _toNullableDouble(row['carbs_per_100g']),
      composition: row['composition']?.toString(),
      rating: _toNullableDouble(row['rating']),
      reviewsCount: _toNullableInt(row['reviews_count']),
    );
  }

  ProductCategory _parseCategory(String? slug) {
    switch (slug) {
      case 'bread':
        return ProductCategory.bread;
      case 'pastry':
        return ProductCategory.pastry;
      case 'cakes':
        return ProductCategory.cakes;
      case 'desserts':
        return ProductCategory.desserts;
      default:
        return ProductCategory.bread;
    }
  }

  ProductBadge? _parseBadge(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'hit':
        return ProductBadge.hit;
      case 'new':
      case 'new_item':
      case 'newitem':
        return ProductBadge.newItem;
      case 'promo':
      case 'promotion':
        return ProductBadge.promo;
      default:
        return null;
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  double? _toNullableDouble(dynamic value) {
    if (value == null) return null;
    return double.tryParse(value.toString());
  }
}
