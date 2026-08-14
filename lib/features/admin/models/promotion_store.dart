import 'promotion.dart';

class PromotionStore {
  PromotionStore._();

  static final PromotionStore instance = PromotionStore._();

  final List<Promotion> _items = [
    Promotion(
      id: 'promo-school',
      title: 'Скоро в школу',
      description: 'Подготовились к 1 сентября вместе со «Всласть».',
      bannerAsset: 'assets/images/banner.png',
      pricingType: PromotionPricingType.discountPercent,
      discountPercent: 10,
      products: const [
        PromotionProduct(productId: 'napoleon_cake'),
        PromotionProduct(productId: 'eclair_chocolate'),
      ],
      isAvailable: true,
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
    ),
    Promotion(
      id: 'promo-ciabatta',
      title: 'Неделя чиабатты',
      description: 'Скидка на чиабатту всю эту неделю.',
      bannerAsset: 'assets/images/hero_banner.jpg',
      pricingType: PromotionPricingType.discountPercent,
      discountPercent: 15,
      products: const [
        PromotionProduct(productId: 'ciabatta'),
      ],
      isAvailable: true,
      createdAt: DateTime(2026, 8, 10),
      updatedAt: DateTime(2026, 8, 10),
    ),
  ];

  List<Promotion> get items => List.unmodifiable(_items);

  List<Promotion> get available =>
      List.unmodifiable(_items.where((item) => item.isAvailable));

  void add(Promotion item) => _items.insert(0, item);

  void update(Promotion item) {
    final index = _items.indexWhere((p) => p.id == item.id);
    if (index >= 0) _items[index] = item;
  }

  void remove(String id) => _items.removeWhere((p) => p.id == id);

  void setAvailability(String id, bool value) {
    final index = _items.indexWhere((p) => p.id == id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(isAvailable: value);
    }
  }
}
