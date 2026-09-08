import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/promotions/screens/promotions_screen.dart';
import '../providers/tab_navigation_controller.dart';
import '../screens/cart_screen.dart';
import '../screens/loyalty_screen.dart';
import '../screens/product_detail_screen.dart';
import '../services/product_service.dart';
import 'push_notification_service.dart';

/// Единственная точка маршрутизации действий после нажатия push.
///
/// Web Service Worker передаёт type + идентификаторы события.
/// Для запущенного PWA событие обрабатывается напрямую, а для
/// terminated/background запуска оно сохраняется в URL и обрабатывается
/// после Splash.
class PushNavigationRouter {
  PushNavigationRouter._();

  static final PushNavigationRouter instance = PushNavigationRouter._();

  Map<String, String>? _pendingData;
  bool _handling = false;

  void setPendingData(Map<String, String> data) {
    final normalized = <String, String>{};
    for (final entry in data.entries) {
      final value = entry.value.trim();
      if (value.isNotEmpty) {
        normalized[entry.key] = value;
      }
    }

    if (normalized.isEmpty) return;

    _pendingData = normalized;
    debugPrint('[PushRouter] Pending data: $_pendingData');
  }

  void setPendingFromUri(Uri uri) {
    final type = uri.queryParameters['push_type']?.trim() ?? '';
    final orderId = uri.queryParameters['order_id']?.trim() ?? '';
    final productId = uri.queryParameters['product_id']?.trim() ?? '';

    if (type.isEmpty && orderId.isEmpty) return;

    setPendingData({
      'type': type,
      'order_id': orderId,
      'product_id': productId,
    });
  }

  /// Обрабатывает pending push после того, как основное приложение создано.
  Future<bool> handlePending() async {
    final data = _pendingData;
    if (data == null || data.isEmpty) return false;

    if (_handling) return false;
    _handling = true;

    try {
      final handled = await handleData(data);
      if (handled && identical(_pendingData, data)) {
        _pendingData = null;
      }
      return handled;
    } finally {
      _handling = false;
    }
  }

  /// Обрабатывает событие, пришедшее от Service Worker.
  Future<bool> handleData(Map<String, String> data) async {
    final type = (data['type'] ?? '').trim().toLowerCase();
    final orderId = (data['order_id'] ?? '').trim();
    final productId = (data['product_id'] ?? '').trim();

    debugPrint(
      '[PushRouter] Handle type=$type order_id=$orderId product_id=$productId',
    );

    switch (type) {
      // Заказы всегда открываются непосредственно на конкретном заказе.
      case 'new_order_admin':
      case 'order_created':
      case 'order_confirmed':
      case 'order_status_changed':
      case 'order_ready':
      case 'order_completed':
      case 'pickup_reminder':
        if (orderId.isEmpty) return false;
        return await PushNotificationService.instance.openOrderById(orderId);

      // Оставленная корзина — сразу в корзину, без попытки открыть
      // последний экран или несуществующий пункт меню.
      case 'cart_abandoned':
      case 'cart_reminder':
        return _openCart();

      // Товар снова в наличии / новый товар — открываем карточку товара,
      // если backend передал product_id. Иначе безопасно переводим в каталог.
      case 'favorite_product_back_in_stock':
      case 'new_product_published':
        if (productId.isNotEmpty) {
          return await _openProduct(productId);
        }
        return _openCatalog();

      // CRM/лояльность.
      case 'crm_bonus_granted':
      case 'bonus_granted':
      case 'bonus_expiring':
      case 'bonus_expiry_warning':
        return _openLoyalty();

      // Ассортимент и промо.
      case 'daily_assortment':
      case 'daily_assortment_reminder':
        return _openCatalog();

      case 'promotion':
      case 'promotion_published':
        return _openPromotions();

      default:
        debugPrint('[PushRouter] Unknown push type: $type');
        return false;
    }
  }

  bool _openCart() {
    final navigator = PushNotificationService.navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('[PushRouter] Navigator is not ready for cart');
      return false;
    }

    navigator.push(
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );

    debugPrint('[PushRouter] Cart opened');
    return true;
  }

  bool _openCatalog() {
    final context = PushNotificationService.navigatorKey.currentContext;
    if (context == null) {
      debugPrint('[PushRouter] Context is not ready for catalog');
      return false;
    }

    context.read<TabNavigationController>().goToCatalog();
    debugPrint('[PushRouter] Catalog selected');
    return true;
  }

  bool _openPromotions() {
    final context = PushNotificationService.navigatorKey.currentContext;
    if (context == null) {
      debugPrint('[PushRouter] Context is not ready for promotions');
      return false;
    }

    context.read<TabNavigationController>().goToPromotions();
    debugPrint('[PushRouter] Promotions selected');
    return true;
  }

  bool _openLoyalty() {
    final context = PushNotificationService.navigatorKey.currentContext;
    if (context == null) {
      debugPrint('[PushRouter] Context is not ready for loyalty');
      return false;
    }

    context.read<TabNavigationController>().goToLoyalty();
    debugPrint('[PushRouter] Loyalty selected');
    return true;
  }

  Future<bool> _openProduct(String productId) async {
    final navigator = PushNotificationService.navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('[PushRouter] Navigator is not ready for product');
      return false;
    }

    try {
      final product = await ProductService.instance.getProduct(productId);
      if (product == null) {
        debugPrint('[PushRouter] Product not found: $productId');
        return _openCatalog();
      }

      navigator.push(
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      );

      debugPrint('[PushRouter] Product opened: $productId');
      return true;
    } catch (error, stackTrace) {
      debugPrint('[PushRouter] Product open error: $error');
      debugPrint('$stackTrace');
      return false;
    }
  }
}
