import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/product.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/product_service.dart';
import '../../../screens/auth_screen.dart';
import '../../../screens/main_screen.dart';
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
