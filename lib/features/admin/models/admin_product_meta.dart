import '../../../models/product.dart';

/// Запись в истории изменения цены товара.
class PriceHistoryEntry {
  final DateTime date;
  final int price;
  final String author;

  const PriceHistoryEntry({
    required this.date,
    required this.price,
    required this.author,
  });
}

/// Административные поля товара, которых нет в общей модели [Product] —
/// она общая с клиентским приложением, и заводить в ней артикулы, склад,
/// себестоимость и т.п. было бы неправильно (это данные ТОЛЬКО для админки).
///
/// Хранится отдельно, привязано к Product.id — по той же логике, что и
/// переключатель "в наличии" на экране списка товаров: это demo-состояние
/// уровня админ-панели, а не изменение общего каталога.
class AdminProductMeta {
  final String article;
  final String subcategory;

  /// "Активен" / "Скрыт" — видимость товара в админке. Отличается от
  /// showInCatalog: скрытый в админке товар не должен даже мелькать в
  /// выдаче на витрине, а showInCatalog — более тонкий флаг показа в
  /// каталоге при том, что товар в принципе активен.
  final bool active;

  final String unit;
  final int stockQuantity;
  final int minStock;
  final bool orderable;
  final bool showInCatalog;
  final List<PriceHistoryEntry> priceHistory;

  final String techCardCode;
  final String yieldWeight;
  final int costPrice;

  final int favoritesCount;
  final int inCartCount;
  final int ordersCount;
  final int postponedCount;

  const AdminProductMeta({
    this.article = '',
    this.subcategory = '',
    this.active = true,
    this.unit = 'За штуку',
    this.stockQuantity = 0,
    this.minStock = 0,
    this.orderable = true,
    this.showInCatalog = true,
    this.priceHistory = const [],
    this.techCardCode = '',
    this.yieldWeight = '',
    this.costPrice = 0,
    this.favoritesCount = 0,
    this.inCartCount = 0,
    this.ordersCount = 0,
    this.postponedCount = 0,
  });

  AdminProductMeta copyWith({
    String? article,
    String? subcategory,
    bool? active,
    String? unit,
    int? stockQuantity,
    int? minStock,
    bool? orderable,
    bool? showInCatalog,
    List<PriceHistoryEntry>? priceHistory,
    String? techCardCode,
    String? yieldWeight,
    int? costPrice,
  }) {
    return AdminProductMeta(
      article: article ?? this.article,
      subcategory: subcategory ?? this.subcategory,
      active: active ?? this.active,
      unit: unit ?? this.unit,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minStock: minStock ?? this.minStock,
      orderable: orderable ?? this.orderable,
      showInCatalog: showInCatalog ?? this.showInCatalog,
      priceHistory: priceHistory ?? this.priceHistory,
      techCardCode: techCardCode ?? this.techCardCode,
      yieldWeight: yieldWeight ?? this.yieldWeight,
      costPrice: costPrice ?? this.costPrice,
      favoritesCount: favoritesCount,
      inCartCount: inCartCount,
      ordersCount: ordersCount,
      postponedCount: postponedCount,
    );
  }

  /// Демо-заполнение для уже существующих mock-товаров, чтобы вкладки
  /// "Продажа"/"Производство"/"Статистика" не были пустыми при первом
  /// открытии реального (не только что добавленного) товара.
  /// [index] используется только для артикула, чтобы они не повторялись.
  factory AdminProductMeta.demoSeed(Product product, int index) {
    final seed = product.id.hashCode.abs();
    final basePrice = product.price;
    return AdminProductMeta(
      article: '10${(index + 1).toString().padLeft(2, '0')}',
      subcategory: product.category.label,
      active: true,
      unit: product.isWeighed ? 'За кг' : 'За штуку',
      stockQuantity: 12 + (seed % 40),
      minStock: 5,
      orderable: product.inStock,
      showInCatalog: true,
      priceHistory: [
        PriceHistoryEntry(
          date: DateTime.now().subtract(const Duration(days: 1)),
          price: basePrice,
          author: 'Сергей',
        ),
        PriceHistoryEntry(
          date: DateTime.now().subtract(const Duration(days: 40)),
          price: (basePrice * 0.93).round(),
          author: 'Сергей',
        ),
        PriceHistoryEntry(
          date: DateTime.now().subtract(const Duration(days: 90)),
          price: (basePrice * 0.85).round(),
          author: 'Сергей',
        ),
      ],
      techCardCode:
          'ТТК-${product.category.name.toUpperCase()}-${(index + 1).toString().padLeft(3, '0')}',
      yieldWeight: product.weightLabel,
      costPrice: (basePrice * 0.35).round(),
      favoritesCount: 20 + (seed % 120),
      inCartCount: 5 + (seed % 60),
      ordersCount: 2 + (seed % 40),
      postponedCount: product.inStock ? 0 : 3 + (seed % 25),
    );
  }

  /// Пустые метаданные для только что создаваемого товара — статистике
  /// взяться неоткуда, история цены и склад заполняются администратором.
  factory AdminProductMeta.blank() => const AdminProductMeta();
}
