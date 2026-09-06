import 'dart:async';

Future<void> showForegroundNotification({
  required String title,
  required String body,
}) async {}

StreamSubscription<dynamic> listenServiceWorkerMessages(
  void Function(String orderId) onOrderClick,
) {
  return const Stream<dynamic>.empty().listen((_) {});
}
