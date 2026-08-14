import '../../../models/product.dart';

enum PromotionPricingType {
  specialPrice,
  discountPercent,
}

extension PromotionPricingTypeX on PromotionPricingType {
  String get label {
    switch (this) {
      case PromotionPricingType.specialPrice:
        return 'Специальная цена';
      case PromotionPricingType.discountPercent:
        return 'Скидка от обычной цены';
    }
  }
}

class PromotionProduct {
  final String productId;
  final int? specialPrice;

  const PromotionProduct({required this.productId, this.specialPrice});

  PromotionProduct copyWith({int? specialPrice}) => PromotionProduct(
        productId: productId,
        specialPrice: specialPrice ?? this.specialPrice,
      );
}

class Promotion {
  final String id;
  final String title;
  final String description;
  final String? bannerAsset;
  final List<int>? bannerBytes;
  final PromotionPricingType pricingType;
  final int? discountPercent;
  final List<PromotionProduct> products;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Promotion({
    required this.id,
    required this.title,
    this.description = '',
    this.bannerAsset,
    this.bannerBytes,
    this.pricingType = PromotionPricingType.discountPercent,
    this.discountPercent,
    this.products = const [],
    this.isAvailable = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Promotion copyWith({
    String? title,
    String? description,
    String? bannerAsset,
    List<int>? bannerBytes,
    PromotionPricingType? pricingType,
    int? discountPercent,
    List<PromotionProduct>? products,
    bool? isAvailable,
  }) {
    return Promotion(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      bannerAsset: bannerAsset ?? this.bannerAsset,
      bannerBytes: bannerBytes ?? this.bannerBytes,
      pricingType: pricingType ?? this.pricingType,
      discountPercent: discountPercent ?? this.discountPercent,
      products: products ?? this.products,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Product? resolveProduct(List<Product> catalog, String productId) {
    for (final product in catalog) {
      if (product.id == productId) return product;
    }
    return null;
  }

  int finalPrice(Product product, PromotionProduct item) {
    if (pricingType == PromotionPricingType.specialPrice && item.specialPrice != null) {
      return item.specialPrice!;
    }
    final discount = discountPercent ?? 0;
    return (product.price * (100 - discount) / 100).round();
  }
}
