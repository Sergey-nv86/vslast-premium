import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/cart_provider.dart';
import '../../../screens/cart_screen.dart';
import '../../../widgets/cart_summary_bar.dart';
import '../widgets/home_header.dart';
import '../widgets/popular_section.dart';
import '../widgets/showcase_section.dart';

/// Главная. Раньше весь экран был одним SingleChildScrollView — блок
/// "Сегодня на витрине" рос вместе с карточками и всё уезжало вниз.
/// Теперь верстка — Column с Expanded вокруг "Сегодня на витрине": сам
/// экран целиком помещается в высоту устройства, а прокручивается только
/// "Сегодня на витрине" (вертикально, внутри своей области). "Популярное"
/// как и раньше — горизонтальный скролл, но теперь занимает фиксированное
/// место внизу, а не "плавает" по общей длине страницы.
///
/// Плашка "Перейти в корзину" — тот же CartSummaryBar, что и в «Каталоге»,
/// всплывает поверх контента при появлении товаров в корзине.
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
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(18, 0, 18, cart.isEmpty ? 0 : 72),
                  child: const ShowcaseSection(),
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
