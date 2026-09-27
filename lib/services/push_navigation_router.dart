import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/tab_navigation_controller.dart';
import '../screens/cart_screen.dart';
import '../features/admin/screens/admin_clients_screen.dart';
import '../features/admin/screens/admin_dashboard_screen.dart';
import '../features/promotions/screens/promotions_screen.dart';
import '../screens/chat_screen.dart';
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
    final threadId = uri.queryParameters['thread_id']?.trim() ?? '';
    final messageId = uri.queryParameters['message_id']?.trim() ?? '';
    final clientId = uri.queryParameters['client_id']?.trim() ?? '';
    final clientUserId = uri.queryParameters['client_user_id']?.trim() ?? '';
    final promotionId = uri.queryParameters['promotion_id']?.trim() ?? '';

    if (type.isEmpty && orderId.isEmpty) return;

    setPendingData({
      'type': type,
      'order_id': orderId,
      'product_id': productId,
      'thread_id': threadId,
      'message_id': messageId,
      'client_id': clientId,
      'client_user_id': clientUserId,
      'promotion_id': promotionId,
    });
  }

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

  Future<bool> handleData(Map<String, String> data) async {
    final type = (data['type'] ?? '').trim().toLowerCase();
    final orderId = (data['order_id'] ?? '').trim();
    final productId = (data['product_id'] ?? '').trim();
    final threadId = (data['thread_id'] ?? '').trim();
    final messageId = (data['message_id'] ?? '').trim();
    final clientId = (data['client_id'] ?? '').trim();
    final clientUserId = (data['client_user_id'] ?? '').trim();
    final promotionId = (data['promotion_id'] ?? '').trim();

    debugPrint(
      '[PushRouter] Handle type=$type order_id=$orderId product_id=$productId',
    );

    // Если push пришёл до готовности Navigator (особенно при запуске PWA
    // по клику на уведомление), не теряем навигацию — оставляем intent
    // в очереди и обрабатываем его после первого кадра.
    if ((type == 'chat_message' || type == 'chat_message_admin') &&
        PushNotificationService.navigatorKey.currentState == null) {
      setPendingData(data);
      return false;
    }

    switch (type) {
      case 'chat_message':
        return _openClientChat(messageId);

      case 'chat_message_admin':
        if (threadId.isEmpty) return false;
        return _openAdminChat(threadId, messageId);

      case 'client_registered_admin':
      case 'client_login_admin':
        return _openAdminClient(
          clientUserId: clientUserId,
          clientId: clientId,
        );
      case 'new_order_admin':
      case 'new_preorder_admin':
      case 'order_created':
      case 'order_confirmed':
      case 'order_status_changed':
      case 'order_ready':
      case 'order_completed':
      case 'order_changed':
      case 'preorder_confirmed':
      case 'order_cancelled':
      case 'pickup_reminder':
        if (orderId.isEmpty) return false;
        return await PushNotificationService.instance.openOrderById(orderId);

      case 'cart_abandoned':
      case 'cart_reminder':
        return _openCart();

      case 'favorite_product_back_in_stock':
      case 'new_product_published':
        if (productId.isNotEmpty) {
          return await _openProduct(productId);
        }
        return _openCatalog();

      case 'crm_bonus_granted':
      case 'bonus_granted':
      case 'bonus_expiring':
      case 'bonus_expiry_warning':
        return _openLoyalty();

      case 'daily_assortment':
      case 'daily_assortment_published':
      case 'daily_assortment_reminder':
      case 'fresh_bakery_published':
        return _openCatalog();

      case 'admin_assortment_reminder':
      case 'admin_assortment_overdue':
        return _openAdminDashboard();

      case 'promotion':
      case 'promotion_published':
        return _openPromotions(promotionId);

      default:
        debugPrint('[PushRouter] Unknown push type: $type');
        return false;
    }
  }

  bool _openClientChat(String messageId) {
    final navigator = PushNotificationService.navigatorKey.currentState;
    if (navigator == null) return false;

    navigator.push(
      MaterialPageRoute(
        builder: (_) => ClientChatScreen(
          targetMessageId: messageId.isEmpty ? null : messageId,
        ),
      ),
    );
    return true;
  }

  bool _openAdminChat(String threadId, String messageId) {
    final navigator = PushNotificationService.navigatorKey.currentState;
    if (navigator == null) return false;

    navigator.push(
      MaterialPageRoute(
        builder: (_) => AdminChatScreen(
          threadId: threadId,
          title: 'Чат с клиентом',
          targetMessageId: messageId.isEmpty ? null : messageId,
        ),
      ),
    );
    return true;
  }

  Future<bool> _openAdminClient({
    required String clientUserId,
    required String clientId,
  }) async {
    final navigator = PushNotificationService.navigatorKey.currentState;
    if (navigator == null) return false;

    var resolvedUserId = clientUserId.trim();
    if (resolvedUserId.isEmpty && clientId.trim().isNotEmpty) {
      try {
        final row = await Supabase.instance.client
            .from('client_accounts')
            .select('legacy_user_id')
            .eq('client_id', clientId.trim())
            .maybeSingle();
        resolvedUserId = row?['legacy_user_id']?.toString().trim() ?? '';
      } catch (error) {
        debugPrint('[PushRouter] Client lookup error: $error');
      }
    }

    if (resolvedUserId.isEmpty) {
      debugPrint('[PushRouter] Client notification has no client user id');
      return false;
    }

    navigator.push(
      MaterialPageRoute(
        builder: (_) => AdminClientDetailScreen(clientId: resolvedUserId),
      ),
    );
    return true;
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

  bool _openAdminDashboard() {
    final navigator = PushNotificationService.navigatorKey.currentState;
    if (navigator == null) return false;

    navigator.push(
      MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
    );
    debugPrint('[PushRouter] Admin dashboard opened');
    return true;
  }

  bool _openPromotions(String promotionId) {
    final navigator = PushNotificationService.navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('[PushRouter] Navigator is not ready for promotions');
      return false;
    }

    if (promotionId.isEmpty) {
      final context = PushNotificationService.navigatorKey.currentContext;
      if (context == null) return false;
      context.read<TabNavigationController>().goToPromotions();
      debugPrint('[PushRouter] Promotions selected');
      return true;
    }

    navigator.push(
      MaterialPageRoute(
        builder: (_) => PromotionsScreen(targetPromotionId: promotionId),
      ),
    );
    debugPrint('[PushRouter] Promotion opened: $promotionId');
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
