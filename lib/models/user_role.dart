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
