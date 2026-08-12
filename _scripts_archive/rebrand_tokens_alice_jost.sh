#!/bin/bash
set -e
#
# Шаг 1 ребрендинга «Всласть Premium» под фирменный брендбук:
#  - шрифты: Playfair Display -> Alice (заголовки), Manrope -> Jost (интерфейс)
#  - цвета: молочный фон (#FAF7F1) + графит (#201C1A) вместо коричневой палитры
#  - добавлены токены фирменной пастели: accentSky/Lavender/Rose/Vanilla
#    (пока не расставлены по экранам — это следующий шаг)
#  - золотой градиент кнопок убран (просьба брендбука) — сведён к сплошному графиту
#  - бейджи ХИТ/НОВИНКА/АКЦИЯ перекрашены под новую палитру (форма — прежняя,
#    "типографические капсулы" из брендбука — отдельный следующий шаг)
#
# Меняются только токены темы + несколько захардкоженных мимо темы цветов на
# Главной и в нижней панели — логика ни одного экрана не тронута.
#
# ЗАПУСК: из корня проекта
#   cd /Users/sukolesnikov/Projects/vslast_premium
#   bash rebrand_tokens_alice_jost.sh

mkdir -p lib

cat > lib/main.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'features/splash/screens/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/tab_navigation_controller.dart';

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
        ChangeNotifierProvider(create: (_) => TabNavigationController()),
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
        // Единый шрифт для всего приложения — теперь по брендбуку "Всласть":
        // Alice — для заголовков/эмоциональных элементов (см. AppTextStyles:
        // screenTitle, orderTitle, authLogoTitle и т.д.), Jost — основной
        // UI-шрифт (цены, кнопки, лейблы). Раньше здесь стояла пара
        // Playfair Display + Manrope — рабочая, но не из фирменного
        // брендбука; смена сделана в одном месте (app_theme.dart) и здесь,
        // остальные экраны ничего не знают о конкретном шрифте.
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFFAF7F1),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF201C1A)),
          textTheme: GoogleFonts.jostTextTheme(),
        ),

        home: const SplashScreen(),
      ),
    );
  }
}
DARTEOF
echo 'lib/main.dart — обновлён'

mkdir -p lib/theme
cat > lib/theme/app_theme.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Цветовая палитра проекта Всласть — на основе фирменного брендбука
/// (CMYK 30/5/0/0 небо, 30/30/0/0 лаванда, 0/25/0/0 роза, 0/5/30/0 ваниль,
/// 5/65/60/80 графит). Философия 70/15/10/5: молочный фон — графит для
/// текста/кнопок — один пастельный акцент на экран — пастель для бейджей.
///
/// ВАЖНО: имя `primaryBrown` — историческое, осталось от прежней
/// коричневой палитры. Сейчас в нём графит, не коричневый — переименовать
/// стоит отдельным заходом (это потребует правки во всех файлах, где он
/// используется), сейчас меняем только значения токенов.
class AppColors {
  AppColors._();

  // Фон — молочный (70%)
  static const Color background = Color(0xFFFAF7F1);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Графит (15%) — текст, кнопки, ключевые элементы.
  static const Color primaryBrown = Color(0xFF201C1A);
  static const Color primaryBrownDark = Color(0xFF14100F);

  // Второстепенные поверхности (поиск, чипы, плашка корзины)
  static const Color surfaceMuted = Color(0xFFF1ECE3);
  static const Color surfaceMutedDark = Color(0xFFE7E0D3);

  // Текст
  static const Color textPrimary = Color(0xFF201C1A);
  static const Color textSecondary = Color(0xFF8A8177);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Фирменная пастель (10%) — один акцент на экран/категорию.
  static const Color accentSky = Color(0xFFB3F2FF);
  static const Color accentLavender = Color(0xFFB3B3FF);
  static const Color accentRose = Color(0xFFFFBFFF);
  static const Color accentVanilla = Color(0xFFFFF2B3);

  // Бейджи (5%) — сейчас всё ещё сплошная заливка с белым текстом (это
  // предстоит переделать в "типографические капсулы" отдельным шагом —
  // см. пункт 9 брендбука). ХИТ — графит, НОВИНКА/АКЦИЯ — более
  // насыщенные варианты лаванды/розы, чтобы белый текст оставался читаемым.
  static const Color badgeHit = Color(0xFF201C1A);
  static const Color badgeNew = Color(0xFF7A7AD1);
  static const Color badgePromo = Color(0xFFCC6FCC);

  static const Color divider = Color(0xFFEDE7DB);
  static const Color shadow = Color(0x14201C1A);

  /// Насыщенный вариант лавандового — для ссылок/тегов на светлом фоне.
  /// Сами accentSky/Lavender/Rose/Vanilla слишком бледные для мелкого
  /// текста (плохо читаются) — они для крупных поверхностей/подложек.
  static const Color linkAccent = Color(0xFF6B6BC7);

  // --- Мои заказы: статусы ---
  static const Color statusPendingBg = Color(0xFFFFF2B3);
  static const Color statusPendingText = Color(0xFF8A7328);
  static const Color statusSuccessBg = Color(0xFFDCEEDB);
  static const Color statusSuccessText = Color(0xFF4C8A55);

  // --- Вход/Регистрация и др.: акцентная кнопка ---
  // Брендбук прямо просит не использовать золотой градиент — раньше
  // здесь была коричнево-золотая заливка ("Иду за покупками", "Оплатить
  // по СБП" и т.д.). Оставил структуру (эти кнопки собраны через
  // LinearGradient) нетронутой в самих виджетах, но обе точки
  // градиента теперь ведут на один и тот же графит — визуально это
  // сплошная кнопка без "золота", без необходимости трогать код кнопок.
  static const Color accentGradientStart = Color(0xFF201C1A);
  static const Color accentGradientEnd = Color(0xFF201C1A);
}

class AppTextStyles {
  AppTextStyles._();

  /// Заголовок экрана «Каталог» — витринный serif-шрифт.
  static TextStyle screenTitle = GoogleFonts.alice(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryBrown,
    height: 1.1,
  );

  static TextStyle searchHint = GoogleFonts.jost(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static TextStyle categoryChip = GoogleFonts.jost(
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static TextStyle productName = GoogleFonts.jost(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.15,
  );

  static TextStyle productPrice = GoogleFonts.jost(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle badgeLabel = GoogleFonts.jost(
    fontSize: 8,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
    letterSpacing: 0.2,
  );

  static TextStyle cartBarText = GoogleFonts.jost(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle cartBarButton = GoogleFonts.jost(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
  );

  static TextStyle preorderButton = GoogleFonts.jost(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
  );

  // --- Оформление заказа / Подтверждение заказа ---

  /// Заголовок экранов «Оформление заказа» и «Заказ принят!».
  static TextStyle screenTitleSmall = GoogleFonts.alice(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryBrown,
    height: 1.15,
  );

  /// Подзаголовки секций: «Ваш заказ», «Способ получения», «Состав заказа».
  static TextStyle sectionLabel = GoogleFonts.jost(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Счётчик рядом с заголовком секции: «4 товара».
  static TextStyle sectionCounter = GoogleFonts.jost(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static TextStyle orderItemName = GoogleFonts.jost(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static TextStyle orderItemPrice = GoogleFonts.jost(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle receiptQty = GoogleFonts.jost(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  /// Обычный текст строки (пункт меню, значение поля).
  static TextStyle rowLabel = GoogleFonts.jost(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle rowLabelMuted = GoogleFonts.jost(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.35,
  );

  static TextStyle rowValue = GoogleFonts.jost(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle totalLabel = GoogleFonts.jost(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle totalValue = GoogleFonts.jost(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle infoNote = GoogleFonts.jost(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.35,
  );

  static TextStyle optionTitle = GoogleFonts.jost(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle optionSubtitle = GoogleFonts.jost(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // --- Мои заказы ---

  static TextStyle orderNumber = GoogleFonts.jost(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  static TextStyle orderTitle = GoogleFonts.alice(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static TextStyle statusPillLabel = GoogleFonts.jost(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  // --- Вход/Регистрация ---

  static TextStyle authLogoTitle = GoogleFonts.alice(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryBrown,
  );

  static TextStyle authTagline = GoogleFonts.jost(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.linkAccent,
    letterSpacing: 0.6,
  );

  static TextStyle authHeading = GoogleFonts.alice(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryBrown,
  );

  static TextStyle fieldLabel = GoogleFonts.jost(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle linkText = GoogleFonts.jost(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.linkAccent,
  );

  static TextStyle checkboxText = GoogleFonts.jost(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // --- Карточка товара ---

  static TextStyle productDetailTitle = GoogleFonts.alice(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryBrown,
    height: 1.15,
  );

  static TextStyle productDetailPrice = GoogleFonts.jost(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle ratingValue = GoogleFonts.jost(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle descriptionText = GoogleFonts.jost(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle nutritionValue = GoogleFonts.jost(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle nutritionLabel = GoogleFonts.jost(
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
cat > lib/screens/main_screen.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/home/screens/home_screen.dart';
import '../providers/tab_navigation_controller.dart';
import 'catalog_screen.dart';
import 'loyalty_screen.dart';
import 'favorite_screen.dart';
import 'cart_screen.dart';

import '../features/home/widgets/bottom_nav_bar.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // currentIndex теперь живёт в TabNavigationController, а не в локальном
    // State — так с любого push-экрана (например, «Заказ принят») можно
    // переключить активную вкладку на «Главная» через
    // context.read<TabNavigationController>().goToHome().
    final currentIndex = context.watch<TabNavigationController>().currentIndex;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F1),

      body: IndexedStack(
        index: currentIndex,
        children: const [
          HomeScreen(),
          CatalogScreen(),
          LoyaltyScreen(),
          FavoriteScreen(),
          CartScreen(),
        ],
      ),

      bottomNavigationBar: PremiumBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) => context.read<TabNavigationController>().setIndex(index),
      ),
    );
  }
}
DARTEOF
echo 'lib/screens/main_screen.dart — обновлён'

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
                        style: GoogleFonts.alice(
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
                            style: GoogleFonts.alice(
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
                                      style: GoogleFonts.alice(
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

              // Названия обобщены до "Покупка" (без привязки к конкретному
              // товару) по вашей просьбе. Важное правило для реальных
              // данных: если покупка оплачивалась (полностью или частично)
              // бонусами — начисление за эту же покупку не показывается,
              // т.е. на одну покупку не может быть одновременно и "+" за
              // начисление, и "−" за списание. Ниже это три разных, не
              // связанных друг с другом события/даты.
              const _HistoryTile(title: "Покупка", date: "Сегодня, 10:30", amount: "+120", positive: true, balance: "1 250"),
              const SizedBox(height: 6),
              const _HistoryTile(title: "Покупка", date: "Вчера, 16:45", amount: "+350", positive: true, balance: "1 130"),
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
          Text(levelName, style: GoogleFonts.alice(fontSize: 19, fontWeight: FontWeight.w700, color: LoyaltyScreen.brown)),
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
        title: Text("Карта лояльности", style: GoogleFonts.alice(color: LoyaltyScreen.brown, fontWeight: FontWeight.w700, fontSize: 20)),
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

mkdir -p lib/features/home/widgets
cat > lib/features/home/widgets/bottom_nav_bar.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Раньше иконки/подписи выглядели блёкло — маленький размер, светлый
/// неактивный цвет, тонкий (не переопределяемый в коде) штрих у самих
/// SVG-файлов. Здесь: крупнее иконки, темнее неактивный цвет, жирный шрифт
/// у подписей всегда (не только у активной), плюс лёгкий приём "faux bold" —
/// иконка отрисовывается двойным слоем со сдвигом на пол-пикселя, что
/// визуально утолщает тонкий штрих без правки самого SVG-файла.
class PremiumBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const PremiumBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const Color _activeColor = Color(0xFF201C1A);
  static const Color _inactiveColor = Color(0xFF8A8177);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(top: 10, bottom: bottomInset > 0 ? bottomInset : 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF8),
        border: Border(
          top: BorderSide(color: Colors.black.withOpacity(.08), width: 1),
        ),
      ),
      child: Row(
        children: [
          _item(icon: 'assets/icons/home.svg', label: 'Главная', index: 0),
          _item(icon: 'assets/icons/catalog.svg', label: 'Каталог', index: 1),
          _item(icon: 'assets/icons/premium.svg', label: 'Карта', index: 2),
          _item(
            icon: 'assets/icons/favorite.svg',
            label: 'Избранное',
            index: 3,
          ),
          _item(icon: 'assets/icons/add.svg', label: 'Корзина', index: 4),
        ],
      ),
    );
  }

  Widget _item({
    required String icon,
    required String label,
    required int index,
  }) {
    final selected = currentIndex == index;
    final color = selected ? _activeColor : _inactiveColor;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _boldIcon(icon, color, 23),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _boldIcon(String path, Color color, double size) {
    final colorFilter = ColorFilter.mode(color, BlendMode.srcIn);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          SvgPicture.asset(path, width: size, height: size, colorFilter: colorFilter),
          Positioned(
            left: 0.6,
            top: 0.6,
            child:
                SvgPicture.asset(path, width: size, height: size, colorFilter: colorFilter),
          ),
        ],
      ),
    );
  }
}
DARTEOF
echo 'lib/features/home/widgets/bottom_nav_bar.dart — обновлён'

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
                  style: GoogleFonts.alice(
                    color: AppColors.primaryBrown,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Испечено с любовью\nдля Вас.',
                  style: AppTextStyles.rowLabelMuted.copyWith(
                    color: AppColors.textPrimary,
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
                  color: AppColors.linkAccent,
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
import '../../../screens/product_detail_screen.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/product_card.dart';

/// Блок "Сегодня на витрине". Занимает всё доступное место между шапкой
/// и "Популярное" (родитель — Expanded в HomeScreen) и прокручивается
/// САМ, отдельно от остального экрана — поэтому Главная целиком
/// помещается на экран, а не растягивается вниз с ростом числа карточек.
///
/// Карточки — тот же ProductCard и с тем же размером/стилем, что и в
/// «Каталоге» (controlScale по умолчанию = 1.0, без увеличения). Список —
/// только товары в наличии (первые 6 из mockProducts, отфильтрованных по
/// inStock), чтобы здесь не показывался "Предзаказ".
class ShowcaseSection extends StatelessWidget {
  const ShowcaseSection({super.key});

  static final List<Product> _highlighted =
      mockProducts.where((p) => p.inStock).take(6).toList();

  static const double _cardTextBlockHeight = 78;
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
              style: GoogleFonts.alice(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.1,
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
                      color: AppColors.linkAccent,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 10,
                    color: AppColors.linkAccent,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - _gridSpacing) / 2;
              return GridView.builder(
                padding: EdgeInsets.zero,
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
import '../../../theme/app_theme.dart';

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
                style: GoogleFonts.alice(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              const Text(
                "Все",
                style: TextStyle(
                  color: AppColors.linkAccent,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.linkAccent),
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
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            "$price ₽",
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
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
echo 'Готово. Затем: flutter pub get && flutter clean && flutter run'
