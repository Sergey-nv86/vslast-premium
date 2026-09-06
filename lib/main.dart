import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase_config.dart';
import 'core/build_info.dart';
import 'features/splash/screens/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/location_provider.dart';
import 'providers/tab_navigation_controller.dart';
import 'theme/premium_design_system.dart';
import 'services/push_notification_service.dart';
import 'firebase_options.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  await PushNotificationService.instance.initialize();

  // Web/PWA push click opens the app with ?order_id=UUID.
  // Put it into the same pending-navigation mechanism used by FCM.
  if (kIsWeb) {
    final orderId = Uri.base.queryParameters['order_id'];

    if (orderId != null && orderId.trim().isNotEmpty) {
      debugPrint(
        '[Push] Web pending order_id=$orderId',
      );

      PushNotificationService.instance.setPendingOrderId(
        orderId.trim(),
      );
    }
  }

  runApp(const VslastPremiumApp());
}

class VslastPremiumApp extends StatelessWidget {
  const VslastPremiumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TabNavigationController()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: PushNotificationService.navigatorKey,
        title: 'Всласть Premium',
        theme: VslastDesignSystem.theme,
        home: const SplashScreen(),
        builder: (context, child) {
          return BuildInfoBanner(
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}


/// Краткая диагностическая информация о версии PWA.
///
/// Показывается только при запуске Web/PWA и автоматически
/// исчезает через несколько секунд.
class BuildInfoBanner extends StatefulWidget {
  const BuildInfoBanner({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<BuildInfoBanner> createState() => _BuildInfoBannerState();
}

class _BuildInfoBannerState extends State<BuildInfoBanner> {
  bool _visible = true;

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      _visible = false;
      return;
    }

    Future<void>.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;

      setState(() {
        _visible = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        if (_visible && kIsWeb)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: IgnorePointer(
              child: SafeArea(
                child: Center(
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black.withValues(alpha: 0.82),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Всласть Premium',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Сборка: $buildLabel',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Build ID: $buildId',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
