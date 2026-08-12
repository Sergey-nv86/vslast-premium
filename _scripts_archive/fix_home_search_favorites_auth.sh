#!/bin/bash
set -e
#
# Исправляет на vslast_premium:
#  - иконка профиля на Главной теперь открывает меню (Профиль/Избранное/Мои заказы)
#  - поиск на Главной теперь открывает Каталог с фокусом в поле поиска
#  - карточки в блоке "Сегодня на витрине" теперь реально добавляют в корзину
#  - у двух товаров выставлен inStock=false — видна кнопка "Предзаказ"
#  - тап на сердечко показывает плавно гаснущее уведомление
#  - экран "Избранное" теперь настоящий список избранных товаров
#
# ЗАПУСК: из корня проекта
#   cd /Users/sukolesnikov/Projects/vslast_premium
#   bash fix_home_search_favorites_auth.sh

mkdir -p lib

cat > lib/main.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/splash/screens/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/favorites_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VslastPremiumApp());
}

class VslastPremiumApp extends StatelessWidget {
  const VslastPremiumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // сюда же добавляйте любые другие провайдеры проекта
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Всласть Premium',

        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF7F3EE),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B5E3C)),
          fontFamily: 'SF Pro Display',
        ),

        home: const SplashScreen(),
      ),
    );
  }
}
DARTEOF
echo 'lib/main.dart — обновлён'

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
final List<Product> mockProducts = [
  const Product(
    id: 'bread_village_sourdough',
    name: 'Хлеб деревенский на закваске',
    price: 390,
    imageUrl: 'assets/images/bread_country.jpg',
    category: ProductCategory.bread,
    badge: ProductBadge.hit,
  ),
  const Product(
    id: 'baguette_classic',
    name: 'Багет классический',
    price: 220,
    imageUrl: 'assets/images/bread_classic.jpg',
    category: ProductCategory.bread,
  ),
  const Product(
    id: 'croissant_butter',
    name: 'Круассан сливочный',
    price: 290,
    imageUrl: 'assets/images/bread_french.jpg',
    category: ProductCategory.pastry,
    badge: ProductBadge.newItem,
  ),
  const Product(
    id: 'brioche',
    name: 'Бриошь',
    price: 290,
    imageUrl: 'assets/images/bread_finnish.jpg',
    category: ProductCategory.pastry,
  ),
  const Product(
    id: 'napoleon_cake',
    name: 'Наполеон',
    price: 420,
    imageUrl: 'assets/images/cake_signature.jpg',
    category: ProductCategory.cakes,
    badge: ProductBadge.hit,
    inStock: false,
  ),
  const Product(
    id: 'cheesecake_cherry',
    name: 'Чизкейк с вишней',
    price: 250,
    imageUrl: 'assets/images/dessert_tart.jpg',
    category: ProductCategory.desserts,
    badge: ProductBadge.newItem,
  ),
  const Product(
    id: 'ciabatta',
    name: 'Чиабатта',
    price: 450,
    imageUrl: 'assets/images/bread_chiabatta.jpg',
    category: ProductCategory.bread,
  ),
  const Product(
    id: 'grain_bun',
    name: 'Булочка зерновая',
    price: 120,
    imageUrl: 'assets/images/bread_sourdough_01.jpg',
    category: ProductCategory.pastry,
    badge: ProductBadge.promo,
    inStock: false,
  ),
  const Product(
    id: 'eclair_chocolate',
    name: 'Эклер шоколадный',
    price: 210,
    imageUrl: 'assets/images/dessert_eclair.jpg',
    category: ProductCategory.desserts,
  ),
];
DARTEOF
echo 'lib/data/mock_products.dart — обновлён'

mkdir -p lib/providers
cat > lib/providers/auth_provider.dart << 'DARTEOF'
import 'package:flutter/foundation.dart';

/// Простейшее состояние "есть ли уже сохранённый аккаунт" — определяет,
/// какой режим экрана «Вход/Регистрация» открывать при нажатии на
/// «Профиль»: при первом обращении — «Регистрация», при последующих —
/// «Вход».
///
/// TODO: сейчас это состояние живёт только в памяти и сбрасывается при
/// перезапуске приложения. Для сохранения между запусками подключите
/// пакет shared_preferences (или ваш реальный слой авторизации) и
/// замените hasAccount на чтение сохранённого флага/токена.
class AuthProvider extends ChangeNotifier {
  bool _hasAccount = false;

  bool get hasAccount => _hasAccount;

  void markRegistered() {
    _hasAccount = true;
    notifyListeners();
  }
}
DARTEOF
echo 'lib/providers/auth_provider.dart — обновлён'

mkdir -p lib/utils
cat > lib/utils/toast.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Плавно появляющееся и гаснущее уведомление поверх текущего экрана
/// (не привязано к Scaffold — использует ближайший Overlay, поэтому
/// работает из любого места, включая карточки товара на Главной).
class FadeToast {
  static void show(
    BuildContext context,
    String message, {
    IconData icon = Icons.favorite,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _FadeToast(
        message: message,
        icon: icon,
        onDismissed: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _FadeToast extends StatefulWidget {
  final String message;
  final IconData icon;
  final VoidCallback onDismissed;

  const _FadeToast({
    required this.message,
    required this.icon,
    required this.onDismissed,
  });

  @override
  State<_FadeToast> createState() => _FadeToastState();
}

class _FadeToastState extends State<_FadeToast> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 1400), () async {
      if (!mounted) return;
      await _controller.reverse();
      widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 24,
      right: 24,
      bottom: 110,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _opacity,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primaryBrown,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: AppColors.shadow, blurRadius: 14, offset: Offset(0, 6)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: 18, color: Colors.white),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      widget.message,
                      style: AppTextStyles.cartBarText.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
DARTEOF
echo 'lib/utils/toast.dart — обновлён'

mkdir -p lib/widgets
cat > lib/widgets/product_card.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../theme/app_theme.dart';
import '../utils/toast.dart';

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
                      onTap: () {
                        final wasFavorite = isFavorite;
                        favorites.toggle(product);
                        FadeToast.show(
                          context,
                          wasFavorite ? 'Удалено из избранного' : 'Добавлено в избранное',
                        );
                      },
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
import 'cart_screen.dart';

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
    // TODO: заменить на переход к реальному экрану «Карточка товара».
    Navigator.of(context).pushNamed('/product-detail', arguments: product);
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

/// Экран «Избранное» — товары, отмеченные сердечком в «Каталоге» (или
/// прямо на «Главной»). Используется и как вкладка нижней панели
/// (IndexedStack — тогда кнопка "назад" ничего не делает), и как
/// push-экран из меню профиля (тогда кнопка "назад" возвращает обратно).
class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  void _openProductDetails(BuildContext context, Product product) {
    // TODO: заменить на переход к реальному экрану «Карточка товара».
    Navigator.of(context).pushNamed('/product-detail', arguments: product);
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

mkdir -p lib/screens
cat > lib/screens/auth_screen.dart << 'DARTEOF'
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import '../utils/phone_formatter.dart';
import '../widgets/labeled_text_field.dart';

enum AuthMode { login, register }

/// Экран «Вход/Регистрация». Открывается через Navigator.push — например,
/// с пункта «Профиль» в меню, которое выпадает по нажатию на иконку
/// профиля на «Главной». Через [initialMode] можно сразу открыть нужный
/// режим — например, «Регистрация» при первом обращении пользователя
/// (см. AuthProvider.hasAccount).
class AuthScreen extends StatefulWidget {
  final AuthMode initialMode;

  const AuthScreen({super.key, this.initialMode = AuthMode.login});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late AuthMode _mode = widget.initialMode;

  // --- Вход ---
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _selectedCity = 'Нижневартовск';

  // --- Регистрация ---
  final _regLoginController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regPasswordConfirmController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController(text: '+7 ');
  final _emailController = TextEditingController();
  bool _obscureRegPassword = true;
  bool _obscureRegPasswordConfirm = true;
  DateTime? _birthDate;
  bool _agreedToTerms = false;
  late final TapGestureRecognizer _agreementLinkRecognizer;

  static const _cities = [
    'Нижневартовск',
    'Москва',
    'Санкт-Петербург',
    'Екатеринбург',
    'Казань',
  ];

  @override
  void initState() {
    super.initState();
    _agreementLinkRecognizer = TapGestureRecognizer()
      ..onTap = () {
        // TODO: открыть реальный текст соглашения (веб-страница/документ).
      };
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _regLoginController.dispose();
    _regPasswordController.dispose();
    _regPasswordConfirmController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _agreementLinkRecognizer.dispose();
    super.dispose();
  }

  Future<void> _pickCity() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _cities
              .map((city) => ListTile(
                    title: Text(city, style: AppTextStyles.rowLabel),
                    trailing: city == _selectedCity
                        ? const Icon(Icons.check, color: AppColors.primaryBrown)
                        : null,
                    onTap: () => Navigator.pop(context, city),
                  ))
              .toList(),
        ),
      ),
    );
    if (picked != null) setState(() => _selectedCity = picked);
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 6, now.month, now.day),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  void _submitLogin() {
    // TODO: подключить реальную авторизацию (логин/телефон + пароль + город).
    Navigator.of(context).maybePop();
  }

  void _submitRegister() {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Подтвердите согласие на обработку персональных данных'),
        ),
      );
      return;
    }
    // TODO: подключить реальную регистрацию и валидацию полей.
    context.read<AuthProvider>().markRegistered();
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.divider, width: 1),
                  ),
                  child: const Icon(Icons.close, size: 20, color: AppColors.primaryBrown),
                ),
              ),
              const SizedBox(height: 12),
              Center(child: _LogoBlock()),
              const SizedBox(height: 24),
              _ModeSwitch(mode: _mode, onChanged: (m) => setState(() => _mode = m)),
              const SizedBox(height: 24),
              Text(
                _mode == AuthMode.login ? 'Добро пожаловать!' : 'Создайте аккаунт',
                style: AppTextStyles.authHeading,
              ),
              const SizedBox(height: 6),
              Text(
                _mode == AuthMode.login
                    ? 'Войдите, чтобы делать покупки быстрее и удобнее'
                    : 'Заполните данные, чтобы зарегистрироваться и делать покупки в Всласть',
                style: AppTextStyles.rowLabelMuted,
              ),
              const SizedBox(height: 22),
              if (_mode == AuthMode.login) _buildLoginForm() else _buildRegisterForm(),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  _mode == AuthMode.login
                      ? 'assets/images/hero_banner.jpg'
                      : 'assets/images/cake_crown_bordeaux.jpg',
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.image_outlined,
                        size: 40, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabeledTextField(
          label: 'Логин или телефон',
          hint: 'Введите логин или телефон',
          leadingIcon: Icons.person_outline,
          controller: _loginController,
        ),
        const SizedBox(height: 16),
        LabeledTextField(
          label: 'Пароль',
          hint: 'Введите пароль',
          leadingIcon: Icons.lock_outline,
          obscureText: _obscurePassword,
          controller: _passwordController,
          trailing: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {
              // TODO: подключить восстановление пароля.
            },
            behavior: HitTestBehavior.opaque,
            child: Text('Забыли пароль?', style: AppTextStyles.linkText),
          ),
        ),
        const SizedBox(height: 12),
        _TappableField(
          label: 'Ваш город',
          value: _selectedCity,
          hint: 'Выберите город',
          icon: Icons.location_on_outlined,
          onTap: _pickCity,
          helperText: 'От выбора города зависит ассортимент и условия доставки',
        ),
        const SizedBox(height: 24),
        _GradientButton(label: 'Иду за покупками', onTap: _submitLogin),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.divider)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('или', style: AppTextStyles.rowLabelMuted),
            ),
            const Expanded(child: Divider(color: AppColors.divider)),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: () => setState(() => _mode = AuthMode.register),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primaryBrown, width: 1.4),
              ),
              alignment: Alignment.center,
              child: Text(
                'Регистрация нового пользователя',
                style: AppTextStyles.rowLabel.copyWith(color: AppColors.primaryBrown),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabeledTextField(
          label: 'Логин',
          hint: 'Придумайте логин',
          leadingIcon: Icons.person_outline,
          controller: _regLoginController,
        ),
        const SizedBox(height: 16),
        LabeledTextField(
          label: 'Пароль',
          hint: 'Придумайте пароль',
          leadingIcon: Icons.lock_outline,
          obscureText: _obscureRegPassword,
          controller: _regPasswordController,
          trailing: IconButton(
            icon: Icon(
              _obscureRegPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
            onPressed: () => setState(() => _obscureRegPassword = !_obscureRegPassword),
          ),
        ),
        const SizedBox(height: 16),
        LabeledTextField(
          label: 'Повторите пароль',
          hint: 'Повторите пароль',
          leadingIcon: Icons.lock_outline,
          obscureText: _obscureRegPasswordConfirm,
          controller: _regPasswordConfirmController,
          trailing: IconButton(
            icon: Icon(
              _obscureRegPasswordConfirm
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
            onPressed: () =>
                setState(() => _obscureRegPasswordConfirm = !_obscureRegPasswordConfirm),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LabeledTextField(
                label: 'Имя',
                hint: 'Введите имя',
                leadingIcon: Icons.person_outline,
                controller: _firstNameController,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LabeledTextField(
                label: 'Фамилия',
                hint: 'Введите фамилию',
                leadingIcon: Icons.person_outline,
                controller: _lastNameController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _TappableField(
          label: 'Дата рождения',
          value: _birthDate == null ? '' : formatRuDateWithYear(_birthDate!),
          hint: 'Выберите дату',
          icon: Icons.calendar_today_outlined,
          onTap: _pickBirthDate,
        ),
        const SizedBox(height: 16),
        LabeledTextField(
          label: 'Телефон',
          hint: '+7 (___) ___-__-__',
          leadingIcon: Icons.phone_outlined,
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [RuPhoneInputFormatter()],
        ),
        const SizedBox(height: 16),
        LabeledTextField(
          label: 'Email (необязательно)',
          hint: 'Введите email',
          leadingIcon: Icons.mail_outline,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _agreedToTerms,
              onChanged: (value) => setState(() => _agreedToTerms = value ?? false),
              activeColor: AppColors.primaryBrown,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text.rich(
                  TextSpan(
                    style: AppTextStyles.checkboxText,
                    children: [
                      const TextSpan(
                        text: 'Я соглашаюсь на обработку персональных данных '
                            'и принимаю условия ',
                      ),
                      TextSpan(
                        text: 'Согласия',
                        style: AppTextStyles.linkText.copyWith(fontSize: 12),
                        recognizer: _agreementLinkRecognizer,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _GradientButton(label: 'Зарегистрироваться', onTap: _submitRegister),
      ],
    );
  }
}

class _LogoBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo_dark.png',
          height: 48,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.eco, size: 40, color: AppColors.badgeHit),
        ),
        const SizedBox(height: 8),
        Text('Всласть', style: AppTextStyles.authLogoTitle),
        const SizedBox(height: 4),
        Text('пекарня • кондитерская', style: AppTextStyles.authTagline),
      ],
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  final AuthMode mode;
  final ValueChanged<AuthMode> onChanged;

  const _ModeSwitch({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _tab(context, 'Вход', AuthMode.login)),
          Expanded(child: _tab(context, 'Регистрация', AuthMode.register)),
        ],
      ),
    );
  }

  Widget _tab(BuildContext context, String label, AuthMode value) {
    final selected = mode == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBrown : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.categoryChip
              .copyWith(color: selected ? Colors.white : AppColors.textPrimary),
        ),
      ),
    );
  }
}

/// Тап-поле, имитирующее выпадающий список (город / дата рождения):
/// показывает выбранное значение или подсказку, открывает шторку/пикер.
class _TappableField extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final IconData icon;
  final VoidCallback onTap;
  final String? helperText;

  const _TappableField({
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
    required this.onTap,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasValue ? value : hint,
                    style: hasValue ? AppTextStyles.rowLabel : AppTextStyles.searchHint,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(helperText!, style: AppTextStyles.rowLabelMuted),
        ],
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 17),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accentGradientStart, AppColors.accentGradientEnd],
            ),
            borderRadius: BorderRadius.circular(26),
          ),
          alignment: Alignment.center,
          child: Text(label, style: AppTextStyles.cartBarButton),
        ),
      ),
    );
  }
}
DARTEOF
echo 'lib/screens/auth_screen.dart — обновлён'

mkdir -p lib/features/home/widgets
cat > lib/features/home/widgets/home_header.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../screens/auth_screen.dart';
import '../../../screens/catalog_screen.dart';
import '../../../screens/favorite_screen.dart';
import '../../../screens/orders_screen.dart';
import '../../../theme/app_theme.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  void _openSearch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CatalogScreen(autofocusSearch: true),
      ),
    );
  }

  void _openProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            _ProfileMenuTile(
              icon: Icons.person_outline,
              label: 'Профиль',
              onTap: () {
                Navigator.pop(sheetContext);
                // При первом обращении открываем "Регистрацию" — данных
                // пользователя ещё нет и их нужно ввести и сохранить.
                // При повторных — "Вход".
                final hasAccount = context.read<AuthProvider>().hasAccount;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AuthScreen(
                      initialMode: hasAccount ? AuthMode.login : AuthMode.register,
                    ),
                  ),
                );
              },
            ),
            _ProfileMenuTile(
              icon: Icons.favorite_border,
              label: 'Избранное',
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FavoriteScreen()),
                );
              },
            ),
            _ProfileMenuTile(
              icon: Icons.receipt_long_outlined,
              label: 'Мои заказы',
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OrdersScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    const double photoHeight = 150;
    const double searchBarOverlap = 20;
    const double searchBarHeight = 46;
    const double bottomGap = 8;

    return SizedBox(
      height: top + photoHeight - searchBarOverlap + searchBarHeight + bottomGap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: double.infinity,
            height: top + photoHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/hero_banner.jpg',
                    fit: BoxFit.cover,
                  ),
                ),

                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    width: 260,
                    height: top + photoHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white.withOpacity(.55),
                          Colors.white.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  left: 22,
                  top: top + 16,
                  right: 96,
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Доброе утро,\nСергей!',
                        style: TextStyle(
                          color: Color(0xFF3E2517),
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                          fontFamily: 'Georgia',
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Испечено с любовью\nдля Вас.',
                        style: TextStyle(
                          color: Color(0xFF4A3226),
                          fontSize: 13,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Georgia',
                        ),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  right: 22,
                  top: top + 6,
                  child: GestureDetector(
                    onTap: () => _openProfileMenu(context),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.94),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 15,
                        color: Color(0xff7B4A22),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            left: 18,
            right: 18,
            top: top + photoHeight - searchBarOverlap,
            child: GestureDetector(
              onTap: () => _openSearch(context),
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: searchBarHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(23),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.10),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 18),
                    Icon(Icons.search, color: Color(0xff8C837D), size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Поиск хлеба, тортов, десертов...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xff8C837D),
                          fontFamily: 'Georgia',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 14),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: AppColors.primaryBrown),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: AppTextStyles.rowLabel)),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
DARTEOF
echo 'lib/features/home/widgets/home_header.dart — обновлён'

mkdir -p lib/features/home/widgets
cat > lib/features/home/widgets/showcase_section.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import '../../../data/mock_products.dart';
import '../../../models/product.dart';
import '../../../screens/catalog_screen.dart';
import '../../../widgets/product_card.dart';

/// Блок "Сегодня на витрине". Раньше карточки здесь были декоративными
/// (свои image/title/price без связи с товаром) — кнопка "+" ничего не
/// добавляла в корзину, потому что виджет не знал, о каком товаре речь.
/// Теперь берём реальные Product из mockProducts и используем тот же
/// ProductCard, что и в "Каталоге" — значит "+", сердечко и "Предзаказ"
/// здесь тоже реально работают и используют общий CartProvider/
/// FavoritesProvider.
class ShowcaseSection extends StatelessWidget {
  const ShowcaseSection({super.key});

  static final List<Product> _highlighted = [
    mockProducts.firstWhere((p) => p.id == 'ciabatta'),
    mockProducts.firstWhere((p) => p.id == 'croissant_butter'),
    mockProducts.firstWhere((p) => p.id == 'bread_village_sourdough'),
    // У "Наполеона" inStock=false — здесь же на Главной видно, что вместо
    // "+" показывается кнопка "Предзаказ".
    mockProducts.firstWhere((p) => p.id == 'napoleon_cake'),
  ];

  void _openProductDetails(BuildContext context, Product product) {
    // TODO: заменить на переход к реальному экрану «Карточка товара».
    Navigator.of(context).pushNamed('/product-detail', arguments: product);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Text(
                'Сегодня на витрине',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff2D2621),
                  fontFamily: 'Georgia',
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
                child: const Row(
                  children: [
                    Text(
                      'Все',
                      style: TextStyle(
                        color: Color(0xff7B4A22),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Georgia',
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 10,
                      color: Color(0xff7B4A22),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ProductCard(
                  product: _highlighted[0],
                  onOpenDetails: (p) => _openProductDetails(context, p),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ProductCard(
                  product: _highlighted[1],
                  onOpenDetails: (p) => _openProductDetails(context, p),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ProductCard(
                  product: _highlighted[2],
                  onOpenDetails: (p) => _openProductDetails(context, p),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ProductCard(
                  product: _highlighted[3],
                  onOpenDetails: (p) => _openProductDetails(context, p),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
DARTEOF
echo 'lib/features/home/widgets/showcase_section.dart — обновлён'

echo ''
echo 'Готово. Затем: flutter clean && flutter pub get && flutter run'
