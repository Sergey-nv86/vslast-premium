#!/bin/bash
set -e
# Запускать из корня проекта: /Users/sukolesnikov/Projects/vslast_premium
# Исправляет: обрезанную цену на карточках товара и полужирное название
# (делает его обычным начертанием).

mkdir -p lib/theme
cat > lib/theme/app_theme.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Единая цветовая палитра экрана «Каталог» проекта Всласть.
/// Значения подобраны по референсу утверждённого макета.
class AppColors {
  AppColors._();

  // Фон
  static const Color background = Color(0xFFF7F2EA);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Брендовый тёмно-коричневый (заголовки, кнопки, выбранная категория)
  static const Color primaryBrown = Color(0xFF3C2415);
  static const Color primaryBrownDark = Color(0xFF2E1B10);

  // Второстепенные поверхности (поиск, чипы, плашка корзины)
  static const Color surfaceMuted = Color(0xFFECE3D6);
  static const Color surfaceMutedDark = Color(0xFFE3D8C6);

  // Текст
  static const Color textPrimary = Color(0xFF2A1B12);
  static const Color textSecondary = Color(0xFF8A7E70);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Бейджи
  static const Color badgeHit = Color(0xFF8C5A34);
  static const Color badgeNew = Color(0xFF7C9473);
  static const Color badgePromo = Color(0xFFD1603D);

  static const Color divider = Color(0xFFE7DECD);
  static const Color shadow = Color(0x1A2A1B12);
}

class AppTextStyles {
  AppTextStyles._();

  /// Заголовок экрана «Каталог» — витринный serif-шрифт.
  static TextStyle screenTitle = GoogleFonts.playfairDisplay(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryBrown,
    height: 1.1,
  );

  static TextStyle searchHint = GoogleFonts.manrope(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static TextStyle categoryChip = GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static TextStyle productName = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.15,
  );

  static TextStyle productPrice = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle badgeLabel = GoogleFonts.manrope(
    fontSize: 8,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
    letterSpacing: 0.2,
  );

  static TextStyle cartBarText = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle cartBarButton = GoogleFonts.manrope(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
  );

  static TextStyle preorderButton = GoogleFonts.manrope(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
  );

  // --- Оформление заказа / Подтверждение заказа ---

  /// Заголовок экранов «Оформление заказа» и «Заказ принят!».
  static TextStyle screenTitleSmall = GoogleFonts.playfairDisplay(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryBrown,
    height: 1.15,
  );

  /// Подзаголовки секций: «Ваш заказ», «Способ получения», «Состав заказа».
  static TextStyle sectionLabel = GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Счётчик рядом с заголовком секции: «4 товара».
  static TextStyle sectionCounter = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static TextStyle orderItemName = GoogleFonts.manrope(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static TextStyle orderItemPrice = GoogleFonts.manrope(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle receiptQty = GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  /// Обычный текст строки (пункт меню, значение поля).
  static TextStyle rowLabel = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle rowLabelMuted = GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.35,
  );

  static TextStyle rowValue = GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle totalLabel = GoogleFonts.manrope(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle totalValue = GoogleFonts.manrope(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle infoNote = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.35,
  );

  static TextStyle optionTitle = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle optionSubtitle = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}

/// Форматирует цену с разделителем разрядов и знаком ₽.
/// 1540 -> "1 540 ₽"
String formatPrice(int price) {
  final digits = price.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    final posFromEnd = digits.length - i;
    buffer.write(digits[i]);
    if (posFromEnd > 1 && posFromEnd % 3 == 1) {
      buffer.write('\u00A0'); // неразрывный пробел
    }
  }
  return '${buffer.toString()} ₽';
}

/// Склонение слова «товар» под число.
/// 1 -> товар, 2-4 -> товара, 5+ -> товаров
String pluralizeItems(int count) {
  final mod10 = count % 10;
  final mod100 = count % 100;
  if (mod10 == 1 && mod100 != 11) return 'товар';
  if (mod10 >= 2 && mod10 <= 4 && !(mod100 >= 12 && mod100 <= 14)) {
    return 'товара';
  }
  return 'товаров';
}
DARTEOF
echo 'lib/theme/app_theme.dart — обновлён'

mkdir -p lib/widgets
cat > lib/widgets/product_card.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../theme/app_theme.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  /// Открытие карточки товара (экран «Карточка товара»).
  final ValueChanged<Product> onOpenDetails;

  const ProductCard({
    super.key,
    required this.product,
    required this.onOpenDetails,
  });

  Color _badgeColor(ProductBadge badge) {
    switch (badge) {
      case ProductBadge.hit:
        return AppColors.badgeHit;
      case ProductBadge.newItem:
        return AppColors.badgeNew;
      case ProductBadge.promo:
        return AppColors.badgePromo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final favorites = context.watch<FavoritesProvider>();
    final quantity = cart.quantityOf(product);
    final isFavorite = favorites.isFavorite(product);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Изображение + бейдж + избранное. Только эта область открывает
          // карточку товара, чтобы не конфликтовать с нажатием на сердечко.
          GestureDetector(
            onTap: () => onOpenDetails(product),
            behavior: HitTestBehavior.opaque,
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.surfaceMuted,
                      child: const Icon(Icons.bakery_dining_outlined,
                          size: 36, color: AppColors.textSecondary),
                    ),
                  ),
                  if (product.badge != null)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: _badgeColor(product.badge!),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.badge!.label,
                          style: AppTextStyles.badgeLabel,
                        ),
                      ),
                    ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _FavoriteButton(
                      isFavorite: isFavorite,
                      onTap: () => favorites.toggle(product),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            // Внимание: сумма высот этого блока (паддинги + название + цена)
            // рассчитана под _cardTextBlockHeight = 78 в catalog_screen.dart.
            // При изменении паддингов/шрифтов здесь — обновите константу там же.
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => onOpenDetails(product),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    height: 28,
                    child: Text(
                      product.name,
                      style: AppTextStyles.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 26,
                  child: !product.inStock
                      ? SizedBox(
                          width: double.infinity,
                          child: _PreorderButton(onTap: () {
                            // TODO: подключить логику предзаказа.
                          }),
                        )
                      : quantity == 0
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    formatPrice(product.price),
                                    style: AppTextStyles.productPrice,
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                _RoundIconButton(
                                  icon: Icons.add,
                                  onTap: () => cart.add(product),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    formatPrice(product.price),
                                    style: AppTextStyles.productPrice,
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                _QuantityStepper(
                                  quantity: quantity,
                                  onDecrement: () => cart.decrement(product),
                                  onIncrement: () => cart.increment(product),
                                ),
                              ],
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onTap;

  const _FavoriteButton({required this.isFavorite, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          size: 13,
          color: isFavorite ? AppColors.badgePromo : AppColors.primaryBrown,
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          color: AppColors.primaryBrown,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 14, color: AppColors.textOnPrimary),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(icon: Icons.remove, onTap: onDecrement, filled: false),
          SizedBox(
            width: 14,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppTextStyles.productName.copyWith(fontSize: 11),
            ),
          ),
          _StepperButton(icon: Icons.add, onTap: onIncrement, filled: true),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _StepperButton({
    required this.icon,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: filled ? AppColors.primaryBrown : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 10,
          color: filled ? AppColors.textOnPrimary : AppColors.primaryBrown,
        ),
      ),
    );
  }
}

class _PreorderButton extends StatelessWidget {
  final VoidCallback onTap;

  const _PreorderButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryBrown,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text('Предзаказ', style: AppTextStyles.preorderButton),
        ),
      ),
    );
  }
}
DARTEOF
echo 'lib/widgets/product_card.dart — обновлён'

echo 'Готово. Теперь: flutter clean && flutter pub get && flutter run'
