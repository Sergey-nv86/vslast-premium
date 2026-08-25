import 'package:flutter/material.dart';
import 'admin_orders_screen.dart';

void openAdminOrders(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const AdminOrdersScreen()));
}
