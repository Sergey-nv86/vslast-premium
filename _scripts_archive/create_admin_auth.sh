#!/bin/bash
set -e

MODEL_DIR="lib/models"
PROVIDER_DIR="lib/providers"
mkdir -p "$MODEL_DIR" "$PROVIDER_DIR"

if [ -f "$PROVIDER_DIR/auth_provider.dart" ]; then
  cp "$PROVIDER_DIR/auth_provider.dart" "$PROVIDER_DIR/auth_provider.dart.backup_before_admin_roles"
fi

cat > "$MODEL_DIR/user_role.dart" <<'DART'
enum UserRole {
  owner,
  admin,
  manager,
  seller,
  baker,
  pastryChef,
  customer,
}

extension UserRoleX on UserRole {
  String get value => switch (this) {
    UserRole.owner => 'owner',
    UserRole.admin => 'admin',
    UserRole.manager => 'manager',
    UserRole.seller => 'seller',
    UserRole.baker => 'baker',
    UserRole.pastryChef => 'pastry_chef',
    UserRole.customer => 'customer',
  };

  String get title => switch (this) {
    UserRole.owner => 'Владелец',
    UserRole.admin => 'Администратор',
    UserRole.manager => 'Управляющий',
    UserRole.seller => 'Продавец',
    UserRole.baker => 'Пекарь',
    UserRole.pastryChef => 'Кондитер',
    UserRole.customer => 'Клиент',
  };

  bool get canAccessAdmin => this != UserRole.customer;
}
DART

cat > "$MODEL_DIR/permission.dart" <<'DART'
enum Permission {
  viewDashboard,
  viewOrders,
  manageOrders,
  viewProducts,
  manageProducts,
  managePrices,
  viewToday,
  manageToday,
  viewProduction,
  manageProduction,
  viewStock,
  manageStock,
  viewCustomers,
  manageLoyalty,
  viewAnalytics,
  manageCommunications,
  viewEmployees,
  manageEmployees,
  viewStores,
  manageIntegrations,
  manageSettings,
}

extension PermissionX on Permission {
  String get value => name;
}
DART

cat > "$PROVIDER_DIR/auth_provider.dart" <<'DART'
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
DART

echo "Созданы UserRole, Permission и AuthProvider."
echo "Запусти: flutter analyze lib/models/user_role.dart lib/models/permission.dart lib/providers/auth_provider.dart"
echo "Предыдущий auth_provider.dart сохранён как backup_before_admin_roles."
