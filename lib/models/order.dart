import 'product.dart';

/// Способ получения заказа.
enum DeliveryMethod { pickup, delivery }

extension DeliveryMethodX on DeliveryMethod {
  String get title {
    switch (this) {
      case DeliveryMethod.pickup:
        return 'Самовывоз';
      case DeliveryMethod.delivery:
        return 'Доставка';
    }
  }

  String get subtitle {
    switch (this) {
      case DeliveryMethod.pickup:
        return 'Заберу в пекарне';
      case DeliveryMethod.delivery:
        return 'Привезём по адресу';
    }
  }
}

/// Способ оплаты заказа.
enum PaymentMethod { onlineSbp, cash }

extension PaymentMethodX on PaymentMethod {
  String get title {
    switch (this) {
      case PaymentMethod.onlineSbp:
        return 'Онлайн оплата по СБП';
      case PaymentMethod.cash:
        return 'Оплата при получении';
    }
  }

  String get subtitle {
    switch (this) {
      case PaymentMethod.onlineSbp:
        return 'Администратор выставит QR-код для оплаты';
      case PaymentMethod.cash:
        return 'Наличными или картой';
    }
  }
}

/// Снимок одной позиции заказа — товар и его количество зафиксированы
/// на момент оформления и не меняются, даже если корзина после этого
/// очищается или меняется.
class OrderItemSnapshot {
  final Product product;
  final int quantity;

  const OrderItemSnapshot({required this.product, required this.quantity});

  int get lineTotal => product.price * quantity;
}

/// Полный снимок оформленного заказа для экрана «Подтверждение заказа».
class OrderSummary {
  final int orderNumber;
  final DateTime createdAt;
  final List<OrderItemSnapshot> items;
  final String? comment;
  final DeliveryMethod deliveryMethod;
  final DateTime pickupDate;
  final String pickupTimeSlot;
  final PaymentMethod paymentMethod;

  /// Адрес доставки — только для DeliveryMethod.delivery, введён на
  /// DeliveryAddressScreen. Для самовывоза всегда null.
  final String? deliveryAddress;

  /// null — стоимость доставки ещё не рассчитана ("Уточняется"),
  /// 0 — бесплатно (например, самовывоз).
  final int? deliveryCost;

  const OrderSummary({
    required this.orderNumber,
    required this.createdAt,
    required this.items,
    this.comment,
    required this.deliveryMethod,
    required this.pickupDate,
    required this.pickupTimeSlot,
    required this.paymentMethod,
    this.deliveryAddress,
    this.deliveryCost = 0,
  });

  int get itemsCount => items.fold(0, (sum, i) => sum + i.quantity);
  int get itemsTotal => items.fold(0, (sum, i) => sum + i.lineTotal);
  int get total => itemsTotal + (deliveryCost ?? 0);
}
