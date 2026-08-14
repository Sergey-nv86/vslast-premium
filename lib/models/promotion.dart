enum PromotionType { collection, discount, specialPrice, bundle }

extension PromotionTypeX on PromotionType {
  String get label {
    switch (this) {
      case PromotionType.collection:
        return 'Подборка';
      case PromotionType.discount:
        return 'Скидка';
      case PromotionType.specialPrice:
        return 'Спеццена';
      case PromotionType.bundle:
        return 'Набор / комбо';
    }
  }
}

class PromotionProduct {
  final String productId;
  final int quantity;
  final double? specialPrice;

  const PromotionProduct({
    required this.productId,
    this.quantity = 1,
    this.specialPrice,
  });

  PromotionProduct copyWith({
    String? productId,
    int? quantity,
    double? specialPrice,
  }) {
    return PromotionProduct(
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      specialPrice: specialPrice ?? this.specialPrice,
    );
  }
}

class Promotion {
  final String id;
  final String title;
  final String description;
  final String bannerAsset;
  final PromotionType type;
  final List<PromotionProduct> products;
  final double? discountPercent;
  final double? offerPrice;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isAvailable;
  final int sortOrder;

  const Promotion({
    required this.id,
    required this.title,
    this.description = '',
    required this.bannerAsset,
    required this.type,
    this.products = const [],
    this.discountPercent,
    this.offerPrice,
    this.startDate,
    this.endDate,
    this.isAvailable = true,
    this.sortOrder = 0,
  });

  Promotion copyWith({
    String? id,
    String? title,
    String? description,
    String? bannerAsset,
    PromotionType? type,
    List<PromotionProduct>? products,
    double? discountPercent,
    double? offerPrice,
    DateTime? startDate,
    DateTime? endDate,
    bool? isAvailable,
    int? sortOrder,
  }) {
    return Promotion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      bannerAsset: bannerAsset ?? this.bannerAsset,
      type: type ?? this.type,
      products: products ?? this.products,
      discountPercent: discountPercent ?? this.discountPercent,
      offerPrice: offerPrice ?? this.offerPrice,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isAvailable: isAvailable ?? this.isAvailable,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
