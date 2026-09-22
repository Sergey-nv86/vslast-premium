import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';

import 'package:web/web.dart' as web;

Future<void> showForegroundNotification({
  required String title,
  required String body,
}) async {
  try {
    final permission = web.Notification.permission;

    if (permission != 'granted') {
      return;
    }

    web.Notification(
      title,
      web.NotificationOptions(body: body, icon: '/icons/Icon-192.png'),
    );
  } catch (_) {
    // Foreground notification is best-effort on Web.
  }
}

/// Слушает сообщения от Firebase Service Worker для навигации после клика.
///
/// Service Worker передаёт полный набор навигационных данных:
/// {
///   type: 'push_navigation',
///   push_type: 'cart_abandoned',
///   order_id: '...',
///   product_id: '...'
/// }
///
/// Важно: приложение не перезапускается при клике по push в уже открытом PWA.
StreamSubscription<web.MessageEvent> listenServiceWorkerPushNavigation(
  void Function(Map<String, String> data) onNavigation,
) {
  final controller = web.window.navigator.serviceWorker;
  final streamController = StreamController<web.MessageEvent>();

  controller.addEventListener(
    'message',
    (web.Event event) {
      streamController.add(event as web.MessageEvent);
    }.toJS,
  );

  return streamController.stream.listen((web.MessageEvent event) {
    try {
      final data = event.data;

      if (data == null) {
        return;
      }

      final dartData = data.dartify();

      if (dartData is! Map) {
        return;
      }

      final type = dartData['type']?.toString() ?? '';
      if (type != 'push_navigation') {
        return;
      }

      final navigation = <String, String>{
        'type': dartData['push_type']?.toString() ?? '',
        'order_id': dartData['order_id']?.toString() ?? '',
        'product_id': dartData['product_id']?.toString() ?? '',
      };

      debugPrint('[Push] Service Worker navigation: $navigation');
      onNavigation(navigation);
    } catch (error, stackTrace) {
      debugPrint('[Push] Service Worker navigation error: $error');
      debugPrint('$stackTrace');
    }
  });
}

/// Слушает старый формат order click.
///
/// Оставлен для обратной совместимости с существующим кодом.
StreamSubscription<web.MessageEvent> listenServiceWorkerMessages(
  void Function(String orderId) onOrderClick,
) {
  return web.window.onMessage.listen((web.MessageEvent event) {
    try {
      final data = event.data;

      if (data == null) {
        return;
      }

      final dartData = data.dartify();

      if (dartData is! Map) {
        return;
      }

      final type = dartData['type']?.toString() ?? '';

      if (type != 'push_order_click') {
        return;
      }

      final orderId = dartData['order_id']?.toString() ?? '';

      if (orderId.isEmpty) {
        return;
      }

      debugPrint('[Push] Service Worker click received: order_id=$orderId');

      onOrderClick(orderId);
    } catch (error, stackTrace) {
      debugPrint('[Push] Service Worker message error: $error');
      debugPrint('$stackTrace');
    }
  });
}
