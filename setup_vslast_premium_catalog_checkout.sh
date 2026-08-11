#!/bin/bash
set -e
#
# Устанавливает/обновляет экраны «Каталог», «Корзина», «Оформление заказа»,
# «Подтверждение заказа», «Мои заказы» и «Вход/Регистрация» в vslast_premium.
#
# ЗАПУСК: из корня проекта
#   cd /Users/sukolesnikov/Projects/vslast_premium
#   bash setup_vslast_premium_catalog_checkout.sh
#
# Создаёт папки lib/{models,data,providers,theme,utils,widgets,screens}
# (если их ещё нет) и полностью перезаписывает файлы ниже.

mkdir -p lib/models
cat > lib/models/product.dart << 'DARTEOF'
/// Категории каталога — соответствуют вкладкам фильтра.
enum ProductCategory { bread, pastry, cakes, desserts }

extension ProductCategoryX on ProductCategory {
  String get label {
    switch (this) {
      case ProductCategory.bread:
        return 'Хлеб';
      case ProductCategory.pastry:
        return 'Выпечка';
      case ProductCategory.cakes:
        return 'Торты';
      case ProductCategory.desserts:
        return 'Десерты';
    }
  }
}

/// Бейдж в левом верхнем углу карточки товара.
enum ProductBadge { hit, newItem, promo }

extension ProductBadgeX on ProductBadge {
  String get label {
    switch (this) {
      case ProductBadge.hit:
        return 'ХИТ';
      case ProductBadge.newItem:
        return 'НОВИНКА';
      case ProductBadge.promo:
        return 'АКЦИЯ';
    }
  }
}

class Product {
  final String id;
  final String name;
  final int price;
  final String imageUrl;
  final ProductCategory category;
  final ProductBadge? badge;

  /// Если false — вместо цены и кнопки "+" показывается кнопка "Предзаказ".
  final bool inStock;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.badge,
    this.inStock = true,
  });

  @override
  bool operator ==(Object other) => other is Product && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
DARTEOF
echo 'lib/models/product.dart — записан'

mkdir -p lib/models
cat > lib/models/order.dart << 'DARTEOF'
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
    this.deliveryCost = 0,
  });

  int get itemsCount => items.fold(0, (sum, i) => sum + i.quantity);
  int get itemsTotal => items.fold(0, (sum, i) => sum + i.lineTotal);
  int get total => itemsTotal + (deliveryCost ?? 0);
}
DARTEOF
echo 'lib/models/order.dart — записан'

mkdir -p lib/models
cat > lib/models/order_list_item.dart << 'DARTEOF'
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
DARTEOF
echo 'lib/models/order_list_item.dart — записан'

mkdir -p lib/data
cat > lib/data/mock_products.dart << 'DARTEOF'
import '../models/product.dart';

/// Мок-данные, соответствующие утверждённому макету экрана «Каталог».
/// TODO: заменить на загрузку из API/локальной БД проекта.
///
/// imageUrl указывает на реальные файлы из вашей папки images/ —
/// подобраны по смыслу названия, при необходимости поменяйте местами.
/// Убедитесь, что в pubspec.yaml проекта эта папка объявлена как asset:
///   flutter:
///     assets:
///       - assets/images/
/// Если ваши файлы физически лежат не в assets/images/, а в другом месте
/// (например просто images/) — поправьте префикс пути ниже под свой проект.
final List<Product> mockProducts = [
  const Product(
    id: 'bread_village_sourdough',
    name: 'Хлеб деревенский на закваске',
    price: 390,
    imageUrl: 'assets/images/bread_country.jpg',
    category: ProductCategory.bread,
    badge: ProductBadge.hit,
  ),
  const Product(
    id: 'baguette_classic',
    name: 'Багет классический',
    price: 220,
    imageUrl: 'assets/images/bread_classic.jpg',
    category: ProductCategory.bread,
  ),
  const Product(
    id: 'croissant_butter',
    name: 'Круассан сливочный',
    price: 290,
    imageUrl: 'assets/images/bread_french.jpg',
    category: ProductCategory.pastry,
    badge: ProductBadge.newItem,
  ),
  const Product(
    id: 'brioche',
    name: 'Бриошь',
    price: 290,
    imageUrl: 'assets/images/bread_finnish.jpg',
    category: ProductCategory.pastry,
  ),
  const Product(
    id: 'napoleon_cake',
    name: 'Наполеон',
    price: 420,
    imageUrl: 'assets/images/cake_signature.jpg',
    category: ProductCategory.cakes,
    badge: ProductBadge.hit,
  ),
  const Product(
    id: 'cheesecake_cherry',
    name: 'Чизкейк с вишней',
    price: 250,
    imageUrl: 'assets/images/dessert_tart.jpg',
    category: ProductCategory.desserts,
    badge: ProductBadge.newItem,
  ),
  const Product(
    id: 'ciabatta',
    name: 'Чиабатта',
    price: 450,
    imageUrl: 'assets/images/bread_chiabatta.jpg',
    category: ProductCategory.bread,
  ),
  const Product(
    id: 'grain_bun',
    name: 'Булочка зерновая',
    price: 120,
    imageUrl: 'assets/images/bread_sourdough_01.jpg',
    category: ProductCategory.pastry,
    badge: ProductBadge.promo,
  ),
  const Product(
    id: 'eclair_chocolate',
    name: 'Эклер шоколадный',
    price: 210,
    imageUrl: 'assets/images/dessert_eclair.jpg',
    category: ProductCategory.desserts,
  ),
];
DARTEOF
echo 'lib/data/mock_products.dart — записан'

mkdir -p lib/data
cat > lib/data/mock_orders.dart << 'DARTEOF'
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
DARTEOF
echo 'lib/data/mock_orders.dart — записан'

mkdir -p lib/providers
cat > lib/providers/cart_provider.dart << 'DARTEOF'
import 'package:flutter/foundation.dart';
import '../models/product.dart';

/// Управляет содержимым корзины. Подключается через
/// ChangeNotifierProvider на уровне приложения (см. README_INTEGRATION.md),
/// чтобы количество товаров было доступно и на экране «Каталог»,
/// и в бейдже нижней панели навигации, и на экране «Корзина».
class CartProvider extends ChangeNotifier {
  final Map<Product, int> _items = {};

  Map<Product, int> get items => Map.unmodifiable(_items);

  int quantityOf(Product product) => _items[product] ?? 0;

  /// Суммарное количество единиц товара в корзине (для бейджа "Корзина").
  int get totalCount => _items.values.fold(0, (sum, qty) => sum + qty);

  /// Суммарная стоимость корзины в рублях.
  int get totalSum =>
      _items.entries.fold(0, (sum, e) => sum + e.key.price * e.value);

  bool get isEmpty => _items.isEmpty;

  void add(Product product) {
    _items[product] = quantityOf(product) + 1;
    notifyListeners();
  }

  void increment(Product product) => add(product);

  void decrement(Product product) {
    final current = quantityOf(product);
    if (current <= 1) {
      _items.remove(product);
    } else {
      _items[product] = current - 1;
    }
    notifyListeners();
  }

  /// Полностью убирает товар из корзины независимо от количества
  /// (кнопка-корзина на экране «Оформление заказа»).
  void remove(Product product) {
    if (_items.remove(product) != null) {
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
DARTEOF
echo 'lib/providers/cart_provider.dart — записан'

mkdir -p lib/providers
cat > lib/providers/favorites_provider.dart << 'DARTEOF'
import 'package:flutter/foundation.dart';
import '../models/product.dart';

class FavoritesProvider extends ChangeNotifier {
  final Set<String> _favoriteIds = {};

  bool isFavorite(Product product) => _favoriteIds.contains(product.id);

  void toggle(Product product) {
    if (_favoriteIds.contains(product.id)) {
      _favoriteIds.remove(product.id);
    } else {
      _favoriteIds.add(product.id);
    }
    notifyListeners();
  }

  int get count => _favoriteIds.length;
}
DARTEOF
echo 'lib/providers/favorites_provider.dart — записан'

mkdir -p lib/theme
cat > lib/theme/app_theme.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Единая цветовая палитра экрана «Каталог» проекта Всласть.
/// Значения подобраны по референсу утверждённого макета.
class AppColors {
  AppColors._();

  // Фон
  static const Color background = Color(0xFFF7F2EA);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Брендовый тёмно-коричневый (заголовки, кнопки, выбранная категория)
  static const Color primaryBrown = Color(0xFF3C2415);
  static const Color primaryBrownDark = Color(0xFF2E1B10);

  // Второстепенные поверхности (поиск, чипы, плашка корзины)
  static const Color surfaceMuted = Color(0xFFECE3D6);
  static const Color surfaceMutedDark = Color(0xFFE3D8C6);

  // Текст
  static const Color textPrimary = Color(0xFF2A1B12);
  static const Color textSecondary = Color(0xFF8A7E70);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Бейджи
  static const Color badgeHit = Color(0xFF8C5A34);
  static const Color badgeNew = Color(0xFF7C9473);
  static const Color badgePromo = Color(0xFFD1603D);

  static const Color divider = Color(0xFFE7DECD);
  static const Color shadow = Color(0x1A2A1B12);

  // --- Мои заказы: статусы ---
  static const Color statusPendingBg = Color(0xFFFBE7D2);
  static const Color statusPendingText = Color(0xFFB8712B);
  static const Color statusSuccessBg = Color(0xFFDCEEDB);
  static const Color statusSuccessText = Color(0xFF4C8A55);

  // --- Вход/Регистрация: акцентный градиент кнопок ---
  static const Color accentGradientStart = Color(0xFFCE9A54);
  static const Color accentGradientEnd = Color(0xFFA9682B);
}

class AppTextStyles {
  AppTextStyles._();

  /// Заголовок экрана «Каталог» — витринный serif-шрифт.
  static TextStyle screenTitle = GoogleFonts.playfairDisplay(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryBrown,
    height: 1.1,
  );

  static TextStyle searchHint = GoogleFonts.manrope(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static TextStyle categoryChip = GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static TextStyle productName = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.15,
  );

  static TextStyle productPrice = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle badgeLabel = GoogleFonts.manrope(
    fontSize: 8,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
    letterSpacing: 0.2,
  );

  static TextStyle cartBarText = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle cartBarButton = GoogleFonts.manrope(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
  );

  static TextStyle preorderButton = GoogleFonts.manrope(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
  );

  // --- Оформление заказа / Подтверждение заказа ---

  /// Заголовок экранов «Оформление заказа» и «Заказ принят!».
  static TextStyle screenTitleSmall = GoogleFonts.playfairDisplay(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryBrown,
    height: 1.15,
  );

  /// Подзаголовки секций: «Ваш заказ», «Способ получения», «Состав заказа».
  static TextStyle sectionLabel = GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Счётчик рядом с заголовком секции: «4 товара».
  static TextStyle sectionCounter = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static TextStyle orderItemName = GoogleFonts.manrope(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static TextStyle orderItemPrice = GoogleFonts.manrope(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle receiptQty = GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  /// Обычный текст строки (пункт меню, значение поля).
  static TextStyle rowLabel = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle rowLabelMuted = GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.35,
  );

  static TextStyle rowValue = GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle totalLabel = GoogleFonts.manrope(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle totalValue = GoogleFonts.manrope(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle infoNote = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.35,
  );

  static TextStyle optionTitle = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle optionSubtitle = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // --- Мои заказы ---

  static TextStyle orderNumber = GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  static TextStyle orderTitle = GoogleFonts.playfairDisplay(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static TextStyle statusPillLabel = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  // --- Вход/Регистрация ---

  static TextStyle authLogoTitle = GoogleFonts.playfairDisplay(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryBrown,
  );

  static TextStyle authTagline = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.badgeHit,
    letterSpacing: 0.6,
  );

  static TextStyle authHeading = GoogleFonts.playfairDisplay(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryBrown,
  );

  static TextStyle fieldLabel = GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle linkText = GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.badgeHit,
  );

  static TextStyle checkboxText = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );
}

/// Форматирует цену с разделителем разрядов и знаком ₽.
/// 1540 -> "1 540 ₽"
String formatPrice(int price) {
  final digits = price.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    final posFromEnd = digits.length - i;
    buffer.write(digits[i]);
    if (posFromEnd > 1 && posFromEnd % 3 == 1) {
      buffer.write('\u00A0'); // неразрывный пробел
    }
  }
  return '${buffer.toString()} ₽';
}

/// Склонение слова «товар» под число.
/// 1 -> товар, 2-4 -> товара, 5+ -> товаров
String pluralizeItems(int count) {
  final mod10 = count % 10;
  final mod100 = count % 100;
  if (mod10 == 1 && mod100 != 11) return 'товар';
  if (mod10 >= 2 && mod10 <= 4 && !(mod100 >= 12 && mod100 <= 14)) {
    return 'товара';
  }
  return 'товаров';
}
DARTEOF
echo 'lib/theme/app_theme.dart — записан'

mkdir -p lib/utils
cat > lib/utils/date_format.dart << 'DARTEOF'
/// Форматирование дат на русском языке без подключения пакета intl —
/// чтобы не тянуть лишнюю зависимость и не настраивать локализацию
/// только ради пары строк на экранах заказа.
const List<String> _ruMonthsGenitive = [
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];

String _twoDigits(int value) => value.toString().padLeft(2, '0');

/// 25 -> "25 июля"
String formatRuDate(DateTime date) {
  return '${date.day} ${_ruMonthsGenitive[date.month - 1]}';
}

/// -> "25 июля 2026"
String formatRuDateWithYear(DateTime date) {
  return '${date.day} ${_ruMonthsGenitive[date.month - 1]} ${date.year}';
}

/// -> "25 июля 2026, 10:45"
String formatRuDateTime(DateTime date) {
  final time = '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
  return '${formatRuDateWithYear(date)}, $time';
}

/// -> "10:32"
String formatRuTime(DateTime date) =>
    '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';

/// Для поля "Когда забрать": добавляет "Сегодня," / "Завтра,", если применимо.
String formatPickupDateLabel(DateTime date) {
  final now = DateTime.now();
  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  if (isSameDay(date, now)) return 'Сегодня, ${formatRuDate(date)}';
  final tomorrow = now.add(const Duration(days: 1));
  if (isSameDay(date, tomorrow)) return 'Завтра, ${formatRuDate(date)}';
  return formatRuDate(date);
}
DARTEOF
echo 'lib/utils/date_format.dart — записан'

mkdir -p lib/utils
cat > lib/utils/phone_formatter.dart << 'DARTEOF'
import 'package:flutter/services.dart';

/// Простой форматтер российского номера телефона без внешних пакетов:
/// вводимые цифры укладываются в маску "+7 (___) ___-__-__".
class RuPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Первая цифра всегда трактуется как код страны (7/8) и не показывается
    // отдельно — маска сама начинается с "+7".
    if (digits.startsWith('7') || digits.startsWith('8')) {
      digits = digits.substring(1);
    }
    if (digits.length > 10) digits = digits.substring(0, 10);

    final buffer = StringBuffer('+7 ');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '+7 ',
        selection: TextSelection.collapsed(offset: 3),
      );
    }

    buffer.write('(');
    buffer.write(digits.substring(0, digits.length.clamp(0, 3)));
    if (digits.length >= 3) buffer.write(') ');
    if (digits.length > 3) {
      buffer.write(digits.substring(3, digits.length.clamp(3, 6)));
    }
    if (digits.length >= 6) buffer.write('-');
    if (digits.length > 6) {
      buffer.write(digits.substring(6, digits.length.clamp(6, 8)));
    }
    if (digits.length >= 8) buffer.write('-');
    if (digits.length > 8) {
      buffer.write(digits.substring(8, digits.length.clamp(8, 10)));
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
DARTEOF
echo 'lib/utils/phone_formatter.dart — записан'

mkdir -p lib/widgets
cat > lib/widgets/category_chip.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBrown : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.categoryChip.copyWith(
            color: selected ? AppColors.textOnPrimary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
DARTEOF
echo 'lib/widgets/category_chip.dart — записан'

mkdir -p lib/widgets
cat > lib/widgets/product_card.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../theme/app_theme.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  /// Открытие карточки товара (экран «Карточка товара»).
  final ValueChanged<Product> onOpenDetails;

  const ProductCard({
    super.key,
    required this.product,
    required this.onOpenDetails,
  });

  Color _badgeColor(ProductBadge badge) {
    switch (badge) {
      case ProductBadge.hit:
        return AppColors.badgeHit;
      case ProductBadge.newItem:
        return AppColors.badgeNew;
      case ProductBadge.promo:
        return AppColors.badgePromo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final favorites = context.watch<FavoritesProvider>();
    final quantity = cart.quantityOf(product);
    final isFavorite = favorites.isFavorite(product);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Изображение + бейдж + избранное. Только эта область открывает
          // карточку товара, чтобы не конфликтовать с нажатием на сердечко.
          GestureDetector(
            onTap: () => onOpenDetails(product),
            behavior: HitTestBehavior.opaque,
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.surfaceMuted,
                      child: const Icon(Icons.bakery_dining_outlined,
                          size: 36, color: AppColors.textSecondary),
                    ),
                  ),
                  if (product.badge != null)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: _badgeColor(product.badge!),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.badge!.label,
                          style: AppTextStyles.badgeLabel,
                        ),
                      ),
                    ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _FavoriteButton(
                      isFavorite: isFavorite,
                      onTap: () => favorites.toggle(product),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            // Внимание: сумма высот этого блока (паддинги + название + цена)
            // рассчитана под _cardTextBlockHeight = 78 в catalog_screen.dart.
            // При изменении паддингов/шрифтов здесь — обновите константу там же.
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => onOpenDetails(product),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    height: 28,
                    child: Text(
                      product.name,
                      style: AppTextStyles.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 26,
                  child: !product.inStock
                      ? SizedBox(
                          width: double.infinity,
                          child: _PreorderButton(onTap: () {
                            // TODO: подключить логику предзаказа.
                          }),
                        )
                      : quantity == 0
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    formatPrice(product.price),
                                    style: AppTextStyles.productPrice,
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                _RoundIconButton(
                                  icon: Icons.add,
                                  onTap: () => cart.add(product),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    formatPrice(product.price),
                                    style: AppTextStyles.productPrice,
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                _QuantityStepper(
                                  quantity: quantity,
                                  onDecrement: () => cart.decrement(product),
                                  onIncrement: () => cart.increment(product),
                                ),
                              ],
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onTap;

  const _FavoriteButton({required this.isFavorite, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          size: 13,
          color: isFavorite ? AppColors.badgePromo : AppColors.primaryBrown,
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          color: AppColors.primaryBrown,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 14, color: AppColors.textOnPrimary),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(icon: Icons.remove, onTap: onDecrement, filled: false),
          SizedBox(
            width: 14,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppTextStyles.productName.copyWith(fontSize: 11),
            ),
          ),
          _StepperButton(icon: Icons.add, onTap: onIncrement, filled: true),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _StepperButton({
    required this.icon,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: filled ? AppColors.primaryBrown : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 10,
          color: filled ? AppColors.textOnPrimary : AppColors.primaryBrown,
        ),
      ),
    );
  }
}

class _PreorderButton extends StatelessWidget {
  final VoidCallback onTap;

  const _PreorderButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryBrown,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text('Предзаказ', style: AppTextStyles.preorderButton),
        ),
      ),
    );
  }
}
DARTEOF
echo 'lib/widgets/product_card.dart — записан'

mkdir -p lib/widgets
cat > lib/widgets/cart_summary_bar.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CartSummaryBar extends StatelessWidget {
  final int itemsCount;
  final int totalSum;
  final VoidCallback onTap;

  const CartSummaryBar({
    super.key,
    required this.itemsCount,
    required this.totalSum,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_bag_outlined,
                size: 20, color: AppColors.primaryBrown),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'В корзине $itemsCount ${pluralizeItems(itemsCount)}\n'
              'на сумму ${formatPrice(totalSum)}',
              style: AppTextStyles.cartBarText,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primaryBrown,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Перейти в корзину', style: AppTextStyles.cartBarButton),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward,
                      size: 16, color: AppColors.textOnPrimary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
DARTEOF
echo 'lib/widgets/cart_summary_bar.dart — записан'

mkdir -p lib/widgets
cat > lib/widgets/order_item_tile.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';

/// Редактируемая строка товара в списке заказа (экран «Оформление заказа»).
/// Читает и меняет состояние напрямую через CartProvider, поэтому список
/// всегда 1-в-1 соответствует содержимому корзины.
class OrderItemTile extends StatelessWidget {
  final Product product;
  final int quantity;

  const OrderItemTile({
    super.key,
    required this.product,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              product.imageUrl,
              width: 76,
              height: 76,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 76,
                height: 76,
                color: AppColors.surfaceMuted,
                child: const Icon(Icons.bakery_dining_outlined,
                    color: AppColors.textSecondary),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: AppTextStyles.orderItemName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => cart.remove(product),
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.only(left: 8, bottom: 4),
                        child: Icon(Icons.delete_outline,
                            size: 20, color: AppColors.primaryBrown),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        formatPrice(product.price),
                        style: AppTextStyles.orderItemPrice,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _CartStepper(
                      quantity: quantity,
                      onDecrement: () => cart.decrement(product),
                      onIncrement: () => cart.increment(product),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _CartStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(icon: Icons.remove, onTap: onDecrement),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppTextStyles.rowLabel,
            ),
          ),
          _StepButton(icon: Icons.add, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: AppColors.primaryBrown),
      ),
    );
  }
}
DARTEOF
echo 'lib/widgets/order_item_tile.dart — записан'

mkdir -p lib/widgets
cat > lib/widgets/receipt_item_tile.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';

/// Строка товара в составе заказа на экране «Подтверждение заказа».
/// В отличие от [OrderItemTile] — только для чтения, без степпера и удаления,
/// так как заказ на этом этапе уже отправлен.
class ReceiptItemTile extends StatelessWidget {
  final OrderItemSnapshot item;

  const ReceiptItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              item.product.imageUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 56,
                height: 56,
                color: AppColors.surfaceMuted,
                child: const Icon(Icons.bakery_dining_outlined,
                    size: 20, color: AppColors.textSecondary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.product.name,
              style: AppTextStyles.orderItemName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text('${item.quantity} шт.', style: AppTextStyles.receiptQty),
          const SizedBox(width: 12),
          Text(formatPrice(item.lineTotal), style: AppTextStyles.orderItemPrice),
        ],
      ),
    );
  }
}
DARTEOF
echo 'lib/widgets/receipt_item_tile.dart — записан'

mkdir -p lib/widgets
cat > lib/widgets/selectable_option_card.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Карточка-переключатель для «Способ получения» и «Способ оплаты».
class SelectableOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const SelectableOptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primaryBrown : AppColors.divider,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 22, color: AppColors.primaryBrown),
                const SizedBox(height: 10),
                Text(title, style: AppTextStyles.optionTitle),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.optionSubtitle,
                  maxLines: 2,
                ),
              ],
            ),
            if (selected)
              const Positioned(
                top: 0,
                right: 0,
                child: Icon(Icons.check_circle,
                    size: 18, color: AppColors.primaryBrown),
              ),
          ],
        ),
      ),
    );
  }
}
DARTEOF
echo 'lib/widgets/selectable_option_card.dart — записан'

mkdir -p lib/widgets
cat > lib/widgets/order_status_pill.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import '../models/order_list_item.dart';
import '../theme/app_theme.dart';

class OrderStatusPill extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isPending = status == OrderStatus.processing;
    final bg = isPending ? AppColors.statusPendingBg : AppColors.statusSuccessBg;
    final fg = isPending ? AppColors.statusPendingText : AppColors.statusSuccessText;
    final icon = isPending ? Icons.sync : Icons.check_circle;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(status.label, style: AppTextStyles.statusPillLabel.copyWith(color: fg)),
        ],
      ),
    );
  }
}
DARTEOF
echo 'lib/widgets/order_status_pill.dart — записан'

mkdir -p lib/widgets
cat > lib/widgets/order_history_card.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import '../models/order_list_item.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import 'order_status_pill.dart';

/// Карточка одного заказа в списке «Мои заказы». Набор кнопок внизу
/// зависит от статуса: у «В обработке» — только описание и сумма,
/// у «Подтвержден» — кнопка оплаты по СБП + QR, у «Исполнен» — кнопка
/// «Повторить заказ».
class OrderHistoryCard extends StatelessWidget {
  final OrderListItem order;
  final VoidCallback? onTap;
  final VoidCallback? onPay;
  final VoidCallback? onShowQr;
  final VoidCallback? onRepeat;

  const OrderHistoryCard({
    super.key,
    required this.order,
    this.onTap,
    this.onPay,
    this.onShowQr,
    this.onRepeat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      order.imageUrl,
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 84,
                        height: 84,
                        color: AppColors.surfaceMuted,
                        child: const Icon(Icons.bakery_dining_outlined,
                            size: 28, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  if (order.itemsCount > 1) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${order.itemsCount} ${pluralizeItems(order.itemsCount)}',
                        style: AppTextStyles.rowValue.copyWith(fontSize: 11),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Заказ №${order.number}', style: AppTextStyles.orderNumber),
                          const Spacer(),
                          OrderStatusPill(status: order.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(order.title, style: AppTextStyles.orderTitle, maxLines: 2),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${formatRuDateWithYear(order.placedAt)} • ${formatRuTime(order.placedAt)}',
                              style: AppTextStyles.rowLabelMuted,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              size: 18, color: AppColors.textSecondary),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    switch (order.status) {
      case OrderStatus.processing:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(order.statusDescription, style: AppTextStyles.rowLabelMuted),
            ),
            const SizedBox(width: 10),
            Text(formatPrice(order.totalPrice), style: AppTextStyles.orderItemPrice),
          ],
        );

      case OrderStatus.awaitingPayment:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(order.statusDescription, style: AppTextStyles.rowLabelMuted),
                ),
                const SizedBox(width: 10),
                Text(formatPrice(order.totalPrice), style: AppTextStyles.orderItemPrice),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onPay,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.accentGradientStart, AppColors.accentGradientEnd],
                        ),
                        borderRadius: BorderRadius.circular(23),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt, size: 18, color: Colors.white),
                          const SizedBox(width: 6),
                          Text('Оплатить по СБП', style: AppTextStyles.cartBarButton),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onShowQr,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.accentGradientEnd, width: 1.4),
                    ),
                    child: const Icon(Icons.qr_code_2,
                        size: 22, color: AppColors.accentGradientEnd),
                  ),
                ),
              ],
            ),
          ],
        );

      case OrderStatus.completed:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(order.statusDescription, style: AppTextStyles.rowLabelMuted),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onRepeat,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryBrown, width: 1.2),
                ),
                child: Text('Повторить заказ',
                    style: AppTextStyles.rowLabel.copyWith(color: AppColors.primaryBrown)),
              ),
            ),
          ],
        );
    }
  }
}
DARTEOF
echo 'lib/widgets/order_history_card.dart — записан'

mkdir -p lib/widgets
cat > lib/widgets/labeled_text_field.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Подписанное текстовое поле в едином стиле экрана «Вход/Регистрация»:
/// текст-лейбл сверху + скруглённое поле с иконкой и опциональной кнопкой
/// (например "глазок" показа пароля).
class LabeledTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData? leadingIcon;
  final Widget? trailing;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final VoidCallback? onTap;
  final bool readOnly;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.hint,
    this.leadingIcon,
    this.trailing,
    this.obscureText = false,
    this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            onTap: onTap,
            readOnly: readOnly,
            style: AppTextStyles.rowLabel,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.searchHint,
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
              prefixIcon: leadingIcon == null
                  ? null
                  : Icon(leadingIcon, size: 20, color: AppColors.textSecondary),
              prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 20),
              suffixIcon: trailing,
            ),
          ),
        ),
      ],
    );
  }
}
DARTEOF
echo 'lib/widgets/labeled_text_field.dart — записан'

mkdir -p lib/screens
cat > lib/screens/catalog_screen.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/mock_products.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/cart_summary_bar.dart';
import '../widgets/category_chip.dart';
import '../widgets/product_card.dart';
import 'cart_screen.dart';

/// Экран «Каталог» проекта Всласть.
///
/// Нижнюю панель навигации этот экран НЕ содержит — она уже реализована
/// в текущем проекте. Чтобы бейдж количества товаров на вкладке «Корзина»
/// обновлялся вместе с этим экраном, оба места должны читать
/// `context.watch<CartProvider>().totalCount` из одного и того же
/// CartProvider, поднятого выше по дереву (см. README_INTEGRATION.md).
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  // null означает выбранную категорию "Все".
  ProductCategory? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  List<Product> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    return mockProducts.where((p) {
      final matchesCategory =
          _selectedCategory == null || p.category == _selectedCategory;
      final matchesQuery =
          query.isEmpty || p.name.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void _openProductDetails(Product product) {
    // TODO: заменить на переход к реальному экрану «Карточка товара».
    Navigator.of(context).pushNamed('/product-detail', arguments: product);
  }

  void _openCart() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Высота блока под фото товара: паддинги карточки + название (до 2 строк)
  /// + строка цены/кнопки. Считается явно, а не через childAspectRatio,
  /// чтобы карточка никогда не переполнялась (RenderFlex overflow) —
  /// независимо от плотности пикселей и мелких отличий шрифта на устройстве.
  static const double _cardTextBlockHeight = 78;
  static const double _gridCrossAxisSpacing = 10;
  static const double _gridMainAxisSpacing = 10;
  static const int _gridCrossAxisCount = 3;

  SliverGridDelegateWithFixedCrossAxisCount _buildGridDelegate(
      BuildContext context, double horizontalPadding) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth -
            horizontalPadding * 2 -
            _gridCrossAxisSpacing * (_gridCrossAxisCount - 1)) /
        _gridCrossAxisCount;
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: _gridCrossAxisCount,
      mainAxisSpacing: _gridMainAxisSpacing,
      crossAxisSpacing: _gridCrossAxisSpacing,
      mainAxisExtent: itemWidth + _cardTextBlockHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final products = _filteredProducts;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _Header(),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _SearchBar(controller: _searchController, onChanged: (_) => setState(() {})),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 0, 0),
                  sliver: SliverToBoxAdapter(
                    child: _CategoryRow(
                      selectedCategory: _selectedCategory,
                      onSelect: (category) =>
                          setState(() => _selectedCategory = category),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                      20, 18, 20, cart.isEmpty ? 20 : 96),
                  sliver: products.isEmpty
                      ? SliverToBoxAdapter(child: _EmptyState())
                      : SliverGrid(
                          gridDelegate: _buildGridDelegate(context, 20),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => ProductCard(
                              product: products[index],
                              onOpenDetails: _openProductDetails,
                            ),
                            childCount: products.length,
                          ),
                        ),
                ),
              ],
            ),
            if (!cart.isEmpty)
              Positioned(
                left: 20,
                right: 20,
                bottom: 12,
                child: CartSummaryBar(
                  itemsCount: cart.totalCount,
                  totalSum: cart.totalSum,
                  onTap: _openCart,
                ),
              ),
          ],
        ),
      ),
      // Нижняя панель навигации намеренно не реализуется здесь —
      // используется текущая панель проекта.
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Кнопка "назад" пригодится, если Каталог у вас открывается через
        // Navigator.push (например, с иконки на Главной). Если Каталог —
        // отдельная вкладка нижней панели (IndexedStack), а не push-экран,
        // можно просто удалить эту кнопку — возврат на вкладку "Главная"
        // и так работает через саму панель.
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider, width: 1),
            ),
            child: const Icon(Icons.chevron_left,
                size: 24, color: AppColors.primaryBrown),
          ),
        ),
        Expanded(child: Text('Каталог', style: AppTextStyles.screenTitle)),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 22, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppTextStyles.searchHint.copyWith(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                hintText: 'Поиск хлеба, тортов, десертов...',
                hintStyle: AppTextStyles.searchHint,
              ),
            ),
          ),
          const Icon(Icons.tune, size: 20, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final ProductCategory? selectedCategory;
  final ValueChanged<ProductCategory?> onSelect;

  const _CategoryRow({required this.selectedCategory, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 20),
        children: [
          CategoryChip(
            label: 'Все',
            selected: selectedCategory == null,
            onTap: () => onSelect(null),
          ),
          const SizedBox(width: 6),
          ...ProductCategory.values.expand((category) => [
                CategoryChip(
                  label: category.label,
                  selected: selectedCategory == category,
                  onTap: () => onSelect(category),
                ),
                const SizedBox(width: 6),
              ]),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Text(
          'Ничего не найдено',
          style: AppTextStyles.productName
              .copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
DARTEOF
echo 'lib/screens/catalog_screen.dart — записан'

mkdir -p lib/screens
cat > lib/screens/cart_screen.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/order_item_tile.dart';
import 'checkout_screen.dart';

/// Экран «Корзина». Список товаров — это прямое отражение [CartProvider]:
/// степпер количества и удаление здесь меняют ту же самую корзину, которую
/// видит и «Каталог», и «Оформление заказа» — отдельного состояния у этого
/// экрана нет.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String? _comment;

  Future<void> _editComment() async {
    final controller = TextEditingController(text: _comment);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Комментарий к заказу', style: AppTextStyles.sectionLabel),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Например: не звонить в домофон',
                filled: true,
                fillColor: AppColors.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () => Navigator.pop(context, controller.text.trim()),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBrown,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: Text('Сохранить', style: AppTextStyles.cartBarButton),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (result != null) setState(() => _comment = result.isEmpty ? null : result);
  }

  void _openCheckout() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final entries = cart.items.entries.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: entries.isEmpty
            ? const _EmptyCartState()
            : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _Header(itemsCount: cart.totalCount),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final entry = entries[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: OrderItemTile(
                              product: entry.key,
                              quantity: entry.value,
                            ),
                          );
                        },
                        childCount: entries.length,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _CommentRow(comment: _comment, onTap: _editComment),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    sliver: const SliverToBoxAdapter(child: _PromoCodeRow()),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _CartSummary(itemsTotal: cart.totalSum),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                    sliver: SliverToBoxAdapter(
                      child: SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: _openCheckout,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 17),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBrown,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            alignment: Alignment.center,
                            child: Text('Оформить заказ',
                                style: AppTextStyles.cartBarButton),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
      // Нижняя панель навигации намеренно не реализуется здесь —
      // используется текущая панель проекта.
    );
  }
}

class _Header extends StatelessWidget {
  final int itemsCount;

  const _Header({required this.itemsCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(right: 12, top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider, width: 1),
            ),
            child: const Icon(Icons.chevron_left,
                size: 24, color: AppColors.primaryBrown),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Корзина', style: AppTextStyles.screenTitle),
              const SizedBox(height: 4),
              Text(
                '$itemsCount ${pluralizeItems(itemsCount)}',
                style: AppTextStyles.rowLabelMuted,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentRow extends StatelessWidget {
  final String? comment;
  final VoidCallback onTap;

  const _CommentRow({required this.comment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasComment = comment != null && comment!.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.primaryBrown,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasComment ? comment! : 'Добавить комментарий к заказу',
                style: AppTextStyles.rowLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _PromoCodeRow extends StatelessWidget {
  const _PromoCodeRow();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: подключить реальную логику применения промокода.
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(Icons.confirmation_number_outlined,
                size: 20, color: AppColors.primaryBrown),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Промокод', style: AppTextStyles.rowLabel),
            ),
            Text('Применить',
                style: AppTextStyles.rowLabel.copyWith(color: AppColors.badgeHit)),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// Упрощённая сводка суммы для «Корзины»: способ получения ещё не выбран
/// (это делается на «Оформлении заказа»), поэтому строка доставки — просто
/// заглушка «Самовывоз: Бесплатно», как в утверждённом макете.
class _CartSummary extends StatelessWidget {
  final int itemsTotal;

  const _CartSummary({required this.itemsTotal});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row('Сумма товаров', formatPrice(itemsTotal)),
        const SizedBox(height: 8),
        _row('Самовывоз', 'Бесплатно'),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1, color: AppColors.divider),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Итого', style: AppTextStyles.totalLabel),
            Text(formatPrice(itemsTotal), style: AppTextStyles.totalValue),
          ],
        ),
      ],
    );
  }

  Widget _row(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.rowLabelMuted),
          Text(value, style: AppTextStyles.rowValue),
        ],
      );
}

class _EmptyCartState extends StatelessWidget {
  const _EmptyCartState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          const _Header(itemsCount: 0),
          const Spacer(),
          Icon(Icons.shopping_bag_outlined,
              size: 40, color: AppColors.textSecondary.withOpacity(0.6)),
          const SizedBox(height: 12),
          Text('Корзина пуста', style: AppTextStyles.sectionLabel),
          const SizedBox(height: 6),
          Text(
            'Добавьте товары из каталога, чтобы оформить заказ',
            textAlign: TextAlign.center,
            style: AppTextStyles.rowLabelMuted,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
DARTEOF
echo 'lib/screens/cart_screen.dart — записан'

mkdir -p lib/screens
cat > lib/screens/checkout_screen.dart << 'DARTEOF'
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import '../widgets/order_item_tile.dart';
import '../widgets/selectable_option_card.dart';
import 'order_confirmation_screen.dart';

/// Экран «Оформление заказа». Список товаров — это живой срез корзины
/// (CartProvider), поэтому изменения количества/удаление здесь сразу
/// отражаются и в корзине, и наоборот.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const List<String> _timeSlots = [
    '10:00 – 11:00',
    '11:00 – 12:00',
    '12:00 – 13:00',
    '13:00 – 14:00',
    '14:00 – 15:00',
    '15:00 – 16:00',
  ];

  DeliveryMethod _deliveryMethod = DeliveryMethod.pickup;
  PaymentMethod _paymentMethod = PaymentMethod.onlineSbp;
  DateTime _pickupDate = DateTime.now();
  late String _pickupTimeSlot;
  String? _comment;

  @override
  void initState() {
    super.initState();
    _pickupTimeSlot = _timeSlots[2]; // 12:00–13:00 по умолчанию, как в макете
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickupDate.isBefore(now) ? now : _pickupDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _pickupDate = picked);
  }

  Future<void> _pickTimeSlot() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _TimeSlotSheet(
        slots: _timeSlots,
        selected: _pickupTimeSlot,
      ),
    );
    if (selected != null) setState(() => _pickupTimeSlot = selected);
  }

  Future<void> _editComment() async {
    final controller = TextEditingController(text: _comment);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Комментарий к заказу', style: AppTextStyles.sectionLabel),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Например: не звонить в домофон',
                filled: true,
                fillColor: AppColors.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () => Navigator.pop(context, controller.text.trim()),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBrown,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: Text('Сохранить', style: AppTextStyles.cartBarButton),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (result != null) setState(() => _comment = result.isEmpty ? null : result);
  }

  void _submitOrder(CartProvider cart) {
    final items = cart.items.entries
        .map((e) => OrderItemSnapshot(product: e.key, quantity: e.value))
        .toList();
    if (items.isEmpty) return;

    final order = OrderSummary(
      // TODO: заменить на номер заказа, который вернёт бэкенд.
      orderNumber: 1000 + Random().nextInt(9000),
      createdAt: DateTime.now(),
      items: items,
      comment: _comment,
      deliveryMethod: _deliveryMethod,
      pickupDate: _pickupDate,
      pickupTimeSlot: _pickupTimeSlot,
      paymentMethod: _paymentMethod,
      deliveryCost: _deliveryMethod == DeliveryMethod.pickup ? 0 : null,
    );

    cart.clear();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => OrderConfirmationScreen(order: order)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final entries = cart.items.entries.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: entries.isEmpty
            ? _EmptyCartState(onBack: () => Navigator.of(context).maybePop())
            : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    sliver: const SliverToBoxAdapter(child: _Header()),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Ваш заказ', style: AppTextStyles.sectionLabel),
                          Text(
                            '${cart.totalCount} ${pluralizeItems(cart.totalCount)}',
                            style: AppTextStyles.sectionCounter,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final entry = entries[index];
                          return Column(
                            children: [
                              OrderItemTile(
                                  product: entry.key, quantity: entry.value),
                              if (index != entries.length - 1)
                                const Divider(height: 1, color: AppColors.divider),
                            ],
                          );
                        },
                        childCount: entries.length,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _CommentRow(comment: _comment, onTap: _editComment),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _Section(
                        title: 'Способ получения',
                        child: Row(
                          children: [
                            Expanded(
                              child: SelectableOptionCard(
                                icon: Icons.shopping_bag_outlined,
                                title: DeliveryMethod.pickup.title,
                                subtitle: DeliveryMethod.pickup.subtitle,
                                selected: _deliveryMethod == DeliveryMethod.pickup,
                                onTap: () => setState(
                                    () => _deliveryMethod = DeliveryMethod.pickup),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SelectableOptionCard(
                                icon: Icons.delivery_dining_outlined,
                                title: DeliveryMethod.delivery.title,
                                subtitle: DeliveryMethod.delivery.subtitle,
                                selected:
                                    _deliveryMethod == DeliveryMethod.delivery,
                                onTap: () => setState(() =>
                                    _deliveryMethod = DeliveryMethod.delivery),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _Section(
                        title: 'Когда забрать',
                        child: Row(
                          children: [
                            Expanded(
                              child: _DropdownField(
                                icon: Icons.calendar_today_outlined,
                                label: formatPickupDateLabel(_pickupDate),
                                onTap: _pickDate,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DropdownField(
                                icon: Icons.access_time,
                                label: _pickupTimeSlot,
                                onTap: _pickTimeSlot,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _Section(
                        title: 'Способ оплаты',
                        child: Row(
                          children: [
                            Expanded(
                              child: SelectableOptionCard(
                                icon: Icons.qr_code,
                                title: PaymentMethod.onlineSbp.title,
                                subtitle: 'Администратор выставит QR-код',
                                selected:
                                    _paymentMethod == PaymentMethod.onlineSbp,
                                onTap: () => setState(() =>
                                    _paymentMethod = PaymentMethod.onlineSbp),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SelectableOptionCard(
                                icon: Icons.account_balance_wallet_outlined,
                                title: PaymentMethod.cash.title,
                                subtitle: PaymentMethod.cash.subtitle,
                                selected: _paymentMethod == PaymentMethod.cash,
                                onTap: () => setState(
                                    () => _paymentMethod = PaymentMethod.cash),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _PriceSummary(
                        itemsTotal: cart.totalSum,
                        deliveryLabel: _deliveryMethod.title,
                        deliveryCost:
                            _deliveryMethod == DeliveryMethod.pickup ? 0 : null,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    sliver: const SliverToBoxAdapter(child: _InfoNote()),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    sliver: SliverToBoxAdapter(
                      child: SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: () => _submitOrder(cart),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 17),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBrown,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            alignment: Alignment.center,
                            child:
                                Text('Заказать', style: AppTextStyles.cartBarButton),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider, width: 1),
            ),
            child: const Icon(Icons.chevron_left,
                size: 24, color: AppColors.primaryBrown),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'Оформление заказа',
            style: AppTextStyles.screenTitleSmall,
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.sectionLabel),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _CommentRow extends StatelessWidget {
  final String? comment;
  final VoidCallback onTap;

  const _CommentRow({required this.comment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasComment = comment != null && comment!.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.primaryBrown,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasComment ? comment! : 'Добавить комментарий к заказу',
                style: AppTextStyles.rowLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DropdownField({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primaryBrown),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.rowLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _TimeSlotSheet extends StatelessWidget {
  final List<String> slots;
  final String selected;

  const _TimeSlotSheet({required this.slots, required this.selected});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Когда забрать', style: AppTextStyles.sectionLabel),
            const SizedBox(height: 8),
            ...slots.map(
              (slot) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(slot, style: AppTextStyles.rowLabel),
                trailing: slot == selected
                    ? const Icon(Icons.check, color: AppColors.primaryBrown)
                    : null,
                onTap: () => Navigator.pop(context, slot),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceSummary extends StatelessWidget {
  final int itemsTotal;
  final String deliveryLabel;

  /// null — "Уточняется", 0 — "Бесплатно", иначе — сумма.
  final int? deliveryCost;

  const _PriceSummary({
    required this.itemsTotal,
    required this.deliveryLabel,
    required this.deliveryCost,
  });

  @override
  Widget build(BuildContext context) {
    final total = itemsTotal + (deliveryCost ?? 0);
    final deliveryValue = deliveryCost == null
        ? 'Уточняется'
        : (deliveryCost == 0 ? 'Бесплатно' : formatPrice(deliveryCost!));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _row('Сумма товаров', formatPrice(itemsTotal)),
          const SizedBox(height: 8),
          _row(deliveryLabel, deliveryValue),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Итого', style: AppTextStyles.totalLabel),
              Text(formatPrice(total), style: AppTextStyles.totalValue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.rowLabelMuted),
          Text(value, style: AppTextStyles.rowValue),
        ],
      );
}

class _InfoNote extends StatelessWidget {
  const _InfoNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Все заказы подтверждаются администратором. '
              'После подтверждения мы пришлём вам уведомление.',
              style: AppTextStyles.infoNote,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCartState extends StatelessWidget {
  final VoidCallback onBack;

  const _EmptyCartState({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          const _Header(),
          const Spacer(),
          Icon(Icons.shopping_bag_outlined,
              size: 40, color: AppColors.textSecondary.withOpacity(0.6)),
          const SizedBox(height: 12),
          Text('Корзина пуста', style: AppTextStyles.sectionLabel),
          const SizedBox(height: 6),
          Text(
            'Добавьте товары из каталога, чтобы оформить заказ',
            textAlign: TextAlign.center,
            style: AppTextStyles.rowLabelMuted,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
DARTEOF
echo 'lib/screens/checkout_screen.dart — записан'

mkdir -p lib/screens
cat > lib/screens/order_confirmation_screen.dart << 'DARTEOF'
import 'package:flutter/material.dart';

import '../models/order.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import '../widgets/receipt_item_tile.dart';

/// Экран «Подтверждение заказа». Полностью работает от переданного
/// в конструктор [order] — снимка заказа, зафиксированного в момент
/// нажатия «Заказать» на экране «Оформление заказа». Корзина к этому
/// моменту уже очищена, поэтому экран не зависит от CartProvider.
class OrderConfirmationScreen extends StatelessWidget {
  final OrderSummary order;

  const OrderConfirmationScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      // Возврат сразу на "Главную", а не на "Оформление
                      // заказа" — после оформления корзина уже очищена,
                      // так что возвращаться в чекаут смысла нет.
                      onTap: () => Navigator.of(context)
                          .popUntil((route) => route.isFirst),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 44,
                        height: 44,
                        margin: const EdgeInsets.only(right: 12, top: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.divider, width: 1),
                        ),
                        child: const Icon(Icons.chevron_left,
                            size: 24, color: AppColors.primaryBrown),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Заказ принят!', style: AppTextStyles.screenTitleSmall),
                          const SizedBox(height: 4),
                          Text('Спасибо, что выбрали Всласть ❤️',
                              style: AppTextStyles.rowLabelMuted),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(child: _StatusCard(order: order)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Состав заказа', style: AppTextStyles.sectionLabel),
                          Text(
                            '${order.itemsCount} ${pluralizeItems(order.itemsCount)}',
                            style: AppTextStyles.sectionCounter,
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1, color: AppColors.divider),
                      ),
                      for (var i = 0; i < order.items.length; i++) ...[
                        ReceiptItemTile(item: order.items[i]),
                        if (i != order.items.length - 1)
                          const Divider(height: 1, color: AppColors.divider),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.event_outlined,
                        label: 'Когда забрать',
                        value:
                            '${formatRuDate(order.pickupDate)}, ${order.pickupTimeSlot}',
                      ),
                      const Divider(height: 1, color: AppColors.divider),
                      _InfoRow(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Способ получения',
                        value: order.deliveryMethod.title,
                      ),
                      const Divider(height: 1, color: AppColors.divider),
                      _InfoRow(
                        icon: Icons.credit_card,
                        label: 'Способ оплаты',
                        value: order.paymentMethod.title,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: () {
                    // TODO: подключить переход в чат/поддержку по заказу.
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline,
                            size: 18, color: AppColors.primaryBrown),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('Связаться с нами по заказу',
                              style: AppTextStyles.rowLabel),
                        ),
                        const Icon(Icons.chevron_right,
                            color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () {
                      // TODO: заменить на переход к реальному экрану «Мои заказы».
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBrown,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      alignment: Alignment.center,
                      child: Text('Перейти в мои заказы',
                          style: AppTextStyles.cartBarButton),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final OrderSummary order;

  const _StatusCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: const BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bakery_dining_outlined,
                size: 40, color: AppColors.primaryBrown),
          ),
          const SizedBox(height: 14),
          Text('Ваш заказ №${order.orderNumber}', style: AppTextStyles.sectionLabel),
          const SizedBox(height: 2),
          Text('от ${formatRuDateTime(order.createdAt)}',
              style: AppTextStyles.rowLabelMuted),
          const SizedBox(height: 12),
          Text(
            'Мы получили ваш заказ и передали его на подтверждение администратору.',
            textAlign: TextAlign.center,
            style: AppTextStyles.rowLabelMuted,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.access_time,
                    size: 18, color: AppColors.primaryBrown),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ожидайте подтверждения', style: AppTextStyles.rowLabel),
                    const SizedBox(height: 2),
                    Text(
                      'Мы свяжемся с вами в ближайшее время и сообщим статус заказа.',
                      style: AppTextStyles.rowLabelMuted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryBrown),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: AppTextStyles.rowLabelMuted)),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.rowValue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
DARTEOF
echo 'lib/screens/order_confirmation_screen.dart — записан'

mkdir -p lib/screens
cat > lib/screens/orders_screen.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import '../data/mock_orders.dart';
import '../models/order_list_item.dart';
import '../theme/app_theme.dart';
import '../widgets/order_history_card.dart';

/// Экран «Мои заказы». Кнопка "назад" ведёт на "Главную" —
/// popUntil((route) => route.isFirst), т.к. этот экран обычно открывается
/// из профиля/нижней панели, а не является частью цепочки покупки.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = mockOrders; // TODO: подставить реальную историю заказов.
    final unreadNotifications = 2; // TODO: подключить реальный счётчик.

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    _RoundButton(
                      icon: Icons.arrow_back,
                      onTap: () =>
                          Navigator.of(context).popUntil((route) => route.isFirst),
                    ),
                    Expanded(
                      child: Text(
                        'Мои заказы',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.screenTitleSmall,
                      ),
                    ),
                    _RoundButton(
                      icon: Icons.notifications_none,
                      badgeCount: unreadNotifications,
                      onTap: () {
                        // TODO: открыть экран уведомлений.
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              sliver: orders.isEmpty
                  ? const SliverToBoxAdapter(child: _EmptyOrdersState())
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final order = orders[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: OrderHistoryCard(
                              order: order,
                              onTap: () {
                                // TODO: открыть детальный экран заказа.
                              },
                              onPay: () {
                                // TODO: подключить реальную оплату по СБП.
                              },
                              onShowQr: () {
                                // TODO: показать QR-код для оплаты.
                              },
                              onRepeat: () {
                                // TODO: добавить товары этого заказа обратно в корзину.
                              },
                            ),
                          );
                        },
                        childCount: orders.length,
                      ),
                    ),
            ),
          ],
        ),
      ),
      // Нижняя панель навигации намеренно не реализуется здесь —
      // используется текущая панель проекта.
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int? badgeCount;

  const _RoundButton({required this.icon, required this.onTap, this.badgeCount});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider, width: 1),
            ),
            child: Icon(icon, size: 22, color: AppColors.primaryBrown),
          ),
          if (badgeCount != null && badgeCount! > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: const BoxDecoration(
                  color: AppColors.badgeHit,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badgeCount',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.statusPillLabel
                      .copyWith(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyOrdersState extends StatelessWidget {
  const _EmptyOrdersState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 40, color: AppColors.textSecondary.withOpacity(0.6)),
          const SizedBox(height: 12),
          Text('Заказов пока нет', style: AppTextStyles.sectionLabel),
        ],
      ),
    );
  }
}
DARTEOF
echo 'lib/screens/orders_screen.dart — записан'

mkdir -p lib/screens
cat > lib/screens/auth_screen.dart << 'DARTEOF'
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import '../utils/phone_formatter.dart';
import '../widgets/labeled_text_field.dart';

enum AuthMode { login, register }

/// Экран «Вход/Регистрация». Открывается через Navigator.push с иконки
/// профиля на «Главной» (у вас в проекте — добавьте вызов из обработчика
/// нажатия на эту иконку, см. README_INTEGRATION.md).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthMode _mode = AuthMode.login;

  // --- Вход ---
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _selectedCity = 'Нижневартовск';

  // --- Регистрация ---
  final _regLoginController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regPasswordConfirmController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController(text: '+7 ');
  final _emailController = TextEditingController();
  bool _obscureRegPassword = true;
  bool _obscureRegPasswordConfirm = true;
  DateTime? _birthDate;
  bool _agreedToTerms = false;
  late final TapGestureRecognizer _agreementLinkRecognizer;

  static const _cities = [
    'Нижневартовск',
    'Москва',
    'Санкт-Петербург',
    'Екатеринбург',
    'Казань',
  ];

  @override
  void initState() {
    super.initState();
    _agreementLinkRecognizer = TapGestureRecognizer()
      ..onTap = () {
        // TODO: открыть реальный текст соглашения (веб-страница/документ).
      };
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _regLoginController.dispose();
    _regPasswordController.dispose();
    _regPasswordConfirmController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _agreementLinkRecognizer.dispose();
    super.dispose();
  }

  Future<void> _pickCity() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _cities
              .map((city) => ListTile(
                    title: Text(city, style: AppTextStyles.rowLabel),
                    trailing: city == _selectedCity
                        ? const Icon(Icons.check, color: AppColors.primaryBrown)
                        : null,
                    onTap: () => Navigator.pop(context, city),
                  ))
              .toList(),
        ),
      ),
    );
    if (picked != null) setState(() => _selectedCity = picked);
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 6, now.month, now.day),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  void _submitLogin() {
    // TODO: подключить реальную авторизацию (логин/телефон + пароль + город).
    Navigator.of(context).maybePop();
  }

  void _submitRegister() {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Подтвердите согласие на обработку персональных данных'),
        ),
      );
      return;
    }
    // TODO: подключить реальную регистрацию и валидацию полей.
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.divider, width: 1),
                  ),
                  child: const Icon(Icons.close, size: 20, color: AppColors.primaryBrown),
                ),
              ),
              const SizedBox(height: 12),
              Center(child: _LogoBlock()),
              const SizedBox(height: 24),
              _ModeSwitch(mode: _mode, onChanged: (m) => setState(() => _mode = m)),
              const SizedBox(height: 24),
              Text(
                _mode == AuthMode.login ? 'Добро пожаловать!' : 'Создайте аккаунт',
                style: AppTextStyles.authHeading,
              ),
              const SizedBox(height: 6),
              Text(
                _mode == AuthMode.login
                    ? 'Войдите, чтобы делать покупки быстрее и удобнее'
                    : 'Заполните данные, чтобы зарегистрироваться и делать покупки в Всласть',
                style: AppTextStyles.rowLabelMuted,
              ),
              const SizedBox(height: 22),
              if (_mode == AuthMode.login) _buildLoginForm() else _buildRegisterForm(),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  _mode == AuthMode.login
                      ? 'assets/images/hero_banner.jpg'
                      : 'assets/images/cake_crown_bordeaux.jpg',
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.image_outlined,
                        size: 40, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabeledTextField(
          label: 'Логин или телефон',
          hint: 'Введите логин или телефон',
          leadingIcon: Icons.person_outline,
          controller: _loginController,
        ),
        const SizedBox(height: 16),
        LabeledTextField(
          label: 'Пароль',
          hint: 'Введите пароль',
          leadingIcon: Icons.lock_outline,
          obscureText: _obscurePassword,
          controller: _passwordController,
          trailing: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {
              // TODO: подключить восстановление пароля.
            },
            behavior: HitTestBehavior.opaque,
            child: Text('Забыли пароль?', style: AppTextStyles.linkText),
          ),
        ),
        const SizedBox(height: 12),
        _TappableField(
          label: 'Ваш город',
          value: _selectedCity,
          hint: 'Выберите город',
          icon: Icons.location_on_outlined,
          onTap: _pickCity,
          helperText: 'От выбора города зависит ассортимент и условия доставки',
        ),
        const SizedBox(height: 24),
        _GradientButton(label: 'Иду за покупками', onTap: _submitLogin),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.divider)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('или', style: AppTextStyles.rowLabelMuted),
            ),
            const Expanded(child: Divider(color: AppColors.divider)),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: () => setState(() => _mode = AuthMode.register),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primaryBrown, width: 1.4),
              ),
              alignment: Alignment.center,
              child: Text(
                'Регистрация нового пользователя',
                style: AppTextStyles.rowLabel.copyWith(color: AppColors.primaryBrown),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabeledTextField(
          label: 'Логин',
          hint: 'Придумайте логин',
          leadingIcon: Icons.person_outline,
          controller: _regLoginController,
        ),
        const SizedBox(height: 16),
        LabeledTextField(
          label: 'Пароль',
          hint: 'Придумайте пароль',
          leadingIcon: Icons.lock_outline,
          obscureText: _obscureRegPassword,
          controller: _regPasswordController,
          trailing: IconButton(
            icon: Icon(
              _obscureRegPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
            onPressed: () => setState(() => _obscureRegPassword = !_obscureRegPassword),
          ),
        ),
        const SizedBox(height: 16),
        LabeledTextField(
          label: 'Повторите пароль',
          hint: 'Повторите пароль',
          leadingIcon: Icons.lock_outline,
          obscureText: _obscureRegPasswordConfirm,
          controller: _regPasswordConfirmController,
          trailing: IconButton(
            icon: Icon(
              _obscureRegPasswordConfirm
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
            onPressed: () =>
                setState(() => _obscureRegPasswordConfirm = !_obscureRegPasswordConfirm),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LabeledTextField(
                label: 'Имя',
                hint: 'Введите имя',
                leadingIcon: Icons.person_outline,
                controller: _firstNameController,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LabeledTextField(
                label: 'Фамилия',
                hint: 'Введите фамилию',
                leadingIcon: Icons.person_outline,
                controller: _lastNameController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _TappableField(
          label: 'Дата рождения',
          value: _birthDate == null ? '' : formatRuDateWithYear(_birthDate!),
          hint: 'Выберите дату',
          icon: Icons.calendar_today_outlined,
          onTap: _pickBirthDate,
        ),
        const SizedBox(height: 16),
        LabeledTextField(
          label: 'Телефон',
          hint: '+7 (___) ___-__-__',
          leadingIcon: Icons.phone_outlined,
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [RuPhoneInputFormatter()],
        ),
        const SizedBox(height: 16),
        LabeledTextField(
          label: 'Email (необязательно)',
          hint: 'Введите email',
          leadingIcon: Icons.mail_outline,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _agreedToTerms,
              onChanged: (value) => setState(() => _agreedToTerms = value ?? false),
              activeColor: AppColors.primaryBrown,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text.rich(
                  TextSpan(
                    style: AppTextStyles.checkboxText,
                    children: [
                      const TextSpan(
                        text: 'Я соглашаюсь на обработку персональных данных '
                            'и принимаю условия ',
                      ),
                      TextSpan(
                        text: 'Согласия',
                        style: AppTextStyles.linkText.copyWith(fontSize: 12),
                        recognizer: _agreementLinkRecognizer,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _GradientButton(label: 'Зарегистрироваться', onTap: _submitRegister),
      ],
    );
  }
}

class _LogoBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo_dark.png',
          height: 48,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.eco, size: 40, color: AppColors.badgeHit),
        ),
        const SizedBox(height: 8),
        Text('Всласть', style: AppTextStyles.authLogoTitle),
        const SizedBox(height: 4),
        Text('пекарня • кондитерская', style: AppTextStyles.authTagline),
      ],
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  final AuthMode mode;
  final ValueChanged<AuthMode> onChanged;

  const _ModeSwitch({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _tab(context, 'Вход', AuthMode.login)),
          Expanded(child: _tab(context, 'Регистрация', AuthMode.register)),
        ],
      ),
    );
  }

  Widget _tab(BuildContext context, String label, AuthMode value) {
    final selected = mode == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBrown : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.categoryChip
              .copyWith(color: selected ? Colors.white : AppColors.textPrimary),
        ),
      ),
    );
  }
}

/// Тап-поле, имитирующее выпадающий список (город / дата рождения):
/// показывает выбранное значение или подсказку, открывает шторку/пикер.
class _TappableField extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final IconData icon;
  final VoidCallback onTap;
  final String? helperText;

  const _TappableField({
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
    required this.onTap,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasValue ? value : hint,
                    style: hasValue ? AppTextStyles.rowLabel : AppTextStyles.searchHint,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(helperText!, style: AppTextStyles.rowLabelMuted),
        ],
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 17),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accentGradientStart, AppColors.accentGradientEnd],
            ),
            borderRadius: BorderRadius.circular(26),
          ),
          alignment: Alignment.center,
          child: Text(label, style: AppTextStyles.cartBarButton),
        ),
      ),
    );
  }
}
DARTEOF
echo 'lib/screens/auth_screen.dart — записан'

echo ''
echo 'Готово. Не забудьте:'
echo '  1) добавить в pubspec.yaml: provider: ^6.1.2  и  google_fonts: ^6.2.1'
echo '  2) поднять CartProvider и FavoritesProvider через MultiProvider в main.dart'
echo '     (уже сделано, если вы применяли предыдущие правки)'
echo '  3) на иконке "Главная" (или иконке профиля) на своей Главной'
echo '     повесить переход на AuthScreen — см. README_INTEGRATION.md, п.7'
echo ''
echo 'Затем: flutter clean && flutter pub get && flutter run'
