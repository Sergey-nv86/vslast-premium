#!/bin/bash
set -e
#
# Добавляет экран «Карточка товара» (в фирменном стиле Всласть) и
# подключает переход на него с Каталога, Избранного и блока
# «Сегодня на витрине» на Главной (раньше там была TODO-заглушка).
#
# Модель Product расширена опциональными полями для карточки товара
# (рейтинг, отзывы, вес, описание, КБЖУ, состав, галерея фото) —
# заполнено для всех 9 товаров в mock_products.dart.
#
# ЗАПУСК: из корня проекта
#   cd /Users/sukolesnikov/Projects/vslast_premium
#   bash add_product_detail_screen.sh

mkdir -p lib

mkdir -p lib/models
cat > lib/models/product.dart << 'DARTEOF'
/// Категории каталога — соответствуют вкладкам фильтра.
enum ProductCategory { bread, pastry, cakes, desserts }

extension ProductCategoryX on ProductCategory {
  String get label {
    switch (this) {
      case ProductCategory.bread:
        return 'Хлеб';
      case ProductCategory.pastry:
        return 'Выпечка';
      case ProductCategory.cakes:
        return 'Торты';
      case ProductCategory.desserts:
        return 'Десерты';
    }
  }
}

/// Бейдж в левом верхнем углу карточки товара.
enum ProductBadge { hit, newItem, promo }

extension ProductBadgeX on ProductBadge {
  String get label {
    switch (this) {
      case ProductBadge.hit:
        return 'ХИТ';
      case ProductBadge.newItem:
        return 'НОВИНКА';
      case ProductBadge.promo:
        return 'АКЦИЯ';
    }
  }
}

class Product {
  final String id;
  final String name;
  final int price;
  final String imageUrl;
  final ProductCategory category;
  final ProductBadge? badge;

  /// Если false — вместо цены и кнопки "+" показывается кнопка "Предзаказ".
  final bool inStock;

  // --- Поля для экрана «Карточка товара» ---
  // Все опциональны: если не заданы, экран аккуратно скрывает
  // соответствующий блок, а не падает и не рисует пустоту.

  final double? rating;
  final int? reviewsCount;

  /// Например "1 кг", "1 шт", "350 г". По умолчанию "1 шт".
  final String weightLabel;

  final String? description;

  final int? caloriesPer100g;
  final double? proteinPer100g;
  final double? fatPer100g;
  final double? carbsPer100g;
  final String? composition;

  /// Фото для галереи на карточке товара. Если не задано — галерея
  /// состоит из одного [imageUrl] (см. геттер [gallery]).
  final List<String>? galleryImages;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.badge,
    this.inStock = true,
    this.rating,
    this.reviewsCount,
    this.weightLabel = '1 шт',
    this.description,
    this.caloriesPer100g,
    this.proteinPer100g,
    this.fatPer100g,
    this.carbsPer100g,
    this.composition,
    this.galleryImages,
  });

  List<String> get gallery =>
      (galleryImages == null || galleryImages!.isEmpty) ? [imageUrl] : galleryImages!;

  bool get hasNutritionInfo =>
      caloriesPer100g != null ||
      proteinPer100g != null ||
      fatPer100g != null ||
      carbsPer100g != null;

  @override
  bool operator ==(Object other) => other is Product && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
DARTEOF
echo 'lib/models/product.dart — обновлён'

mkdir -p lib/data
cat > lib/data/mock_products.dart << 'DARTEOF'
import '../models/product.dart';

/// Мок-данные, соответствующие утверждённому макету экрана «Каталог».
/// TODO: заменить на загрузку из API/локальной БД проекта.
///
/// imageUrl указывает на реальные файлы из вашей папки images/ —
/// подобраны по смыслу названия, при необходимости поменяйте местами.
/// Убедитесь, что в pubspec.yaml проекта эта папка объявлена как asset:
///   flutter:
///     assets:
///       - assets/images/
/// Если ваши файлы физически лежат не в assets/images/, а в другом месте
/// (например просто images/) — поправьте префикс пути ниже под свой проект.
///
/// rating/reviewsCount/description/КБЖУ/состав — тоже мок-данные для
/// экрана «Карточка товара», под замену на реальные при подключении бэкенда.
final List<Product> mockProducts = [
  const Product(
    id: 'bread_village_sourdough',
    name: 'Хлеб деревенский на закваске',
    price: 390,
    imageUrl: 'assets/images/bread_country.jpg',
    category: ProductCategory.bread,
    badge: ProductBadge.hit,
    rating: 4.8,
    reviewsCount: 96,
    weightLabel: '750 г',
    description:
        'Хлеб на натуральной закваске длительной ферментации: хрустящая '
        'корочка, пористый мякиш и лёгкая кислинка. Без дрожжей и улучшителей.',
    caloriesPer100g: 245,
    proteinPer100g: 8.1,
    fatPer100g: 1.2,
    carbsPer100g: 48.5,
    composition: 'Мука пшеничная, вода, закваска, соль.',
    galleryImages: [
      'assets/images/bread_country.jpg',
      'assets/images/bread_sourdough_02.jpg',
      'assets/images/bread_rustic.jpg',
    ],
  ),
  const Product(
    id: 'baguette_classic',
    name: 'Багет классический',
    price: 220,
    imageUrl: 'assets/images/bread_classic.jpg',
    category: ProductCategory.bread,
    rating: 4.7,
    reviewsCount: 58,
    weightLabel: '300 г',
    description:
        'Французский багет с хрустящей корочкой и воздушным мякишем. '
        'Выпекается несколько раз в день, чтобы к вам он попадал только свежим.',
    caloriesPer100g: 262,
    proteinPer100g: 8.5,
    fatPer100g: 1.0,
    carbsPer100g: 53.0,
    composition: 'Мука пшеничная, вода, дрожжи, соль.',
    galleryImages: [
      'assets/images/bread_classic.jpg',
      'assets/images/bread_sourdough_04.jpg',
    ],
  ),
  const Product(
    id: 'croissant_butter',
    name: 'Круассан сливочный',
    price: 290,
    imageUrl: 'assets/images/bread_french.jpg',
    category: ProductCategory.pastry,
    badge: ProductBadge.newItem,
    rating: 4.9,
    reviewsCount: 121,
    weightLabel: '1 шт',
    description:
        'Слоёное тесто на настоящем сливочном масле — 27 тонких слоёв, '
        'хрустящих снаружи и нежных внутри. Наш самый популярный круассан.',
    caloriesPer100g: 406,
    proteinPer100g: 7.3,
    fatPer100g: 21.0,
    carbsPer100g: 45.8,
    composition: 'Мука пшеничная, масло сливочное, молоко, яйцо, сахар, дрожжи, соль.',
  ),
  const Product(
    id: 'brioche',
    name: 'Бриошь',
    price: 290,
    imageUrl: 'assets/images/bread_finnish.jpg',
    category: ProductCategory.pastry,
    rating: 4.6,
    reviewsCount: 34,
    weightLabel: '350 г',
    description:
        'Сдобная выпечка на сливочном масле и яйцах — мягкая, чуть сладкая, '
        'с нежным сливочным ароматом. Хороша сама по себе и с джемом.',
    caloriesPer100g: 320,
    proteinPer100g: 8.0,
    fatPer100g: 12.5,
    carbsPer100g: 45.0,
    composition: 'Мука пшеничная, масло сливочное, яйца, молоко, сахар, дрожжи, соль.',
    galleryImages: [
      'assets/images/bread_finnish.jpg',
      'assets/images/bread_sourdough_05.jpg',
    ],
  ),
  const Product(
    id: 'napoleon_cake',
    name: 'Наполеон',
    price: 420,
    imageUrl: 'assets/images/cake_signature.jpg',
    category: ProductCategory.cakes,
    badge: ProductBadge.hit,
    inStock: false,
    rating: 4.9,
    reviewsCount: 87,
    weightLabel: '350 г',
    description:
        'Классический торт из тонких слоёв слоёного теста с заварным кремом. '
        'Готовим по традиционному рецепту — настаивается сутки перед подачей.',
    caloriesPer100g: 355,
    proteinPer100g: 5.2,
    fatPer100g: 22.0,
    carbsPer100g: 34.0,
    composition: 'Мука, масло сливочное, яйца, молоко, сахар, ваниль.',
    galleryImages: [
      'assets/images/cake_signature.jpg',
      'assets/images/cake_crown_bordeaux.jpg',
      'assets/images/cake_crown_breton.png',
    ],
  ),
  const Product(
    id: 'cheesecake_cherry',
    name: 'Чизкейк с вишней',
    price: 250,
    imageUrl: 'assets/images/dessert_tart.jpg',
    category: ProductCategory.desserts,
    badge: ProductBadge.newItem,
    rating: 4.8,
    reviewsCount: 42,
    weightLabel: '1 шт (120 г)',
    description:
        'Нежный чизкейк на песочной основе с вишнёвым соусом. Кремовая '
        'текстура и лёгкая кислинка вишни — баланс сладкого и свежего.',
    caloriesPer100g: 298,
    proteinPer100g: 5.6,
    fatPer100g: 19.4,
    carbsPer100g: 27.0,
    composition: 'Творожный сыр, сливки, яйца, сахар, песочное печенье, вишня.',
    galleryImages: [
      'assets/images/dessert_tart.jpg',
      'assets/images/dessert_dacquoise.jpg',
    ],
  ),
  const Product(
    id: 'ciabatta',
    name: 'Чиабатта',
    price: 450,
    imageUrl: 'assets/images/bread_chiabatta.jpg',
    category: ProductCategory.bread,
    rating: 4.7,
    reviewsCount: 29,
    weightLabel: '400 г',
    description:
        'Итальянский хлеб с крупнопористым мякишем и хрустящей мучнистой '
        'корочкой. Готовим на оливковом масле по классической рецептуре.',
    caloriesPer100g: 271,
    proteinPer100g: 9.0,
    fatPer100g: 3.5,
    carbsPer100g: 50.0,
    composition: 'Мука пшеничная, вода, оливковое масло, дрожжи, соль.',
    galleryImages: [
      'assets/images/bread_chiabatta.jpg',
      'assets/images/bread_sourdough_06.jpg',
    ],
  ),
  const Product(
    id: 'grain_bun',
    name: 'Булочка зерновая',
    price: 120,
    imageUrl: 'assets/images/bread_sourdough_01.jpg',
    category: ProductCategory.pastry,
    badge: ProductBadge.promo,
    inStock: false,
    rating: 4.5,
    reviewsCount: 18,
    weightLabel: '120 г',
    description:
        'Булочка с цельнозерновой мукой и смесью семян — плотная, сытная, '
        'с лёгким ореховым привкусом. Хороший выбор для завтрака.',
    caloriesPer100g: 258,
    proteinPer100g: 9.4,
    fatPer100g: 4.8,
    carbsPer100g: 44.0,
    composition: 'Мука цельнозерновая, вода, семена подсолнечника, лён, кунжут, дрожжи, соль.',
    galleryImages: [
      'assets/images/bread_sourdough_01.jpg',
      'assets/images/bread_sourdough_07.jpg',
    ],
  ),
  const Product(
    id: 'eclair_chocolate',
    name: 'Эклер шоколадный',
    price: 210,
    imageUrl: 'assets/images/dessert_eclair.jpg',
    category: ProductCategory.desserts,
    rating: 4.9,
    reviewsCount: 64,
    weightLabel: '1 шт (90 г)',
    description:
        'Заварное тесто с воздушным кремом и шоколадной глазурью. '
        'Классика французской кондитерской в фирменном исполнении Всласть.',
    caloriesPer100g: 312,
    proteinPer100g: 6.0,
    fatPer100g: 18.0,
    carbsPer100g: 32.0,
    composition: 'Мука, масло сливочное, яйца, молоко, сахар, шоколад, крем заварной.',
    galleryImages: [
      'assets/images/dessert_eclair.jpg',
      'assets/images/dessert_lemon_basil.jpg',
    ],
  ),
];
DARTEOF
echo 'lib/data/mock_products.dart — обновлён'

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

  // --- Мои заказы: статусы ---
  static const Color statusPendingBg = Color(0xFFFBE7D2);
  static const Color statusPendingText = Color(0xFFB8712B);
  static const Color statusSuccessBg = Color(0xFFDCEEDB);
  static const Color statusSuccessText = Color(0xFF4C8A55);

  // --- Вход/Регистрация: акцентный градиент кнопок ---
  static const Color accentGradientStart = Color(0xFFCE9A54);
  static const Color accentGradientEnd = Color(0xFFA9682B);
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

  // --- Мои заказы ---

  static TextStyle orderNumber = GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  static TextStyle orderTitle = GoogleFonts.playfairDisplay(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static TextStyle statusPillLabel = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  // --- Вход/Регистрация ---

  static TextStyle authLogoTitle = GoogleFonts.playfairDisplay(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryBrown,
  );

  static TextStyle authTagline = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.badgeHit,
    letterSpacing: 0.6,
  );

  static TextStyle authHeading = GoogleFonts.playfairDisplay(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryBrown,
  );

  static TextStyle fieldLabel = GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle linkText = GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.badgeHit,
  );

  static TextStyle checkboxText = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // --- Карточка товара ---

  static TextStyle productDetailTitle = GoogleFonts.playfairDisplay(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryBrown,
    height: 1.15,
  );

  static TextStyle productDetailPrice = GoogleFonts.manrope(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle ratingValue = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle descriptionText = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle nutritionValue = GoogleFonts.manrope(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle nutritionLabel = GoogleFonts.manrope(
    fontSize: 11,
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

mkdir -p lib/screens
cat > lib/screens/product_detail_screen.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../theme/app_theme.dart';
import '../utils/toast.dart';

/// Экран «Карточка товара». Открывается с любой карточки товара в
/// приложении (Каталог, Избранное, «Сегодня на витрине»...) — передайте
/// сюда сам [Product], больше ничего не нужно, экран сам подписан на
/// CartProvider/FavoritesProvider.
class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final PageController _galleryController = PageController();
  int _galleryIndex = 0;

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final cart = context.watch<CartProvider>();
    final favorites = context.watch<FavoritesProvider>();
    final isFavorite = favorites.isFavorite(product);
    final quantity = cart.quantityOf(product);
    final gallery = product.gallery;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _GalleryHeader(
                  images: gallery,
                  controller: _galleryController,
                  currentIndex: _galleryIndex,
                  onPageChanged: (i) => setState(() => _galleryIndex = i),
                  isFavorite: isFavorite,
                  onBack: () => Navigator.of(context).maybePop(),
                  onToggleFavorite: () {
                    final wasFavorite = isFavorite;
                    favorites.toggle(product);
                    FadeToast.show(
                      context,
                      wasFavorite ? 'Удалено из избранного' : 'Добавлено в избранное',
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  transform: Matrix4.translationValues(0, -24, 0),
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.badge != null) _BadgeRow(badge: product.badge!),
                      if (product.badge != null) const SizedBox(height: 14),

                      Text(product.name, style: AppTextStyles.productDetailTitle),
                      const SizedBox(height: 10),

                      if (product.rating != null) ...[
                        _RatingRow(
                          rating: product.rating!,
                          reviewsCount: product.reviewsCount,
                        ),
                        const SizedBox(height: 16),
                      ],

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(formatPrice(product.price),
                              style: AppTextStyles.productDetailPrice),
                          const SizedBox(width: 8),
                          Text('за ${product.weightLabel}',
                              style: AppTextStyles.rowLabelMuted),
                        ],
                      ),

                      if (product.description != null) ...[
                        const SizedBox(height: 16),
                        Text(product.description!, style: AppTextStyles.descriptionText),
                      ],

                      if (product.hasNutritionInfo) ...[
                        const SizedBox(height: 22),
                        _NutritionCard(product: product),
                      ],

                      const SizedBox(height: 14),
                      _InfoRow(
                        icon: Icons.inventory_2_outlined,
                        label: 'Вес',
                        value: product.weightLabel,
                      ),

                      if (product.composition != null) ...[
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.eco_outlined,
                          label: 'Состав',
                          value: product.composition!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: _BottomActionBar(
                  product: product,
                  quantity: quantity,
                  onAdd: () => cart.add(product),
                  onIncrement: () => cart.increment(product),
                  onDecrement: () => cart.decrement(product),
                  onNotifyMe: () {
                    FadeToast.show(
                      context,
                      'Сообщим, когда товар появится в наличии',
                      icon: Icons.notifications_active,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryHeader extends StatelessWidget {
  final List<String> images;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onToggleFavorite;

  const _GalleryHeader({
    required this.images,
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
    required this.isFavorite,
    required this.onBack,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: top + 380,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: controller,
            onPageChanged: onPageChanged,
            itemCount: images.length,
            itemBuilder: (context, index) => Image.asset(
              images[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.surfaceMuted,
                child: const Icon(Icons.bakery_dining_outlined,
                    size: 48, color: AppColors.textSecondary),
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: top + 12,
            child: _RoundSquareButton(icon: Icons.arrow_back, onTap: onBack),
          ),
          Positioned(
            right: 16,
            top: top + 12,
            child: _RoundSquareButton(
              icon: isFavorite ? Icons.favorite : Icons.favorite_border,
              iconColor: isFavorite ? AppColors.badgePromo : AppColors.primaryBrown,
              onTap: onToggleFavorite,
            ),
          ),
          if (images.length > 1)
            Positioned(
              right: 16,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.image_outlined, size: 15, color: AppColors.primaryBrown),
                    const SizedBox(width: 5),
                    Text('${currentIndex + 1} / ${images.length}',
                        style: AppTextStyles.rowValue),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoundSquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  const _RoundSquareButton({
    required this.icon,
    required this.onTap,
    this.iconColor = AppColors.primaryBrown,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  final ProductBadge badge;

  const _BadgeRow({required this.badge});

  Color _bg(ProductBadge b) {
    switch (b) {
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
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _bg(badge),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badge == ProductBadge.hit) ...[
                const Icon(Icons.local_fire_department, size: 13, color: Colors.white),
                const SizedBox(width: 4),
              ],
              Text(badge.label,
                  style: AppTextStyles.statusPillLabel.copyWith(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RatingRow extends StatelessWidget {
  final double rating;
  final int? reviewsCount;

  const _RatingRow({required this.rating, this.reviewsCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 18, color: AppColors.accentGradientEnd),
        const SizedBox(width: 4),
        Text(rating.toStringAsFixed(1), style: AppTextStyles.ratingValue),
        if (reviewsCount != null) ...[
          const SizedBox(width: 8),
          Text('($reviewsCount)', style: AppTextStyles.rowLabelMuted),
          const SizedBox(width: 8),
          Text('•', style: AppTextStyles.rowLabelMuted),
          const SizedBox(width: 8),
          Text('$reviewsCount отзывов', style: AppTextStyles.rowLabelMuted),
        ],
      ],
    );
  }
}

class _NutritionCard extends StatelessWidget {
  final Product product;

  const _NutritionCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('КБЖУ на 100 г', style: AppTextStyles.sectionLabel.copyWith(fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _NutritionItem(
                  icon: Icons.local_fire_department_outlined,
                  label: 'Ккал',
                  value: product.caloriesPer100g?.toString() ?? '—',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NutritionItem(
                  icon: Icons.water_drop_outlined,
                  label: 'Белки',
                  value: product.proteinPer100g == null
                      ? '—'
                      : '${product.proteinPer100g!.toStringAsFixed(1)} г',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NutritionItem(
                  icon: Icons.eco_outlined,
                  label: 'Жиры',
                  value: product.fatPer100g == null
                      ? '—'
                      : '${product.fatPer100g!.toStringAsFixed(1)} г',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NutritionItem(
                  icon: Icons.grain,
                  label: 'Углеводы',
                  value: product.carbsPer100g == null
                      ? '—'
                      : '${product.carbsPer100g!.toStringAsFixed(1)} г',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NutritionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _NutritionItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: AppColors.primaryBrown),
              const SizedBox(width: 4),
              Flexible(
                child: Text(label,
                    style: AppTextStyles.nutritionLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.nutritionValue),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 19, color: AppColors.primaryBrown),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.sectionLabel.copyWith(fontSize: 14)),
                const SizedBox(height: 3),
                Text(value, style: AppTextStyles.rowLabelMuted.copyWith(height: 1.4)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final Product product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onNotifyMe;

  const _BottomActionBar({
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
    required this.onNotifyMe,
  });

  @override
  Widget build(BuildContext context) {
    if (!product.inStock) {
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                // TODO: подключить логику предзаказа.
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accentGradientStart, AppColors.accentGradientEnd],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Предзаказ', style: AppTextStyles.cartBarButton),
                    const SizedBox(height: 2),
                    Text('Товара временно нет в наличии',
                        style: AppTextStyles.rowLabelMuted.copyWith(
                            color: Colors.white.withOpacity(0.9), fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onNotifyMe,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accentGradientEnd, width: 1.2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_none,
                      size: 18, color: AppColors.accentGradientEnd),
                  const SizedBox(height: 2),
                  Text('Уведомить\nо наличии',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.rowValue
                          .copyWith(color: AppColors.accentGradientEnd, fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (quantity == 0) {
      return GestureDetector(
        onTap: onAdd,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 17),
          decoration: BoxDecoration(
            color: AppColors.primaryBrown,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_bag_outlined, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text('Добавить в корзину · ${formatPrice(product.price)}',
                  style: AppTextStyles.cartBarButton),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryBrown,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Text('В корзине', style: AppTextStyles.cartBarButton.copyWith(fontSize: 14)),
          const Spacer(),
          _StepperControl(onDecrement: onDecrement, onIncrement: onIncrement, quantity: quantity),
          const SizedBox(width: 14),
          Text(formatPrice(product.price * quantity), style: AppTextStyles.cartBarButton),
        ],
      ),
    );
  }
}

class _StepperControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _StepperControl({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _button(Icons.remove, onDecrement),
        SizedBox(
          width: 28,
          child: Text('$quantity',
              textAlign: TextAlign.center,
              style: AppTextStyles.cartBarButton.copyWith(fontSize: 15)),
        ),
        _button(Icons.add, onIncrement),
      ],
    );
  }

  Widget _button(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}
DARTEOF
echo 'lib/screens/product_detail_screen.dart — обновлён'

mkdir -p lib/screens
cat > lib/screens/catalog_screen.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/mock_products.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/cart_summary_bar.dart';
import '../widgets/category_chip.dart';
import '../widgets/product_card.dart';
import '../widgets/screen_banner.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';

/// Экран «Каталог» проекта Всласть.
///
/// Нижнюю панель навигации этот экран НЕ содержит — она уже реализована
/// в текущем проекте. Чтобы бейдж количества товаров на вкладке «Корзина»
/// обновлялся вместе с этим экраном, оба места должны читать
/// `context.watch<CartProvider>().totalCount` из одного и того же
/// CartProvider, поднятого выше по дереву (см. README_INTEGRATION.md).
class CatalogScreen extends StatefulWidget {
  final bool autofocusSearch;

  const CatalogScreen({super.key, this.autofocusSearch = false});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  // null означает выбранную категорию "Все".
  ProductCategory? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  List<Product> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    return mockProducts.where((p) {
      final matchesCategory =
          _selectedCategory == null || p.category == _selectedCategory;
      final matchesQuery =
          query.isEmpty || p.name.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void _openProductDetails(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  void _openCart() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Высота блока под фото товара: паддинги карточки + название (до 2 строк)
  /// + строка цены/кнопки. Считается явно, а не через childAspectRatio,
  /// чтобы карточка никогда не переполнялась (RenderFlex overflow) —
  /// независимо от плотности пикселей и мелких отличий шрифта на устройстве.
  static const double _cardTextBlockHeight = 78;
  static const double _gridCrossAxisSpacing = 10;
  static const double _gridMainAxisSpacing = 10;
  static const int _gridCrossAxisCount = 3;

  SliverGridDelegateWithFixedCrossAxisCount _buildGridDelegate(
      BuildContext context, double horizontalPadding) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth -
            horizontalPadding * 2 -
            _gridCrossAxisSpacing * (_gridCrossAxisCount - 1)) /
        _gridCrossAxisCount;
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: _gridCrossAxisCount,
      mainAxisSpacing: _gridMainAxisSpacing,
      crossAxisSpacing: _gridCrossAxisSpacing,
      mainAxisExtent: itemWidth + _cardTextBlockHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final products = _filteredProducts;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _Header(),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: ScreenBanner(
                      imageUrl: 'assets/images/banner.png',
                      title: 'Свежая выпечка каждое утро',
                      subtitle: 'Из печи — прямо к вашему столу',
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _SearchBar(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      autofocus: widget.autofocusSearch,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 0, 0),
                  sliver: SliverToBoxAdapter(
                    child: _CategoryRow(
                      selectedCategory: _selectedCategory,
                      onSelect: (category) =>
                          setState(() => _selectedCategory = category),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                      20, 18, 20, cart.isEmpty ? 20 : 96),
                  sliver: products.isEmpty
                      ? SliverToBoxAdapter(child: _EmptyState())
                      : SliverGrid(
                          gridDelegate: _buildGridDelegate(context, 20),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => ProductCard(
                              product: products[index],
                              onOpenDetails: _openProductDetails,
                            ),
                            childCount: products.length,
                          ),
                        ),
                ),
              ],
            ),
            if (!cart.isEmpty)
              Positioned(
                left: 20,
                right: 20,
                bottom: 12,
                child: CartSummaryBar(
                  itemsCount: cart.totalCount,
                  totalSum: cart.totalSum,
                  onTap: _openCart,
                ),
              ),
          ],
        ),
      ),
      // Нижняя панель навигации намеренно не реализуется здесь —
      // используется текущая панель проекта.
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Кнопка "назад" пригодится, если Каталог у вас открывается через
        // Navigator.push (например, с иконки на Главной). Если Каталог —
        // отдельная вкладка нижней панели (IndexedStack), а не push-экран,
        // можно просто удалить эту кнопку — возврат на вкладку "Главная"
        // и так работает через саму панель.
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider, width: 1),
            ),
            child: const Icon(Icons.chevron_left,
                size: 24, color: AppColors.primaryBrown),
          ),
        ),
        Expanded(child: Text('Каталог', style: AppTextStyles.screenTitle)),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 22, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              autofocus: autofocus,
              style: AppTextStyles.searchHint.copyWith(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                hintText: 'Поиск хлеба, тортов, десертов...',
                hintStyle: AppTextStyles.searchHint,
              ),
            ),
          ),
          const Icon(Icons.tune, size: 20, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final ProductCategory? selectedCategory;
  final ValueChanged<ProductCategory?> onSelect;

  const _CategoryRow({required this.selectedCategory, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 20),
        children: [
          CategoryChip(
            label: 'Все',
            selected: selectedCategory == null,
            onTap: () => onSelect(null),
          ),
          const SizedBox(width: 6),
          ...ProductCategory.values.expand((category) => [
                CategoryChip(
                  label: category.label,
                  selected: selectedCategory == category,
                  onTap: () => onSelect(category),
                ),
                const SizedBox(width: 6),
              ]),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Text(
          'Ничего не найдено',
          style: AppTextStyles.productName
              .copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
DARTEOF
echo 'lib/screens/catalog_screen.dart — обновлён'

mkdir -p lib/screens
cat > lib/screens/favorite_screen.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/mock_products.dart';
import '../models/product.dart';
import '../providers/favorites_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

/// Экран «Избранное» — товары, отмеченные сердечком в «Каталоге» (или
/// прямо на «Главной»). Используется и как вкладка нижней панели
/// (IndexedStack — тогда кнопка "назад" ничего не делает), и как
/// push-экран из меню профиля (тогда кнопка "назад" возвращает обратно).
class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  void _openProductDetails(BuildContext context, Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  static const double _cardTextBlockHeight = 78;
  static const double _gridSpacing = 10;
  static const int _crossAxisCount = 3;

  SliverGridDelegateWithFixedCrossAxisCount _buildGridDelegate(
      BuildContext context, double horizontalPadding) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth -
            horizontalPadding * 2 -
            _gridSpacing * (_crossAxisCount - 1)) /
        _crossAxisCount;
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: _crossAxisCount,
      mainAxisSpacing: _gridSpacing,
      crossAxisSpacing: _gridSpacing,
      mainAxisExtent: itemWidth + _cardTextBlockHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final favoriteProducts =
        mockProducts.where((p) => favorites.isFavorite(p)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 44,
                        height: 44,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.divider, width: 1),
                        ),
                        child: const Icon(Icons.chevron_left,
                            size: 24, color: AppColors.primaryBrown),
                      ),
                    ),
                    Expanded(child: Text('Избранное', style: AppTextStyles.screenTitle)),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              sliver: favoriteProducts.isEmpty
                  ? const SliverToBoxAdapter(child: _EmptyFavorites())
                  : SliverGrid(
                      gridDelegate: _buildGridDelegate(context, 20),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => ProductCard(
                          product: favoriteProducts[index],
                          onOpenDetails: (p) => _openProductDetails(context, p),
                        ),
                        childCount: favoriteProducts.length,
                      ),
                    ),
            ),
          ],
        ),
      ),
      // Нижняя панель навигации намеренно не реализуется здесь —
      // используется текущая панель проекта.
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.favorite_border,
              size: 40, color: AppColors.textSecondary.withOpacity(0.6)),
          const SizedBox(height: 12),
          Text('Пока нет избранных товаров', style: AppTextStyles.sectionLabel),
          const SizedBox(height: 6),
          Text(
            'Нажмите на сердечко на карточке товара,\nчтобы добавить его сюда',
            textAlign: TextAlign.center,
            style: AppTextStyles.rowLabelMuted,
          ),
        ],
      ),
    );
  }
}
DARTEOF
echo 'lib/screens/favorite_screen.dart — обновлён'

mkdir -p lib/features/home/widgets
cat > lib/features/home/widgets/showcase_section.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/mock_products.dart';
import '../../../models/product.dart';
import '../../../screens/catalog_screen.dart';
import '../../../screens/product_detail_screen.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/product_card.dart';

/// Блок "Сегодня на витрине". Занимает всё доступное место между шапкой
/// и "Популярное" (родитель — Expanded в HomeScreen) и прокручивается
/// САМ, отдельно от остального экрана — поэтому Главная целиком
/// помещается на экран, а не растягивается вниз с ростом числа карточек.
///
/// Карточки — тот же ProductCard, что и в «Каталоге»/«Избранном», поэтому
/// "+", сердечко и "Предзаказ" здесь по-настоящему работают через общий
/// CartProvider/FavoritesProvider. controlScale: 1.7 — увеличенный
/// степпер количества, как попросили.
class ShowcaseSection extends StatelessWidget {
  const ShowcaseSection({super.key});

  static final List<Product> _highlighted = [
    mockProducts.firstWhere((p) => p.id == 'ciabatta'),
    mockProducts.firstWhere((p) => p.id == 'croissant_butter'),
    mockProducts.firstWhere((p) => p.id == 'bread_village_sourdough'),
    // У "Наполеона" inStock=false — здесь же на Главной видно, что вместо
    // "+" показывается кнопка "Предзаказ".
    mockProducts.firstWhere((p) => p.id == 'napoleon_cake'),
    mockProducts.firstWhere((p) => p.id == 'cheesecake_cherry'),
    mockProducts.firstWhere((p) => p.id == 'eclair_chocolate'),
  ];

  static const double _controlScale = 1.7;
  // Бюджет высоты текстового блока под фото при увеличенном степпере:
  // паддинги (14) + название (28) + отступ (4) + строка цены/степпера
  // (26 * 1.7 + 6 = 50.2). Небольшой запас — 100 вместо ~96.
  static const double _cardTextBlockHeight = 100;
  static const double _gridSpacing = 10;

  void _openProductDetails(BuildContext context, Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Сегодня на витрине',
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xff2D2621),
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CatalogScreen()),
                );
              },
              child: Row(
                children: [
                  Text(
                    'Все',
                    style: AppTextStyles.rowLabel.copyWith(
                      color: const Color(0xff7B4A22),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 10,
                    color: Color(0xff7B4A22),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - _gridSpacing) / 2;
              return GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: _gridSpacing,
                  crossAxisSpacing: _gridSpacing,
                  mainAxisExtent: itemWidth + _cardTextBlockHeight,
                ),
                itemCount: _highlighted.length,
                itemBuilder: (context, index) => ProductCard(
                  product: _highlighted[index],
                  controlScale: _controlScale,
                  onOpenDetails: (p) => _openProductDetails(context, p),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
DARTEOF
echo 'lib/features/home/widgets/showcase_section.dart — обновлён'

echo ''
echo 'Готово. Затем: flutter pub get && flutter clean && flutter run'
