import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/product.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/product_service.dart';
import '../../../services/push_navigation_router.dart';
import '../../../screens/auth_screen.dart';
import '../../../screens/main_screen.dart';
import '../../admin/screens/app_mode_selection_screen.dart';
import '../../../core/build_info.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Stopwatch _splashTimer;

  @override
  void initState() {
    super.initState();

    _splashTimer = Stopwatch()..start();

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

    // Start independent initialization work together. The previous flow
    // waited for auth, then products, then an unconditional 3-second delay.
    final authFuture = auth.initialize();
    final productsFuture = ProductService.instance
        .getCatalogProducts()
        .catchError((error, stackTrace) {
      debugPrint('SPLASH PRODUCT PRELOAD ERROR: $error');
      debugPrint('$stackTrace');
      return <Product>[];
    });

    List<Product> products = const [];

    await authFuture;

    // Admin/login screens do not need product data, but sharing the request
    // with Main/Catalog keeps customer startup fast and avoids duplicate work.
    if (auth.isLoggedIn && !auth.canAccessAdmin) {
      try {
        products = await productsFuture;
      } catch (_) {
        // The preload future already logs and converts failures to an empty
        // list, allowing auth/navigation to continue normally.
      }
    }

    if (!mounted) return;

    // Keep the splash on screen for a consistent branded presentation.
    // The minimum total display time is 3.5 seconds, including initialization.
    const minimumSplashDuration = Duration(milliseconds: 3500);
    final remaining = minimumSplashDuration - _splashTimer.elapsed;

    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }

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

    // Push-навигация выполняется только после завершения перехода со Splash,
    // чтобы не конкурировать с pushReplacement и не возвращать пользователя
    // на последний открытый экран.
    final pushDelay = auth.isLoggedIn
        ? const Duration(milliseconds: 450)
        : const Duration(milliseconds: 250);

    await Future<void>.delayed(pushDelay);

    if (!mounted) return;

    final handled = await PushNavigationRouter.instance.handlePending();

    debugPrint('[PushRouter] Splash pending navigation handled=$handled');
  }

  @override
  void dispose() {
    _splashTimer.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _opacity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/splash.jpg', fit: BoxFit.cover),
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Center(
                child: Text(
                  buildLabel,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
