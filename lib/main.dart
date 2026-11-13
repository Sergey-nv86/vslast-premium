import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase_config.dart';
import 'features/admin/screens/recipe_preview_login_screen.dart';
import 'features/splash/screens/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/location_provider.dart';
import 'providers/tab_navigation_controller.dart';
import 'theme/premium_design_system.dart';
import 'services/push_notification_service.dart';
import 'services/push_navigation_router.dart';
import 'services/web_notification_helper.dart';
import 'firebase_options.dart';

const bool isRecipePreview = bool.fromEnvironment('RECIPE_PREVIEW', defaultValue: false);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!isRecipePreview) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  if (!isRecipePreview) {
    await PushNotificationService.instance.initialize();
  }

  if (!isRecipePreview && kIsWeb) {
    // Для background/terminated push Service Worker открывает приложение
    // с push_type/order_id/product_id в query string.
    PushNavigationRouter.instance.setPendingFromUri(Uri.base);

    // Для уже открытого PWA Service Worker передаёт событие напрямую,
    // без перезагрузки приложения.
    listenServiceWorkerPushNavigation((data) {
      // Не открываем экран напрямую: сначала ставим navigation intent
      // в очередь, чтобы клик не терялся, если Navigator ещё не готов.
      PushNavigationRouter.instance.setPendingData(data);
      unawaited(PushNavigationRouter.instance.handlePending());
    });
  }

  runApp(const VslastPremiumApp());

  // Обрабатываем push, который открыл PWA в новой вкладке/окне.
  // К этому моменту MaterialApp уже получил возможность построить Navigator.
  if (!isRecipePreview) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(PushNavigationRouter.instance.handlePending());
    });
  }
}

class VslastPremiumApp extends StatelessWidget {
  const VslastPremiumApp({super.key});

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: PushNotificationService.navigatorKey,
      title: 'Всласть Premium',
      theme: VslastDesignSystem.theme,
      home: isRecipePreview ? const RecipePreviewLoginScreen() : const SplashScreen(),
    );

    if (isRecipePreview) return app;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TabNavigationController()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: app,
    );
  }
}
