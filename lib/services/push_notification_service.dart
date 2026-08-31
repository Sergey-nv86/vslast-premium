import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Firebase Cloud Messaging.
///
/// Отвечает за регистрацию устройства и получение Push.
/// Бизнес-логика заказов здесь не находится.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance =
      PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static const String _webVapidKey =
      'BHd7dgz_EuiKbeZolnTafJNkGp5BnNULNoww95DdFPKD1vhyQjkJ-RYJp9yInHmXO9HZiw2-HqSvUq6-r7JU0Nc';

  final SupabaseClient _supabase = Supabase.instance.client;

  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<AuthState>? _authSubscription;

  bool _initialized = false;

  String? _pendingToken;

  Future<void> initialize() async {
    if (_initialized) return;

    _initialized = true;

    try {
      if (!kIsWeb) {
        final settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

        debugPrint(
          'FCM permission: ${settings.authorizationStatus}',
        );
      }

      _tokenSubscription = _messaging.onTokenRefresh.listen(
        (token) async {
          debugPrint('FCM token refreshed');
          _pendingToken = token;
          await _savePendingToken();
        },
      );

      _foregroundSubscription = FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
      );

      _authSubscription =
          _supabase.auth.onAuthStateChange.listen((data) async {
        debugPrint('FCM auth event: ${data.event}');

        switch (data.event) {
          case AuthChangeEvent.signedIn:
          case AuthChangeEvent.initialSession:
          case AuthChangeEvent.tokenRefreshed:
            await _savePendingToken();
            break;

          case AuthChangeEvent.signedOut:
            _pendingToken = null;
            debugPrint('FCM: user signed out');
            break;

          default:
            break;
        }
      });

      // On Apple platforms APNs token is not guaranteed to be
      // available immediately after requestPermission(). Firebase
      // requires the APNs token before calling getToken().
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS)) {
        final apnsToken = await _waitForApnsToken();

        if (apnsToken == null || apnsToken.isEmpty) {
          debugPrint(
            'FCM: APNs token was not received, skipping FCM getToken()',
          );
          return;
        }

        debugPrint('FCM: APNs token received');
      }

      final token = await _messaging.getToken(
        vapidKey: kIsWeb ? _webVapidKey : null,
      );

      if (token != null && token.isNotEmpty) {
        debugPrint('FCM token received');
        _pendingToken = token;

        await _savePendingToken();
      } else {
        debugPrint('FCM: token is null');
      }

      debugPrint('FCM service initialized');
    } catch (error, stackTrace) {
      debugPrint('FCM initialization error: $error');
      debugPrint('$stackTrace');
    }
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
      debugPrint(
        'FCM: no authenticated user, token kept for later',
      );
      return;
    }

    await _saveToken(token);
  }

  Future<void> _saveToken(String token) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      _pendingToken = token;

      debugPrint(
        'FCM: no authenticated user, token kept for later',
      );

      return;
    }

    final platform = kIsWeb
        ? 'web'
        : defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : defaultTargetPlatform == TargetPlatform.android
                ? 'android'
                : defaultTargetPlatform.name;

    try {
      await _supabase.from('user_devices').upsert(
        {
          'user_id': user.id,
          'fcm_token': token,
          'platform': platform,
          'is_active': true,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id,fcm_token',
      );

      _pendingToken = null;

      debugPrint(
        'FCM token saved: platform=$platform',
      );
    } catch (error, stackTrace) {
      debugPrint('FCM token save error: $error');
      debugPrint('$stackTrace');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint(
      'FCM foreground message: '
      'title=${message.notification?.title}, '
      'body=${message.notification?.body}, '
      'data=${message.data}',
    );
  }

  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _authSubscription?.cancel();

    _tokenSubscription = null;
    _foregroundSubscription = null;
    _authSubscription = null;

    _pendingToken = null;
    _initialized = false;
  }
}
