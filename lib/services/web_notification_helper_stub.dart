import 'dart:async';

Future<void> showForegroundNotification({
  required String title,
  required String body,
}) async {}

StreamSubscription<dynamic> listenServiceWorkerPushNavigation(
  void Function(Map<String, String> data) onNavigation,
) {
  return const Stream<dynamic>.empty().listen((_) {});
}

StreamSubscription<dynamic> listenServiceWorkerMessages(
  void Function(String orderId) onOrderClick,
) {
  return const Stream<dynamic>.empty().listen((_) {});
}
