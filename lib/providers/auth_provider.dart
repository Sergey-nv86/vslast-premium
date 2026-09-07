import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/permission.dart';
import '../models/user_role.dart';
import '../services/client_identity_service.dart';

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

  bool hasPermission(Permission permission) => permissions.contains(permission);

  bool get canAccessAdmin => role.canAccessAdmin;

  factory AuthUser.fromProfile({
    required String userId,
    required Map<String, dynamic> profile,
    required User authUser,
  }) {
    final role = _parseRole(profile['role']);
    final displayName = _stringValue(profile['display_name']).isNotEmpty
        ? _stringValue(profile['display_name'])
        : _buildDisplayName(
            firstName: _stringValue(profile['first_name']),
            lastName: _stringValue(profile['last_name']),
          );

    final authEmail = _stringValue(authUser.email);
    final profileEmail = _stringValue(profile['email']);
    final email = authEmail.endsWith('@auth.vslast.internal')
        ? ''
        : (profileEmail.isNotEmpty ? profileEmail : authEmail);

    final phone = _stringValue(profile['phone']).isNotEmpty
        ? _stringValue(profile['phone'])
        : _stringValue(authUser.phone);

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
    switch (value?.toString().trim().toLowerCase()) {
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

  static String _stringValue(dynamic value) => value?.toString().trim() ?? '';

  static String _buildDisplayName({
    required String firstName,
    required String lastName,
  }) {
    return <String>[firstName, lastName]
        .where((value) => value.isNotEmpty)
        .join(' ');
  }
}

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

/// Central authentication provider.
///
/// Customer login is now based on the permanent C-xxxxxx client ID.
/// Supabase Auth keeps an internal synthetic email only as an implementation
/// detail. The client never asks for or displays that email during auth.
class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  AuthUser? _user;
  String? _clientId;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isPasswordRecovery = false;
  StreamSubscription<AuthState>? _authSubscription;

  AuthUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isPasswordRecovery => _isPasswordRecovery;
  String get clientId => _clientId ?? '';
  String get displayName => _user?.displayName ?? '';
  String get phone => _user?.phone ?? '';
  String get email => _user?.email ?? '';
  String get city => _user?.city ?? '';
  UserRole? get role => _user?.role;
  bool get canAccessAdmin => _user?.canAccessAdmin ?? false;

  bool hasPermission(Permission permission) =>
      _user?.hasPermission(permission) ?? false;

  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;

    try {
      final completer = Completer<void>();
      var initialHandled = false;

      _authSubscription ??= _supabase.auth.onAuthStateChange.listen(
        (data) async {
          final session = data.session;

          if (data.event == AuthChangeEvent.initialSession) {
            if (session != null) {
              await _loadUserProfile(session.user);
            } else {
              _clearIdentity();
            }
            initialHandled = true;
            if (!completer.isCompleted) completer.complete();
            return;
          }

          if (data.event == AuthChangeEvent.signedOut) {
            _clearIdentity();
            _isPasswordRecovery = false;
            _errorMessage = null;
            _isLoading = false;
            notifyListeners();
            return;
          }

          if (data.event == AuthChangeEvent.passwordRecovery) {
            _isPasswordRecovery = true;
            if (session != null) await _loadUserProfile(session.user);
            return;
          }

          if (session != null &&
              (data.event == AuthChangeEvent.signedIn ||
                  data.event == AuthChangeEvent.tokenRefreshed ||
                  data.event == AuthChangeEvent.userUpdated)) {
            await _loadUserProfile(session.user);
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('[AUTH] stream error: $error');
          debugPrint('$stackTrace');
          if (!initialHandled && !completer.isCompleted) completer.complete();
        },
      );

      final current = _supabase.auth.currentSession;
      if (current != null) {
        await _loadUserProfile(current.user);
        initialHandled = true;
        if (!completer.isCompleted) completer.complete();
      } else {
        await completer.future.timeout(
          const Duration(seconds: 5),
          onTimeout: () {},
        );
        final restored = _supabase.auth.currentSession;
        if (restored != null) await _loadUserProfile(restored.user);
      }
    } catch (error, stackTrace) {
      debugPrint('[AUTH] initialize error: $error');
      debugPrint('$stackTrace');
      _clearIdentity();
      _errorMessage = _friendlyError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
      } else if (response['is_active'] == false) {
        _clearIdentity();
        _errorMessage = 'Профиль пользователя отключён.';
        return;
      } else {
        _user = AuthUser.fromProfile(
          userId: authUser.id,
          profile: response,
          authUser: authUser,
        );
      }

      _clientId = await ClientIdentityService.instance.ensureClientId();
    } catch (error) {
      _clearIdentity();
      _errorMessage = _friendlyError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _createMissingProfile(User authUser) async {
    final metadata = authUser.userMetadata ?? <String, dynamic>{};
    await _supabase.from('profiles').upsert({
      'id': authUser.id,
      'first_name': _nullableString(metadata['first_name']?.toString()),
      'last_name': _nullableString(metadata['last_name']?.toString()),
      'display_name': _nullableString(metadata['display_name']?.toString()),
      'phone': _nullableString(metadata['phone']?.toString()),
      'email': _string(metadata['email']).isEmpty
          ? (authUser.email?.endsWith('@auth.vslast.internal') == true
              ? null
              : authUser.email)
          : _string(metadata['email']),
      'city': _string(metadata['city']).isEmpty
          ? 'Нижневартовск'
          : _string(metadata['city']),
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

  Future<bool> signInWithClientId({
    required String clientId,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _isPasswordRecovery = false;
    notifyListeners();

    try {
      final normalizedId = clientId.trim().toUpperCase();
      if (!RegExp(r'^C-\d{6}$').hasMatch(normalizedId)) {
        _errorMessage = 'Введите корректный ID клиента, например C-000123.';
        return false;
      }
      if (password.isEmpty) {
        _errorMessage = 'Введите пароль.';
        return false;
      }

      final response = await _supabase.functions.invoke(
        'client-auth',
        body: {
          'action': 'login',
          'client_id': normalizedId,
          'password': password,
        },
      );

      final data = _asMap(response.data);
      final accessToken = _string(data['access_token']);
      final refreshToken = _string(data['refresh_token']);

      if (accessToken.isEmpty || refreshToken.isEmpty) {
        _errorMessage = _string(data['error']).isNotEmpty
            ? _string(data['error'])
            : 'Неверный ID клиента или пароль.';
        return false;
      }

      final session = await _supabase.auth.setSession(
        refreshToken,
        accessToken: accessToken,
      );

      final user = session.user ?? _supabase.auth.currentUser;
      if (user == null) {
        _errorMessage = 'Не удалось восстановить авторизованную сессию.';
        return false;
      }

      await _loadUserProfile(user);
      return _user != null;
    } catch (error) {
      _user = null;
      _errorMessage = _friendlyError(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Backward-compatible name. New code should call signInWithClientId().
  Future<bool> signInWithPhone({
    required String phone,
    required String password,
  }) {
    return signInWithClientId(clientId: phone, password: password);
  }

  Future<bool> signUp({
    String? phone,
    String? email,
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
      if (password.length < 6) {
        _errorMessage = 'Пароль должен содержать минимум 6 символов.';
        return false;
      }

      final response = await _supabase.functions.invoke(
        'client-auth',
        body: {
          'action': 'register',
          'password': password,
        },
      );

      final data = _asMap(response.data);
      final accessToken = _string(data['access_token']);
      final refreshToken = _string(data['refresh_token']);
      final newClientId = _string(data['client_id']);

      if (accessToken.isEmpty || refreshToken.isEmpty || newClientId.isEmpty) {
        _errorMessage = _string(data['error']).isNotEmpty
            ? _string(data['error'])
            : 'Не удалось зарегистрировать клиента.';
        return false;
      }

      final session = await _supabase.auth.setSession(
        refreshToken,
        accessToken: accessToken,
      );

      final user = session.user ?? _supabase.auth.currentUser;
      if (user == null) {
        _errorMessage = 'Не удалось создать авторизованную сессию.';
        return false;
      }

      _clientId = newClientId;
      await _loadUserProfile(user);
      return _user != null;
    } catch (error) {
      _user = null;
      _errorMessage = _friendlyError(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Password recovery by e-mail is intentionally not part of the new
  /// client-ID-only registration flow. It will be restored after a profile
  /// e-mail is collected on the Russian infrastructure.
  Future<bool> resetPassword(String email) async {
    _errorMessage =
        'Восстановление по e-mail появится после добавления e-mail в профиле.';
    notifyListeners();
    return false;
  }

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

  void clearPasswordRecovery() {
    _isPasswordRecovery = false;
    _errorMessage = null;
    notifyListeners();
  }

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
      if (firstName != null) data['first_name'] = firstName.trim();
      if (lastName != null) data['last_name'] = lastName.trim();
      if (displayName != null) data['display_name'] = displayName.trim();
      if (phone != null) data['phone'] = normalizePhone(phone);
      if (city != null) data['city'] = city.trim();
      if (birthDate != null) data['birth_date'] = _formatDate(birthDate);

      if (data.isNotEmpty) {
        await _supabase.from('profiles').update(data).eq('id', current.id);
      }

      final authUser = _supabase.auth.currentUser;
      if (authUser != null) await _loadUserProfile(authUser);
      return _user != null;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markLoggedIn({String displayName = 'Пользователь'}) async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) {
      _clearIdentity();
      _errorMessage = 'Пользователь не авторизован.';
      notifyListeners();
      return;
    }
    await _loadUserProfile(authUser);
  }

  Future<void> signOut() async {
    _isLoading = true;
    _errorMessage = null;
    _isPasswordRecovery = false;
    notifyListeners();

    try {
      await _supabase.auth.signOut();
      _clearIdentity();
    } catch (error) {
      _errorMessage = _friendlyError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() => signOut();

  Future<void> signInMock({
    UserRole role = UserRole.owner,
    String id = 'demo-owner',
    String displayName = 'Сергей',
    String phone = '+7 900 000-00-00',
  }) async {
    await refreshUser();
  }

  Future<void> switchMockRole(UserRole role) async {
    await refreshUser();
  }

  Future<void> refreshUser() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) {
      _clearIdentity();
      notifyListeners();
      return;
    }
    await _loadUserProfile(authUser);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _clearIdentity() {
    _user = null;
    _clientId = null;
    ClientIdentityService.instance.clear();
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static String _string(dynamic value) => value?.toString().trim() ?? '';

  static String? _nullableString(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String normalizePhone(String value) {
    var digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    if (digits.startsWith('8') && digits.length == 11) {
      digits = '7${digits.substring(1)}';
    }
    if (digits.startsWith('7') && digits.length == 11) return '+$digits';
    if (digits.length == 10) return '+7$digits';
    return '+$digits';
  }

  static String _friendlyError(Object error) {
    if (error is AuthException) {
      final message = error.message.toLowerCase();
      if (message.contains('invalid login')) {
        return 'Неверный ID клиента или пароль.';
      }
      if (message.contains('rate limit')) {
        return 'Слишком много попыток. Попробуйте немного позже.';
      }
      if (message.contains('password should be at least')) {
        return 'Пароль слишком короткий.';
      }
      return error.message;
    }
    if (error is FunctionException) {
      final details = error.details;
      if (details is Map && _string(details['error']).isNotEmpty) {
        return _string(details['error']);
      }
      return 'Не удалось выполнить операцию авторизации.';
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
