import 'dart:async';
import 'package:flutter/material.dart';
import 'web_notification_helper.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/order_detail_screen.dart';

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
        _serviceWorkerSubscription =
            listenServiceWorkerMessages(_handleServiceWorkerOrderClick);

        debugPrint(
          '[Push] Service Worker message listener registered',
        );
      }

      // Push tap while the app is in background.
      _messageOpenedSubscription =
          FirebaseMessaging.onMessageOpenedApp.listen(
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

      final token = await _messaging.getToken();

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
    debugPrint('FCM Web: requesting notification permission');

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('FCM Web permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('FCM Web: notification permission not granted');
      return false;
    }

    final token = await _messaging.getToken(vapidKey: _webVapidKey);

    if (token == null || token.isEmpty) {
      debugPrint('FCM Web: token is null/empty');
      return false;
    }

    debugPrint('FCM Web: token received');
    debugPrint('FCM WEB TOKEN >>> $token <<<');

    _pendingToken = token;
    await _savePendingToken();

    return true;
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

      debugPrint(
        'FCM SAVE: upsert success, rows=${result.length}',
      );

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
    debugPrint(
      '[Push] Service Worker order click: order_id=$orderId',
    );

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
      '[Push] Opening order immediately from Service Worker: '
      'order_id=$orderId',
    );

    navigator.push(
      MaterialPageRoute(
        builder: (_) => _orderDetailScreen(orderId),
      ),
    );

    _pendingOrderId = null;
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint(
      '[Push] Message opened app: data=${message.data}',
    );

    _queueOrderFromMessage(message);

    final orderId = message.data['order_id']?.toString();

    if (orderId == null || orderId.isEmpty) {
      debugPrint('[Push] Opened message has no order_id');
      return;
    }

    _pendingOrderId = orderId;

    final navigator = navigatorKey.currentState;

    if (navigator == null) {
      debugPrint(
        '[Push] Navigator is not ready, '
        'order_id=$orderId remains pending',
      );
      return;
    }

    debugPrint(
      '[Push] Navigating directly to order_id=$orderId',
    );

    navigator.push(
      MaterialPageRoute(
        builder: (_) => _orderDetailScreen(orderId),
      ),
    );

    _pendingOrderId = null;
  }

  /// Извлекает order_id из push и сохраняет его до готовности навигации.
  void _queueOrderFromMessage(RemoteMessage message) {
    final orderId = message.data['order_id']?.toString();

    if (orderId == null || orderId.isEmpty) {
      debugPrint(
        '[Push] Message has no order_id: data=${message.data}',
      );
      return;
    }

    _pendingOrderId = orderId;

    debugPrint(
      '[Push] Queued order_id=$orderId',
    );
  }

  void setPendingOrderId(String orderId) {
    final value = orderId.trim();

    if (value.isEmpty) {
      return;
    }

    _pendingOrderId = value;

    debugPrint(
      '[Push] Pending order_id set manually: $value',
    );
  }

  String? consumePendingOrderId() {
    final orderId = _pendingOrderId;

    _pendingOrderId = null;

    if (orderId != null && orderId.isNotEmpty) {
      debugPrint(
        '[Push] Consumed pending order_id=$orderId',
      );
    }

    return orderId;
  }

  Widget _orderDetailScreen(String orderId) {
    return OrderDetailScreen(
      orderId: orderId,
    );
  }

  /// TEMP: возвращает текущий FCM token для диагностики.
  Future<String?> getCurrentFcmToken() async {
    try {
      if (kIsWeb) {
        return await _messaging.getToken(vapidKey: _webVapidKey);
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
        debugPrint(
          'FCM Web: existing permission is not authorized',
        );
        return false;
      }

      final user = _supabase.auth.currentUser;

      if (user == null) {
        debugPrint(
          'FCM Web: no authenticated user',
        );
        return false;
      }

      final token = await _messaging.getToken(
        vapidKey: _webVapidKey,
      );

      if (token == null || token.isEmpty) {
        debugPrint(
          'FCM Web: existing permission, token is null/empty',
        );
        return false;
      }

      debugPrint(
        'FCM Web: existing permission, token received',
      );

      _pendingToken = token;
      await _savePendingToken();

      return true;
    } catch (error, stackTrace) {
      debugPrint(
        'FCM Web existing registration error: $error',
      );
      debugPrint('$stackTrace');
      return false;
    }
  }

  Future<bool> isNotificationPermissionGranted() async {
    try {
      final settings = await _messaging.getNotificationSettings();

      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (error) {
      debugPrint('FCM permission status error: $error');
      return false;
    }
  }

  Future<void> disableCurrentDevice() async {
    final user = _supabase.auth.currentUser;

    if (user == null) return;

    try {
      final token = await _messaging.getToken(
        vapidKey: kIsWeb ? _webVapidKey : null,
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
