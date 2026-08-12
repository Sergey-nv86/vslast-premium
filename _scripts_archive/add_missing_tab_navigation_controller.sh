#!/bin/bash
set -e
#
# Добавляет недостающий providers/tab_navigation_controller.dart —
# main.dart и main_screen.dart уже на него ссылаются (после прошлых
# правок и ребрендинга), но сам файл создавался отдельным скриптом,
# который, похоже, не был запущен.
#
# ЗАПУСК: из корня проекта
#   cd /Users/sukolesnikov/Projects/vslast_premium
#   bash add_missing_tab_navigation_controller.sh

mkdir -p lib

mkdir -p lib/providers
cat > lib/providers/tab_navigation_controller.dart << 'DARTEOF'
import 'package:flutter/foundation.dart';

/// Индекс активной вкладки нижней панели (Главная/Каталог/Карта/
/// Избранное/Корзина) в [MainScreen] — вынесен в провайдер, чтобы любой
/// push-экран (например, «Заказ принят») мог переключить пользователя на
/// вкладку «Главная», не имея прямого доступа к состоянию MainScreen.
class TabNavigationController extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  static const int homeIndex = 0;

  void setIndex(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    notifyListeners();
  }

  void goToHome() => setIndex(homeIndex);
}
DARTEOF
echo 'lib/providers/tab_navigation_controller.dart — записан'

echo ''
echo 'Готово. Если ранее также не запускали остальные части этого патча,'
echo 'на всякий случай прогоните ещё раз: fix_home_catalog_cart_confirmation_loyalty.sh'
echo 'Затем: flutter pub get && flutter clean && flutter run'
