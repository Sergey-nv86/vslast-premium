import 'package:flutter/material.dart';

import 'features/splash/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VslastPremiumApp());
}

class VslastPremiumApp extends StatelessWidget {
  const VslastPremiumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Всласть Premium',

      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F3EE),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B5E3C)),
        fontFamily: 'SF Pro Display',
      ),

      home: const SplashScreen(),
    );
  }
}
