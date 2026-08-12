import '../models/order_list_item.dart';

/// Мок-данные для экрана «Мои заказы».
/// TODO: заменить на загрузку истории заказов пользователя с бэкенда.
final List<OrderListItem> mockOrders = [
  OrderListItem(
    number: 1287,
    title: 'Хлеб деревенский + Чиабатта',
    status: OrderStatus.processing,
    placedAt: DateTime(2025, 5, 18, 10, 32),
    itemsCount: 2,
    totalPrice: 690,
    statusDescription: 'Заказ отправлен администратору.\nОжидает подтверждения.',
    imageUrl: 'assets/images/bread_country.jpg',
  ),
  OrderListItem(
    number: 1286,
    title: 'Торт Фисташковый',
    status: OrderStatus.awaitingPayment,
    placedAt: DateTime(2025, 5, 17, 16, 45),
    itemsCount: 1,
    totalPrice: 3200,
    statusDescription: 'Заказ подтвержден.\nОжидается оплата по СБП.',
    imageUrl: 'assets/images/cake_crown_bordeaux.jpg',
  ),
  OrderListItem(
    number: 1285,
    title: 'Круассаны сливочные',
    status: OrderStatus.completed,
    placedAt: DateTime(2025, 5, 15, 9, 21),
    itemsCount: 3,
    totalPrice: 870,
    statusDescription: 'Спасибо за покупку!',
    imageUrl: 'assets/images/bread_french.jpg',
  ),
];
