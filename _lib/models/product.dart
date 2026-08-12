/// Категории каталога — соответствуют вкладкам фильтра.
enum ProductCategory { bread, pastry, cakes, desserts }

extension ProductCategoryX on ProductCategory {
  String get label {
    switch (this) {
      case ProductCategory.bread:
        return 'Хлеб';
      case ProductCategory.pastry:
        return 'Выпечка';
      case ProductCategory.cakes:
        return 'Торты';
      case ProductCategory.desserts:
        return 'Десерты';
    }
  }
}

/// Бейдж в левом верхнем углу карточки товара.
enum ProductBadge { hit, newItem, promo }

extension ProductBadgeX on ProductBadge {
  String get label {
    switch (this) {
      case ProductBadge.hit:
        return 'ХИТ';
      case ProductBadge.newItem:
        return 'НОВИНКА';
      case ProductBadge.promo:
        return 'АКЦИЯ';
    }
  }
}

class Product {
  final String id;
  final String name;
  final int price;
  final String imageUrl;
  final ProductCategory category;
  final ProductBadge? badge;

  /// Если false — вместо цены и кнопки "+" показывается кнопка "Предзаказ".
  final bool inStock;

  /// Продаётся на вес (а не поштучно/по фиксированному объёму). На экране
  /// «Предзаказ» именно этот признак (вместе с категорией "торты") решает,
  /// показывать ли шаг выбора веса.
  final bool isWeighed;

  // --- Поля для экрана «Карточка товара» ---
  // Все опциональны: если не заданы, экран аккуратно скрывает
  // соответствующий блок, а не падает и не рисует пустоту.

  final double? rating;
  final int? reviewsCount;

  /// Например "1 кг", "1 шт", "350 г". По умолчанию "1 шт".
  final String weightLabel;

  final String? description;

  final int? caloriesPer100g;
  final double? proteinPer100g;
  final double? fatPer100g;
  final double? carbsPer100g;
  final String? composition;

  /// Фото для галереи на карточке товара. Если не задано — галерея
  /// состоит из одного [imageUrl] (см. геттер [gallery]).
  final List<String>? galleryImages;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.badge,
    this.inStock = true,
    this.isWeighed = false,
    this.rating,
    this.reviewsCount,
    this.weightLabel = '1 шт',
    this.description,
    this.caloriesPer100g,
    this.proteinPer100g,
    this.fatPer100g,
    this.carbsPer100g,
    this.composition,
    this.galleryImages,
  });

  List<String> get gallery =>
      (galleryImages == null || galleryImages!.isEmpty) ? [imageUrl] : galleryImages!;

  bool get hasNutritionInfo =>
      caloriesPer100g != null ||
      proteinPer100g != null ||
      fatPer100g != null ||
      carbsPer100g != null;

  /// Экран «Предзаказ» показывает шаг выбора веса только для тортов или
  /// весового товара — для остального (эклер, булочка и т.п.) вес не
  /// выбирается, и шаг просто не рисуется.
  bool get showsWeightSelector => category == ProductCategory.cakes || isWeighed;

  @override
  bool operator ==(Object other) => other is Product && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
