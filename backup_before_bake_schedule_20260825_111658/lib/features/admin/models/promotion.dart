import '../../../models/product.dart';

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
  final int? specialPrice;

  const PromotionProduct({
    required this.productId,
    this.quantity = 1,
    this.specialPrice,
  });

  PromotionProduct copyWith({int? quantity, int? specialPrice}) =>
      PromotionProduct(
        productId: productId,
        quantity: quantity ?? this.quantity,
        specialPrice: specialPrice ?? this.specialPrice,
      );
}

class Promotion {
  final String id;
  final String title;
  final String description;
  final String? bannerAsset;
  final List<int>? bannerBytes;
  final PromotionType type;
  final int? discountPercent;
  final int? offerPrice;
  final List<PromotionProduct> products;
  final bool isAvailable;
  final DateTime? startDate;
  final DateTime? endDate;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Promotion({
    required this.id,
    required this.title,
    this.description = '',
    this.bannerAsset,
    this.bannerBytes,
    this.type = PromotionType.collection,
    this.discountPercent,
    this.offerPrice,
    this.products = const [],
    this.isAvailable = false,
    this.startDate,
    this.endDate,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Promotion copyWith({
    String? title,
    String? description,
    Object? bannerAsset = _keep,
    Object? bannerBytes = _keep,
    PromotionType? type,
    Object? discountPercent = _keep,
    Object? offerPrice = _keep,
    List<PromotionProduct>? products,
    bool? isAvailable,
    Object? startDate = _keep,
    Object? endDate = _keep,
    int? sortOrder,
  }) => Promotion(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    bannerAsset: identical(bannerAsset, _keep)
        ? this.bannerAsset
        : bannerAsset as String?,
    bannerBytes: identical(bannerBytes, _keep)
        ? this.bannerBytes
        : bannerBytes as List<int>?,
    type: type ?? this.type,
    discountPercent: identical(discountPercent, _keep)
        ? this.discountPercent
        : discountPercent as int?,
    offerPrice: identical(offerPrice, _keep)
        ? this.offerPrice
        : offerPrice as int?,
    products: products ?? this.products,
    isAvailable: isAvailable ?? this.isAvailable,
    startDate: identical(startDate, _keep)
        ? this.startDate
        : startDate as DateTime?,
    endDate: identical(endDate, _keep) ? this.endDate : endDate as DateTime?,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );

  static const Object _keep = Object();

  Product? resolveProduct(List<Product> catalog, String productId) {
    for (final product in catalog) {
      if (product.id == productId) return product;
    }
    return null;
  }

  int finalPrice(Product product, PromotionProduct item) {
    switch (type) {
      case PromotionType.collection:
        return product.price;
      case PromotionType.specialPrice:
        return item.specialPrice ?? product.price;
      case PromotionType.discount:
        final discount = discountPercent ?? 0;
        return (product.price * (100 - discount) / 100).round();
      case PromotionType.bundle:
        return offerPrice ?? product.price;
    }
  }

  bool get isScheduledOut {
    final now = DateTime.now();
    return (startDate != null && now.isBefore(startDate!)) ||
        (endDate != null && now.isAfter(endDate!));
  }
}
