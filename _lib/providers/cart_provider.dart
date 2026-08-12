import 'package:flutter/foundation.dart';
import '../models/product.dart';

/// Управляет содержимым корзины. Подключается через
/// ChangeNotifierProvider на уровне приложения (см. README_INTEGRATION.md),
/// чтобы количество товаров было доступно и на экране «Каталог»,
/// и в бейдже нижней панели навигации, и на экране «Корзина».
class CartProvider extends ChangeNotifier {
  final Map<Product, int> _items = {};

  Map<Product, int> get items => Map.unmodifiable(_items);

  int quantityOf(Product product) => _items[product] ?? 0;

  /// Суммарное количество единиц товара в корзине (для бейджа "Корзина").
  int get totalCount => _items.values.fold(0, (sum, qty) => sum + qty);

  /// Суммарная стоимость корзины в рублях.
  int get totalSum =>
      _items.entries.fold(0, (sum, e) => sum + e.key.price * e.value);

  bool get isEmpty => _items.isEmpty;

  void add(Product product) {
    _items[product] = quantityOf(product) + 1;
    notifyListeners();
  }

  void increment(Product product) => add(product);

  void decrement(Product product) {
    final current = quantityOf(product);
    if (current <= 1) {
      _items.remove(product);
    } else {
      _items[product] = current - 1;
    }
    notifyListeners();
  }

  /// Полностью убирает товар из корзины независимо от количества
  /// (кнопка-корзина на экране «Оформление заказа»).
  void remove(Product product) {
    if (_items.remove(product) != null) {
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
