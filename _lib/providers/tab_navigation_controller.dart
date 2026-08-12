import 'package:flutter/foundation.dart';

/// Индекс активной вкладки нижней панели (Главная/Каталог/Карта/
/// Избранное/Корзина) в [MainScreen] — вынесен в провайдер, чтобы любой
/// push-экран (например, «Заказ принят») мог переключить пользователя на
/// вкладку «Главная», не имея прямого доступа к состоянию MainScreen.
class TabNavigationController extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  static const int homeIndex = 0;
  static const int catalogIndex = 1;

  void setIndex(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    notifyListeners();
  }

  void goToHome() => setIndex(homeIndex);
  void goToCatalog() => setIndex(catalogIndex);
}
