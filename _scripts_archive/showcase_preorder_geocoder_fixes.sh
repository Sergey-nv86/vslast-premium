#!/bin/bash
set -e
#
# Этот раунд правок:
#  - «Сегодня на витрине»: показывает ВСЕ товары в наличии (не только 4),
#    список сам скроллится вертикально
#  - на Главной при изменении количества товара всплывает плашка
#    «Перейти в корзину» — как в Каталоге
#  - новый экран «Предзаказ» (в фирменном стиле): подключён с кнопки
#    «Предзаказ» на карточке товара и на карточке товара (детальный экран).
#    Шаг «Вес» показывается только для тортов/весовых товаров — для
#    остальных высота экрана меньше сама по себе.
#  - геокодер: при неудаче теперь показывает тост с понятной причиной
#    (ключ не настроен / запрос не удался), плюс подробный лог в консоль —
#    вместо тихого бесконечного "Определяется по карте..."
#  - «Заказ принят»: кнопка «назад» тоже ведёт в Каталог (как и вторая
#    кнопка на этом экране), а не на Главную
#
# !!! ВАЖНО: перезаписывает lib/utils/yandex_geocoder.dart — впишите свой
# ключ HTTP Geocoder заново после применения.
#
# ЗАПУСК: из корня проекта
#   cd /Users/sukolesnikov/Projects/vslast_premium
#   bash showcase_preorder_geocoder_fixes.sh

mkdir -p lib

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

  /// Продаётся на вес (а не поштучно/по фиксированному объёму). На экране
  /// «Предзаказ» именно этот признак (вместе с категорией "торты") решает,
  /// показывать ли шаг выбора веса.
  final bool isWeighed;

  // --- Поля для экрана «Карточка товара» ---
  // Все опциональны: если не заданы, экран аккуратно скрывает
  // соответствующий блок, а не падает и не рисует пустоту.

  final double? rating;
  final int? reviewsCount;

  /// Например "1 кг", "1 шт", "350 г". По умолчанию "1 шт".
  final String weightLabel;

  final String? description;

  final int? caloriesPer100g;
  final double? proteinPer100g;
  final double? fatPer100g;
  final double? carbsPer100g;
  final String? composition;

  /// Фото для галереи на карточке товара. Если не задано — галерея
  /// состоит из одного [imageUrl] (см. геттер [gallery]).
  final List<String>? galleryImages;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.badge,
    this.inStock = true,
    this.isWeighed = false,
    this.rating,
    this.reviewsCount,
    this.weightLabel = '1 шт',
    this.description,
    this.caloriesPer100g,
    this.proteinPer100g,
    this.fatPer100g,
    this.carbsPer100g,
    this.composition,
    this.galleryImages,
  });

  List<String> get gallery =>
      (galleryImages == null || galleryImages!.isEmpty) ? [imageUrl] : galleryImages!;

  bool get hasNutritionInfo =>
      caloriesPer100g != null ||
      proteinPer100g != null ||
      fatPer100g != null ||
      carbsPer100g != null;

  /// Экран «Предзаказ» показывает шаг выбора веса только для тортов или
  /// весового товара — для остального (эклер, булочка и т.п.) вес не
  /// выбирается, и шаг просто не рисуется.
  bool get showsWeightSelector => category == ProductCategory.cakes || isWeighed;

  @override
  bool operator ==(Object other) => other is Product && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
DARTEOF
echo 'lib/models/product.dart — обновлён'

mkdir -p lib/utils
cat > lib/utils/yandex_geocoder.dart << 'DARTEOF'
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Обратное геокодирование через HTTP Geocoder API Яндекса — координаты
/// точки на карте → человекочитаемый адрес.
///
/// ВАЖНО — это отдельный ключ, не тот же самый, что ключ MapKit SDK:
///   1. Получите ключ "JavaScript API и HTTP Geocoder" на
///      https://developer.tech.yandex.ru/services (бесплатный лимит есть).
///   2. Впишите его в [_apiKey] ниже.
/// Без ключа функция всегда будет возвращать null — поле «Адрес» на экране
/// доставки при этом остаётся обычным редактируемым текстовым полем, так
/// что пользователь всегда может ввести адрес руками, даже если геокодер
/// не настроен или недоступен.
class YandexGeocoder {
  YandexGeocoder._();

  static const String _apiKey = 'ВСТАВЬТЕ_СЮДА_КЛЮЧ_HTTP_GEOCODER';

  /// true, если ключ реально вписан (не осталась заглушка). Экран доставки
  /// использует это, чтобы сразу показать понятную подсказку "введите
  /// адрес вручную" вместо бесконечного тихого ожидания.
  static bool get isConfigured =>
      _apiKey != 'ВСТАВЬТЕ_СЮДА_КЛЮЧ_HTTP_GEOCODER' && _apiKey.isNotEmpty;

  /// [lat] — широта, [lon] — долгота. Возвращает строку адреса или null,
  /// если ключ не настроен, запрос не удался, или ничего не найдено.
  static Future<String?> reverseGeocode(double lat, double lon) async {
    if (!isConfigured) return null;
    try {
      final uri = Uri.parse('https://geocode-maps.yandex.ru/1.x/').replace(
        queryParameters: {
          'apikey': _apiKey,
          'geocode': '$lon,$lat', // Яндекс ждёт "долгота,широта", не наоборот
          'format': 'json',
          'results': '1',
          'lang': 'ru_RU',
        },
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) {
        // Диагностика: смотрите консоль Xcode/Android Studio, если адрес
        // не определяется — здесь будет видна настоящая причина (неверный
        // ключ, лимит запросов исчерпан и т.п.), а не молчаливый null.
        debugPrint('YandexGeocoder: HTTP ${response.statusCode} — ${response.body}');
        return null;
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final members = data['response']?['GeoObjectCollection']?['featureMember'];
      if (members is! List || members.isEmpty) {
        debugPrint('YandexGeocoder: пустой результат для $lat,$lon');
        return null;
      }

      final geoObject = members.first['GeoObject'];
      final metaData = geoObject?['metaDataProperty']?['GeocoderMetaData'];

      // Полный текст выглядит как "Россия, ХМАО, Нижневартовск, ул. Мира, 12"
      // — для доставки нужны только улица и дом, без страны/региона/города.
      // Яндекс отдаёт разбор по компонентам с типами (kind) — берём именно
      // street/house, а не режем строку по запятым вслепую.
      final components = metaData?['Address']?['Components'];
      if (components is List) {
        String? street;
        String? house;
        for (final c in components) {
          final kind = c['kind'];
          final name = c['name'];
          if (kind == 'street' && name is String) street = name;
          if (kind == 'house' && name is String) house = name;
        }
        if (street != null || house != null) {
          return [street, house].where((e) => e != null && e.isNotEmpty).join(', ');
        }
      }

      // Резервный вариант, если компонентов почему-то нет в ответе: берём
      // последние два сегмента полного адреса (обычно это и есть улица+дом).
      final text = metaData?['text'];
      if (text is String && text.isNotEmpty) {
        final parts = text.split(', ');
        return parts.length >= 2 ? parts.sublist(parts.length - 2).join(', ') : text;
      }
      debugPrint('YandexGeocoder: не нашёл ни компонентов, ни текста в ответе');
      return null;
    } catch (e) {
      // Сеть недоступна / geocoder вернул неожиданный формат — молча
      // отступаем к ручному вводу адреса (это не критическая ошибка для
      // пользователя), но логируем, чтобы при отладке было видно причину.
      debugPrint('YandexGeocoder: исключение — $e');
      return null;
    }
  }
}
DARTEOF
echo 'lib/utils/yandex_geocoder.dart — обновлён'

mkdir -p lib/widgets
cat > lib/widgets/product_card.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../theme/app_theme.dart';
import '../utils/toast.dart';
import '../screens/preorder_screen.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  /// Открытие карточки товара (экран «Карточка товара»).
  final ValueChanged<Product> onOpenDetails;

  /// Масштаб степпера количества (кнопка "+" / "−N+"). По умолчанию 1.0 —
  /// как в «Каталоге» и «Избранном». На Главной, в блоке «Сегодня на
  /// витрине», используется 1.7 — там по вашей просьбе кнопки крупнее.
  final double controlScale;

  const ProductCard({
    super.key,
    required this.product,
    required this.onOpenDetails,
    this.controlScale = 1.0,
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
    // Высота строки "цена + кнопка" растёт вместе с controlScale, чтобы
    // увеличенный степпер не обрезался фиксированной высотой строки.
    final priceRowHeight = controlScale <= 1.0 ? 26.0 : 26.0 * controlScale + 6.0;

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
                      onTap: () {
                        final wasFavorite = isFavorite;
                        favorites.toggle(product);
                        FadeToast.show(
                          context,
                          wasFavorite ? 'Удалено из избранного' : 'Добавлено в избранное',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            // Внимание: сумма высот этого блока (паддинги + название + цена)
            // рассчитана под _cardTextBlockHeight = 80 в catalog_screen.dart.
            // При изменении паддингов/шрифтов здесь — обновите константу там же.
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => onOpenDetails(product),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    height: 30,
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
                  height: priceRowHeight,
                  child: !product.inStock
                      ? SizedBox(
                          width: double.infinity,
                          child: _PreorderButton(
                            controlScale: controlScale,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PreorderScreen(product: product),
                                ),
                              );
                            },
                          ),
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
                                  controlScale: controlScale,
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
                                  controlScale: controlScale,
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
  final double controlScale;

  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.controlScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final size = 26.0 * controlScale;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.primaryBrown,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 14.0 * controlScale, color: AppColors.textOnPrimary),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final double controlScale;

  const _QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    this.controlScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.symmetric(horizontal: 1 * controlScale, vertical: 1 * controlScale),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
              icon: Icons.remove, onTap: onDecrement, filled: false, controlScale: controlScale),
          SizedBox(
            width: 14.0 * controlScale,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppTextStyles.productName.copyWith(fontSize: 11.0 * controlScale),
            ),
          ),
          _StepperButton(
              icon: Icons.add, onTap: onIncrement, filled: true, controlScale: controlScale),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final double controlScale;

  const _StepperButton({
    required this.icon,
    required this.onTap,
    required this.filled,
    this.controlScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final size = 18.0 * controlScale;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: filled ? AppColors.primaryBrown : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 10.0 * controlScale,
          color: filled ? AppColors.textOnPrimary : AppColors.primaryBrown,
        ),
      ),
    );
  }
}

class _PreorderButton extends StatelessWidget {
  final VoidCallback onTap;
  final double controlScale;

  const _PreorderButton({required this.onTap, this.controlScale = 1.0});

  @override
  Widget build(BuildContext context) {
    final height = controlScale <= 1.0 ? 26.0 : 26.0 * controlScale + 6.0;
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryBrown,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Text('Предзаказ',
              style: AppTextStyles.preorderButton.copyWith(fontSize: 11.0 * controlScale.clamp(1.0, 1.3))),
        ),
      ),
    );
  }
}
DARTEOF
echo 'lib/widgets/product_card.dart — обновлён'

mkdir -p lib/features/home/screens
cat > lib/features/home/screens/home_screen.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/cart_provider.dart';
import '../../../screens/cart_screen.dart';
import '../../../widgets/cart_summary_bar.dart';
import '../widgets/home_header.dart';
import '../widgets/popular_section.dart';
import '../widgets/showcase_section.dart';

/// Главная. Раньше весь экран был одним SingleChildScrollView — блок
/// "Сегодня на витрине" рос вместе с карточками и всё уезжало вниз.
/// Теперь верстка — Column с Expanded вокруг "Сегодня на витрине": сам
/// экран целиком помещается в высоту устройства, а прокручивается только
/// "Сегодня на витрине" (вертикально, внутри своей области). "Популярное"
/// как и раньше — горизонтальный скролл, но теперь занимает фиксированное
/// место внизу, а не "плавает" по общей длине страницы.
///
/// Плашка "Перейти в корзину" — тот же CartSummaryBar, что и в «Каталоге»,
/// всплывает поверх контента при появлении товаров в корзине.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openCart(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return SafeArea(
      top: false,
      bottom: false,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HomeHeader(),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(18, 0, 18, cart.isEmpty ? 0 : 72),
                  child: const ShowcaseSection(),
                ),
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: PopularSection(),
              ),
              const SizedBox(height: 8),
            ],
          ),
          if (!cart.isEmpty)
            Positioned(
              left: 18,
              right: 18,
              bottom: 8,
              child: CartSummaryBar(
                itemsCount: cart.totalCount,
                totalSum: cart.totalSum,
                onTap: () => _openCart(context),
              ),
            ),
        ],
      ),
    );
  }
}
DARTEOF
echo 'lib/features/home/screens/home_screen.dart — обновлён'

mkdir -p lib/features/home/widgets
cat > lib/features/home/widgets/showcase_section.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/mock_products.dart';
import '../../../models/product.dart';
import '../../../screens/catalog_screen.dart';
import '../../../screens/product_detail_screen.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/product_card.dart';

/// Блок "Сегодня на витрине". Занимает всё доступное место между шапкой
/// и "Популярное" (родитель — Expanded в HomeScreen) и прокручивается
/// САМ, отдельно от остального экрана — поэтому Главная целиком
/// помещается на экран, а не растягивается вниз с ростом числа карточек.
///
/// Карточки — тот же ProductCard и с тем же размером/стилем, что и в
/// «Каталоге» (controlScale по умолчанию = 1.0, без увеличения). Список —
/// все товары в наличии из mockProducts (без лимита — блок сам
/// прокручивается вертикально, см. комментарий выше).
class ShowcaseSection extends StatelessWidget {
  const ShowcaseSection({super.key});

  static final List<Product> _highlighted =
      mockProducts.where((p) => p.inStock).toList();

  static const double _cardTextBlockHeight = 80;
  static const double _gridSpacing = 10;

  void _openProductDetails(BuildContext context, Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Сегодня на витрине',
              style: GoogleFonts.alice(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.1,
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CatalogScreen()),
                );
              },
              child: Row(
                children: [
                  Text(
                    'Все',
                    style: AppTextStyles.rowLabel.copyWith(
                      color: AppColors.linkAccent,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 10,
                    color: AppColors.linkAccent,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - _gridSpacing) / 2;
              return GridView.builder(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: _gridSpacing,
                  crossAxisSpacing: _gridSpacing,
                  mainAxisExtent: itemWidth + _cardTextBlockHeight,
                ),
                itemCount: _highlighted.length,
                itemBuilder: (context, index) => ProductCard(
                  product: _highlighted[index],
                  onOpenDetails: (p) => _openProductDetails(context, p),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
DARTEOF
echo 'lib/features/home/widgets/showcase_section.dart — обновлён'

mkdir -p lib/screens
cat > lib/screens/product_detail_screen.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../theme/app_theme.dart';
import '../utils/toast.dart';
import 'preorder_screen.dart';

/// Экран «Карточка товара». Открывается с любой карточки товара в
/// приложении (Каталог, Избранное, «Сегодня на витрине»...) — передайте
/// сюда сам [Product], больше ничего не нужно, экран сам подписан на
/// CartProvider/FavoritesProvider.
class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final PageController _galleryController = PageController();
  int _galleryIndex = 0;

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final cart = context.watch<CartProvider>();
    final favorites = context.watch<FavoritesProvider>();
    final isFavorite = favorites.isFavorite(product);
    final quantity = cart.quantityOf(product);
    final gallery = product.gallery;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _GalleryHeader(
                  images: gallery,
                  controller: _galleryController,
                  currentIndex: _galleryIndex,
                  onPageChanged: (i) => setState(() => _galleryIndex = i),
                  isFavorite: isFavorite,
                  onBack: () => Navigator.of(context).maybePop(),
                  onToggleFavorite: () {
                    final wasFavorite = isFavorite;
                    favorites.toggle(product);
                    FadeToast.show(
                      context,
                      wasFavorite ? 'Удалено из избранного' : 'Добавлено в избранное',
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  transform: Matrix4.translationValues(0, -24, 0),
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.badge != null) _BadgeRow(badge: product.badge!),
                      if (product.badge != null) const SizedBox(height: 14),

                      Text(product.name, style: AppTextStyles.productDetailTitle),
                      const SizedBox(height: 10),

                      if (product.rating != null) ...[
                        _RatingRow(
                          rating: product.rating!,
                          reviewsCount: product.reviewsCount,
                        ),
                        const SizedBox(height: 16),
                      ],

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(formatPrice(product.price),
                              style: AppTextStyles.productDetailPrice),
                          const SizedBox(width: 8),
                          Text('за ${product.weightLabel}',
                              style: AppTextStyles.rowLabelMuted),
                        ],
                      ),

                      if (product.description != null) ...[
                        const SizedBox(height: 16),
                        Text(product.description!, style: AppTextStyles.descriptionText),
                      ],

                      if (product.hasNutritionInfo) ...[
                        const SizedBox(height: 22),
                        _NutritionCard(product: product),
                      ],

                      const SizedBox(height: 14),
                      _InfoRow(
                        icon: Icons.inventory_2_outlined,
                        label: 'Вес',
                        value: product.weightLabel,
                      ),

                      if (product.composition != null) ...[
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.eco_outlined,
                          label: 'Состав',
                          value: product.composition!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: _BottomActionBar(
                  product: product,
                  quantity: quantity,
                  onAdd: () => cart.add(product),
                  onIncrement: () => cart.increment(product),
                  onDecrement: () => cart.decrement(product),
                  onNotifyMe: () {
                    FadeToast.show(
                      context,
                      'Сообщим, когда товар появится в наличии',
                      icon: Icons.notifications_active,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryHeader extends StatelessWidget {
  final List<String> images;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onToggleFavorite;

  const _GalleryHeader({
    required this.images,
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
    required this.isFavorite,
    required this.onBack,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: top + 380,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: controller,
            onPageChanged: onPageChanged,
            itemCount: images.length,
            itemBuilder: (context, index) => Image.asset(
              images[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.surfaceMuted,
                child: const Icon(Icons.bakery_dining_outlined,
                    size: 48, color: AppColors.textSecondary),
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: top + 12,
            child: _RoundSquareButton(icon: Icons.arrow_back, onTap: onBack),
          ),
          Positioned(
            right: 16,
            top: top + 12,
            child: _RoundSquareButton(
              icon: isFavorite ? Icons.favorite : Icons.favorite_border,
              iconColor: isFavorite ? AppColors.badgePromo : AppColors.primaryBrown,
              onTap: onToggleFavorite,
            ),
          ),
          if (images.length > 1)
            Positioned(
              right: 16,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.image_outlined, size: 15, color: AppColors.primaryBrown),
                    const SizedBox(width: 5),
                    Text('${currentIndex + 1} / ${images.length}',
                        style: AppTextStyles.rowValue),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoundSquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  const _RoundSquareButton({
    required this.icon,
    required this.onTap,
    this.iconColor = AppColors.primaryBrown,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  final ProductBadge badge;

  const _BadgeRow({required this.badge});

  Color _bg(ProductBadge b) {
    switch (b) {
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
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _bg(badge),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badge == ProductBadge.hit) ...[
                const Icon(Icons.local_fire_department, size: 13, color: Colors.white),
                const SizedBox(width: 4),
              ],
              Text(badge.label,
                  style: AppTextStyles.statusPillLabel.copyWith(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RatingRow extends StatelessWidget {
  final double rating;
  final int? reviewsCount;

  const _RatingRow({required this.rating, this.reviewsCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 18, color: AppColors.accentGradientEnd),
        const SizedBox(width: 4),
        Text(rating.toStringAsFixed(1), style: AppTextStyles.ratingValue),
        if (reviewsCount != null) ...[
          const SizedBox(width: 8),
          Text('($reviewsCount)', style: AppTextStyles.rowLabelMuted),
          const SizedBox(width: 8),
          Text('•', style: AppTextStyles.rowLabelMuted),
          const SizedBox(width: 8),
          Text('$reviewsCount отзывов', style: AppTextStyles.rowLabelMuted),
        ],
      ],
    );
  }
}

class _NutritionCard extends StatelessWidget {
  final Product product;

  const _NutritionCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('КБЖУ на 100 г', style: AppTextStyles.sectionLabel.copyWith(fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _NutritionItem(
                  icon: Icons.local_fire_department_outlined,
                  label: 'Ккал',
                  value: product.caloriesPer100g?.toString() ?? '—',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NutritionItem(
                  icon: Icons.water_drop_outlined,
                  label: 'Белки',
                  value: product.proteinPer100g == null
                      ? '—'
                      : '${product.proteinPer100g!.toStringAsFixed(1)} г',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NutritionItem(
                  icon: Icons.eco_outlined,
                  label: 'Жиры',
                  value: product.fatPer100g == null
                      ? '—'
                      : '${product.fatPer100g!.toStringAsFixed(1)} г',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NutritionItem(
                  icon: Icons.grain,
                  label: 'Углеводы',
                  value: product.carbsPer100g == null
                      ? '—'
                      : '${product.carbsPer100g!.toStringAsFixed(1)} г',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NutritionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _NutritionItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: AppColors.primaryBrown),
              const SizedBox(width: 4),
              Flexible(
                child: Text(label,
                    style: AppTextStyles.nutritionLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.nutritionValue),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 19, color: AppColors.primaryBrown),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.sectionLabel.copyWith(fontSize: 14)),
                const SizedBox(height: 3),
                Text(value, style: AppTextStyles.rowLabelMuted.copyWith(height: 1.4)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final Product product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onNotifyMe;

  const _BottomActionBar({
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
    required this.onNotifyMe,
  });

  @override
  Widget build(BuildContext context) {
    if (!product.inStock) {
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PreorderScreen(product: product)),
                );
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accentGradientStart, AppColors.accentGradientEnd],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Предзаказ', style: AppTextStyles.cartBarButton),
                    const SizedBox(height: 2),
                    Text('Товара временно нет в наличии',
                        style: AppTextStyles.rowLabelMuted.copyWith(
                            color: Colors.white.withOpacity(0.9), fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onNotifyMe,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accentGradientEnd, width: 1.2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_none,
                      size: 18, color: AppColors.accentGradientEnd),
                  const SizedBox(height: 2),
                  Text('Уведомить\nо наличии',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.rowValue
                          .copyWith(color: AppColors.accentGradientEnd, fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (quantity == 0) {
      return GestureDetector(
        onTap: onAdd,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 17),
          decoration: BoxDecoration(
            color: AppColors.primaryBrown,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_bag_outlined, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text('Добавить в корзину · ${formatPrice(product.price)}',
                  style: AppTextStyles.cartBarButton),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryBrown,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Text('В корзине', style: AppTextStyles.cartBarButton.copyWith(fontSize: 14)),
          const Spacer(),
          _StepperControl(onDecrement: onDecrement, onIncrement: onIncrement, quantity: quantity),
          const SizedBox(width: 14),
          Text(formatPrice(product.price * quantity), style: AppTextStyles.cartBarButton),
        ],
      ),
    );
  }
}

class _StepperControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _StepperControl({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _button(Icons.remove, onDecrement),
        SizedBox(
          width: 28,
          child: Text('$quantity',
              textAlign: TextAlign.center,
              style: AppTextStyles.cartBarButton.copyWith(fontSize: 15)),
        ),
        _button(Icons.add, onIncrement),
      ],
    );
  }

  Widget _button(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}
DARTEOF
echo 'lib/screens/product_detail_screen.dart — обновлён'

mkdir -p lib/screens
cat > lib/screens/delivery_address_screen.dart << 'DARTEOF'
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import '../providers/location_provider.dart';
import '../theme/app_theme.dart';
import '../utils/toast.dart';
import '../utils/yandex_geocoder.dart';

/// Экран ввода адреса доставки в фирменном стиле Всласть — карта Яндекса
/// почти на весь экран, пин закреплён по центру экрана, карта двигается
/// под ним (стандартный паттерн "перетащи карту, чтобы поставить точку",
/// как в Яндекс.Еде/Delivery-приложениях).
///
/// При открытии карта всегда встаёт на город, выбранный в профиле —
/// геолокация пользователя используется ТОЛЬКО по явному нажатию на
/// кнопку "моё местоположение", не автоматически при входе на экран (в
/// доставке за пределы одного города смысла нет, а случайная геопозиция
/// при открытии только путает).
class DeliveryAddressScreen extends StatefulWidget {
  final String? initialAddress;

  const DeliveryAddressScreen({super.key, this.initialAddress});

  @override
  State<DeliveryAddressScreen> createState() => _DeliveryAddressScreenState();
}

class _DeliveryAddressScreenState extends State<DeliveryAddressScreen> {
  static const double _minZoom = 3;
  static const double _maxZoom = 19;

  YandexMapController? _mapController;
  late final TextEditingController _addressController =
      TextEditingController(text: widget.initialAddress);
  final TextEditingController _apartmentController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  Point? _selectedPoint;
  double _currentZoom = 15;
  bool _isLocating = false;
  bool _isGeocoding = false;
  bool _detailsExpanded = false;
  Timer? _geocodeDebounce;

  @override
  void dispose() {
    _addressController.dispose();
    _apartmentController.dispose();
    _floorController.dispose();
    _commentController.dispose();
    _geocodeDebounce?.cancel();
    super.dispose();
  }

  Future<void> _onMapCreated(YandexMapController controller) async {
    _mapController = controller;
    final city = context.read<LocationProvider>().cityCenter;
    final point = Point(latitude: city.$1, longitude: city.$2);
    await controller.moveCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: point, zoom: _currentZoom)),
    );
    setState(() => _selectedPoint = point);
  }

  /// Вызывается, когда камера сдвинулась (перетаскивание, зум, программное
  /// перемещение) — держим зум и центр карты в актуальном состоянии.
  void _onCameraChanged(CameraPosition position, bool finished) {
    _currentZoom = position.zoom;
    if (!finished) return;
    setState(() => _selectedPoint = position.target);
    _geocodeDebounce?.cancel();
    _geocodeDebounce = Timer(const Duration(milliseconds: 350), () {
      _reverseGeocode(position.target);
    });
  }

  bool _geocodeFailureShown = false;

  Future<void> _reverseGeocode(Point point) async {
    setState(() => _isGeocoding = true);
    final address = await YandexGeocoder.reverseGeocode(
      point.latitude,
      point.longitude,
    );
    if (!mounted) return;
    setState(() {
      _isGeocoding = false;
      // Геокодер не настроен/недоступен — оставляем то, что человек уже
      // ввёл руками, ничего не затираем пустотой.
      if (address != null) _addressController.text = address;
    });
    // Показываем один раз за визит на экран, а не при каждом движении
    // карты — иначе будет спамить тостами при активном скролле.
    if (address == null && !_geocodeFailureShown) {
      _geocodeFailureShown = true;
      if (!YandexGeocoder.isConfigured) {
        FadeToast.show(
          context,
          'Автоопределение адреса не настроено — введите вручную',
          icon: Icons.info_outline,
        );
      } else {
        FadeToast.show(
          context,
          'Не удалось определить адрес по карте — введите вручную',
          icon: Icons.error_outline,
        );
      }
    }
  }

  Future<void> _zoomBy(double delta) async {
    final target = _selectedPoint;
    if (target == null || _mapController == null) return;
    final newZoom = (_currentZoom + delta).clamp(_minZoom, _maxZoom);
    await _mapController!.moveCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: newZoom)),
      animation: const MapAnimation(type: MapAnimationType.smooth, duration: 0.2),
    );
    setState(() => _currentZoom = newZoom);
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          FadeToast.show(context, 'Нужен доступ к геолокации в настройках',
              icon: Icons.location_disabled);
        }
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          FadeToast.show(context, 'Включите геолокацию на устройстве',
              icon: Icons.location_disabled);
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 8));
      final point = Point(latitude: position.latitude, longitude: position.longitude);
      await _mapController?.moveCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: point, zoom: 16)),
        animation: const MapAnimation(type: MapAnimationType.smooth, duration: 0.4),
      );
      _onCameraChanged(CameraPosition(target: point, zoom: 16), true);
    } catch (_) {
      if (mounted) {
        FadeToast.show(context, 'Не удалось определить местоположение',
            icon: Icons.error_outline);
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _confirm() {
    final street = _addressController.text.trim();
    if (street.isEmpty) {
      FadeToast.show(context, 'Укажите адрес доставки', icon: Icons.error_outline);
      return;
    }
    final apartment = _apartmentController.text.trim();
    final floor = _floorController.text.trim();
    final comment = _commentController.text.trim();

    final parts = <String>[street];
    if (apartment.isNotEmpty) parts.add('кв. $apartment');
    if (floor.isNotEmpty) parts.add('этаж $floor');
    var result = parts.join(', ');
    if (comment.isNotEmpty) result = '$result ($comment)';

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Карта — почти на весь экран, под статус-баром и под нижней
          // панелью тоже (так же, как в вашем референсе).
          Positioned.fill(
            child: YandexMap(
              onMapCreated: _onMapCreated,
              onCameraPositionChanged: (position, reason, finished) {
                _onCameraChanged(position, finished);
              },
            ),
          ),

          // Закреплённый по центру экрана пин — карта двигается под ним,
          // сам он никогда не смещается.
          const IgnorePointer(
            child: Align(
              alignment: Alignment.center,
              child: Padding(
                // Небольшой сдвиг вверх, чтобы остриё пина указывало точно
                // в оптический центр, а не сама иконка целиком.
                padding: EdgeInsets.only(bottom: 36),
                child: Icon(Icons.location_on, size: 44, color: AppColors.primaryBrown),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
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
                        boxShadow: const [
                          BoxShadow(
                              color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 3)),
                        ],
                      ),
                      child: const Icon(Icons.chevron_left,
                          size: 24, color: AppColors.primaryBrown),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                              color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 3)),
                        ],
                      ),
                      child: Text('Адрес доставки', style: AppTextStyles.screenTitleSmall),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Зум +/- и "моё местоположение" — колонка плавающих кнопок
          // справа над картой. Отступ снизу подобран под компактную
          // нижнюю панель (см. _panelEstimatedHeight ниже) — если панель
          // разворачивается (показаны доп.поля), кнопки всё равно на
          // безопасной высоте, т.к. панель в развёрнутом виде скроллится
          // сама внутри себя, а не растёт поверх кнопок.
          Positioned(
            right: 16,
            bottom: 190,
            child: Column(
              children: [
                _MapRoundButton(icon: Icons.add, onTap: () => _zoomBy(1)),
                const SizedBox(height: 8),
                _MapRoundButton(icon: Icons.remove, onTap: () => _zoomBy(-1)),
                const SizedBox(height: 16),
                _MapRoundButton(
                  icon: Icons.my_location,
                  onTap: _isLocating ? null : _useCurrentLocation,
                  loading: _isLocating,
                ),
              ],
            ),
          ),

          // Нижняя панель — компактная по умолчанию (адрес + кнопка),
          // квартира/этаж/комментарий скрыты за раскрывашкой "Добавить
          // детали", чтобы не занимать пол-экрана, когда не нужны.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.42,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: Offset(0, -4)),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Улица, дом', style: AppTextStyles.fieldLabel),
                          if (_isGeocoding) ...[
                            const SizedBox(width: 8),
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                  strokeWidth: 1.6, color: AppColors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          controller: _addressController,
                          style: AppTextStyles.rowLabel,
                          decoration: InputDecoration(
                            hintText: 'Определяется по карте — или введите вручную',
                            hintStyle: AppTextStyles.searchHint,
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            prefixIcon: const Icon(Icons.location_on_outlined,
                                size: 18, color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => setState(() => _detailsExpanded = !_detailsExpanded),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _detailsExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                size: 18,
                                color: AppColors.linkAccent,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Квартира, этаж, комментарий курьеру',
                                style: AppTextStyles.linkText,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_detailsExpanded) ...[
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _SmallField(
                                label: 'Квартира',
                                hint: 'Например: 45',
                                controller: _apartmentController,
                                keyboardType: TextInputType.text,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SmallField(
                                label: 'Этаж',
                                hint: 'Например: 3',
                                controller: _floorController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text('Комментарий курьеру', style: AppTextStyles.fieldLabel),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TextField(
                            controller: _commentController,
                            maxLines: 2,
                            style: AppTextStyles.rowLabel,
                            decoration: InputDecoration(
                              hintText: 'Например: домофон 45К',
                              hintStyle: AppTextStyles.searchHint,
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ] else
                        const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: _confirm,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBrown,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            alignment: Alignment.center,
                            child: Text('Подтвердить адрес',
                                style: AppTextStyles.cartBarButton),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;

  const _SmallField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: AppTextStyles.rowLabel,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.searchHint,
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _MapRoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;

  const _MapRoundButton({required this.icon, required this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        child: loading
            ? const Padding(
                padding: EdgeInsets.all(13),
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primaryBrown),
              )
            : Icon(icon, size: 20, color: AppColors.primaryBrown),
      ),
    );
  }
}
DARTEOF
echo 'lib/screens/delivery_address_screen.dart — обновлён'

mkdir -p lib/screens
cat > lib/screens/order_confirmation_screen.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/tab_navigation_controller.dart';
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

  /// Возврат сразу на "Главную", а не на ту вкладку, с которой начался
  /// заказ ("Каталог") — после оформления корзина уже очищена,
  /// возвращаться в чекаут смысла нет. Простого popUntil(isFirst)
  /// недостаточно: он вернёт на MainScreen, но активная вкладка там
  /// останется прежней (IndexedStack не сбрасывается сам по себе) —
  /// поэтому сначала явно переключаем вкладку.
  void _goToCatalog(BuildContext context) {
    context.read<TabNavigationController>().goToCatalog();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

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
                      onTap: () => _goToCatalog(context),
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
                        value: order.deliveryAddress == null
                            ? order.deliveryMethod.title
                            : '${order.deliveryMethod.title}, ${order.deliveryAddress}',
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
                      context.read<TabNavigationController>().goToCatalog();
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
echo 'lib/screens/order_confirmation_screen.dart — обновлён'

mkdir -p lib/screens
cat > lib/screens/preorder_screen.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import '../widgets/category_chip.dart';
import 'auth_screen.dart';
import 'favorite_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

/// Экран «Предзаказ» в фирменном стиле Всласть — открывается с кнопки
/// «Предзаказ» на карточке товара (в каталоге, на карточке товара и т.д.)
/// для товаров с inStock == false.
///
/// Шаг выбора веса показывается ТОЛЬКО если [Product.showsWeightSelector]
/// (категория "торты" или явный признак "весовой") — для остальных
/// товаров (эклер, булочка и т.п.) этого шага просто нет в дереве
/// виджетов, поэтому высота экрана естественным образом меньше — никакого
/// отдельного расчёта высоты не нужно, Column сама короче без лишнего шага.
class PreorderScreen extends StatefulWidget {
  final Product product;

  const PreorderScreen({super.key, required this.product});

  @override
  State<PreorderScreen> createState() => _PreorderScreenState();
}

class _PreorderScreenState extends State<PreorderScreen> {
  static const List<String> _weightOptions = ['1 кг', '1.5 кг', '2 кг', '3 кг'];
  static const List<String> _timeSlots = [
    '10:00', '12:00', '14:00', '16:00', '18:00', '20:00',
  ];

  int _quantity = 1;
  late String _selectedWeight = _weightOptions.first;
  DateTime _pickupDate = DateTime.now().add(const Duration(days: 1));
  late String _pickupTime = _timeSlots[4];
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickupDate.isBefore(now) ? now : _pickupDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _pickupDate = picked);
  }

  Future<void> _pickTime() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            for (final slot in _timeSlots)
              ListTile(
                title: Text(slot, style: AppTextStyles.rowLabel),
                trailing: slot == _pickupTime
                    ? const Icon(Icons.check, color: AppColors.primaryBrown)
                    : null,
                onTap: () => Navigator.pop(sheetContext, slot),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected != null) setState(() => _pickupTime = selected);
  }

  void _openProfileMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final hasAccount = context.read<AuthProvider>().isLoggedIn;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.person_outline, color: AppColors.primaryBrown),
                title: Text('Профиль', style: AppTextStyles.rowLabel),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => hasAccount
                          ? const ProfileScreen()
                          : const AuthScreen(initialMode: AuthMode.register),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite_border, color: AppColors.primaryBrown),
                title: Text('Избранное', style: AppTextStyles.rowLabel),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FavoriteScreen()),
                  );
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.receipt_long_outlined, color: AppColors.primaryBrown),
                title: Text('Мои заказы', style: AppTextStyles.rowLabel),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OrdersScreen()),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _submit() {
    // TODO: отправить предзаказ на бэкенд (товар, количество, вес,
    // дата/время получения, комментарий).
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (dialogContext) => _PreorderConfirmedDialog(
        onDone: () {
          Navigator.of(dialogContext).pop();
          Navigator.of(context).maybePop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  _RoundButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Text(
                      'Предзаказ',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.screenTitleSmall,
                    ),
                  ),
                  _RoundButton(icon: Icons.person_outline, onTap: _openProfileMenu),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProductSummaryCard(product: product),
                    const SizedBox(height: 22),

                    _Section(
                      number: 1,
                      title: 'Количество',
                      child: _QuantityStepper(
                        quantity: _quantity,
                        onDecrement: () =>
                            setState(() => _quantity = (_quantity - 1).clamp(1, 99)),
                        onIncrement: () =>
                            setState(() => _quantity = (_quantity + 1).clamp(1, 99)),
                      ),
                    ),

                    if (product.showsWeightSelector) ...[
                      const SizedBox(height: 20),
                      _Section(
                        number: 2,
                        title: 'Вес торта',
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _weightOptions
                              .map((w) => CategoryChip(
                                    label: w,
                                    selected: w == _selectedWeight,
                                    onTap: () => setState(() => _selectedWeight = w),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    _Section(
                      number: product.showsWeightSelector ? 3 : 2,
                      title: 'Дата получения',
                      child: _DropdownField(
                        icon: Icons.calendar_today_outlined,
                        label: formatRuDateWithYear(_pickupDate),
                        onTap: _pickDate,
                      ),
                    ),

                    const SizedBox(height: 20),
                    _Section(
                      number: product.showsWeightSelector ? 4 : 3,
                      title: 'Время получения',
                      child: _DropdownField(
                        icon: Icons.access_time,
                        label: _pickupTime,
                        onTap: _pickTime,
                      ),
                    ),

                    const SizedBox(height: 20),
                    _Section(
                      number: product.showsWeightSelector ? 5 : 4,
                      title: 'Комментарий',
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          controller: _commentController,
                          maxLines: 3,
                          style: AppTextStyles.rowLabel,
                          decoration: InputDecoration(
                            hintText:
                                'Например: поздравительная надпись, оформление, пожелания...',
                            hintStyle: AppTextStyles.searchHint,
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline,
                              size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'После оформления предзаказа администратор свяжется '
                              'с вами для подтверждения деталей заказа.',
                              style: AppTextStyles.rowLabelMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: _submit,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 17),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBrown,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          alignment: Alignment.center,
                          child:
                              Text('Оформить предзаказ', style: AppTextStyles.cartBarButton),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductSummaryCard extends StatelessWidget {
  final Product product;

  const _ProductSummaryCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              product.imageUrl,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 96,
                height: 96,
                color: AppColors.surfaceMuted,
                child: const Icon(Icons.bakery_dining_outlined,
                    size: 28, color: AppColors.textSecondary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: AppTextStyles.orderTitle),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.public, size: 14, color: AppColors.statusPendingText),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Временно отсутствует в наличии',
                        style: AppTextStyles.statusPillLabel
                            .copyWith(color: AppColors.statusPendingText),
                      ),
                    ),
                  ],
                ),
                if (product.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    product.description!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.rowLabelMuted,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final int number;
  final String title;
  final Widget child;

  const _Section({required this.number, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$number. $title', style: AppTextStyles.fieldLabel),
        const SizedBox(height: 10),
        child,
      ],
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
    return Row(
      children: [
        _button(Icons.remove, onDecrement),
        SizedBox(
          width: 48,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: AppTextStyles.orderTitle,
          ),
        ),
        _button(Icons.add, onIncrement),
      ],
    );
  }

  Widget _button(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: AppColors.surfaceMuted,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: AppColors.primaryBrown),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DropdownField({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: AppTextStyles.rowLabel)),
            const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: Icon(icon, size: 20, color: AppColors.primaryBrown),
      ),
    );
  }
}

class _PreorderConfirmedDialog extends StatelessWidget {
  final VoidCallback onDone;

  const _PreorderConfirmedDialog({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.statusSuccessBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 28, color: AppColors.statusSuccessText),
            ),
            const SizedBox(height: 16),
            Text('Предзаказ оформлен', style: AppTextStyles.orderTitle),
            const SizedBox(height: 8),
            Text(
              'Спасибо! В ближайшее время администратор свяжется с вами '
              'для подтверждения заказа.',
              textAlign: TextAlign.center,
              style: AppTextStyles.rowLabelMuted,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: onDone,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBrown,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  alignment: Alignment.center,
                  child: Text('Понятно', style: AppTextStyles.cartBarButton),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
DARTEOF
echo 'lib/screens/preorder_screen.dart — обновлён'

echo ''
echo '!!! Впишите заново ключ HTTP Geocoder в lib/utils/yandex_geocoder.dart'
echo 'Затем: flutter clean && flutter pub get && flutter run'
