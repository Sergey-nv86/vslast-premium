import 'package:flutter/material.dart';

import '../features/home/screens/home_screen.dart';
import 'catalog_screen.dart';
import 'loyalty_screen.dart';
import 'favorite_screen.dart';
import 'cart_screen.dart';

import '../features/home/widgets/bottom_nav_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  late final List<Widget> pages = [
    const HomeScreen(),
    const CatalogScreen(),
    const LoyaltyScreen(),
    const FavoriteScreen(),
    const CartScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),

      body: IndexedStack(index: currentIndex, children: pages),

      bottomNavigationBar: PremiumBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
    );
  }
}
