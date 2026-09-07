import 'dart:async';
import 'package:flutter/material.dart';
import 'web_notification_helper.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/order_detail_screen.dart';
import '../features/admin/screens/admin_order_detail_screen.dart';
import '../services/admin_orders_service.dart';

/// Firebase Cloud Messaging / Web Push.
///
/// Для PWA:
/// 1. initialize() только подготавливает listeners.
/// 2. requestPermissionAndRegister() вызывается пользователем
///    по нажатию кнопки "Включить уведомления".
/// 3. FCM token сохраняется в Supabase user_devices.
class PushNotificationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  String? _lastPushDiagnostic;

  String? get lastPushDiagnostic => _lastPushDiagnostic;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _webVapidKey =
      'BHd7dgz_EuiKbeZolnTafJNkGp5BnNULNoww95DdFPKD1vhyQjkJ-RYJp9yInHmXO9HZiw2-HqSvUq6-r7JU0Nc';

  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<dynamic>? _serviceWorkerSubscription;

  bool _initialized = false;
  String? _pendingToken;
  String? _pendingOrderId;

  /// Подготовка push-сервиса без автоматического запроса permission.
  Future<void> initialize() async {
    if (_initialized) return;

    _initialized = true;

    try {
      _tokenSubscription = _messaging.onTokenRefresh.listen(
        (token) async {
          debugPrint('FCM: token refreshed');
          _pendingToken = token;
          await _savePendingToken();
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('FCM token refresh error: $error');
          debugPrint('$stackTrace');
        },
      );

      _foregroundSubscription = FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
      );

      // Web/PWA: получаем order_id от Service Worker
      // при нажатии на push в уже открытом PWA.
      if (kIsWeb) {
        _serviceWorkerSubscription = listenServiceWorkerMessages(
          _handleServiceWorkerOrderClick,
        );

        debugPrint('[Push] Service Worker message listener registered');
      }

      // Push tap while the app is in background.
      _messageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        _handleMessageOpenedApp,
      );

      // Push tap that launched the app from a terminated state.
      final initialMessage = await _messaging.getInitialMessage();

      if (initialMessage != null) {
        debugPrint(
          '[Push] Initial message received: data=${initialMessage.data}',
        );
        _queueOrderFromMessage(initialMessage);
      }

      _authSubscription = _supabase.auth.onAuthStateChange.listen((data) async {
        debugPrint('FCM auth event: ${data.event}');

        switch (data.event) {
          case AuthChangeEvent.signedIn:
          case AuthChangeEvent.initialSession:
          case AuthChangeEvent.tokenRefreshed:
            // Сначала сохраняем token, который мог прийти до авторизации.
            await _savePendingToken();

            // Если permission уже был выдан ранее, получаем текущий
            // FCM token после восстановления/создания сессии.
            // Новый системный запрос permission здесь НЕ выполняется.
            await _registerExistingPermissionToken();
            break;

          case AuthChangeEvent.signedOut:
            _pendingToken = null;
            debugPrint('FCM: user signed out');
            break;

          default:
            break;
        }
      });

      debugPrint('FCM service initialized');

      // Если разрешение Push уже было выдано ранее,
      // автоматически регистрируем текущий FCM token.
      // Новый системный запрос permission здесь НЕ выполняется.
      await _registerExistingPermissionToken();
    } catch (error, stackTrace) {
      debugPrint('FCM initialization error: $error');
      debugPrint('$stackTrace');
    }
  }

  /// Регистрирует текущий FCM token, если permission уже выдан.
  ///
  /// Не вызывает системный запрос permission.
  Future<void> _registerExistingPermissionToken() async {
    try {
      final settings = await _messaging.getNotificationSettings();

      final authorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (!authorized) {
        debugPrint(
          'FCM: notification permission not granted, '
          'automatic registration skipped',
        );
        return;
      }

      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint(
          'FCM: no authenticated user, automatic registration skipped',
        );
        return;
      }

      final token = kIsWeb
          ? await _messaging.getToken(
              vapidKey: _webVapidKey,
              serviceWorkerScriptPath: 'firebase-messaging-sw.js',
            )
          : await _messaging.getToken();

      if (token == null || token.isEmpty) {
        debugPrint('FCM: existing permission, but token is null/empty');
        return;
      }

      debugPrint('FCM: existing permission, token received');
      _pendingToken = token;
      await _savePendingToken();
    } catch (error, stackTrace) {
      debugPrint('FCM existing token registration error: $error');
      debugPrint('$stackTrace');
    }
  }

  /// Запрос разрешения и регистрация устройства.
  ///
  /// Для PWA этот метод должен вызываться из пользовательского действия:
  /// например, после нажатия кнопки "Включить уведомления".
  Future<bool> requestPermissionAndRegister() async {
    try {
      if (kIsWeb) {
        return await _registerWebPush();
      }

      return await _registerNativePush();
    } catch (error, stackTrace) {
      debugPrint('FCM permission/register error: $error');
      debugPrint('$stackTrace');
      return false;
    }
  }

  Future<bool> _registerWebPush() async {
    _lastPushDiagnostic = null;

    debugPrint('WEB PUSH DIAGNOSTIC: START');

    try {
      debugPrint('WEB PUSH: requestPermission START');

      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint(
        'WEB PUSH: authorizationStatus=${settings.authorizationStatus}',
      );

      debugPrint('WEB PUSH: alert=${settings.alert}');

      debugPrint('WEB PUSH: badge=${settings.badge}');

      debugPrint('WEB PUSH: sound=${settings.sound}');

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        _lastPushDiagnostic =
            'Разрешение не получено. Статус Firebase: ${settings.authorizationStatus}.';

        debugPrint('WEB PUSH DIAGNOSTIC: $_lastPushDiagnostic');

        return false;
      }

      debugPrint('WEB PUSH: permission AUTHORIZED');
      debugPrint('WEB PUSH: getToken START');

      final token = await _messaging.getToken(
        vapidKey: _webVapidKey,
        serviceWorkerScriptPath: 'firebase-messaging-sw.js',
      );

      if (token == null || token.isEmpty) {
        _lastPushDiagnostic =
            'Разрешение получено, но Firebase не вернул FCM token.';

        debugPrint('WEB PUSH DIAGNOSTIC: $_lastPushDiagnostic');

        return false;
      }

      debugPrint('WEB PUSH: FCM TOKEN RECEIVED');
      debugPrint('FCM WEB TOKEN >>> $token <<<');

      _pendingToken = token;
      await _savePendingToken();

      _lastPushDiagnostic =
          'Уведомления разрешены. FCM token получен и сохранён.';

      debugPrint('WEB PUSH DIAGNOSTIC: $_lastPushDiagnostic');

      debugPrint('WEB PUSH DIAGNOSTIC: END');

      return true;
    } catch (error, stackTrace) {
      _lastPushDiagnostic = 'Ошибка Web Push: $error';

      debugPrint('WEB PUSH DIAGNOSTIC ERROR: $_lastPushDiagnostic');

      debugPrint('$stackTrace');

      return false;
    }
  }

  Future<bool> _registerNativePush() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('FCM native permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      return false;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      final apnsToken = await _waitForApnsToken();

      if (apnsToken == null || apnsToken.isEmpty) {
        debugPrint('FCM: APNs token was not received');
        return false;
      }
    }

    final token = await _messaging.getToken();

    if (token == null || token.isEmpty) {
      debugPrint('FCM native: token is null/empty');
      return false;
    }

    debugPrint('FCM native: token received');

    _pendingToken = token;
    await _savePendingToken();

    return true;
  }

  Future<String?> _waitForApnsToken({
    Duration timeout = const Duration(seconds: 15),
    Duration interval = const Duration(milliseconds: 500),
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      try {
        final token = await _messaging.getAPNSToken();

        if (token != null && token.isNotEmpty) {
          debugPrint('FCM: APNs token available');
          return token;
        }
      } catch (error) {
        debugPrint('FCM: waiting for APNs token: $error');
      }

      await Future<void>.delayed(interval);
    }

    debugPrint('FCM: APNs token timeout after ${timeout.inSeconds}s');

    return null;
  }

  Future<void> _savePendingToken() async {
    final token = _pendingToken;

    if (token == null || token.isEmpty) {
      debugPrint('FCM: no pending token');
      return;
    }

    final user = _supabase.auth.currentUser;

    if (user == null) {
      debugPrint('FCM: no authenticated user, token kept for later');
      return;
    }

    await _saveToken(token);
  }

  Future<void> _saveToken(String token) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      _pendingToken = token;
      debugPrint('FCM SAVE: no authenticated user');
      return;
    }

    final platform = kIsWeb
        ? 'web'
        : defaultTargetPlatform == TargetPlatform.iOS
        ? 'ios'
        : defaultTargetPlatform == TargetPlatform.android
        ? 'android'
        : defaultTargetPlatform.name;

    debugPrint(
      'FCM SAVE: user=${user.id}, platform=$platform, '
      'token_length=${token.length}',
    );

    try {
      final result = await _supabase
          .from('user_devices')
          .upsert({
            'user_id': user.id,
            'fcm_token': token,
            'platform': platform,
            'is_active': true,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }, onConflict: 'user_id,fcm_token')
          .select('id,user_id,platform,is_active,updated_at');

      debugPrint('FCM SAVE: upsert success, rows=${result.length}');

      if (result.isNotEmpty) {
        final row = result.first;
        debugPrint(
          'FCM SAVE: saved id=${row['id']}, '
          'user_id=${row['user_id']}, '
          'platform=${row['platform']}, '
          'is_active=${row['is_active']}, '
          'updated_at=${row['updated_at']}',
        );
      }

      _pendingToken = null;
    } catch (error, stackTrace) {
      debugPrint('FCM token save error: $error');
      debugPrint('$stackTrace');
    }
  }

  /// Обрабатывает push, когда приложение открыто.
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint(
      '[Push] Foreground message: '
      'data=${message.data}, '
      'title=${message.notification?.title}, '
      'body=${message.notification?.body}',
    );

    _queueOrderFromMessage(message);

    if (kIsWeb) {
      try {
        await showForegroundNotification(
          title: message.notification?.title ?? 'Всласть',
          body: message.notification?.body ?? '',
        );
      } catch (error, stackTrace) {
        debugPrint('[Push] Web foreground notification error: $error');
        debugPrint('$stackTrace');
      }
    }
  }

  /// Обрабатывает нажатие push, когда приложение было в фоне.
  void _handleServiceWorkerOrderClick(String orderId) {
    debugPrint('[Push] Service Worker order click: order_id=$orderId');

    if (orderId.isEmpty) {
      return;
    }

    _pendingOrderId = orderId;

    final navigator = navigatorKey.currentState;

    if (navigator == null) {
      debugPrint(
        '[Push] Navigator is not ready for Service Worker '
        'order_id=$orderId. Keeping pending.',
      );
      return;
    }

    debugPrint(
      '[Push] Opening order from Service Worker: '
      'order_id=$orderId',
    );

    unawaited(openPendingOrder());
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('[Push] Message opened app: data=${message.data}');

    _queueOrderFromMessage(message);

    final orderId = message.data['order_id']?.toString();

    if (orderId == null || orderId.isEmpty) {
      debugPrint('[Push] Opened message has no order_id');
      return;
    }

    debugPrint(
      '[Push] Opening order from FCM tap: '
      'order_id=$orderId',
    );

    unawaited(openPendingOrder());
  }

  /// Извлекает order_id из push и сохраняет его до готовности навигации.
  void _queueOrderFromMessage(RemoteMessage message) {
    final orderId = message.data['order_id']?.toString();

    if (orderId == null || orderId.isEmpty) {
      debugPrint('[Push] Message has no order_id: data=${message.data}');
      return;
    }

    _pendingOrderId = orderId;

    debugPrint('[Push] Queued order_id=$orderId');
  }

  void setPendingOrderId(String orderId) {
    final value = orderId.trim();

    if (value.isEmpty) {
      return;
    }

    _pendingOrderId = value;

    debugPrint('[Push] Pending order_id set manually: $value');
  }

  String? consumePendingOrderId() {
    final orderId = _pendingOrderId;

    _pendingOrderId = null;

    if (orderId != null && orderId.isNotEmpty) {
      debugPrint('[Push] Consumed pending order_id=$orderId');
    }

    return orderId;
  }

  /// Открывает отложенный заказ с учётом роли текущего пользователя.
  ///
  /// customer -> клиентский OrderDetailScreen.
  /// staff/admin -> AdminOrderDetailScreen.
  Future<void> openPendingOrder() async {
    final orderId = consumePendingOrderId();

    if (orderId == null || orderId.isEmpty) {
      debugPrint('[Push] No pending order to open');
      return;
    }

    await openOrderById(orderId);
  }

  /// Открывает конкретный заказ.
  Future<void> openOrderById(String orderId) async {
    final normalizedOrderId = orderId.trim();

    if (normalizedOrderId.isEmpty) {
      return;
    }

    final navigator = navigatorKey.currentState;

    if (navigator == null) {
      debugPrint(
        '[Push] Navigator is not ready for '
        'order_id=$normalizedOrderId',
      );

      _pendingOrderId = normalizedOrderId;
      return;
    }

    final user = _supabase.auth.currentUser;

    if (user == null) {
      debugPrint(
        '[Push] No authenticated user for '
        'order_id=$normalizedOrderId',
      );

      _pendingOrderId = normalizedOrderId;
      return;
    }

    try {
      final profileResponse = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      final role =
          profileResponse?['role']?.toString().trim().toLowerCase() ??
          'customer';

      final canAccessAdmin = role != 'customer';

      debugPrint(
        '[Push] Routing order_id=$normalizedOrderId '
        'role=$role admin=$canAccessAdmin',
      );

      if (!canAccessAdmin) {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: normalizedOrderId),
          ),
        );

        return;
      }

      final order = await AdminOrdersService.instance.fetchOrderById(
        normalizedOrderId,
      );

      if (order == null) {
        debugPrint(
          '[Push] Admin order not found: '
          'order_id=$normalizedOrderId',
        );
        return;
      }

      navigator.push(
        MaterialPageRoute(builder: (_) => AdminOrderDetailScreen(order: order)),
      );

      debugPrint(
        '[Push] Admin order opened: '
        'order_id=${order.id} number=${order.number}',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[Push] Error opening order '
        'order_id=$normalizedOrderId: $error',
      );
      debugPrint('$stackTrace');
    }
  }

  /// TEMP: возвращает текущий FCM token для диагностики.
  Future<String?> getCurrentFcmToken() async {
    try {
      if (kIsWeb) {
        return await _messaging.getToken(
          vapidKey: _webVapidKey,
          serviceWorkerScriptPath: 'firebase-messaging-sw.js',
        );
      }

      return await _messaging.getToken();
    } catch (error, stackTrace) {
      debugPrint('FCM getCurrentFcmToken error: $error');
      debugPrint('$stackTrace');
      return null;
    }
  }

  /// Если разрешение Web Push уже выдано, получает текущий FCM token
  /// с VAPID и сохраняет его для авторизованного пользователя.
  Future<bool> registerExistingPermissionToken() async {
    try {
      if (!kIsWeb) {
        return false;
      }

      final settings = await _messaging.getNotificationSettings();

      debugPrint(
        'FCM Web existing permission: ${settings.authorizationStatus}',
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        debugPrint('FCM Web: existing permission is not authorized');
        return false;
      }

      final user = _supabase.auth.currentUser;

      if (user == null) {
        debugPrint('FCM Web: no authenticated user');
        return false;
      }

      final token = await _messaging.getToken(
        vapidKey: _webVapidKey,
        serviceWorkerScriptPath: 'firebase-messaging-sw.js',
      );

      if (token == null || token.isEmpty) {
        debugPrint('FCM Web: existing permission, token is null/empty');
        return false;
      }

      debugPrint('FCM Web: existing permission, token received');

      _pendingToken = token;
      await _savePendingToken();

      return true;
    } catch (error, stackTrace) {
      debugPrint('FCM Web existing registration error: $error');
      debugPrint('$stackTrace');
      return false;
    }
  }

  Future<bool> isNotificationPermissionGranted() async {
    try {
      final settings = await _messaging.getNotificationSettings();

      debugPrint(
        'FCM permission status check: ${settings.authorizationStatus}',
      );

      debugPrint('FCM permission alert: ${settings.alert}');

      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (error, stackTrace) {
      _lastPushDiagnostic = 'Ошибка проверки разрешения: $error';

      debugPrint('FCM permission status error: $error');

      debugPrint('$stackTrace');

      return false;
    }
  }

  Future<void> disableCurrentDevice() async {
    final user = _supabase.auth.currentUser;

    if (user == null) return;

    try {
      final token = await _messaging.getToken(
        vapidKey: kIsWeb ? _webVapidKey : null,
        serviceWorkerScriptPath:
            kIsWeb ? 'firebase-messaging-sw.js' : null,
      );

      if (token == null || token.isEmpty) return;

      await _supabase
          .from('user_devices')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('user_id', user.id)
          .eq('fcm_token', token);

      debugPrint('FCM: current device disabled');
    } catch (error, stackTrace) {
      debugPrint('FCM disable device error: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _messageOpenedSubscription?.cancel();
    await _authSubscription?.cancel();
    await _serviceWorkerSubscription?.cancel();

    _tokenSubscription = null;
    _foregroundSubscription = null;
    _messageOpenedSubscription = null;
    _authSubscription = null;
    _serviceWorkerSubscription = null;

    _pendingToken = null;
    _pendingOrderId = null;
    _initialized = false;
  }
}
