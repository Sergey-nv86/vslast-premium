import 'package:flutter/foundation.dart';
import '../models/permission.dart';
import '../models/user_role.dart';

class AuthUser {
  final String id;
  final String displayName;
  final String phone;
  final UserRole role;
  final Set<Permission> permissions;

  const AuthUser({
    required this.id,
    required this.displayName,
    required this.phone,
    required this.role,
    required this.permissions,
  });

  bool hasPermission(Permission permission) => permissions.contains(permission);
  bool get canAccessAdmin => role.canAccessAdmin;
}

class RolePermissions {
  static Set<Permission> forRole(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return Permission.values.toSet();
      case UserRole.admin:
        return {
          Permission.viewDashboard, Permission.viewOrders, Permission.manageOrders,
          Permission.viewProducts, Permission.manageProducts, Permission.managePrices,
          Permission.viewToday, Permission.manageToday, Permission.viewProduction,
          Permission.manageProduction, Permission.viewStock, Permission.manageStock,
          Permission.viewCustomers, Permission.manageLoyalty, Permission.viewAnalytics,
          Permission.manageCommunications, Permission.viewEmployees, Permission.viewStores,
          Permission.manageIntegrations,
        };
      case UserRole.manager:
        return {
          Permission.viewDashboard, Permission.viewOrders, Permission.manageOrders,
          Permission.viewProducts, Permission.manageProducts, Permission.managePrices,
          Permission.viewToday, Permission.manageToday, Permission.viewProduction,
          Permission.manageProduction, Permission.viewStock, Permission.manageStock,
          Permission.viewCustomers, Permission.viewAnalytics,
          Permission.manageCommunications,
        };
      case UserRole.seller:
        return {
          Permission.viewDashboard, Permission.viewOrders, Permission.manageOrders,
          Permission.viewProducts, Permission.viewToday, Permission.viewStock,
        };
      case UserRole.baker:
      case UserRole.pastryChef:
        return {
          Permission.viewDashboard, Permission.viewProduction,
          Permission.manageProduction, Permission.viewStock,
          Permission.manageStock, Permission.viewToday,
        };
      case UserRole.customer:
        return {};
    }
  }
}

class AuthProvider extends ChangeNotifier {
  AuthUser? _user;
  bool _isLoading = false;

  AuthUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String get displayName => _user?.displayName ?? '';
  UserRole? get role => _user?.role;
  bool get canAccessAdmin => _user?.canAccessAdmin ?? false;

  bool hasPermission(Permission permission) =>
      _user?.hasPermission(permission) ?? false;

  Future<void> signInMock({
    UserRole role = UserRole.owner,
    String id = 'demo-owner',
    String displayName = 'Сергей',
    String phone = '+7 900 000-00-00',
  }) async {
    _isLoading = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _user = AuthUser(
      id: id,
      displayName: displayName,
      phone: phone,
      role: role,
      permissions: RolePermissions.forRole(role),
    );
    _isLoading = false;
    notifyListeners();
  }

  /// Compatibility method for the existing client auth flow.
  /// Replace with real authentication/session restoration when backend auth is connected.
  void markLoggedIn({String displayName = 'Пользователь'}) {
    if (_user != null) return;
    _user = AuthUser(
      id: 'demo-customer',
      displayName: displayName,
      phone: '',
      role: UserRole.customer,
      permissions: RolePermissions.forRole(UserRole.customer),
    );
    notifyListeners();
  }

  /// Compatibility alias used by the existing profile screen.
  Future<void> logout() => signOut();

  Future<void> signOut() async {
    _user = null;
    notifyListeners();
  }

  Future<void> switchMockRole(UserRole role) {
    final current = _user;
    return signInMock(
      role: role,
      id: current?.id ?? 'demo-user',
      displayName: current?.displayName ?? 'Тестовый пользователь',
      phone: current?.phone ?? '+7 900 000-00-00',
    );
  }
}
