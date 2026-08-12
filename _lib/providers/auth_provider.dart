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
