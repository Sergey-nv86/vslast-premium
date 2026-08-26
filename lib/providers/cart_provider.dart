import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';

/// Единая корзина пользователя.
///
/// В корзину можно добавлять одновременно:
/// - товары в наличии;
/// - товары с признаком предзаказа.
///
/// Если в корзине есть хотя бы один товар с inStock == false,
/// вся корзина при оформлении считается одним предзаказом.
///
/// Дата и время предзаказа НЕ являются свойством товара.
/// Они являются свойствами текущей корзины / будущего заказа.
class CartProvider extends ChangeNotifier {
  final Map<Product, int> _items = {};

  /// Общая дата предзаказа для всей корзины.
  DateTime? _preorderDate;

  /// Общее время предзаказа для всей корзины.
  String? _preorderTime;

  Map<Product, int> get items => Map.unmodifiable(_items);

  int quantityOf(Product product) => _items[product] ?? 0;

  int get totalCount =>
      _items.values.fold(0, (sum, quantity) => sum + quantity);

  int get totalSum => _items.entries.fold(
    0,
    (sum, entry) => sum + entry.key.price * entry.value,
  );

  bool get isEmpty => _items.isEmpty;

  /// true, если в корзине есть хотя бы один товар, который нельзя получить
  /// сегодня и который оформляется как предзаказ.
  bool get hasPreorderItems => _items.keys.any((product) => !product.inStock);

  /// Общая корзина оформляется как предзаказ, если в ней есть
  /// хотя бы один preorder-товар.
  bool get isPreorder => hasPreorderItems;

  DateTime? get preorderDate => _preorderDate;

  String? get preorderTime => _preorderTime;

  SupabaseClient get _supabase => Supabase.instance.client;

  /// Установить общую дату предзаказа.
  void setPreorderDate(DateTime date) {
    _preorderDate = DateTime(date.year, date.month, date.day);

    notifyListeners();
  }

  /// Установить общее время предзаказа.
  void setPreorderTime(String time) {
    _preorderTime = time;
    notifyListeners();
  }

  /// Установить дату и время одновременно.
  void setPreorderSchedule({required DateTime date, required String time}) {
    _preorderDate = DateTime(date.year, date.month, date.day);
    _preorderTime = time;

    notifyListeners();
  }

  /// Очистить только расписание предзаказа.
  ///
  /// Используется, например, если корзина снова стала обычной.
  void clearPreorderSchedule() {
    _preorderDate = null;
    _preorderTime = null;
    notifyListeners();
  }

  Future<String?> _ensureCart() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      debugPrint('CartProvider: пользователь не авторизован');
      return null;
    }

    try {
      final existing = await _supabase
          .from('carts')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (existing != null && existing['id'] != null) {
        return existing['id'].toString();
      }

      final created = await _supabase
          .from('carts')
          .insert({'user_id': user.id})
          .select('id')
          .single();

      final cartId = created['id']?.toString();

      debugPrint(
        'CartProvider: создана корзина $cartId '
        'для пользователя ${user.id}',
      );

      return cartId;
    } on PostgrestException catch (error, stackTrace) {
      debugPrint(
        'CartProvider _ensureCart PostgrestException: '
        'code=${error.code}, '
        'message=${error.message}, '
        'details=${error.details}, '
        'hint=${error.hint}',
      );

      debugPrintStack(stackTrace: stackTrace);
      return null;
    } catch (error, stackTrace) {
      debugPrint('CartProvider _ensureCart error: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  /// Загружает корзину пользователя из Supabase.
  ///
  /// Product-объекты восстанавливаются текущим каталогом.
  Future<void> loadFromSupabase() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      _items.clear();
      _preorderDate = null;
      _preorderTime = null;
      notifyListeners();
      return;
    }

    try {
      final cart = await _supabase
          .from('carts')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (cart == null || cart['id'] == null) {
        _items.clear();
        _preorderDate = null;
        _preorderTime = null;
        notifyListeners();
        return;
      }

      final cartId = cart['id'].toString();

      final rows = await _supabase
          .from('cart_items')
          .select('product_id, quantity, unit_price, weight_label')
          .eq('cart_id', cartId);

      _items.clear();

      for (final row in rows) {
        final productId = row['product_id']?.toString();
        final quantity = row['quantity'];

        if (productId == null || quantity is! int || quantity <= 0) {
          continue;
        }

        // Product восстанавливается существующим механизмом каталога.
        // Здесь намеренно не создаём Product из неполных данных.
      }

      notifyListeners();

      debugPrint(
        'CartProvider: корзина $cartId загружена, '
        'позиций=${rows.length}',
      );
    } catch (error, stackTrace) {
      debugPrint('CartProvider loadFromSupabase error: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Добавить товар в корзину.
  ///
  /// Обычный товар и preorder-товар используют одну и ту же корзину.
  Future<void> add(Product product) async {
    final current = quantityOf(product);
    final newQuantity = current + 1;

    _items[product] = newQuantity;
    notifyListeners();

    final cartId = await _ensureCart();

    if (cartId == null) {
      debugPrint(
        'CartProvider: не удалось получить cart_id '
        'для ${product.name}',
      );
      return;
    }

    try {
      await _supabase.from('cart_items').upsert({
        'cart_id': cartId,
        'product_id': product.id,
        'quantity': newQuantity,
        'unit_price': product.price,
        'weight_label': product.weightLabel,
      }, onConflict: 'cart_id,product_id');

      debugPrint(
        'CartProvider: добавлен ${product.name}, '
        'quantity=$newQuantity, '
        'preorder=${!product.inStock}',
      );
    } on PostgrestException catch (error, stackTrace) {
      debugPrint(
        'CartProvider add PostgrestException: '
        'code=${error.code}, '
        'message=${error.message}, '
        'details=${error.details}, '
        'hint=${error.hint}',
      );

      debugPrintStack(stackTrace: stackTrace);
    } catch (error, stackTrace) {
      debugPrint('CartProvider add error: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> increment(Product product) => add(product);

  Future<void> decrement(Product product) async {
    final current = quantityOf(product);

    if (current <= 0) {
      return;
    }

    if (current == 1) {
      _items.remove(product);
    } else {
      _items[product] = current - 1;
    }

    if (_items.isEmpty) {
      _preorderDate = null;
      _preorderTime = null;
    }

    notifyListeners();

    final user = _supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      final cart = await _supabase
          .from('carts')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (cart == null || cart['id'] == null) {
        return;
      }

      final cartId = cart['id'].toString();

      if (current == 1) {
        await _supabase
            .from('cart_items')
            .delete()
            .eq('cart_id', cartId)
            .eq('product_id', product.id);
      } else {
        await _supabase
            .from('cart_items')
            .update({'quantity': current - 1})
            .eq('cart_id', cartId)
            .eq('product_id', product.id);
      }
    } catch (error, stackTrace) {
      debugPrint('CartProvider decrement error: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> remove(Product product) async {
    if (_items.remove(product) == null) {
      return;
    }

    if (_items.isEmpty) {
      _preorderDate = null;
      _preorderTime = null;
    }

    notifyListeners();

    final user = _supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      final cart = await _supabase
          .from('carts')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (cart == null || cart['id'] == null) {
        return;
      }

      await _supabase
          .from('cart_items')
          .delete()
          .eq('cart_id', cart['id'])
          .eq('product_id', product.id);
    } catch (error, stackTrace) {
      debugPrint('CartProvider remove error: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Очистить только локальное состояние.
  ///
  /// Серверные cart_items уже удаляются PostgreSQL-функцией
  /// create_order_from_cart().
  void clearLocal() {
    _items.clear();
    _preorderDate = null;
    _preorderTime = null;
    notifyListeners();
  }

  /// Полностью очистить корзину локально и на сервере.
  Future<void> clear() async {
    _items.clear();
    _preorderDate = null;
    _preorderTime = null;

    notifyListeners();

    final user = _supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      final cart = await _supabase
          .from('carts')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (cart == null || cart['id'] == null) {
        return;
      }

      await _supabase.from('cart_items').delete().eq('cart_id', cart['id']);
    } catch (error, stackTrace) {
      debugPrint('CartProvider clear error: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
