import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/cart_provider.dart';
import '../../../screens/cart_screen.dart';
import '../../../widgets/cart_summary_bar.dart';
import '../widgets/home_header.dart';
import '../widgets/popular_section.dart';
import '../widgets/showcase_section.dart';

/// Главная.
///
/// Экран НЕ прокручивается целиком — прокручивается только сама витрина
/// "Сегодня на витрине" (см. ShowcaseSection), у неё собственный
/// вертикальный скролл внутри Expanded. Высота этой области ВСЕГДА
/// постоянна и не зависит от корзины — ни Padding, ни доля Expanded
/// никогда не меняются из-за появления/исчезновения плашки корзины.
/// Именно смена этой высоты раньше вызывала "прыжки"/"пустую часть
/// экрана" при добавлении товара во время скролла.
///
/// Плашка "Перейти в корзину" (CartSummaryBar) — не часть обычного потока
/// Column, а отдельный слой поверх экрана (Positioned внутри Stack),
/// прижатый к низу и наложенный на "Популярное". Она не участвует в
/// расчёте размеров остального контента вообще, поэтому ничего не сжимает.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openCart(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return SafeArea(
      top: false,
      bottom: false,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HomeHeader(),
              const SizedBox(height: 12),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: ShowcaseSection(),
                ),
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: PopularSection(),
              ),
              const SizedBox(height: 8),
            ],
          ),
          if (!cart.isEmpty)
            Positioned(
              left: 18,
              right: 18,
              bottom: 8,
              child: CartSummaryBar(
                itemsCount: cart.totalCount,
                totalSum: cart.totalSum,
                onTap: () => _openCart(context),
              ),
            ),
        ],
      ),
    );
  }
}
