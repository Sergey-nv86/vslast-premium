import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/permission.dart';
import '../models/user_role.dart';

/// Реальный авторизованный пользователь приложения.
///
/// Авторизация:
///   Supabase Auth
///
/// Основной идентификатор входа:
///   phone + password
///
/// E-mail:
///   хранится в Supabase Auth + public.profiles
///   используется для восстановления пароля
///
/// Профиль:
///   public.profiles
///
/// Лояльность:
///   public.loyalty_accounts
class AuthUser {
  final String id;
  final String displayName;
  final String phone;
  final String email;
  final String city;
  final UserRole role;
  final Set<Permission> permissions;

  const AuthUser({
    required this.id,
    required this.displayName,
    required this.phone,
    required this.email,
    required this.city,
    required this.role,
    required this.permissions,
  });

  bool hasPermission(Permission permission) {
    return permissions.contains(permission);
  }

  bool get canAccessAdmin => role.canAccessAdmin;

  factory AuthUser.fromProfile({
    required String userId,
    required Map<String, dynamic> profile,
    required User authUser,
  }) {
    final role = _parseRole(profile['role']);

    final profileDisplayName = _stringValue(profile['display_name']);

    final displayName = profileDisplayName.isNotEmpty
        ? profileDisplayName
        : _buildDisplayName(
            firstName: _stringValue(profile['first_name']),
            lastName: _stringValue(profile['last_name']),
          );

    final phone = _stringValue(profile['phone']).isNotEmpty
        ? _stringValue(profile['phone'])
        : _stringValue(authUser.phone);

    final email = _stringValue(profile['email']).isNotEmpty
        ? _stringValue(profile['email'])
        : _stringValue(authUser.email);

    final city = _stringValue(profile['city']).isNotEmpty
        ? _stringValue(profile['city'])
        : 'Нижневартовск';

    return AuthUser(
      id: userId,
      displayName: displayName.isNotEmpty ? displayName : 'Пользователь',
      phone: phone,
      email: email,
      city: city,
      role: role,
      permissions: RolePermissions.forRole(role),
    );
  }

  static UserRole _parseRole(dynamic value) {
    final raw = value?.toString().trim().toLowerCase();

    switch (raw) {
      case 'owner':
        return UserRole.owner;

      case 'admin':
        return UserRole.admin;

      case 'manager':
        return UserRole.manager;

      case 'seller':
        return UserRole.seller;

      case 'baker':
        return UserRole.baker;

      case 'pastry_chef':
      case 'pastrychef':
      case 'pastry-chef':
        return UserRole.pastryChef;

      case 'customer':
      default:
        return UserRole.customer;
    }
  }

  static String _stringValue(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static String _buildDisplayName({
    required String firstName,
    required String lastName,
  }) {
    final parts = <String>[
      firstName,
      lastName,
    ].where((item) => item.isNotEmpty).toList();

    return parts.join(' ');
  }
}

/// Матрица прав приложения.
///
/// Роли соответствуют public.profiles.role.
class RolePermissions {
  static Set<Permission> forRole(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return Permission.values.toSet();

      case UserRole.admin:
        return {
          Permission.viewDashboard,
          Permission.viewOrders,
          Permission.manageOrders,
          Permission.viewProducts,
          Permission.manageProducts,
          Permission.managePrices,
          Permission.viewToday,
          Permission.manageToday,
          Permission.viewProduction,
          Permission.manageProduction,
          Permission.viewStock,
          Permission.manageStock,
          Permission.viewCustomers,
          Permission.manageLoyalty,
          Permission.viewAnalytics,
          Permission.manageCommunications,
          Permission.viewEmployees,
          Permission.viewStores,
          Permission.manageIntegrations,
        };

      case UserRole.manager:
        return {
          Permission.viewDashboard,
          Permission.viewOrders,
          Permission.manageOrders,
          Permission.viewProducts,
          Permission.manageProducts,
          Permission.managePrices,
          Permission.viewToday,
          Permission.manageToday,
          Permission.viewProduction,
          Permission.manageProduction,
          Permission.viewStock,
          Permission.manageStock,
          Permission.viewCustomers,
          Permission.viewAnalytics,
          Permission.manageCommunications,
        };

      case UserRole.seller:
        return {
          Permission.viewDashboard,
          Permission.viewOrders,
          Permission.manageOrders,
          Permission.viewProducts,
          Permission.viewToday,
          Permission.viewStock,
        };

      case UserRole.baker:
      case UserRole.pastryChef:
        return {
          Permission.viewDashboard,
          Permission.viewProduction,
          Permission.manageProduction,
          Permission.viewStock,
          Permission.manageStock,
          Permission.viewToday,
        };

      case UserRole.customer:
        return {};
    }
  }
}

/// Реальная авторизация через Supabase.
///
/// Схема:
///
///                  ┌──────────────┐
///                  │ Supabase Auth│
///                  └──────┬───────┘
///                         │
///             ┌───────────┴───────────┐
///             │                       │
///          phone                  email
///             │                       │
///       ВХОД + пароль        ВОССТАНОВЛЕНИЕ
///             │                       │
///             └───────────┬───────────┘
///                         │
///                  public.profiles
///
/// SMS / OTP для текущей версии НЕ используется.
class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  AuthUser? _user;

  bool _isLoading = true;

  String? _errorMessage;

  bool _isPasswordRecovery = false;

  StreamSubscription<AuthState>? _authSubscription;

  AuthUser? get user => _user;

  bool get isLoggedIn => _user != null;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get isPasswordRecovery => _isPasswordRecovery;

  String get displayName => _user?.displayName ?? '';

  String get phone => _user?.phone ?? '';

  String get email => _user?.email ?? '';

  String get city => _user?.city ?? '';

  UserRole? get role => _user?.role;

  bool get canAccessAdmin => _user?.canAccessAdmin ?? false;

  bool hasPermission(Permission permission) {
    return _user?.hasPermission(permission) ?? false;
  }

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================

  /// Инициализация AuthProvider.
  ///
  /// Восстанавливает существующую Supabase-сессию.
  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;

    try {
      // В supabase_flutter 2.x восстановление сессии может завершиться
      // уже после Supabase.initialize(). Поэтому сначала подписываемся
      // на auth-события, а затем проверяем currentSession.
      //
      // Если currentSession уже доступна — используем её сразу.
      // Если ещё нет — ждём initialSession.

      final initialSessionCompleter = Completer<void>();
      var initialSessionHandled = false;

      _authSubscription ??= _supabase.auth.onAuthStateChange.listen(
        (AuthState data) async {
          final event = data.event;
          final session = data.session;

          debugPrint(
            '[AUTH] event=$event session=${session?.user.id ?? "null"}',
          );

          // -------------------------------------------------------------------
          // ПЕРВИЧНОЕ ВОССТАНОВЛЕНИЕ СЕССИИ
          // -------------------------------------------------------------------
          if (event == AuthChangeEvent.initialSession) {
            try {
              if (session != null) {
                await _loadUserProfile(session.user);
              } else {
                _user = null;
              }
            } finally {
              if (!initialSessionHandled) {
                initialSessionHandled = true;
                if (!initialSessionCompleter.isCompleted) {
                  initialSessionCompleter.complete();
                }
              }
            }
            return;
          }

          // -------------------------------------------------------------------
          // ВЫХОД
          // -------------------------------------------------------------------
          if (event == AuthChangeEvent.signedOut) {
            _user = null;
            _isPasswordRecovery = false;
            _errorMessage = null;
            _isLoading = false;

            notifyListeners();
            return;
          }

          // -------------------------------------------------------------------
          // ВОССТАНОВЛЕНИЕ ПАРОЛЯ
          // -------------------------------------------------------------------
          if (event == AuthChangeEvent.passwordRecovery) {
            _isPasswordRecovery = true;
            _errorMessage = null;

            if (session != null) {
              await _loadUserProfile(session.user);
            } else {
              notifyListeners();
            }

            return;
          }

          // -------------------------------------------------------------------
          // ОБЫЧНАЯ АВТОРИЗАЦИЯ
          // -------------------------------------------------------------------
          if (event == AuthChangeEvent.signedIn ||
              event == AuthChangeEvent.tokenRefreshed ||
              event == AuthChangeEvent.userUpdated) {
            if (session != null) {
              await _loadUserProfile(session.user);
            }
          }

          // userDeleted сейчас не обрабатываем.
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('[AUTH] stream error: $error');
          debugPrint('$stackTrace');

          if (!initialSessionHandled &&
              !initialSessionCompleter.isCompleted) {
            initialSessionCompleter.complete();
          }
        },
      );

      // После установки listener ещё раз проверяем currentSession.
      // Это закрывает race condition между установкой listener
      // и событием initialSession.
      final session = _supabase.auth.currentSession;

      if (session != null) {
        debugPrint(
          '[AUTH] currentSession available: ${session.user.id}',
        );

        if (_user == null || _user?.id != session.user.id) {
          await _loadUserProfile(session.user);
        }

        initialSessionHandled = true;

        if (!initialSessionCompleter.isCompleted) {
          initialSessionCompleter.complete();
        }
      } else {
        debugPrint('[AUTH] currentSession is null, waiting for initialSession');

        await initialSessionCompleter.future.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint(
              '[AUTH] initialSession timeout after 5 seconds',
            );
          },
        );

        // После initialSession ещё раз проверяем фактическую сессию.
        final restoredSession = _supabase.auth.currentSession;

        if (restoredSession != null &&
            (_user == null || _user?.id != restoredSession.user.id)) {
          debugPrint(
            '[AUTH] restored session found after initialSession: '
            '${restoredSession.user.id}',
          );

          await _loadUserProfile(restoredSession.user);
        }
      }
    } catch (error, stackTrace) {
      debugPrint('[AUTH] initialize error: $error');
      debugPrint('$stackTrace');

      _errorMessage = _friendlyError(error);
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // PROFILE
  // ===========================================================================

  /// Загружает профиль из public.profiles.
  Future<void> _loadUserProfile(User authUser) async {
    try {
      _isLoading = true;
      _errorMessage = null;

      notifyListeners();

      final response = await _supabase
          .from('profiles')
          .select('''
            id,
            first_name,
            last_name,
            display_name,
            phone,
            email,
            city,
            birth_date,
            role,
            is_active
          ''')
          .eq('id', authUser.id)
          .maybeSingle();

      if (response == null) {
        await _createMissingProfile(authUser);
        return;
      }

      final isActive = response['is_active'] != false;

      if (!isActive) {
        _user = null;
        _errorMessage = 'Профиль пользователя отключён.';
        return;
      }

      _user = AuthUser.fromProfile(
        userId: authUser.id,
        profile: response,
        authUser: authUser,
      );
    } catch (error) {
      _errorMessage = _friendlyError(error);
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Создаёт профиль, если database trigger
  /// handle_new_user() ещё не создал запись.
  Future<void> _createMissingProfile(User authUser) async {
    final metadata = authUser.userMetadata ?? <String, dynamic>{};

    final firstName = _string(metadata['first_name']);
    final lastName = _string(metadata['last_name']);
    final metadataDisplayName = _string(metadata['display_name']);

    final displayName = metadataDisplayName.isNotEmpty
        ? metadataDisplayName
        : _joinName(firstName, lastName);

    final metadataPhone = _string(metadata['phone']);

    final phone = metadataPhone.isNotEmpty
        ? metadataPhone
        : _string(authUser.phone);

    final metadataEmail = _string(metadata['email']);

    final email = metadataEmail.isNotEmpty
        ? metadataEmail
        : _string(authUser.email);

    final metadataCity = _string(metadata['city']);

    final city = metadataCity.isNotEmpty ? metadataCity : 'Нижневартовск';

    final birthDate = _string(metadata['birth_date']);

    await _supabase.from('profiles').upsert({
      'id': authUser.id,
      'first_name': firstName.isEmpty ? null : firstName,
      'last_name': lastName.isEmpty ? null : lastName,
      'display_name': displayName.isEmpty ? null : displayName,
      'phone': phone.isEmpty ? null : phone,
      'email': email.isEmpty ? null : email,
      'city': city,
      if (birthDate.isNotEmpty) 'birth_date': birthDate,
      'role': 'customer',
      'is_active': true,
    }, onConflict: 'id');

    final response = await _supabase
        .from('profiles')
        .select('''
          id,
          first_name,
          last_name,
          display_name,
          phone,
          email,
          city,
          birth_date,
          role,
          is_active
        ''')
        .eq('id', authUser.id)
        .maybeSingle();

    if (response == null) {
      throw Exception('Не удалось создать профиль пользователя.');
    }

    _user = AuthUser.fromProfile(
      userId: authUser.id,
      profile: response,
      authUser: authUser,
    );
  }

  // ===========================================================================
  // LOGIN
  // ===========================================================================

  /// Реальный вход:
  ///
  /// Телефон + пароль.
  ///
  /// Никаких SMS и OTP.
  /// Реальный вход пользователя.
  ///
  /// Пользователь вводит:
  ///   телефон + пароль
  ///
  /// Внутри приложения:
  ///   телефон
  ///      ↓
  ///   RPC get_auth_email_by_phone()
  ///      ↓
  ///   email
  ///      ↓
  ///   Supabase Auth
  ///
  /// Supabase Auth при этом использует email + password.
  Future<bool> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _isPasswordRecovery = false;

    notifyListeners();

    try {
      final normalizedPhone = normalizePhone(phone);

      if (normalizedPhone.isEmpty) {
        _errorMessage = 'Введите номер телефона.';
        return false;
      }

      if (!_isValidRussianPhone(normalizedPhone)) {
        _errorMessage = 'Введите корректный номер телефона.';
        return false;
      }

      if (password.isEmpty) {
        _errorMessage = 'Введите пароль.';
        return false;
      }

      // -----------------------------------------------------------------------
      // 1. Находим email по номеру телефона.
      //
      // Не читаем public.profiles напрямую из клиента.
      // Используем защищённую PostgreSQL RPC-функцию.
      // -----------------------------------------------------------------------

      final result = await _supabase.rpc(
        'get_auth_email_by_phone',
        params: {'p_phone': normalizedPhone},
      );

      if (result == null || result.toString().trim().isEmpty) {
        _errorMessage = 'Пользователь с таким номером телефона не найден.';
        return false;
      }

      final normalizedEmail = result.toString().trim().toLowerCase();

      // -----------------------------------------------------------------------
      // 2. Входим в Supabase Auth.
      // -----------------------------------------------------------------------

      final response = await _supabase.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );

      final user = response.user;

      if (user == null) {
        _errorMessage = 'Не удалось выполнить вход.';
        return false;
      }

      // -----------------------------------------------------------------------
      // 3. Загружаем профиль из public.profiles.
      // -----------------------------------------------------------------------

      await _loadUserProfile(user);

      if (_user == null) {
        return false;
      }

      return true;
    } on AuthException catch (error) {
      _errorMessage = _friendlyError(error);
      _user = null;
      return false;
    } on PostgrestException catch (error) {
      _errorMessage = 'Ошибка базы данных: ${error.message}';
      _user = null;
      return false;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      _user = null;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // REGISTRATION
  // ===========================================================================

  /// Регистрация нового клиента.
  ///
  /// Пользователь регистрируется с:
  ///   phone
  ///   email
  ///   password
  ///
  /// Supabase Auth использует email + password.
  ///
  /// Номер телефона хранится в public.profiles
  /// и используется как пользовательский логин.
  ///
  /// При входе:
  ///   phone → email → Supabase Auth.
  ///
  /// SMS / OTP НЕ используется.
  ///
  /// В Supabase создаётся один auth.users с:
  ///   email
  ///   password
  ///
  /// Телефон хранится в public.profiles.
  Future<bool> signUp({
    required String phone,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? displayName,
    String? city,
    DateTime? birthDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _isPasswordRecovery = false;

    notifyListeners();

    try {
      final normalizedPhone = normalizePhone(phone);
      final normalizedEmail = email.trim().toLowerCase();

      // -----------------------------------------------------------------------
      // PHONE
      // -----------------------------------------------------------------------

      if (normalizedPhone.isEmpty) {
        _errorMessage = 'Введите номер телефона.';
        return false;
      }

      if (!_isValidRussianPhone(normalizedPhone)) {
        _errorMessage = 'Введите корректный номер телефона.';
        return false;
      }

      // -----------------------------------------------------------------------
      // EMAIL
      // -----------------------------------------------------------------------

      if (normalizedEmail.isEmpty) {
        _errorMessage = 'Введите e-mail для восстановления пароля.';
        return false;
      }

      if (!_isValidEmail(normalizedEmail)) {
        _errorMessage = 'Введите корректный e-mail.';
        return false;
      }

      // -----------------------------------------------------------------------
      // PASSWORD
      // -----------------------------------------------------------------------

      if (password.length < 6) {
        _errorMessage = 'Пароль должен содержать минимум 6 символов.';
        return false;
      }

      // -----------------------------------------------------------------------
      // METADATA
      // -----------------------------------------------------------------------

      final metadata = <String, dynamic>{
        'email': normalizedEmail,
        'phone': normalizedPhone,
        'first_name': _nullableString(firstName),
        'last_name': _nullableString(lastName),
        'display_name': _nullableString(displayName),
        'city': _nullableString(city) ?? 'Нижневартовск',
        if (birthDate != null) 'birth_date': _formatDate(birthDate),
      };

      // -----------------------------------------------------------------------
      // SUPABASE AUTH
      // -----------------------------------------------------------------------
      //
      // ВАЖНО:
      //
      // Один пользователь получает сразу два идентификатора:
      //
      // phone -> вход
      // email -> восстановление
      //
      // SMS OTP здесь НЕ вызывается.
      //

      final response = await _supabase.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: metadata,
      );

      final user = response.user;

      if (user == null) {
        _errorMessage = 'Supabase не вернул созданного пользователя.';
        return false;
      }

      // -----------------------------------------------------------------------
      // SESSION
      // -----------------------------------------------------------------------

      if (response.session != null) {
        await _loadUserProfile(user);

        if (_user == null) {
          return false;
        }

        return true;
      }

      // -----------------------------------------------------------------------
      // EMAIL CONFIRMATION
      // -----------------------------------------------------------------------

      _user = null;

      _errorMessage =
          'Регистрация выполнена. Проверьте e-mail и подтвердите регистрацию.';

      return true;
    } on AuthException catch (error) {
      _errorMessage = _friendlyError(error);
      _user = null;

      return false;
    } on PostgrestException catch (error) {
      _errorMessage = 'Ошибка базы данных: ${error.message}';
      _user = null;

      return false;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      _user = null;

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // PASSWORD RECOVERY
  // ===========================================================================

  /// Отправляет письмо для восстановления пароля.
  ///
  /// Вход в приложение при этом осуществляется по телефону.
  ///
  /// E-mail используется только для восстановления.
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final normalizedEmail = email.trim().toLowerCase();

      if (normalizedEmail.isEmpty) {
        _errorMessage = 'Введите e-mail.';
        return false;
      }

      if (!_isValidEmail(normalizedEmail)) {
        _errorMessage = 'Введите корректный e-mail.';
        return false;
      }

      await _supabase.auth.resetPasswordForEmail(normalizedEmail);

      return true;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Обновляет пароль после перехода по ссылке из e-mail.
  Future<bool> updatePassword(String newPassword) async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      if (newPassword.length < 6) {
        _errorMessage = 'Пароль должен содержать минимум 6 символов.';
        return false;
      }

      await _supabase.auth.updateUser(UserAttributes(password: newPassword));

      _isPasswordRecovery = false;

      return true;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Завершает режим восстановления пароля.
  void clearPasswordRecovery() {
    _isPasswordRecovery = false;
    _errorMessage = null;
    notifyListeners();
  }

  // ===========================================================================
  // PROFILE UPDATE
  // ===========================================================================

  /// Обновляет данные профиля клиента.
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? displayName,
    String? phone,
    String? city,
    DateTime? birthDate,
  }) async {
    final current = _user;

    if (current == null) {
      _errorMessage = 'Пользователь не авторизован.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final data = <String, dynamic>{};

      if (firstName != null) {
        data['first_name'] = firstName.trim();
      }

      if (lastName != null) {
        data['last_name'] = lastName.trim();
      }

      if (displayName != null) {
        data['display_name'] = displayName.trim();
      }

      if (phone != null) {
        final normalizedPhone = normalizePhone(phone);

        if (!_isValidRussianPhone(normalizedPhone)) {
          _errorMessage = 'Введите корректный номер телефона.';
          return false;
        }

        data['phone'] = normalizedPhone;
      }

      if (city != null) {
        data['city'] = city.trim();
      }

      if (birthDate != null) {
        data['birth_date'] = _formatDate(birthDate);
      }

      if (data.isNotEmpty) {
        await _supabase.from('profiles').update(data).eq('id', current.id);
      }

      final authUser = _supabase.auth.currentUser;

      if (authUser != null) {
        await _loadUserProfile(authUser);
      }

      return _user != null;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // LEGACY COMPATIBILITY
  // ===========================================================================

  /// Совместимость со старым кодом.
  Future<void> markLoggedIn({String displayName = 'Пользователь'}) async {
    final authUser = _supabase.auth.currentUser;

    if (authUser == null) {
      _user = null;
      _errorMessage = 'Пользователь не авторизован.';
      notifyListeners();
      return;
    }

    await _loadUserProfile(authUser);
  }

  /// Реальный выход из Supabase.
  Future<void> signOut() async {
    _isLoading = true;
    _errorMessage = null;
    _isPasswordRecovery = false;

    notifyListeners();

    try {
      await _supabase.auth.signOut();

      _user = null;
    } catch (error) {
      _errorMessage = _friendlyError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Совместимость со старым ProfileScreen.
  Future<void> logout() => signOut();

  /// Старый demo-вход полностью отключён.
  Future<void> signInMock({
    UserRole role = UserRole.owner,
    String id = 'demo-owner',
    String displayName = 'Сергей',
    String phone = '+7 900 000-00-00',
  }) async {
    final authUser = _supabase.auth.currentUser;

    if (authUser == null) {
      _user = null;
      _errorMessage =
          'Демо-вход отключён. Используйте реальную авторизацию Supabase.';
      notifyListeners();
      return;
    }

    await _loadUserProfile(authUser);
  }

  /// Старое переключение mock-роли отключено.
  Future<void> switchMockRole(UserRole role) async {
    final authUser = _supabase.auth.currentUser;

    if (authUser == null) {
      _user = null;
      notifyListeners();
      return;
    }

    await _loadUserProfile(authUser);
  }

  /// Перечитать текущий профиль.
  Future<void> refreshUser() async {
    final authUser = _supabase.auth.currentUser;

    if (authUser == null) {
      _user = null;
      notifyListeners();
      return;
    }

    await _loadUserProfile(authUser);
  }

  /// Очищает локальную ошибку.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ===========================================================================
  // PHONE HELPERS
  // ===========================================================================

  /// Приводит российский номер к формату E.164:
  ///
  /// +7 900 123-45-67
  ///        ↓
  /// +79001234567
  static String normalizePhone(String value) {
    var digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      return '';
    }

    if (digits.startsWith('8') && digits.length == 11) {
      digits = '7${digits.substring(1)}';
    }

    if (digits.startsWith('7') && digits.length == 11) {
      return '+$digits';
    }

    if (digits.length == 10) {
      return '+7$digits';
    }

    if (value.trim().startsWith('+') && digits.isNotEmpty) {
      return '+$digits';
    }

    return '+$digits';
  }

  static bool _isValidRussianPhone(String phone) {
    return RegExp(r'^\+7\d{10}$').hasMatch(phone);
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  static String _string(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static String? _nullableString(String? value) {
    final normalized = value?.trim();

    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  static String _joinName(String firstName, String lastName) {
    return <String>[
      firstName,
      lastName,
    ].where((value) => value.isNotEmpty).join(' ');
  }

  static String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  static bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  // ===========================================================================
  // FRIENDLY ERRORS
  // ===========================================================================

  static String _friendlyError(Object error) {
    if (error is AuthException) {
      final message = error.message.toLowerCase();

      if (message.contains('invalid login credentials')) {
        return 'Неверный номер телефона или пароль.';
      }

      if (message.contains('invalid login')) {
        return 'Неверный номер телефона или пароль.';
      }

      if (message.contains('phone provider is disabled')) {
        return 'Авторизация по телефону отключена в Supabase.';
      }

      if (message.contains('phone') && message.contains('disabled')) {
        return 'Авторизация по телефону отключена в Supabase.';
      }

      if (message.contains('email not confirmed')) {
        return 'Подтвердите e-mail перед входом.';
      }

      if (message.contains('user already registered')) {
        return 'Пользователь с таким телефоном или e-mail уже зарегистрирован.';
      }

      if (message.contains('already registered')) {
        return 'Пользователь с таким телефоном или e-mail уже зарегистрирован.';
      }

      if (message.contains('password should be at least')) {
        return 'Пароль слишком короткий.';
      }

      if (message.contains('invalid email')) {
        return 'Введите корректный e-mail.';
      }

      if (message.contains('invalid phone')) {
        return 'Введите корректный номер телефона.';
      }

      if (message.contains('signup is disabled')) {
        return 'Регистрация пользователей отключена в Supabase.';
      }

      if (message.contains('rate limit')) {
        return 'Слишком много попыток. Попробуйте немного позже.';
      }

      return error.message;
    }

    if (error is PostgrestException) {
      return 'Ошибка базы данных: ${error.message}';
    }

    return 'Не удалось выполнить операцию. Попробуйте ещё раз.';
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
