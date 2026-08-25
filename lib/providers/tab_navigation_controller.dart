import 'package:flutter/foundation.dart';

/// Управляет активной вкладкой клиентского приложения.
///
/// Нижняя навигация:
/// 0 — Главная
/// 1 — Каталог
/// 2 — Карта лояльности
/// 3 — Акции
/// 4 — График
class TabNavigationController extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  static const int homeIndex = 0;
  static const int catalogIndex = 1;
  static const int loyaltyIndex = 2;
  static const int promotionsIndex = 3;
  static const int scheduleIndex = 4;

  void setIndex(int index) {
    if (_currentIndex == index) {
      return;
    }

    if (index < 0 || index > scheduleIndex) {
      return;
    }

    _currentIndex = index;
    notifyListeners();
  }

  void goToHome() => setIndex(homeIndex);

  void goToCatalog() => setIndex(catalogIndex);

  void goToLoyalty() => setIndex(loyaltyIndex);

  void goToPromotions() => setIndex(promotionsIndex);

  void goToSchedule() => setIndex(scheduleIndex);
}
