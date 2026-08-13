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
/// "Популярное" (горизонтальный скролл) — сразу под шапкой. Ниже —
/// панель "Фильтр" + категории и сама витрина "Сегодня на витрине",
/// сгруппированная по категориям — вместе они занимают всё оставшееся
/// место до нижней навигации (Expanded), см. ShowcaseSection: там же
/// логика scroll-spy (чипы категорий синхронизированы со скроллом) и
/// модалка "Фильтр".
///
/// Экран НЕ прокручивается целиком — прокручивается только сама витрина
/// внутри своего Expanded. Высота этой области ВСЕГДА постоянна и не
/// зависит от корзины — ни Padding, ни доля Expanded никогда не меняются
/// из-за появления/исчезновения плашки корзины. Именно смена этой высоты
/// раньше вызывала "прыжки"/"пустую часть экрана" при добавлении товара
/// во время скролла.
///
/// Плашка "Перейти в корзину" (CartSummaryBar) — не часть обычного потока
/// Column, а отдельный слой поверх экрана (Positioned внутри Stack),
/// прижатый к низу и наложенный на витрину. Она не участвует в расчёте
/// размеров остального контента вообще, поэтому ничего не сжимает.
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: PopularSection(),
              ),
              const SizedBox(height: 14),
              const Expanded(child: ShowcaseSection()),
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
