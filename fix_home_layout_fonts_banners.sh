#!/bin/bash
set -e
#
# Исправляет на vslast_premium:
#  - степпер количества в блоке "Сегодня на витрине" увеличен в 1.7 раза
#  - убран декоративный поиск с Главной
#  - Главная больше не растягивается: Column+Expanded вместо одного
#    SingleChildScrollView — "Сегодня на витрине" скроллится вертикально
#    само по себе, "Популярное" остаётся горизонтальным скроллом снизу
#  - на экране Вход/Регистрация — баннер с логотипом Всласть сверху
#  - вход нужен один раз: AuthProvider теперь хранит isLoggedIn через
#    shared_preferences (раньше было только в памяти)
#  - новый экран "Профиль" — открывается вместо Входа, когда пользователь
#    уже входил раньше
#  - баннеры сверху на Каталоге и Корзине (новый виджет ScreenBanner)
#  - единый шрифт по всему приложению: Playfair Display (заголовки) +
#    Manrope (текст) — вместо смеси SF Pro Display/Georgia/незагруженных
#    PlayfairDisplay и GreatVibes
#
# ВАЖНО: этот патч добавляет новую зависимость — добавьте в pubspec.yaml:
#   shared_preferences: ^2.2.2
# (google_fonts и provider должны быть добавлены уже раньше)
#
# ЗАПУСК: из корня проекта
#   cd /Users/sukolesnikov/Projects/vslast_premium
#   bash fix_home_layout_fonts_banners.sh

mkdir -p lib

cat > lib/main.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

        // Единый шрифт для всего приложения: Manrope — для основного
        // текста (чистый, современный, отлично читается на мелких
        // размерах — цены, лейблы, кнопки), Playfair Display — для
        // заголовков и брендовых надписей (см. AppTextStyles в
        // lib/theme/app_theme.dart: screenTitle, orderTitle,
        // authLogoTitle и т.д. уже используют его явно).
        // Раньше в разных местах проекта встречались разные варианты
        // ('SF Pro Display', 'Georgia', голые строки "PlayfairDisplay"/
        // "GreatVibes" без реального шрифта) — они не были на самом деле
        // подключены как ассеты и тихо откатывались на системный шрифt
        // платформы, из-за чего вид отличался от экрана к экрану.
        // GoogleFonts грузит и кэширует настоящий файл шрифта, поэтому
        // выглядит одинаково на всех платформах.
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF7F3EE),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B5E3C)),
          textTheme: GoogleFonts.manropeTextTheme(),
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
import 'package:shared_preferences/shared_preferences.dart';

/// Состояние "пользователь уже входил в приложение раньше" —
/// сохраняется на устройстве (SharedPreferences), поэтому вход
/// действительно нужен только один раз: после успешного входа/регистрации
/// при следующих запусках приложение открывается сразу, без экрана
/// «Вход/Регистрация».
///
/// TODO: это упрощённая замена настоящей авторизации — здесь нет ни
/// токена, ни проверки пароля на сервере. Когда подключите бэкенд,
/// замените isLoggedIn/markLoggedIn на реальную сессию (токен + его
/// проверку/обновление), а этот класс можно оставить как обёртку над тем
/// же UI-состоянием.
class AuthProvider extends ChangeNotifier {
  static const _keyLoggedIn = 'auth_is_logged_in';
  static const _keyDisplayName = 'auth_display_name';

  bool _isLoggedIn = false;
  bool _isLoaded = false;
  String? _displayName;

  bool get isLoggedIn => _isLoggedIn;

  /// true, когда сохранённое состояние уже прочитано с устройства.
  /// Пока false — не принимайте решений об isLoggedIn, подождите.
  bool get isLoaded => _isLoaded;

  String? get displayName => _displayName;

  AuthProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_keyLoggedIn) ?? false;
    _displayName = prefs.getString(_keyDisplayName);
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> markLoggedIn({String? displayName}) async {
    _isLoggedIn = true;
    if (displayName != null && displayName.trim().isNotEmpty) {
      _displayName = displayName.trim();
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, true);
    if (_displayName != null) {
      await prefs.setString(_keyDisplayName, _displayName!);
    }
  }

  /// Выход — пригодится для кнопки "Выйти" на экране «Профиль»
  /// и для проверки сценария первого входа при разработке.
  Future<void> logout() async {
    _isLoggedIn = false;
    _displayName = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoggedIn);
    await prefs.remove(_keyDisplayName);
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
import '../utils/toast.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  /// Открытие карточки товара (экран «Карточка товара»).
  final ValueChanged<Product> onOpenDetails;

  /// Масштаб степпера количества (кнопка "+" / "−N+"). По умолчанию 1.0 —
  /// как в «Каталоге» и «Избранном». На Главной, в блоке «Сегодня на
  /// витрине», используется 1.7 — там по вашей просьбе кнопки крупнее.
  final double controlScale;

  const ProductCard({
    super.key,
    required this.product,
    required this.onOpenDetails,
    this.controlScale = 1.0,
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
    // Высота строки "цена + кнопка" растёт вместе с controlScale, чтобы
    // увеличенный степпер не обрезался фиксированной высотой строки.
    final priceRowHeight = controlScale <= 1.0 ? 26.0 : 26.0 * controlScale + 6.0;

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
                  height: priceRowHeight,
                  child: !product.inStock
                      ? SizedBox(
                          width: double.infinity,
                          child: _PreorderButton(
                            controlScale: controlScale,
                            onTap: () {
                              // TODO: подключить логику предзаказа.
                            },
                          ),
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
                                  controlScale: controlScale,
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
                                  controlScale: controlScale,
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
  final double controlScale;

  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.controlScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final size = 26.0 * controlScale;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.primaryBrown,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 14.0 * controlScale, color: AppColors.textOnPrimary),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final double controlScale;

  const _QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    this.controlScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.symmetric(horizontal: 1 * controlScale, vertical: 1 * controlScale),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
              icon: Icons.remove, onTap: onDecrement, filled: false, controlScale: controlScale),
          SizedBox(
            width: 14.0 * controlScale,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppTextStyles.productName.copyWith(fontSize: 11.0 * controlScale),
            ),
          ),
          _StepperButton(
              icon: Icons.add, onTap: onIncrement, filled: true, controlScale: controlScale),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final double controlScale;

  const _StepperButton({
    required this.icon,
    required this.onTap,
    required this.filled,
    this.controlScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final size = 18.0 * controlScale;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: filled ? AppColors.primaryBrown : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 10.0 * controlScale,
          color: filled ? AppColors.textOnPrimary : AppColors.primaryBrown,
        ),
      ),
    );
  }
}

class _PreorderButton extends StatelessWidget {
  final VoidCallback onTap;
  final double controlScale;

  const _PreorderButton({required this.onTap, this.controlScale = 1.0});

  @override
  Widget build(BuildContext context) {
    final height = controlScale <= 1.0 ? 26.0 : 26.0 * controlScale + 6.0;
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryBrown,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Text('Предзаказ',
              style: AppTextStyles.preorderButton.copyWith(fontSize: 11.0 * controlScale.clamp(1.0, 1.3))),
        ),
      ),
    );
  }
}
DARTEOF
echo 'lib/widgets/product_card.dart — обновлён'

mkdir -p lib/widgets
cat > lib/widgets/screen_banner.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Промо-баннер в верхней части экрана (Каталог, Корзина и т.д.):
/// изображение на всю ширину со скруглёнными углами, лёгким затемнением
/// снизу для читаемости текста и коротким заголовком/подзаголовком.
class ScreenBanner extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String? subtitle;
  final double height;

  const ScreenBanner({
    super.key,
    required this.imageUrl,
    required this.title,
    this.subtitle,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.surfaceMuted,
                child: const Icon(Icons.image_outlined,
                    size: 32, color: AppColors.textSecondary),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0),
                      Colors.black.withOpacity(0.45),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTextStyles.rowLabelMuted.copyWith(color: Colors.white70),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
DARTEOF
echo 'lib/widgets/screen_banner.dart — обновлён'

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
cat > lib/screens/cart_screen.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/order_item_tile.dart';
import '../widgets/screen_banner.dart';
import 'checkout_screen.dart';

/// Экран «Корзина». Список товаров — это прямое отражение [CartProvider]:
/// степпер количества и удаление здесь меняют ту же самую корзину, которую
/// видит и «Каталог», и «Оформление заказа» — отдельного состояния у этого
/// экрана нет.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String? _comment;

  Future<void> _editComment() async {
    final controller = TextEditingController(text: _comment);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Комментарий к заказу', style: AppTextStyles.sectionLabel),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Например: не звонить в домофон',
                filled: true,
                fillColor: AppColors.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () => Navigator.pop(context, controller.text.trim()),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBrown,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: Text('Сохранить', style: AppTextStyles.cartBarButton),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (result != null) setState(() => _comment = result.isEmpty ? null : result);
  }

  void _openCheckout() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final entries = cart.items.entries.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: entries.isEmpty
            ? const _EmptyCartState()
            : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _Header(itemsCount: cart.totalCount),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: ScreenBanner(
                        imageUrl: 'assets/images/hero_banner_old.jpg',
                        title: 'Почти готово!',
                        subtitle: 'Проверьте заказ и переходите к оформлению',
                        height: 100,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final entry = entries[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: OrderItemTile(
                              product: entry.key,
                              quantity: entry.value,
                            ),
                          );
                        },
                        childCount: entries.length,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _CommentRow(comment: _comment, onTap: _editComment),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    sliver: const SliverToBoxAdapter(child: _PromoCodeRow()),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _CartSummary(itemsTotal: cart.totalSum),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                    sliver: SliverToBoxAdapter(
                      child: SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: _openCheckout,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 17),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBrown,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            alignment: Alignment.center,
                            child: Text('Оформить заказ',
                                style: AppTextStyles.cartBarButton),
                          ),
                        ),
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

class _Header extends StatelessWidget {
  final int itemsCount;

  const _Header({required this.itemsCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(right: 12, top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider, width: 1),
            ),
            child: const Icon(Icons.chevron_left,
                size: 24, color: AppColors.primaryBrown),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Корзина', style: AppTextStyles.screenTitle),
              const SizedBox(height: 4),
              Text(
                '$itemsCount ${pluralizeItems(itemsCount)}',
                style: AppTextStyles.rowLabelMuted,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentRow extends StatelessWidget {
  final String? comment;
  final VoidCallback onTap;

  const _CommentRow({required this.comment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasComment = comment != null && comment!.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.primaryBrown,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasComment ? comment! : 'Добавить комментарий к заказу',
                style: AppTextStyles.rowLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _PromoCodeRow extends StatelessWidget {
  const _PromoCodeRow();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: подключить реальную логику применения промокода.
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(Icons.confirmation_number_outlined,
                size: 20, color: AppColors.primaryBrown),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Промокод', style: AppTextStyles.rowLabel),
            ),
            Text('Применить',
                style: AppTextStyles.rowLabel.copyWith(color: AppColors.badgeHit)),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// Упрощённая сводка суммы для «Корзины»: способ получения ещё не выбран
/// (это делается на «Оформлении заказа»), поэтому строка доставки — просто
/// заглушка «Самовывоз: Бесплатно», как в утверждённом макете.
class _CartSummary extends StatelessWidget {
  final int itemsTotal;

  const _CartSummary({required this.itemsTotal});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row('Сумма товаров', formatPrice(itemsTotal)),
        const SizedBox(height: 8),
        _row('Самовывоз', 'Бесплатно'),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1, color: AppColors.divider),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Итого', style: AppTextStyles.totalLabel),
            Text(formatPrice(itemsTotal), style: AppTextStyles.totalValue),
          ],
        ),
      ],
    );
  }

  Widget _row(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.rowLabelMuted),
          Text(value, style: AppTextStyles.rowValue),
        ],
      );
}

class _EmptyCartState extends StatelessWidget {
  const _EmptyCartState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          const _Header(itemsCount: 0),
          const Spacer(),
          Icon(Icons.shopping_bag_outlined,
              size: 40, color: AppColors.textSecondary.withOpacity(0.6)),
          const SizedBox(height: 12),
          Text('Корзина пуста', style: AppTextStyles.sectionLabel),
          const SizedBox(height: 6),
          Text(
            'Добавьте товары из каталога, чтобы оформить заказ',
            textAlign: TextAlign.center,
            style: AppTextStyles.rowLabelMuted,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
DARTEOF
echo 'lib/screens/cart_screen.dart — обновлён'

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
/// (см. AuthProvider.isLoggedIn).
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
    context.read<AuthProvider>().markLoggedIn(displayName: _loginController.text);
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
    context.read<AuthProvider>().markLoggedIn(displayName: _firstNameController.text);
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
              Image.asset(
                'assets/images/logo_light.png',
                width: double.infinity,
                height: 130,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 130,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.image_outlined,
                      size: 36, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 20),
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

mkdir -p lib/screens
cat > lib/screens/profile_screen.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

/// Экран «Профиль» — показывается вместо «Вход/Регистрация», когда
/// пользователь уже входил в приложение раньше (AuthProvider.isLoggedIn).
/// Сейчас это минимальная заглушка с данными и кнопкой «Выйти» — по мере
/// появления бэкенда замените на реальные данные пользователя, историю,
/// настройки и т.д.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                  Expanded(child: Text('Профиль', style: AppTextStyles.screenTitle)),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.person, size: 40, color: AppColors.primaryBrown),
              ),
              const SizedBox(height: 16),
              Text(
                auth.displayName?.isNotEmpty == true ? auth.displayName! : 'Гость Всласть',
                style: AppTextStyles.authHeading,
              ),
              const SizedBox(height: 4),
              Text('Вы вошли в приложение', style: AppTextStyles.rowLabelMuted),
              const SizedBox(height: 32),
              // TODO: здесь разместите реальные данные пользователя —
              // телефон, email, адреса доставки, способы оплаты и т.д.
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) Navigator.of(context).maybePop();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.primaryBrown, width: 1.4),
                    ),
                    alignment: Alignment.center,
                    child: Text('Выйти',
                        style: AppTextStyles.rowLabel.copyWith(color: AppColors.primaryBrown)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
DARTEOF
echo 'lib/screens/profile_screen.dart — обновлён'

mkdir -p lib/screens
cat > lib/screens/loyalty_screen.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class LoyaltyScreen extends StatelessWidget {
  const LoyaltyScreen({super.key});

  static const Color background = Color(0xFFF8F4EE);
  static const Color brown = Color(0xFF2E1C13);
  static const Color gold = Color(0xFFD6A54B);
  static const Color lightGold = Color(0xFFF7E3B8);
  static const Color green = Color(0xFF2E9C56);
  static const Color muted = Color(0xFF9A8C7C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE7DFD2)),
                    ),
                    child: const Icon(Icons.chevron_left_rounded, color: brown, size: 20),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "Карта лояльности",
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: brown,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),

              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF24160F), Color(0xFF3A2519), Color(0xFF5B3923)],
                  ),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 10,
                      right: 10,
                      child: SizedBox(
                        width: 78,
                        height: 48,
                        child: SvgPicture.asset("assets/images/bakery_illustration.svg", fit: BoxFit.contain),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Всласть",
                            style: GoogleFonts.playfairDisplay(
                              color: lightGold,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              fontStyle: FontStyle.italic,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "— PREMIUM —",
                            style: TextStyle(color: gold.withOpacity(.85), fontSize: 9, letterSpacing: 2.5, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "PREMIUM MEMBER",
                                      style: TextStyle(color: gold, fontSize: 9.5, letterSpacing: 1.2, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      "Sergey Kolesnikov",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.playfairDisplay(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      "№ 000 123 456",
                                      style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: gold.withOpacity(.5), width: 1),
                                    ),
                                    child: Image.asset("assets/images/qr_demo.png", fit: BoxFit.contain),
                                  ),
                                  const SizedBox(height: 5),
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      "Покажите QR\nна кассе",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: gold.withOpacity(.9), fontSize: 9, height: 1.25),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    Expanded(child: _BalanceCard(balance: 1250, approxValue: "≈ 1 250 ₽")),
                    SizedBox(width: 10),
                    Expanded(child: _LevelCard(levelName: "Premium", current: 1250, target: 2000)),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text("Ваши привилегии", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: brown)),
                  Text("Все привилегии  ›", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: muted)),
                ],
              ),

              const SizedBox(height: 8),

              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    Expanded(child: _BenefitTile(iconAsset: "assets/icons/gift.svg", title: "Подарок\nко дню рождения")),
                    SizedBox(width: 10),
                    Expanded(child: _BenefitTile(iconAsset: "assets/icons/bread.svg", title: "Ранний доступ\nк новинкам")),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    Expanded(child: _BenefitTile(iconAsset: "assets/icons/premium.svg", title: "Персональные\nпредложения")),
                    SizedBox(width: 10),
                    Expanded(child: _BenefitTile(iconAsset: "assets/icons/crown_1.svg", title: "Приоритетный\nпредзаказ")),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text("История начислений", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: brown)),
                  Text("Вся история  ›", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: muted)),
                ],
              ),

              const SizedBox(height: 10),

              const _HistoryTile(title: "Покупка хлеба", date: "Сегодня, 10:30", amount: "+120", positive: true, balance: "1 250"),
              const SizedBox(height: 6),
              const _HistoryTile(title: "Торт «Фисташковый»", date: "Вчера, 16:45", amount: "+350", positive: true, balance: "1 130"),
              const SizedBox(height: 6),
              const _HistoryTile(title: "Оплата бонусами", date: "12 июля, 14:20", amount: "−200", positive: false, balance: "780"),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FullQrScreen()));
                  },
                  icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                  label: const Text("Показать QR кассиру", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _goldIcon(String asset, double size) {
  return SvgPicture.asset(
    asset,
    width: size,
    height: size,
    colorFilter: const ColorFilter.mode(LoyaltyScreen.brown, BlendMode.srcIn),
  );
}

class _BalanceCard extends StatelessWidget {
  final int balance;
  final String approxValue;
  const _BalanceCard({required this.balance, required this.approxValue});

  @override
  Widget build(BuildContext context) {
    final formattedBalance = _formatThousands(balance);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(color: LoyaltyScreen.lightGold, shape: BoxShape.circle),
            child: _goldIcon("assets/icons/zvezda.svg", 18),
          ),
          const SizedBox(height: 5),
          const Text("Ваш баланс", style: TextStyle(fontSize: 10.5, color: LoyaltyScreen.muted)),
          const SizedBox(height: 3),
          Text(
            formattedBalance,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: LoyaltyScreen.brown, height: 1.05),
          ),
          const Text("бонусов", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: LoyaltyScreen.brown)),
          const SizedBox(height: 4),
          Text(approxValue, style: const TextStyle(fontSize: 10, color: LoyaltyScreen.muted)),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final String levelName;
  final int current;
  final int target;
  const _LevelCard({required this.levelName, required this.current, required this.target});

  @override
  Widget build(BuildContext context) {
    final remaining = target - current;
    final progress = (current / target).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(color: LoyaltyScreen.lightGold, shape: BoxShape.circle),
            child: _goldIcon("assets/icons/crown_1.svg", 18),
          ),
          const SizedBox(height: 5),
          const Text("Ваш уровень", style: TextStyle(fontSize: 10.5, color: LoyaltyScreen.muted)),
          const SizedBox(height: 2),
          Text(levelName, style: GoogleFonts.playfairDisplay(fontSize: 19, fontWeight: FontWeight.w700, color: LoyaltyScreen.brown)),
          const SizedBox(height: 5),
          Text(
            "До следующего уровня\nосталось $remaining бонусов",
            style: const TextStyle(fontSize: 9.5, color: LoyaltyScreen.muted, height: 1.2),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: const Color(0xFFF0E6D2),
              valueColor: const AlwaysStoppedAnimation<Color>(LoyaltyScreen.brown),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${_formatThousands(current)} / ${_formatThousands(target)}",
            style: const TextStyle(fontSize: 9.5, color: LoyaltyScreen.muted),
          ),
        ],
      ),
    );
  }
}

String _formatThousands(int value) {
  final s = value.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i != 0 && (s.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(s[i]);
  }
  return buffer.toString();
}

class _BenefitTile extends StatelessWidget {
  final String iconAsset;
  final String title;
  const _BenefitTile({required this.iconAsset, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(color: LoyaltyScreen.lightGold, shape: BoxShape.circle),
            child: _goldIcon(iconAsset, 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: LoyaltyScreen.brown, fontSize: 10.5, fontWeight: FontWeight.w700, height: 1.15),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final String title;
  final String date;
  final String amount;
  final bool positive;
  final String balance;
  const _HistoryTile({required this.title, required this.date, required this.amount, required this.positive, required this.balance});

  @override
  Widget build(BuildContext context) {
    final amountColor = positive ? LoyaltyScreen.green : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          SizedBox(width: 38, child: Text(amount, style: TextStyle(color: amountColor, fontSize: 13, fontWeight: FontWeight.w700))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: LoyaltyScreen.brown, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(date, style: const TextStyle(color: LoyaltyScreen.muted, fontSize: 10.5)),
              ],
            ),
          ),
          Text(balance, style: const TextStyle(color: LoyaltyScreen.brown, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(width: 5),
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(color: LoyaltyScreen.gold, shape: BoxShape.circle),
            child: const Center(child: Text("Б", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
          ),
        ],
      ),
    );
  }
}

class FullQrScreen extends StatelessWidget {
  const FullQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoyaltyScreen.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: LoyaltyScreen.background,
        centerTitle: true,
        iconTheme: const IconThemeData(color: LoyaltyScreen.brown),
        title: Text("Карта лояльности", style: GoogleFonts.playfairDisplay(color: LoyaltyScreen.brown, fontWeight: FontWeight.w700, fontSize: 20)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 24, offset: const Offset(0, 10))],
              ),
              child: Image.asset("assets/images/qr_demo.png", width: 260, height: 260, fit: BoxFit.contain),
            ),
            const SizedBox(height: 24),
            const Text("Покажите QR кассиру", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: LoyaltyScreen.brown)),
            const SizedBox(height: 6),
            const Text("Бонусы будут начислены автоматически", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 32),
            SizedBox(
              width: 240,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(elevation: 0, backgroundColor: LoyaltyScreen.gold, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Закрыть", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
DARTEOF
echo 'lib/screens/loyalty_screen.dart — обновлён'

mkdir -p lib/features/home/screens
cat > lib/features/home/screens/home_screen.dart << 'DARTEOF'
import 'package:flutter/material.dart';

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
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeHeader(),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
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
    );
  }
}
DARTEOF
echo 'lib/features/home/screens/home_screen.dart — обновлён'

mkdir -p lib/features/home/widgets
cat > lib/features/home/widgets/home_header.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../screens/auth_screen.dart';
import '../../../screens/favorite_screen.dart';
import '../../../screens/orders_screen.dart';
import '../../../screens/profile_screen.dart';
import '../../../theme/app_theme.dart';

/// Шапка «Главной»: фото-баннер, приветствие и иконка профиля.
/// Строку поиска отсюда убрали по вашей просьбе — если понадобится
/// вернуть, поищите её в истории версий этого файла.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

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
                // Вход нужен только один раз: если пользователь уже
                // входил раньше (AuthProvider.isLoggedIn сохраняется на
                // устройстве) — сразу открываем «Профиль», а не форму
                // входа. Иначе — «Регистрацию», данных ещё нет.
                final auth = context.read<AuthProvider>();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => auth.isLoggedIn
                        ? const ProfileScreen()
                        : const AuthScreen(initialMode: AuthMode.register),
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
    const double photoHeight = 140;

    return SizedBox(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Доброе утро,\nСергей!',
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFF3E2517),
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Испечено с любовью\nдля Вас.',
                  style: AppTextStyles.rowLabelMuted.copyWith(
                    color: const Color(0xFF4A3226),
                    fontSize: 13,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
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
import 'package:google_fonts/google_fonts.dart';
import '../../../data/mock_products.dart';
import '../../../models/product.dart';
import '../../../screens/catalog_screen.dart';
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
    // TODO: заменить на переход к реальному экрану «Карточка товара».
    Navigator.of(context).pushNamed('/product-detail', arguments: product);
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

mkdir -p lib/features/home/widgets
cat > lib/features/home/widgets/popular_section.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PopularSection extends StatelessWidget {
  const PopularSection({super.key});

  @override
  Widget build(BuildContext context) {
    final products = [
      const _PopularItem(
        image: 'assets/images/dessert_eclair.jpg',
        title: 'Эклер',
        price: 210,
      ),
      const _PopularItem(
        image: 'assets/images/dessert_dacquoise.jpg',
        title: 'Дакуаз',
        price: 260,
      ),
      const _PopularItem(
        image: 'assets/images/dessert_lemon_basil.jpg',
        title: 'Тарт лимон-б...',
        price: 320,
      ),
      const _PopularItem(
        image: 'assets/images/bread_chiabatta.jpg',
        title: 'Чиабатта',
        price: 250,
      ),
      const _PopularItem(
        image: 'assets/images/bread_classic.jpg',
        title: 'Булочка сдобная',
        price: 120,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                "Популярное",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xff2D2621),
                ),
              ),
              const Spacer(),
              const Text(
                "Все",
                style: TextStyle(
                  color: Color(0xff7B4A22),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xff7B4A22)),
            ],
          ),
        ),

        const SizedBox(height: 8),

        SizedBox(
          height: 114,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, index) => products[index],
          ),
        ),
      ],
    );
  }
}

class _PopularItem extends StatelessWidget {
  final String image;
  final String title;
  final int price;

  const _PopularItem({
    required this.image,
    required this.title,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 76,
              height: 76,
              child: Image.asset(image, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xff2D2621),
            ),
          ),
          Text(
            "$price ₽",
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xff7B4A22),
            ),
          ),
        ],
      ),
    );
  }
}
DARTEOF
echo 'lib/features/home/widgets/popular_section.dart — обновлён'

echo ''
echo 'Готово.'
echo 'Не забудьте добавить в pubspec.yaml: shared_preferences: ^2.2.2'
echo 'Затем: flutter pub get && flutter clean && flutter run'
