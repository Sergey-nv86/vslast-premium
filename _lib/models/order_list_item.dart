/// Статус заказа в списке «Мои заказы».
enum OrderStatus {
  /// Заказ отправлен, администратор ещё не подтвердил.
  processing,

  /// Администратор подтвердил, ожидается оплата.
  awaitingPayment,

  /// Заказ полностью выполнен (получен клиентом).
  completed,
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.processing:
        return 'В обработке';
      case OrderStatus.awaitingPayment:
        return 'Подтвержден';
      case OrderStatus.completed:
        return 'Исполнен';
    }
  }
}

/// Один заказ в списке «Мои заказы» — облегчённое представление истории
/// заказов (для полной информации ведёт на детальный экран заказа).
class OrderListItem {
  final int number;
  final String title;
  final OrderStatus status;
  final DateTime placedAt;
  final int itemsCount;
  final int totalPrice;
  final String statusDescription;
  final String imageUrl;

  const OrderListItem({
    required this.number,
    required this.title,
    required this.status,
    required this.placedAt,
    required this.itemsCount,
    required this.totalPrice,
    required this.statusDescription,
    required this.imageUrl,
  });
}
