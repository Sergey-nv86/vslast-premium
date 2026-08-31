import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../features/bake_schedule/screens/bake_schedule_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/home/widgets/bottom_nav_bar.dart';
import '../features/promotions/screens/promotions_screen.dart';
import '../providers/tab_navigation_controller.dart';
import '../services/product_service.dart';
import 'catalog_screen.dart';
import 'loyalty_screen.dart';

class MainScreen extends StatefulWidget {
  final List<Product> products;

  const MainScreen({super.key, this.products = const []});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late List<Product> _products;
  bool _isLoadingProducts = false;

  @override
  void initState() {
    super.initState();

    _products = List<Product>.of(widget.products);

    debugPrint('===== MAIN INIT =====');
    debugPrint('MAIN INITIAL PRODUCTS: ${_products.length}');

    if (_products.isEmpty) {
      _loadProducts();
    }
  }

  Future<void> _loadProducts() async {
    if (_isLoadingProducts) return;

    setState(() {
      _isLoadingProducts = true;
    });

    try {
      final products = await ProductService.instance.getProducts();

      if (!mounted) return;

      setState(() {
        _products = products;
        _isLoadingProducts = false;
      });

      debugPrint('===== MAIN PRODUCT LOAD SUCCESS =====');
      debugPrint('MAIN PRODUCTS COUNT: ${_products.length}');
      debugPrint(
        'MAIN IN STOCK COUNT: '
        '${_products.where((product) => product.inStock).length}',
      );
    } catch (error, stackTrace) {
      debugPrint('===== MAIN PRODUCT LOAD ERROR =====');
      debugPrint('$error');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _isLoadingProducts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('===== MAIN BUILD =====');
    debugPrint('MAIN PRODUCTS COUNT: ${_products.length}');

    final currentIndex = context.watch<TabNavigationController>().currentIndex;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: IndexedStack(
        index: currentIndex,
        children: [
          HomeScreen(products: _products, isLoading: _isLoadingProducts),
          const CatalogScreen(),
          const BakeScheduleScreen(),
          const PromotionsScreen(),
          const LoyaltyScreen(),
        ],
      ),
      bottomNavigationBar: PremiumBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          context.read<TabNavigationController>().setIndex(index);
        },
      ),
    );
  }
}
