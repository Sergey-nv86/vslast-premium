import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/home/screens/home_screen.dart';
import '../features/promotions/screens/promotions_screen.dart';
import '../providers/tab_navigation_controller.dart';
import 'catalog_screen.dart';
import 'loyalty_screen.dart';
import 'schedule_screen.dart';
import '../features/home/widgets/bottom_nav_bar.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentIndex = context.watch<TabNavigationController>().currentIndex;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F1),
      body: IndexedStack(
        index: currentIndex,
        children: const [
          HomeScreen(),
          CatalogScreen(),
          LoyaltyScreen(),
          PromotionsScreen(),
          ScheduleScreen(),
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
