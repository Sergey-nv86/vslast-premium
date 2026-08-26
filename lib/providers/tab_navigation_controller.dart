import 'package:flutter/foundation.dart';

/// Управляет активной вкладкой клиентского приложения.
///
/// Основная навигация:
/// 0 — Главная
/// 1 — Каталог
/// 2 — Запеки
/// 3 — Акции
/// 4 — Лояльность
///
/// Профиль и Корзина не занимают место в основной навигации.
class TabNavigationController extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  static const int homeIndex = 0;
  static const int catalogIndex = 1;
  static const int bakeScheduleIndex = 2;
  static const int promotionsIndex = 3;
  static const int loyaltyIndex = 4;

  void setIndex(int index) {
    if (_currentIndex == index) {
      return;
    }

    if (index < homeIndex || index > loyaltyIndex) {
      return;
    }

    _currentIndex = index;
    notifyListeners();
  }

  void goToHome() => setIndex(homeIndex);

  void goToCatalog() => setIndex(catalogIndex);

  void goToBakeSchedule() => setIndex(bakeScheduleIndex);

  /// Алиас для обратной совместимости со старым именем «schedule».
  void goToSchedule() => goToBakeSchedule();

  void goToPromotions() => setIndex(promotionsIndex);

  void goToLoyalty() => setIndex(loyaltyIndex);
}
