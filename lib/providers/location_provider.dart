import 'package:flutter/foundation.dart';

/// Выбранный пользователем город. Список городов сейчас фиксированный —
/// расширите под реальные города доставки/самовывоза, когда появятся.
class LocationProvider extends ChangeNotifier {
  static const List<String> availableCities = [
    'Нижневартовск',
    'Екатеринбург',
    'Санкт-Петербург',
  ];

  /// Координаты центра города — чтобы карта на экране доставки открывалась
  /// сразу в нужном месте, а не где-то в океане по умолчанию.
  static const Map<String, (double, double)> cityCenters = {
    'Нижневартовск': (60.9344, 76.5531),
    'Екатеринбург': (56.8389, 60.6057),
    'Санкт-Петербург': (59.9311, 30.3609),
  };

  String _city = availableCities.first;

  String get city => _city;

  (double, double) get cityCenter => cityCenters[_city]!;

  void setCity(String city) {
    if (!availableCities.contains(city) || city == _city) return;
    _city = city;
    notifyListeners();
  }
}
