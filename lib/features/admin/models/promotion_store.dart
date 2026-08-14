import 'promotion.dart';

class PromotionStore {
  PromotionStore._();

  static final PromotionStore instance = PromotionStore._();

  final List<Promotion> _items = [
    Promotion(
      id: 'promo-school',
      title: 'Скоро в школу',
      description: 'Подборка товаров к 1 сентября.',
      bannerAsset: 'assets/images/banner.png',
      type: PromotionType.collection,
      products: const [
        PromotionProduct(productId: 'napoleon_cake'),
        PromotionProduct(productId: 'eclair_chocolate'),
      ],
      isAvailable: true,
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 9, 2),
      sortOrder: 1,
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
    ),
    Promotion(
      id: 'promo-ciabatta',
      title: 'Неделя чиабатты',
      description: 'Скидка на чиабатту всю эту неделю.',
      bannerAsset: 'assets/images/hero_banner.jpg',
      type: PromotionType.discount,
      discountPercent: 15,
      products: const [
        PromotionProduct(productId: 'ciabatta'),
      ],
      isAvailable: true,
      startDate: DateTime(2026, 8, 10),
      endDate: DateTime(2026, 8, 17),
      sortOrder: 2,
      createdAt: DateTime(2026, 8, 10),
      updatedAt: DateTime(2026, 8, 10),
    ),
    Promotion(
      id: 'promo-breakfast',
      title: 'Завтрак «Всласть»',
      description: 'Кофе и выпечка по специальной цене.',
      bannerAsset: 'assets/images/hero_banner.jpg',
      type: PromotionType.bundle,
      offerPrice: 599,
      products: const [
        PromotionProduct(productId: 'ciabatta'),
        PromotionProduct(productId: 'croissant'),
      ],
      isAvailable: false,
      sortOrder: 3,
      createdAt: DateTime(2026, 8, 12),
      updatedAt: DateTime(2026, 8, 12),
    ),
  ];

  List<Promotion> get items => List.unmodifiable(
        [..._items]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
      );

  List<Promotion> get available => List.unmodifiable(
        items.where((item) => item.isAvailable && !item.isScheduledOut),
      );

  void add(Promotion item) => _items.insert(0, item);

  void update(Promotion item) {
    final index = _items.indexWhere((p) => p.id == item.id);
    if (index >= 0) _items[index] = item;
  }

  void remove(String id) => _items.removeWhere((p) => p.id == id);

  void setAvailability(String id, bool value) {
    final index = _items.indexWhere((p) => p.id == id);
    if (index >= 0) _items[index] = _items[index].copyWith(isAvailable: value);
  }
}
