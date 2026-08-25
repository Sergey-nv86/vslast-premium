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
