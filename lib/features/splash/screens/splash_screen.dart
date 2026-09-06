import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/product.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/product_service.dart';
import '../../../services/push_notification_service.dart';
import '../../../screens/auth_screen.dart';
import '../../../screens/main_screen.dart';
import '../../../screens/order_detail_screen.dart';
import '../../admin/screens/app_mode_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initialize();
      }
    });
  }

  Future<void> _initialize() async {
    final auth = context.read<AuthProvider>();

    await auth.initialize();

    List<Product> products = const [];

    // Загружаем товары во время Splash, чтобы Главная открывалась
    // уже с готовыми данными.
    try {
      products = await ProductService.instance.getProducts();
      debugPrint('SPLASH PRODUCT PRELOAD SUCCESS: ${products.length}');
    } catch (error, stackTrace) {
      debugPrint('SPLASH PRODUCT PRELOAD ERROR: $error');
      debugPrint('$stackTrace');
    }

    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    await _controller.reverse();

    if (!mounted) return;

    Widget destination;

    if (!auth.isLoggedIn) {
      destination = const AuthScreen(initialMode: AuthMode.login);
    } else if (auth.canAccessAdmin) {
      destination = const AppModeSelectionScreen();
    } else {
      debugPrint('===== SPLASH -> MAIN =====');
      debugPrint('SPLASH PRODUCTS TO MAIN: ${products.length}');
      for (final product in products) {
        debugPrint(
          'MAIN PRODUCT: '
          'name=${product.name} '
          'inStock=${product.inStock} '
          'category=${product.category}',
        );
      }

      destination = MainScreen(products: products);
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => destination));

    // Если приложение было открыто нажатием на push о заказе,
    // открываем именно этот заказ после завершения Splash.
    final pendingOrderId =
        PushNotificationService.instance.consumePendingOrderId();

    if (pendingOrderId != null && pendingOrderId.isNotEmpty) {
      debugPrint(
        '[Push] Splash -> pending order navigation: '
        'order_id=$pendingOrderId',
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final navigator =
            PushNotificationService.navigatorKey.currentState;

        if (navigator == null) {
          debugPrint(
            '[Push] Navigator is not ready for order_id=$pendingOrderId',
          );

          // Navigator может появиться только после следующего кадра.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;

            final retryNavigator =
                PushNotificationService.navigatorKey.currentState;

            if (retryNavigator == null) {
              debugPrint(
                '[Push] Navigator still not ready for '
                'order_id=$pendingOrderId',
              );
              return;
            }

            debugPrint(
              '[Push] Retrying navigation to order_id=$pendingOrderId',
            );

            retryNavigator.push(
              MaterialPageRoute(
                builder: (_) => OrderDetailScreen(
                  orderId: pendingOrderId,
                ),
              ),
            );
          });

          return;
        }

        debugPrint(
          '[Push] Opening OrderDetailScreen: '
          'order_id=$pendingOrderId',
        );

        navigator.push(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(
              orderId: pendingOrderId,
            ),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _opacity,
        child: SizedBox.expand(
          child: Image.asset('assets/images/splash.jpg', fit: BoxFit.cover),
        ),
      ),
    );
  }
}
