#!/bin/bash
set -e
# Запускать из корня проекта: /Users/sukolesnikov/Projects/vslast_premium
# Полностью перезаписывает эти файлы — старое содержимое стирается без следа.

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

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.badge,
    this.inStock = true,
  });

  @override
  bool operator ==(Object other) => other is Product && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
DARTEOF
echo 'lib/models/product.dart — записан'

mkdir -p lib/data
cat > lib/data/mock_products.dart << 'DARTEOF'
import '../models/product.dart';

/// Мок-данные, соответствующие утверждённому макету экрана «Каталог».
/// TODO: заменить на загрузку из API/локальной БД проекта.
/// TODO: заменить imageUrl на реальные пути к ассетам / сетевые URL.
final List<Product> mockProducts = [
  const Product(
    id: 'bread_village_sourdough',
    name: 'Хлеб деревенский на закваске',
    price: 390,
    imageUrl: 'assets/images/bread_village_sourdough.jpg',
    category: ProductCategory.bread,
    badge: ProductBadge.hit,
  ),
  const Product(
    id: 'baguette_classic',
    name: 'Багет классический',
    price: 220,
    imageUrl: 'assets/images/baguette_classic.jpg',
    category: ProductCategory.bread,
  ),
  const Product(
    id: 'croissant_butter',
    name: 'Круассан сливочный',
    price: 290,
    imageUrl: 'assets/images/croissant_butter.jpg',
    category: ProductCategory.pastry,
    badge: ProductBadge.newItem,
  ),
  const Product(
    id: 'brioche',
    name: 'Бриошь',
    price: 290,
    imageUrl: 'assets/images/brioche.jpg',
    category: ProductCategory.pastry,
  ),
  const Product(
    id: 'napoleon_cake',
    name: 'Наполеон',
    price: 420,
    imageUrl: 'assets/images/napoleon_cake.jpg',
    category: ProductCategory.cakes,
    badge: ProductBadge.hit,
  ),
  const Product(
    id: 'cheesecake_cherry',
    name: 'Чизкейк с вишней',
    price: 250,
    imageUrl: 'assets/images/cheesecake_cherry.jpg',
    category: ProductCategory.desserts,
    badge: ProductBadge.newItem,
  ),
  const Product(
    id: 'ciabatta',
    name: 'Чиабатта',
    price: 450,
    imageUrl: 'assets/images/ciabatta.jpg',
    category: ProductCategory.bread,
  ),
  const Product(
    id: 'grain_bun',
    name: 'Булочка зерновая',
    price: 120,
    imageUrl: 'assets/images/grain_bun.jpg',
    category: ProductCategory.pastry,
    badge: ProductBadge.promo,
  ),
  const Product(
    id: 'eclair_chocolate',
    name: 'Эклер шоколадный',
    price: 210,
    imageUrl: 'assets/images/eclair_chocolate.jpg',
    category: ProductCategory.desserts,
  ),
];
DARTEOF
echo 'lib/data/mock_products.dart — записан'

mkdir -p lib/providers
cat > lib/providers/cart_provider.dart << 'DARTEOF'
import 'package:flutter/foundation.dart';
import '../models/product.dart';

/// Управляет содержимым корзины. Подключается через
/// ChangeNotifierProvider на уровне приложения (см. README_INTEGRATION.md),
/// чтобы количество товаров было доступно и на экране «Каталог»,
/// и в бейдже нижней панели навигации, и на экране «Корзина».
class CartProvider extends ChangeNotifier {
  final Map<Product, int> _items = {};

  Map<Product, int> get items => Map.unmodifiable(_items);

  int quantityOf(Product product) => _items[product] ?? 0;

  /// Суммарное количество единиц товара в корзине (для бейджа "Корзина").
  int get totalCount => _items.values.fold(0, (sum, qty) => sum + qty);

  /// Суммарная стоимость корзины в рублях.
  int get totalSum =>
      _items.entries.fold(0, (sum, e) => sum + e.key.price * e.value);

  bool get isEmpty => _items.isEmpty;

  void add(Product product) {
    _items[product] = quantityOf(product) + 1;
    notifyListeners();
  }

  void increment(Product product) => add(product);

  void decrement(Product product) {
    final current = quantityOf(product);
    if (current <= 1) {
      _items.remove(product);
    } else {
      _items[product] = current - 1;
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
DARTEOF
echo 'lib/providers/cart_provider.dart — записан'

mkdir -p lib/providers
cat > lib/providers/favorites_provider.dart << 'DARTEOF'
import 'package:flutter/foundation.dart';
import '../models/product.dart';

class FavoritesProvider extends ChangeNotifier {
  final Set<String> _favoriteIds = {};

  bool isFavorite(Product product) => _favoriteIds.contains(product.id);

  void toggle(Product product) {
    if (_favoriteIds.contains(product.id)) {
      _favoriteIds.remove(product.id);
    } else {
      _favoriteIds.add(product.id);
    }
    notifyListeners();
  }

  int get count => _favoriteIds.length;
}
DARTEOF
echo 'lib/providers/favorites_provider.dart — записан'

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
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  static TextStyle productName = GoogleFonts.manrope(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static TextStyle productPrice = GoogleFonts.manrope(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle badgeLabel = GoogleFonts.manrope(
    fontSize: 11,
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
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
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
echo 'lib/theme/app_theme.dart — записан'

mkdir -p lib/widgets
cat > lib/widgets/category_chip.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBrown : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Text(
          label,
          style: AppTextStyles.categoryChip.copyWith(
            color: selected ? AppColors.textOnPrimary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
DARTEOF
echo 'lib/widgets/category_chip.dart — записан'

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
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 4)),
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
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _badgeColor(product.badge!),
                          borderRadius: BorderRadius.circular(8),
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
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => onOpenDetails(product),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    height: 38,
                    child: Text(
                      product.name,
                      style: AppTextStyles.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (!product.inStock)
                  _PreorderButton(onTap: () {
                    // TODO: подключить логику предзаказа.
                  })
                else if (quantity == 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(formatPrice(product.price),
                          style: AppTextStyles.productPrice),
                      _RoundIconButton(
                        icon: Icons.add,
                        onTap: () => cart.add(product),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(formatPrice(product.price),
                          style: AppTextStyles.productPrice),
                      _QuantityStepper(
                        quantity: quantity,
                        onDecrement: () => cart.decrement(product),
                        onIncrement: () => cart.increment(product),
                      ),
                    ],
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
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          size: 18,
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
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.primaryBrown,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: AppColors.textOnPrimary),
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(icon: Icons.remove, onTap: onDecrement, filled: false),
          SizedBox(
            width: 22,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppTextStyles.productName.copyWith(fontSize: 15),
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
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: filled ? AppColors.primaryBrown : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
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
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.primaryBrown,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text('Предзаказ', style: AppTextStyles.preorderButton),
        ),
      ),
    );
  }
}
DARTEOF
echo 'lib/widgets/product_card.dart — записан'

mkdir -p lib/widgets
cat > lib/widgets/cart_summary_bar.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CartSummaryBar extends StatelessWidget {
  final int itemsCount;
  final int totalSum;
  final VoidCallback onTap;

  const CartSummaryBar({
    super.key,
    required this.itemsCount,
    required this.totalSum,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_bag_outlined,
                size: 20, color: AppColors.primaryBrown),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'В корзине $itemsCount ${pluralizeItems(itemsCount)}\n'
              'на сумму ${formatPrice(totalSum)}',
              style: AppTextStyles.cartBarText,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primaryBrown,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Перейти в корзину', style: AppTextStyles.cartBarButton),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward,
                      size: 16, color: AppColors.textOnPrimary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
DARTEOF
echo 'lib/widgets/cart_summary_bar.dart — записан'

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

/// Экран «Каталог» проекта Всласть.
///
/// Нижнюю панель навигации этот экран НЕ содержит — она уже реализована
/// в текущем проекте. Чтобы бейдж количества товаров на вкладке «Корзина»
/// обновлялся вместе с этим экраном, оба места должны читать
/// `context.watch<CartProvider>().totalCount` из одного и того же
/// CartProvider, поднятого выше по дереву (см. README_INTEGRATION.md).
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

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
    // TODO: заменить на переход к реальному экрану «Карточка товара».
    Navigator.of(context).pushNamed('/product-detail', arguments: product);
  }

  void _openCart() {
    // TODO: заменить на переход к реальному экрану «Корзина».
    Navigator.of(context).pushNamed('/cart');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _SearchBar(controller: _searchController, onChanged: (_) => setState(() {})),
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
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.62,
                          ),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Каталог', style: AppTextStyles.screenTitle),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.divider, width: 1),
          ),
          child: const Icon(Icons.person_outline,
              size: 24, color: AppColors.primaryBrown),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

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
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 20),
        children: [
          CategoryChip(
            label: 'Все',
            selected: selectedCategory == null,
            onTap: () => onSelect(null),
          ),
          const SizedBox(width: 10),
          ...ProductCategory.values.expand((category) => [
                CategoryChip(
                  label: category.label,
                  selected: selectedCategory == category,
                  onTap: () => onSelect(category),
                ),
                const SizedBox(width: 10),
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
echo 'lib/screens/catalog_screen.dart — записан'

echo 'Готово. Теперь: flutter clean && flutter pub get && flutter run'
