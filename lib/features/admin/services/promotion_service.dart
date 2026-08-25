import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/promotion.dart';

class PromotionService {
  PromotionService._();

  static final PromotionService instance = PromotionService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _promotionColumns = '''
    id,
    title,
    description,
    banner_asset,
    type,
    discount_percent,
    offer_price,
    is_available,
    start_date,
    end_date,
    sort_order,
    created_at,
    updated_at
  ''';

  Future<List<Promotion>> getPromotions() async {
    final rows = await _supabase
        .from('promotions')
        .select(_promotionColumns)
        .order('sort_order')
        .order('created_at', ascending: false);

    if (rows.isEmpty) {
      return [];
    }

    final ids = rows.map((row) => row['id'] as String).toList();

    final productRows = await _supabase
        .from('promotion_products')
        .select('promotion_id, product_id, quantity, special_price')
        .inFilter('promotion_id', ids);

    final productsByPromotion = <String, List<PromotionProduct>>{};

    for (final row in productRows) {
      final promotionId = row['promotion_id'] as String;

      productsByPromotion
          .putIfAbsent(promotionId, () => [])
          .add(
            PromotionProduct(
              productId: row['product_id'] as String,
              quantity: (row['quantity'] as num?)?.toInt() ?? 1,
              specialPrice: (row['special_price'] as num?)?.toInt(),
            ),
          );
    }

    return rows.map((row) {
      final id = row['id'] as String;

      return Promotion(
        id: id,
        title: row['title'] as String? ?? '',
        description: row['description'] as String? ?? '',
        bannerAsset: row['banner_asset'] as String?,
        type: _parseType(row['type'] as String?),
        discountPercent: (row['discount_percent'] as num?)?.toInt(),
        offerPrice: (row['offer_price'] as num?)?.toInt(),
        products: productsByPromotion[id] ?? const [],
        isAvailable: row['is_available'] as bool? ?? false,
        startDate: _parseDate(row['start_date']),
        endDate: _parseDate(row['end_date']),
        sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
        createdAt: _parseDate(row['created_at']) ?? DateTime.now(),
        updatedAt: _parseDate(row['updated_at']) ?? DateTime.now(),
      );
    }).toList();
  }

  Future<Promotion?> getPromotion(String id) async {
    final rows = await _supabase
        .from('promotions')
        .select(_promotionColumns)
        .eq('id', id)
        .limit(1);

    if (rows.isEmpty) {
      return null;
    }

    final promotionRows = await _supabase
        .from('promotion_products')
        .select('promotion_id, product_id, quantity, special_price')
        .eq('promotion_id', id);

    final row = rows.first;

    return Promotion(
      id: row['id'] as String,
      title: row['title'] as String? ?? '',
      description: row['description'] as String? ?? '',
      bannerAsset: row['banner_asset'] as String?,
      type: _parseType(row['type'] as String?),
      discountPercent: (row['discount_percent'] as num?)?.toInt(),
      offerPrice: (row['offer_price'] as num?)?.toInt(),
      products: promotionRows.map((item) {
        return PromotionProduct(
          productId: item['product_id'] as String,
          quantity: (item['quantity'] as num?)?.toInt() ?? 1,
          specialPrice: (item['special_price'] as num?)?.toInt(),
        );
      }).toList(),
      isAvailable: row['is_available'] as bool? ?? false,
      startDate: _parseDate(row['start_date']),
      endDate: _parseDate(row['end_date']),
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(row['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(row['updated_at']) ?? DateTime.now(),
    );
  }

  Future<Promotion> createPromotion(Promotion promotion) async {
    var data = await _supabase
        .from('promotions')
        .insert({
          'title': promotion.title,
          'description': promotion.description,
          'banner_asset': promotion.bannerAsset,
          'type': _typeToString(promotion.type),
          'discount_percent': promotion.discountPercent,
          'offer_price': promotion.offerPrice,
          'is_available': promotion.isAvailable,
          'start_date': promotion.startDate?.toIso8601String(),
          'end_date': promotion.endDate?.toIso8601String(),
          'sort_order': promotion.sortOrder,
        })
        .select(_promotionColumns)
        .single();

    final bannerUrl = await _uploadBanner(
      promotionId: data['id'] as String,
      bytes: promotion.bannerBytes,
      existingUrl: promotion.bannerAsset,
    );

    if (bannerUrl != promotion.bannerAsset) {
      data = await _supabase
          .from('promotions')
          .update({'banner_asset': bannerUrl})
          .eq('id', data['id'])
          .select(_promotionColumns)
          .single();
    }

    return _replaceProducts(data, promotion.products);
  }

  Future<Promotion> updatePromotion(Promotion promotion) async {
    var data = await _supabase
        .from('promotions')
        .update({
          'title': promotion.title,
          'description': promotion.description,
          'banner_asset': promotion.bannerAsset,
          'type': _typeToString(promotion.type),
          'discount_percent': promotion.discountPercent,
          'offer_price': promotion.offerPrice,
          'is_available': promotion.isAvailable,
          'start_date': promotion.startDate?.toIso8601String(),
          'end_date': promotion.endDate?.toIso8601String(),
          'sort_order': promotion.sortOrder,
        })
        .eq('id', promotion.id)
        .select(_promotionColumns)
        .single();

    final bannerUrl = await _uploadBanner(
      promotionId: promotion.id,
      bytes: promotion.bannerBytes,
      existingUrl: promotion.bannerAsset,
    );

    if (bannerUrl != promotion.bannerAsset) {
      data = await _supabase
          .from('promotions')
          .update({'banner_asset': bannerUrl})
          .eq('id', promotion.id)
          .select(_promotionColumns)
          .single();
    }

    await _supabase
        .from('promotion_products')
        .delete()
        .eq('promotion_id', promotion.id);

    return _replaceProducts(data, promotion.products);
  }

  Future<void> deletePromotion(String id) async {
    // Сначала удаляем связанные товары, чтобы удаление не зависело
    // от настройки ON DELETE CASCADE в Supabase.
    await _supabase.from('promotion_products').delete().eq('promotion_id', id);

    await _supabase.from('promotions').delete().eq('id', id);

    try {
      await _deleteBanner(id);
    } catch (_) {
      // Удаление записи акции уже выполнено.
      // Ошибка очистки Storage не должна ломать удаление акции.
    }
  }

  Future<void> setAvailability(String id, bool value) async {
    await _supabase
        .from('promotions')
        .update({'is_available': value})
        .eq('id', id);
  }

  Future<Promotion> duplicatePromotion(Promotion promotion) async {
    // Копия акции не должна ссылаться на баннер оригинала.
    // Сначала создаём новую акцию без banner_asset.
    var data = await _supabase
        .from('promotions')
        .insert({
          'title': '${promotion.title} — копия',
          'description': promotion.description,
          'banner_asset': null,
          'type': _typeToString(promotion.type),
          'discount_percent': promotion.discountPercent,
          'offer_price': promotion.offerPrice,
          'is_available': false,
          'start_date': promotion.startDate?.toIso8601String(),
          'end_date': promotion.endDate?.toIso8601String(),
          'sort_order': 0,
        })
        .select(_promotionColumns)
        .single();

    final newPromotionId = data['id'] as String;

    // Если у оригинала есть баннер, создаём его отдельную копию
    // в Storage для новой акции.
    if (promotion.bannerAsset != null &&
        promotion.bannerAsset!.trim().isNotEmpty) {
      final sourcePath = 'promotions/${promotion.id}/banner.jpg';
      final targetPath = 'promotions/$newPromotionId/banner.jpg';

      final sourceBytes = await _supabase.storage
          .from('product-images')
          .download(sourcePath);

      await _supabase.storage
          .from('product-images')
          .uploadBinary(
            targetPath,
            sourceBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final bannerUrl = _supabase.storage
          .from('product-images')
          .getPublicUrl(targetPath);

      data = await _supabase
          .from('promotions')
          .update({'banner_asset': bannerUrl})
          .eq('id', newPromotionId)
          .select(_promotionColumns)
          .single();
    }

    return _replaceProducts(data, promotion.products);
  }

  Future<String?> _uploadBanner({
    required String promotionId,
    required List<int>? bytes,
    String? existingUrl,
  }) async {
    if (bytes == null || bytes.isEmpty) {
      return existingUrl;
    }

    final path = 'promotions/$promotionId/banner.jpg';

    await _supabase.storage
        .from('product-images')
        .uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    return _supabase.storage.from('product-images').getPublicUrl(path);
  }

  Future<void> _deleteBanner(String promotionId) async {
    await _supabase.storage.from('product-images').remove([
      'promotions/$promotionId/banner.jpg',
    ]);
  }

  Future<Promotion> _replaceProducts(
    Map<String, dynamic> row,
    List<PromotionProduct> products,
  ) async {
    final promotionId = row['id'] as String;

    if (products.isNotEmpty) {
      await _supabase
          .from('promotion_products')
          .insert(
            products.map((product) {
              return {
                'promotion_id': promotionId,
                'product_id': product.productId,
                'quantity': product.quantity,
                'special_price': product.specialPrice,
              };
            }).toList(),
          );
    }

    return Promotion(
      id: promotionId,
      title: row['title'] as String? ?? '',
      description: row['description'] as String? ?? '',
      bannerAsset: row['banner_asset'] as String?,
      type: _parseType(row['type'] as String?),
      discountPercent: (row['discount_percent'] as num?)?.toInt(),
      offerPrice: (row['offer_price'] as num?)?.toInt(),
      products: products,
      isAvailable: row['is_available'] as bool? ?? false,
      startDate: _parseDate(row['start_date']),
      endDate: _parseDate(row['end_date']),
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(row['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(row['updated_at']) ?? DateTime.now(),
    );
  }

  PromotionType _parseType(String? value) {
    switch (value) {
      case 'discount':
        return PromotionType.discount;
      case 'specialPrice':
        return PromotionType.specialPrice;
      case 'bundle':
        return PromotionType.bundle;
      case 'collection':
      default:
        return PromotionType.collection;
    }
  }

  String _typeToString(PromotionType type) {
    switch (type) {
      case PromotionType.collection:
        return 'collection';
      case PromotionType.discount:
        return 'discount';
      case PromotionType.specialPrice:
        return 'specialPrice';
      case PromotionType.bundle:
        return 'bundle';
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value.toString());
  }
}
