import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'features/splash/screens/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/location_provider.dart';
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
        ChangeNotifierProvider(create: (_) => LocationProvider()),
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
