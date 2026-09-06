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
      web.NotificationOptions(
        body: body,
        icon: '/icons/Icon-192.png',
      ),
    );
  } catch (_) {
    // Foreground notification is best-effort on Web.
  }
}

/// Слушает сообщения от Firebase Service Worker.
///
/// Для уже открытого PWA Service Worker передаёт:
/// {
///   type: 'push_order_click',
///   order_id: '...'
/// }
///
/// Важно: приложение не перезапускается.
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

      debugPrint(
        '[Push] Service Worker click received: order_id=$orderId',
      );

      onOrderClick(orderId);
    } catch (error, stackTrace) {
      debugPrint(
        '[Push] Service Worker message error: $error',
      );
      debugPrint('$stackTrace');
    }
  });
}
