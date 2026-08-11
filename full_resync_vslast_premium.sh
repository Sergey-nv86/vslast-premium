#!/bin/bash
set -e
#
# ПОЛНАЯ синхронизация lib/ проекта vslast_premium — перезаписывает
# ВСЕ .dart файлы разом (52 файла), чтобы исключить любые расхождения
# из-за скриптов, применённых не полностью или не по порядку в прошлых
# раундах. Безопасно запускать даже если часть файлов уже актуальна —
# перезапишутся тем же содержимым.
#
# В этом раунде: шрифт на карточках товара крупнее; на Главной — 4
# карточки в «Сегодня на витрине»; исправлен переход на карточку товара
# из «Популярное» (добавлены 2 новых товара: Дакуаз, Тарт лимон-базилик);
# в меню профиля — выбор города (Нижневартовск/Екатеринбург/
# Санкт-Петербург); баннеры убраны с Каталога и Корзины; поиск на
# Каталоге сбрасывает категорию на «Все»; промокод в Корзине теперь
# работает (комментарий там по-прежнему убран); кнопка «В мои заказы»
# после оформления ведёт в Каталог; добавлен экран ввода адреса доставки
# (с плейсхолдером карты — см. комментарий в самом файле).
#
# ЗАПУСК: из корня проекта
#   cd /Users/sukolesnikov/Projects/vslast_premium
#   bash full_resync_vslast_premium.sh

mkdir -p lib

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
///
/// rating/reviewsCount/description/КБЖУ/состав — тоже мок-данные для
/// экрана «Карточка товара», под замену на реальные при подключении бэкенда.
final List<Product> mockProducts = [
  const Product(
    id: 'bread_village_sourdough',
    name: 'Хлеб деревенский на закваске',
    price: 390,
    imageUrl: 'assets/images/bread_country.jpg',
    category: ProductCategory.bread,
    badge: ProductBadge.hit,
    rating: 4.8,
    reviewsCount: 96,
    weightLabel: '750 г',
    description:
        'Хлеб на натуральной закваске длительной ферментации: хрустящая '
        'корочка, пористый мякиш и лёгкая кислинка. Без дрожжей и улучшителей.',
    caloriesPer100g: 245,
    proteinPer100g: 8.1,
    fatPer100g: 1.2,
    carbsPer100g: 48.5,
    composition: 'Мука пшеничная, вода, закваска, соль.',
    galleryImages: [
      'assets/images/bread_country.jpg',
      'assets/images/bread_sourdough_02.jpg',
      'assets/images/bread_rustic.jpg',
    ],
  ),
  const Product(
    id: 'baguette_classic',
    name: 'Багет классический',
    price: 220,
    imageUrl: 'assets/images/bread_classic.jpg',
    category: ProductCategory.bread,
    rating: 4.7,
    reviewsCount: 58,
    weightLabel: '300 г',
    description:
        'Французский багет с хрустящей корочкой и воздушным мякишем. '
        'Выпекается несколько раз в день, чтобы к вам он попадал только свежим.',
    caloriesPer100g: 262,
    proteinPer100g: 8.5,
    fatPer100g: 1.0,
    carbsPer100g: 53.0,
    composition: 'Мука пшеничная, вода, дрожжи, соль.',
    galleryImages: [
      'assets/images/bread_classic.jpg',
      'assets/images/bread_sourdough_04.jpg',
    ],
  ),
  const Product(
    id: 'croissant_butter',
    name: 'Круассан сливочный',
    price: 290,
    imageUrl: 'assets/images/bread_french.jpg',
    category: ProductCategory.pastry,
    badge: ProductBadge.newItem,
    rating: 4.9,
    reviewsCount: 121,
    weightLabel: '1 шт',
    description:
        'Слоёное тесто на настоящем сливочном масле — 27 тонких слоёв, '
        'хрустящих снаружи и нежных внутри. Наш самый популярный круассан.',
    caloriesPer100g: 406,
    proteinPer100g: 7.3,
    fatPer100g: 21.0,
    carbsPer100g: 45.8,
    composition: 'Мука пшеничная, масло сливочное, молоко, яйцо, сахар, дрожжи, соль.',
  ),
  const Product(
    id: 'brioche',
    name: 'Бриошь',
    price: 290,
    imageUrl: 'assets/images/bread_finnish.jpg',
    category: ProductCategory.pastry,
    rating: 4.6,
    reviewsCount: 34,
    weightLabel: '350 г',
    description:
        'Сдобная выпечка на сливочном масле и яйцах — мягкая, чуть сладкая, '
        'с нежным сливочным ароматом. Хороша сама по себе и с джемом.',
    caloriesPer100g: 320,
    proteinPer100g: 8.0,
    fatPer100g: 12.5,
    carbsPer100g: 45.0,
    composition: 'Мука пшеничная, масло сливочное, яйца, молоко, сахар, дрожжи, соль.',
    galleryImages: [
      'assets/images/bread_finnish.jpg',
      'assets/images/bread_sourdough_05.jpg',
    ],
  ),
  const Product(
    id: 'napoleon_cake',
    name: 'Наполеон',
    price: 420,
    imageUrl: 'assets/images/cake_signature.jpg',
    category: ProductCategory.cakes,
    badge: ProductBadge.hit,
    inStock: false,
    rating: 4.9,
    reviewsCount: 87,
    weightLabel: '350 г',
    description:
        'Классический торт из тонких слоёв слоёного теста с заварным кремом. '
        'Готовим по традиционному рецепту — настаивается сутки перед подачей.',
    caloriesPer100g: 355,
    proteinPer100g: 5.2,
    fatPer100g: 22.0,
    carbsPer100g: 34.0,
    composition: 'Мука, масло сливочное, яйца, молоко, сахар, ваниль.',
    galleryImages: [
      'assets/images/cake_signature.jpg',
      'assets/images/cake_crown_bordeaux.jpg',
      'assets/images/cake_crown_breton.png',
    ],
  ),
  const Product(
    id: 'cheesecake_cherry',
    name: 'Чизкейк с вишней',
    price: 250,
    imageUrl: 'assets/images/dessert_tart.jpg',
    category: ProductCategory.desserts,
    badge: ProductBadge.newItem,
    rating: 4.8,
    reviewsCount: 42,
    weightLabel: '1 шт (120 г)',
    description:
        'Нежный чизкейк на песочной основе с вишнёвым соусом. Кремовая '
        'текстура и лёгкая кислинка вишни — баланс сладкого и свежего.',
    caloriesPer100g: 298,
    proteinPer100g: 5.6,
    fatPer100g: 19.4,
    carbsPer100g: 27.0,
    composition: 'Творожный сыр, сливки, яйца, сахар, песочное печенье, вишня.',
    galleryImages: [
      'assets/images/dessert_tart.jpg',
      'assets/images/dessert_dacquoise.jpg',
    ],
  ),
  const Product(
    id: 'ciabatta',
    name: 'Чиабатта',
    price: 450,
    imageUrl: 'assets/images/bread_chiabatta.jpg',
    category: ProductCategory.bread,
    rating: 4.7,
    reviewsCount: 29,
    weightLabel: '400 г',
    description:
        'Итальянский хлеб с крупнопористым мякишем и хрустящей мучнистой '
        'корочкой. Готовим на оливковом масле по классической рецептуре.',
    caloriesPer100g: 271,
    proteinPer100g: 9.0,
    fatPer100g: 3.5,
    carbsPer100g: 50.0,
    composition: 'Мука пшеничная, вода, оливковое масло, дрожжи, соль.',
    galleryImages: [
      'assets/images/bread_chiabatta.jpg',
      'assets/images/bread_sourdough_06.jpg',
    ],
  ),
  const Product(
    id: 'grain_bun',
    name: 'Булочка зерновая',
    price: 120,
    imageUrl: 'assets/images/bread_sourdough_01.jpg',
    category: ProductCategory.pastry,
    badge: ProductBadge.promo,
    inStock: false,
    rating: 4.5,
    reviewsCount: 18,
    weightLabel: '120 г',
    description:
        'Булочка с цельнозерновой мукой и смесью семян — плотная, сытная, '
        'с лёгким ореховым привкусом. Хороший выбор для завтрака.',
    caloriesPer100g: 258,
    proteinPer100g: 9.4,
    fatPer100g: 4.8,
    carbsPer100g: 44.0,
    composition: 'Мука цельнозерновая, вода, семена подсолнечника, лён, кунжут, дрожжи, соль.',
    galleryImages: [
      'assets/images/bread_sourdough_01.jpg',
      'assets/images/bread_sourdough_07.jpg',
    ],
  ),
  const Product(
    id: 'eclair_chocolate',
    name: 'Эклер шоколадный',
    price: 210,
    imageUrl: 'assets/images/dessert_eclair.jpg',
    category: ProductCategory.desserts,
    rating: 4.9,
    reviewsCount: 64,
    weightLabel: '1 шт (90 г)',
    description:
        'Заварное тесто с воздушным кремом и шоколадной глазурью. '
        'Классика французской кондитерской в фирменном исполнении Всласть.',
    caloriesPer100g: 312,
    proteinPer100g: 6.0,
    fatPer100g: 18.0,
    carbsPer100g: 32.0,
    composition: 'Мука, масло сливочное, яйца, молоко, сахар, шоколад, крем заварной.',
    galleryImages: [
      'assets/images/dessert_eclair.jpg',
      'assets/images/dessert_lemon_basil.jpg',
    ],
  ),
  const Product(
    id: 'dacquoise',
    name: 'Дакуаз',
    price: 260,
    imageUrl: 'assets/images/dessert_dacquoise.jpg',
    category: ProductCategory.desserts,
    rating: 4.8,
    reviewsCount: 37,
    weightLabel: '1 шт (110 г)',
    description:
        'Миндально-фундучный бисквит дакуаз с воздушным кремом — хрустящий '
        'снаружи, нежный внутри. Один из самых деликатных десертов витрины.',
    caloriesPer100g: 340,
    proteinPer100g: 5.8,
    fatPer100g: 21.0,
    carbsPer100g: 30.0,
    composition: 'Миндальная и фундучная мука, яичный белок, сахар, сливочный крем.',
  ),
  const Product(
    id: 'lemon_basil_tart',
    name: 'Тарт лимон-базилик',
    price: 320,
    imageUrl: 'assets/images/dessert_lemon_basil.jpg',
    category: ProductCategory.desserts,
    rating: 4.7,
    reviewsCount: 21,
    weightLabel: '1 шт (100 г)',
    description:
        'Песочная тарталетка с лимонным курдом и лёгкой нотой свежего '
        'базилика — освежающий десерт с яркой кислинкой.',
    caloriesPer100g: 310,
    proteinPer100g: 4.5,
    fatPer100g: 16.0,
    carbsPer100g: 36.0,
    composition: 'Песочное тесто, лимонный курд, свежий базилик, сахар, яйца.',
  ),
];
DARTEOF
echo 'lib/data/mock_products.dart — записан'

mkdir -p lib/features/home/screens
cat > lib/features/home/screens/home_screen.dart << 'DARTEOF'
import 'package:flutter/material.dart';

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
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeHeader(),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: ShowcaseSection(),
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
    );
  }
}
DARTEOF
echo 'lib/features/home/screens/home_screen.dart — записан'

mkdir -p lib/features/home/widgets
cat > lib/features/home/widgets/bottom_nav_bar.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Раньше иконки/подписи выглядели блёкло — маленький размер, светлый
/// неактивный цвет, тонкий (не переопределяемый в коде) штрих у самих
/// SVG-файлов. Здесь: крупнее иконки, темнее неактивный цвет, жирный шрифт
/// у подписей всегда (не только у активной), плюс лёгкий приём "faux bold" —
/// иконка отрисовывается двойным слоем со сдвигом на пол-пикселя, что
/// визуально утолщает тонкий штрих без правки самого SVG-файла.
class PremiumBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const PremiumBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const Color _activeColor = Color(0xFF201C1A);
  static const Color _inactiveColor = Color(0xFF8A8177);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(top: 10, bottom: bottomInset > 0 ? bottomInset : 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF8),
        border: Border(
          top: BorderSide(color: Colors.black.withOpacity(.08), width: 1),
        ),
      ),
      child: Row(
        children: [
          _item(icon: 'assets/icons/home.svg', label: 'Главная', index: 0),
          _item(icon: 'assets/icons/catalog.svg', label: 'Каталог', index: 1),
          _item(icon: 'assets/icons/premium.svg', label: 'Карта', index: 2),
          _item(
            icon: 'assets/icons/favorite.svg',
            label: 'Избранное',
            index: 3,
          ),
          _item(icon: 'assets/icons/add.svg', label: 'Корзина', index: 4),
        ],
      ),
    );
  }

  Widget _item({
    required String icon,
    required String label,
    required int index,
  }) {
    final selected = currentIndex == index;
    final color = selected ? _activeColor : _inactiveColor;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _boldIcon(icon, color, 23),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _boldIcon(String path, Color color, double size) {
    final colorFilter = ColorFilter.mode(color, BlendMode.srcIn);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          SvgPicture.asset(path, width: size, height: size, colorFilter: colorFilter),
          Positioned(
            left: 0.6,
            top: 0.6,
            child:
                SvgPicture.asset(path, width: size, height: size, colorFilter: colorFilter),
          ),
        ],
      ),
    );
  }
}
DARTEOF
echo 'lib/features/home/widgets/bottom_nav_bar.dart — записан'

mkdir -p lib/features/home/widgets
cat > lib/features/home/widgets/category_section.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CategorySection extends StatelessWidget {
  const CategorySection({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      (icon: 'assets/icons/bread.svg', title: 'Хлеб'),
      (icon: 'assets/icons/pastry.svg', title: 'Выпечка'),
      (icon: 'assets/icons/cake.svg', title: 'Торты'),
      (icon: 'assets/icons/dessert.svg', title: 'Десерты'),
    ];

    return SizedBox(
      height: 70,
      child: Row(
        children: categories.map((item) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      item.icon,
                      width: 28,
                      height: 28,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF7B4A22),
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D2621),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
DARTEOF
echo 'lib/features/home/widgets/category_section.dart — записан'

mkdir -p lib/features/home/widgets
cat > lib/features/home/widgets/home_header.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/location_provider.dart';
import '../../../screens/auth_screen.dart';
import '../../../screens/favorite_screen.dart';
import '../../../screens/orders_screen.dart';
import '../../../screens/profile_screen.dart';
import '../../../theme/app_theme.dart';

/// Шапка «Главной»: фото-баннер, приветствие и иконка профиля.
/// Строку поиска отсюда убрали по вашей просьбе — если понадобится
/// вернуть, поищите её в истории версий этого файла.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  void _openProfileMenu(BuildContext context) {
    showModalBottomSheet(
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
            const SizedBox(height: 12),
            _ProfileMenuTile(
              icon: Icons.person_outline,
              label: 'Профиль',
              onTap: () {
                Navigator.pop(sheetContext);
                // Вход нужен только один раз: если пользователь уже
                // входил раньше (AuthProvider.isLoggedIn сохраняется на
                // устройстве) — сразу открываем «Профиль», а не форму
                // входа. Иначе — «Регистрацию», данных ещё нет.
                final auth = context.read<AuthProvider>();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => auth.isLoggedIn
                        ? const ProfileScreen()
                        : const AuthScreen(initialMode: AuthMode.register),
                  ),
                );
              },
            ),
            _ProfileMenuTile(
              icon: Icons.favorite_border,
              label: 'Избранное',
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FavoriteScreen()),
                );
              },
            ),
            _ProfileMenuTile(
              icon: Icons.location_on_outlined,
              label: 'Город',
              value: context.read<LocationProvider>().city,
              onTap: () {
                Navigator.pop(sheetContext);
                _pickCity(context);
              },
            ),
            _ProfileMenuTile(
              icon: Icons.receipt_long_outlined,
              label: 'Мои заказы',
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
      ),
    );
  }

  void _pickCity(BuildContext context) {
    final location = context.read<LocationProvider>();
    showModalBottomSheet<void>(
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
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Ваш город', style: AppTextStyles.sectionLabel),
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (final city in LocationProvider.availableCities)
              ListTile(
                title: Text(city, style: AppTextStyles.rowLabel),
                trailing: city == location.city
                    ? const Icon(Icons.check, color: AppColors.primaryBrown)
                    : null,
                onTap: () {
                  location.setCity(city);
                  Navigator.pop(sheetContext);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    const double photoHeight = 140;

    return SizedBox(
      width: double.infinity,
      height: top + photoHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/hero_banner.jpg',
              fit: BoxFit.cover,
            ),
          ),

          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 260,
              height: top + photoHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white.withOpacity(.55),
                    Colors.white.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            left: 22,
            top: top + 16,
            right: 96,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Доброе утро,\nСергей!',
                  style: GoogleFonts.alice(
                    color: AppColors.primaryBrown,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Испечено с любовью\nдля Вас.',
                  style: AppTextStyles.rowLabelMuted.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            right: 22,
            top: top + 6,
            child: GestureDetector(
              onTap: () => _openProfileMenu(context),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.94),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 15,
                  color: AppColors.linkAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _ProfileMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: AppColors.primaryBrown),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: AppTextStyles.rowLabel)),
            if (value != null) ...[
              Text(value!, style: AppTextStyles.rowLabelMuted),
              const SizedBox(width: 6),
            ],
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
DARTEOF
echo 'lib/features/home/widgets/home_header.dart — записан'

mkdir -p lib/features/home/widgets
cat > lib/features/home/widgets/popular_section.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/mock_products.dart';
import '../../../models/product.dart';
import '../../../screens/product_detail_screen.dart';
import '../../../theme/app_theme.dart';

/// Блок "Популярное". Раньше карточки были декоративными (свои
/// image/title/price без связи с товаром, без onTap) — отсюда и не
/// открывалась карточка товара по нажатию. Теперь ссылаемся на реальные
/// Product из mockProducts — переход на ProductDetailScreen работает, и
/// цена/фото/название больше не могут разойтись с каталогом.
class PopularSection extends StatelessWidget {
  const PopularSection({super.key});

  static final List<Product> _items = [
    mockProducts.firstWhere((p) => p.id == 'eclair_chocolate'),
    mockProducts.firstWhere((p) => p.id == 'dacquoise'),
    mockProducts.firstWhere((p) => p.id == 'lemon_basil_tart'),
    mockProducts.firstWhere((p) => p.id == 'ciabatta'),
    mockProducts.firstWhere((p) => p.id == 'grain_bun'),
  ];

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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                "Популярное",
                style: GoogleFonts.alice(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              const Text(
                "Все",
                style: TextStyle(
                  color: AppColors.linkAccent,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.linkAccent),
            ],
          ),
        ),

        const SizedBox(height: 8),

        SizedBox(
          height: 114,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) => _PopularItem(
              product: _items[index],
              onTap: () => _openProductDetails(context, _items[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _PopularItem extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _PopularItem({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 76,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 76,
                height: 76,
                child: Image.asset(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.surfaceMuted,
                    child: const Icon(Icons.bakery_dining_outlined,
                        size: 22, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              product.inStock ? "${product.price} ₽" : "Под заказ",
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
DARTEOF
echo 'lib/features/home/widgets/popular_section.dart — записан'

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
/// только товары в наличии (первые 4 из mockProducts, отфильтрованных по
/// inStock), чтобы здесь не показывался "Предзаказ", и чтобы все карточки
/// целиком помещались до блока "Популярное" на типичном экране.
class ShowcaseSection extends StatelessWidget {
  const ShowcaseSection({super.key});

  static final List<Product> _highlighted =
      mockProducts.where((p) => p.inStock).take(4).toList();

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
echo 'lib/features/home/widgets/showcase_section.dart — записан'

mkdir -p lib/features/loyalty/screens
cat > lib/features/loyalty/screens/qr_screen.dart << 'DARTEOF'
import 'package:flutter/material.dart';

class QrScreen extends StatelessWidget {
  const QrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F3EE),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xffF7F3EE),
        centerTitle: true,
        title: const Text(
          "Всласть Premium",
          style: TextStyle(
            color: Color(0xff2D2621),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Предъявите QR-код кассиру",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff2D2621),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  "Начисление и списание бонусов",
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),

                const SizedBox(height: 36),

                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.08),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),

                  child: Column(
                    children: [
                      SizedBox(
                        width: 250,
                        height: 250,
                        child: Image.asset(
                          "assets/images/qr_demo.png",
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 22),

                      const Text(
                        "Сергей",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        "Gold Premium",
                        style: TextStyle(
                          color: Color(0xff8B5E3C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff8B5E3C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: const Text(
                      "Закрыть",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
DARTEOF
echo 'lib/features/loyalty/screens/qr_screen.dart — записан'

mkdir -p lib/features/loyalty/widgets
cat > lib/features/loyalty/widgets/benefits_grid.dart << 'DARTEOF'
import 'package:flutter/material.dart';

class BenefitsGrid extends StatelessWidget {
  const BenefitsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final benefits = [
      (
        icon: Icons.cake_rounded,
        title: "Подарок\nна День рождения",
        color: const Color(0xffD69A2D),
      ),
      (
        icon: Icons.local_fire_department_rounded,
        title: "Ранний доступ\nк новинкам",
        color: const Color(0xffD26A45),
      ),
      (
        icon: Icons.coffee_rounded,
        title: "Бесплатный\nкофе",
        color: const Color(0xff7B4A22),
      ),
      (
        icon: Icons.restaurant_menu_rounded,
        title: "Закрытые\nдегустации",
        color: const Color(0xff8A6B47),
      ),
      (
        icon: Icons.card_giftcard_rounded,
        title: "Персональные\nпредложения",
        color: const Color(0xff4D8A66),
      ),
      (
        icon: Icons.workspace_premium_rounded,
        title: "Приоритетный\nпредзаказ",
        color: const Color(0xff6C63B8),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: benefits.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (_, index) {
        final item = benefits[index];

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: item.color.withOpacity(.12),
                child: Icon(item.icon, color: item.color, size: 28),
              ),

              const SizedBox(height: 16),

              Text(
                item.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff2D2621),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
DARTEOF
echo 'lib/features/loyalty/widgets/benefits_grid.dart — записан'

mkdir -p lib/features/loyalty/widgets
cat > lib/features/loyalty/widgets/bonus_balance_card.dart << 'DARTEOF'
import 'package:flutter/material.dart';

class BonusBalanceCard extends StatelessWidget {
  const BonusBalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: "Бонусы",
            value: "2 480",
            icon: Icons.stars_rounded,
            color: const Color(0xffD68B2A),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _StatCard(
            title: "Кэшбэк",
            value: "7%",
            icon: Icons.savings_rounded,
            color: const Color(0xff6B8E4E),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(.12),
            child: Icon(icon, color: color, size: 22),
          ),

          const Spacer(),

          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xff2D2621),
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            style: const TextStyle(
              color: Color(0xff8C837D),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
DARTEOF
echo 'lib/features/loyalty/widgets/bonus_balance_card.dart — записан'

mkdir -p lib/features/loyalty/widgets
cat > lib/features/loyalty/widgets/history_list.dart << 'DARTEOF'
import 'package:flutter/material.dart';

class HistoryList extends StatelessWidget {
  const HistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final history = [
      (
        title: "Хлеб Деревенский",
        subtitle: "Сегодня • 09:42",
        bonus: "+35",
        color: const Color(0xff5BAA5B),
        icon: Icons.add_circle_rounded,
      ),
      (
        title: "Торт Фисташковый",
        subtitle: "Вчера • 18:26",
        bonus: "+120",
        color: const Color(0xff5BAA5B),
        icon: Icons.add_circle_rounded,
      ),
      (
        title: "Оплата бонусами",
        subtitle: "20 июля • 13:18",
        bonus: "-200",
        color: const Color(0xffD86A52),
        icon: Icons.remove_circle_rounded,
      ),
      (
        title: "Круассан Миндальный",
        subtitle: "18 июля • 08:55",
        bonus: "+18",
        color: const Color(0xff5BAA5B),
        icon: Icons.add_circle_rounded,
      ),
    ];

    return Column(
      children: history.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: item.color.withOpacity(.12),
                child: Icon(item.icon, color: item.color, size: 26),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff2D2621),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xff8C837D),
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                item.bonus,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: item.color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
DARTEOF
echo 'lib/features/loyalty/widgets/history_list.dart — записан'

mkdir -p lib/features/loyalty/widgets
cat > lib/features/loyalty/widgets/loyalty_qr_card.dart << 'DARTEOF'
import 'package:flutter/material.dart';

class LoyaltyQrCard extends StatelessWidget {
  const LoyaltyQrCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Карта клиента",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xff2D2621),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            "Покажите QR-код кассиру\nдля начисления бонусов",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xff8C837D)),
          ),

          const SizedBox(height: 24),

          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: Icon(
                Icons.qr_code_2_rounded,
                size: 150,
                color: Color(0xff2D2621),
              ),
            ),
          ),

          const SizedBox(height: 22),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xffF6F1EB),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              "№ 000128",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xff7B4A22),
              ),
            ),
          ),

          const SizedBox(height: 26),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff7B4A22),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () {},
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text(
                "Показать QR кассиру",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
DARTEOF
echo 'lib/features/loyalty/widgets/loyalty_qr_card.dart — записан'

mkdir -p lib/features/loyalty/widgets
cat > lib/features/loyalty/widgets/premium_card.dart << 'DARTEOF'
import 'package:flutter/material.dart';

class PremiumCard extends StatelessWidget {
  const PremiumCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 215,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xffA36A39), Color(0xff7B4A22), Color(0xff5B3215)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(.05),
              ),
            ),
          ),

          Positioned(
            bottom: -45,
            left: -35,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(.04),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "ВСЛАСТЬ",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  "Premium Club",
                  style: TextStyle(
                    color: Colors.white.withOpacity(.85),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const Spacer(),

                const Text(
                  "Сергей Колесников",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.18),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.workspace_premium,
                            color: Colors.amber,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            "PREMIUM",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    Text(
                      "№ 000128",
                      style: TextStyle(
                        color: Colors.white.withOpacity(.85),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.18),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: .82,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "До уровня Diamond осталось 18%",
                  style: TextStyle(
                    color: Colors.white.withOpacity(.82),
                    fontSize: 13,
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
DARTEOF
echo 'lib/features/loyalty/widgets/premium_card.dart — записан'

mkdir -p lib/features/loyalty/widgets
cat > lib/features/loyalty/widgets/qr_button.dart << 'DARTEOF'
import 'package:flutter/material.dart';

class QRButton extends StatelessWidget {
  const QRButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.qr_code_scanner_rounded, size: 26),
        label: const Text(
          "Показать QR кассиру",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: .2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF7B4A22),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
DARTEOF
echo 'lib/features/loyalty/widgets/qr_button.dart — записан'

mkdir -p lib/features/loyalty/widgets
cat > lib/features/loyalty/widgets/status_card.dart << 'DARTEOF'
import 'package:flutter/material.dart';

class StatusCard extends StatelessWidget {
  const StatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Ваш статус",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xff2D2621),
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: const [
              _Level(active: false, emoji: "🥉", title: "Classic"),
              SizedBox(width: 12),
              _Level(active: false, emoji: "🥈", title: "Silver"),
              SizedBox(width: 12),
              _Level(active: true, emoji: "🥇", title: "Gold"),
              SizedBox(width: 12),
              _Level(active: false, emoji: "💎", title: "Premium"),
            ],
          ),

          const SizedBox(height: 24),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: const LinearProgressIndicator(
              value: .72,
              minHeight: 10,
              backgroundColor: Color(0xffECE6DE),
              valueColor: AlwaysStoppedAnimation(Color(0xffD69A2D)),
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            "До Premium осталось покупок на 754 ₽",
            style: TextStyle(fontSize: 14, color: Color(0xff8C837D)),
          ),
        ],
      ),
    );
  }
}

class _Level extends StatelessWidget {
  final bool active;
  final String emoji;
  final String title;

  const _Level({
    required this.active,
    required this.emoji,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? const Color(0xff7B4A22) : const Color(0xffF5F1EC),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : const Color(0xff6A625D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
DARTEOF
echo 'lib/features/loyalty/widgets/status_card.dart — записан'

mkdir -p lib/features/splash/screens
cat > lib/features/splash/screens/splash_screen.dart << 'DARTEOF'
import 'dart:async';
import 'package:flutter/material.dart';

import '../../../screens/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();

    Timer(const Duration(seconds: 4), () async {
      await _controller.reverse();

      if (!mounted) return;

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _opacity,
        child: SizedBox.expand(
          child: Image.asset('assets/images/splash.jpg', fit: BoxFit.cover),
        ),
      ),
    );
  }
}
DARTEOF
echo 'lib/features/splash/screens/splash_screen.dart — записан'

cat > lib/main.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'features/splash/screens/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/location_provider.dart';
import 'providers/tab_navigation_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VslastPremiumApp());
}

class VslastPremiumApp extends StatelessWidget {
  const VslastPremiumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TabNavigationController()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        // сюда же добавляйте любые другие провайдеры проекта
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Всласть Premium',

        // Единый шрифт для всего приложения: Manrope — для основного
        // текста (чистый, современный, отлично читается на мелких
        // размерах — цены, лейблы, кнопки), Playfair Display — для
        // заголовков и брендовых надписей (см. AppTextStyles в
        // lib/theme/app_theme.dart: screenTitle, orderTitle,
        // authLogoTitle и т.д. уже используют его явно).
        // Раньше в разных местах проекта встречались разные варианты
        // ('SF Pro Display', 'Georgia', голые строки "PlayfairDisplay"/
        // "GreatVibes" без реального шрифта) — они не были на самом деле
        // подключены как ассеты и тихо откатывались на системный шрифt
        // платформы, из-за чего вид отличался от экрана к экрану.
        // GoogleFonts грузит и кэширует настоящий файл шрифта, поэтому
        // выглядит одинаково на всех платформах.
        // Единый шрифт для всего приложения — теперь по брендбуку "Всласть":
        // Alice — для заголовков/эмоциональных элементов (см. AppTextStyles:
        // screenTitle, orderTitle, authLogoTitle и т.д.), Jost — основной
        // UI-шрифт (цены, кнопки, лейблы). Раньше здесь стояла пара
        // Playfair Display + Manrope — рабочая, но не из фирменного
        // брендбука; смена сделана в одном месте (app_theme.dart) и здесь,
        // остальные экраны ничего не знают о конкретном шрифте.
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFFAF7F1),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF201C1A)),
          textTheme: GoogleFonts.jostTextTheme(),
        ),

        home: const SplashScreen(),
      ),
    );
  }
}
DARTEOF
echo 'lib/main.dart — записан'

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

  @override
  bool operator ==(Object other) => other is Product && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
DARTEOF
echo 'lib/models/product.dart — записан'

mkdir -p lib/providers
cat > lib/providers/auth_provider.dart << 'DARTEOF'
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Состояние "пользователь уже входил в приложение раньше" —
/// сохраняется на устройстве (SharedPreferences), поэтому вход
/// действительно нужен только один раз: после успешного входа/регистрации
/// при следующих запусках приложение открывается сразу, без экрана
/// «Вход/Регистрация».
///
/// TODO: это упрощённая замена настоящей авторизации — здесь нет ни
/// токена, ни проверки пароля на сервере. Когда подключите бэкенд,
/// замените isLoggedIn/markLoggedIn на реальную сессию (токен + его
/// проверку/обновление), а этот класс можно оставить как обёртку над тем
/// же UI-состоянием.
class AuthProvider extends ChangeNotifier {
  static const _keyLoggedIn = 'auth_is_logged_in';
  static const _keyDisplayName = 'auth_display_name';

  bool _isLoggedIn = false;
  bool _isLoaded = false;
  String? _displayName;

  bool get isLoggedIn => _isLoggedIn;

  /// true, когда сохранённое состояние уже прочитано с устройства.
  /// Пока false — не принимайте решений об isLoggedIn, подождите.
  bool get isLoaded => _isLoaded;

  String? get displayName => _displayName;

  AuthProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_keyLoggedIn) ?? false;
    _displayName = prefs.getString(_keyDisplayName);
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> markLoggedIn({String? displayName}) async {
    _isLoggedIn = true;
    if (displayName != null && displayName.trim().isNotEmpty) {
      _displayName = displayName.trim();
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, true);
    if (_displayName != null) {
      await prefs.setString(_keyDisplayName, _displayName!);
    }
  }

  /// Выход — пригодится для кнопки "Выйти" на экране «Профиль»
  /// и для проверки сценария первого входа при разработке.
  Future<void> logout() async {
    _isLoggedIn = false;
    _displayName = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoggedIn);
    await prefs.remove(_keyDisplayName);
  }
}
DARTEOF
echo 'lib/providers/auth_provider.dart — записан'

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

mkdir -p lib/providers
cat > lib/providers/location_provider.dart << 'DARTEOF'
import 'package:flutter/foundation.dart';

/// Выбранный пользователем город. Список городов сейчас фиксированный —
/// расширите под реальные города доставки/самовывоза, когда появятся.
class LocationProvider extends ChangeNotifier {
  static const List<String> availableCities = [
    'Нижневартовск',
    'Екатеринбург',
    'Санкт-Петербург',
  ];

  String _city = availableCities.first;

  String get city => _city;

  void setCity(String city) {
    if (!availableCities.contains(city) || city == _city) return;
    _city = city;
    notifyListeners();
  }
}
DARTEOF
echo 'lib/providers/location_provider.dart — записан'

mkdir -p lib/providers
cat > lib/providers/tab_navigation_controller.dart << 'DARTEOF'
import 'package:flutter/foundation.dart';

/// Индекс активной вкладки нижней панели (Главная/Каталог/Карта/
/// Избранное/Корзина) в [MainScreen] — вынесен в провайдер, чтобы любой
/// push-экран (например, «Заказ принят») мог переключить пользователя на
/// вкладку «Главная», не имея прямого доступа к состоянию MainScreen.
class TabNavigationController extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  static const int homeIndex = 0;
  static const int catalogIndex = 1;

  void setIndex(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    notifyListeners();
  }

  void goToHome() => setIndex(homeIndex);
  void goToCatalog() => setIndex(catalogIndex);
}
DARTEOF
echo 'lib/providers/tab_navigation_controller.dart — записан'

mkdir -p lib/screens
cat > lib/screens/auth_screen.dart << 'DARTEOF'
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import '../utils/phone_formatter.dart';
import '../widgets/labeled_text_field.dart';

enum AuthMode { login, register }

/// Экран «Вход/Регистрация». Открывается через Navigator.push — например,
/// с пункта «Профиль» в меню, которое выпадает по нажатию на иконку
/// профиля на «Главной». Через [initialMode] можно сразу открыть нужный
/// режим — например, «Регистрация» при первом обращении пользователя
/// (см. AuthProvider.isLoggedIn).
class AuthScreen extends StatefulWidget {
  final AuthMode initialMode;

  const AuthScreen({super.key, this.initialMode = AuthMode.login});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late AuthMode _mode = widget.initialMode;

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

  // Список городов — единый с меню профиля на Главной, см.
  // LocationProvider.availableCities.

  @override
  void initState() {
    super.initState();
    _selectedCity = context.read<LocationProvider>().city;
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
          children: LocationProvider.availableCities
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
    // TODO: подключить реальную авторизацию (логин/телефон + пароль).
    context.read<AuthProvider>().markLoggedIn(displayName: _loginController.text);
    context.read<LocationProvider>().setCity(_selectedCity);
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
    context.read<AuthProvider>().markLoggedIn(displayName: _firstNameController.text);
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
              Image.asset(
                'assets/images/logo_light.png',
                width: double.infinity,
                height: 130,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 130,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.image_outlined,
                      size: 36, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 20),
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
///
/// Комментарий к заказу убран — этот шаг теперь только на «Оформлении
/// заказа», чтобы не дублировать одно и то же на двух экранах подряд.
/// Промокод, наоборот, остаётся здесь и работает (шторка ввода кода).
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String? _promoCode;

  void _openCheckout(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    );
  }

  Future<void> _editPromoCode() async {
    final controller = TextEditingController(text: _promoCode);
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
            Text('Промокод', style: AppTextStyles.sectionLabel),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Например: SALE10',
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
                  child: Text('Применить', style: AppTextStyles.cartBarButton),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      // TODO: подключить реальную проверку промокода на бэкенде
      // (сейчас код просто сохраняется и показывается как применённый,
      // без пересчёта суммы).
      setState(() => _promoCode = result.isEmpty ? null : result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final entries = cart.items.entries.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: entries.isEmpty
            ? const _EmptyCartState()
            : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Корзина', style: AppTextStyles.screenTitle),
                                Text(
                                  '${cart.totalCount} ${pluralizeItems(cart.totalCount)}',
                                  style: AppTextStyles.rowLabelMuted,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
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
                      child: _PromoCodeRow(code: _promoCode, onTap: _editPromoCode),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
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
                          onTap: () => _openCheckout(context),
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

class _PromoCodeRow extends StatelessWidget {
  final String? code;
  final VoidCallback onTap;

  const _PromoCodeRow({required this.code, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasCode = code != null && code!.isNotEmpty;
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
            Icon(
              hasCode ? Icons.check_circle : Icons.confirmation_number_outlined,
              size: 20,
              color: hasCode ? AppColors.statusSuccessText : AppColors.primaryBrown,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasCode ? 'Промокод $code применён' : 'Промокод',
                style: AppTextStyles.rowLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!hasCode)
              Text('Применить',
                  style: AppTextStyles.rowLabel.copyWith(color: AppColors.linkAccent)),
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
          Row(
            children: [
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
              Expanded(child: Text('Корзина', style: AppTextStyles.screenTitle)),
            ],
          ),
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
cat > lib/screens/catalog_screen.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/mock_products.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/tab_navigation_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/cart_summary_bar.dart';
import '../widgets/category_chip.dart';
import '../widgets/product_card.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';

/// Экран «Каталог» проекта Всласть.
///
/// Нижнюю панель навигации этот экран НЕ содержит — она уже реализована
/// в текущем проекте. Чтобы бейдж количества товаров на вкладке «Корзина»
/// обновлялся вместе с этим экраном, оба места должны читать
/// `context.watch<CartProvider>().totalCount` из одного и того же
/// CartProvider, поднятого выше по дереву (см. README_INTEGRATION.md).
class CatalogScreen extends StatefulWidget {
  final bool autofocusSearch;

  const CatalogScreen({super.key, this.autofocusSearch = false});

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

  void _onSearchChanged(String query) {
    setState(() {
      // Поиск всегда ищет по всем категориям — если человек что-то печатает,
      // выбранная категория сбрасывается на "Все", чтобы результат не
      // выглядел пустым из-за случайно оставленного фильтра.
      if (query.trim().isNotEmpty) {
        _selectedCategory = null;
      }
    });
  }

  void _openProductDetails(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  void _openCart() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }

  /// Кнопка "назад": если Каталог открыт через Navigator.push (например, с
  /// иконки/поиска на «Главной» — тогда в стеке есть что закрыть) — просто
  /// закрываем этот экран. Если Каталог открыт как вкладка нижней панели
  /// (тогда закрывать нечего, canPop() == false) — переключаем саму вкладку
  /// на «Главная» через TabNavigationController. Так кнопка "назад" всегда
  /// приводит на «Главную», независимо от того, как был открыт Каталог.
  void _goHome() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      context.read<TabNavigationController>().goToHome();
    }
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
  static const double _cardTextBlockHeight = 80;
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
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _goHome,
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
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _SearchBar(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      autofocus: widget.autofocusSearch,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 0, 0),
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

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    this.autofocus = false,
  });

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
              autofocus: autofocus,
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
import 'delivery_address_screen.dart';
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
  String? _deliveryAddress;

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

  Future<void> _selectDelivery() async {
    final address = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => DeliveryAddressScreen(initialAddress: _deliveryAddress),
      ),
    );
    if (address != null) {
      setState(() {
        _deliveryMethod = DeliveryMethod.delivery;
        _deliveryAddress = address;
      });
    }
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
      deliveryAddress:
          _deliveryMethod == DeliveryMethod.delivery ? _deliveryAddress : null,
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
                                subtitle: _deliveryMethod == DeliveryMethod.delivery &&
                                        _deliveryAddress != null
                                    ? _deliveryAddress!
                                    : DeliveryMethod.delivery.subtitle,
                                selected:
                                    _deliveryMethod == DeliveryMethod.delivery,
                                onTap: _selectDelivery,
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
cat > lib/screens/delivery_address_screen.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/toast.dart';
import '../widgets/labeled_text_field.dart';

/// Экран ввода адреса доставки в фирменном стиле Всласть.
///
/// Возвращает через Navigator.pop(context, address) готовую строку адреса
/// (с комментарием курьеру, если он заполнен) — или null, если пользователь
/// вышел назад, ничего не подтвердив.
///
/// Карта — пока плейсхолдер: реальную интерактивную карту (Яндекс.Карты
/// или 2ГИС) нужно подключать нативно — это требует API-ключа и настройки
/// на стороне iOS/Android, чего у меня нет и что я не могу протестировать
/// вслепую. Готовые пакеты под это:
///   - yandex_mapkit (pub.dev) — официальный Yandex MapKit для Flutter;
///   - flutter_2gis / 2gis_maps (2GIS SDK для Flutter).
/// Экран уже собран так, что map-виджет можно вставить одним блоком вместо
/// [_MapPlaceholder] — вся остальная вёрстка (поля, кнопка) трогать не
/// придётся.
class DeliveryAddressScreen extends StatefulWidget {
  final String? initialAddress;

  const DeliveryAddressScreen({super.key, this.initialAddress});

  @override
  State<DeliveryAddressScreen> createState() => _DeliveryAddressScreenState();
}

class _DeliveryAddressScreenState extends State<DeliveryAddressScreen> {
  late final TextEditingController _addressController =
      TextEditingController(text: widget.initialAddress);
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _useCurrentLocation() {
    // TODO: подключить геолокацию (geolocator) + обратное геокодирование
    // через API карты, когда будет подключена сама карта.
    FadeToast.show(
      context,
      'Определение местоположения скоро будет доступно',
      icon: Icons.my_location,
    );
  }

  void _confirm() {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      FadeToast.show(context, 'Укажите адрес доставки', icon: Icons.error_outline);
      return;
    }
    final comment = _commentController.text.trim();
    final result = comment.isEmpty ? address : '$address ($comment)';
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
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
                  Expanded(
                    child: Text('Адрес доставки', style: AppTextStyles.screenTitleSmall),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _MapPlaceholder(),
                    const SizedBox(height: 18),
                    LabeledTextField(
                      label: 'Адрес',
                      hint: 'Улица, дом, квартира',
                      leadingIcon: Icons.location_on_outlined,
                      controller: _addressController,
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _useCurrentLocation,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.my_location,
                              size: 16, color: AppColors.linkAccent),
                          const SizedBox(width: 6),
                          Text('Определить моё местоположение',
                              style: AppTextStyles.linkText),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text('Комментарий курьеру', style: AppTextStyles.fieldLabel),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: _commentController,
                        maxLines: 3,
                        style: AppTextStyles.rowLabel,
                        decoration: InputDecoration(
                          hintText: 'Например: домофон 45К, 3 этаж',
                          hintStyle: AppTextStyles.searchHint,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _confirm,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBrown,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    alignment: Alignment.center,
                    child: Text('Подтвердить адрес', style: AppTextStyles.cartBarButton),
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

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 220,
        width: double.infinity,
        color: AppColors.surfaceMuted,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Лёгкая имитация сетки карты — просто чтобы не выглядело как
            // сломанный/пустой блок до подключения настоящей карты.
            CustomPaint(size: const Size.fromHeight(220), painter: _MapGridPainter()),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on,
                      size: 24, color: AppColors.primaryBrown),
                ),
                const SizedBox(height: 10),
                Text('Карта появится здесь', style: AppTextStyles.rowLabel),
                const SizedBox(height: 2),
                Text('Яндекс Карты или 2ГИС', style: AppTextStyles.rowLabelMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
DARTEOF
echo 'lib/screens/delivery_address_screen.dart — записан'

mkdir -p lib/screens
cat > lib/screens/favorite_screen.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/mock_products.dart';
import '../models/product.dart';
import '../providers/favorites_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

/// Экран «Избранное» — товары, отмеченные сердечком в «Каталоге» (или
/// прямо на «Главной»). Используется и как вкладка нижней панели
/// (IndexedStack — тогда кнопка "назад" ничего не делает), и как
/// push-экран из меню профиля (тогда кнопка "назад" возвращает обратно).
class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  void _openProductDetails(BuildContext context, Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  static const double _cardTextBlockHeight = 80;
  static const double _gridSpacing = 10;
  static const int _crossAxisCount = 3;

  SliverGridDelegateWithFixedCrossAxisCount _buildGridDelegate(
      BuildContext context, double horizontalPadding) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth -
            horizontalPadding * 2 -
            _gridSpacing * (_crossAxisCount - 1)) /
        _crossAxisCount;
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: _crossAxisCount,
      mainAxisSpacing: _gridSpacing,
      crossAxisSpacing: _gridSpacing,
      mainAxisExtent: itemWidth + _cardTextBlockHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final favoriteProducts =
        mockProducts.where((p) => favorites.isFavorite(p)).toList();

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
                    Expanded(child: Text('Избранное', style: AppTextStyles.screenTitle)),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              sliver: favoriteProducts.isEmpty
                  ? const SliverToBoxAdapter(child: _EmptyFavorites())
                  : SliverGrid(
                      gridDelegate: _buildGridDelegate(context, 20),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => ProductCard(
                          product: favoriteProducts[index],
                          onOpenDetails: (p) => _openProductDetails(context, p),
                        ),
                        childCount: favoriteProducts.length,
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

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.favorite_border,
              size: 40, color: AppColors.textSecondary.withOpacity(0.6)),
          const SizedBox(height: 12),
          Text('Пока нет избранных товаров', style: AppTextStyles.sectionLabel),
          const SizedBox(height: 6),
          Text(
            'Нажмите на сердечко на карточке товара,\nчтобы добавить его сюда',
            textAlign: TextAlign.center,
            style: AppTextStyles.rowLabelMuted,
          ),
        ],
      ),
    );
  }
}
DARTEOF
echo 'lib/screens/favorite_screen.dart — записан'

mkdir -p lib/screens
cat > lib/screens/loyalty_screen.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class LoyaltyScreen extends StatelessWidget {
  const LoyaltyScreen({super.key});

  static const Color background = Color(0xFFF8F4EE);
  static const Color brown = Color(0xFF2E1C13);
  static const Color gold = Color(0xFFD6A54B);
  static const Color lightGold = Color(0xFFF7E3B8);
  static const Color green = Color(0xFF2E9C56);
  static const Color muted = Color(0xFF9A8C7C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE7DFD2)),
                    ),
                    child: const Icon(Icons.chevron_left_rounded, color: brown, size: 20),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "Карта лояльности",
                        style: GoogleFonts.alice(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: brown,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),

              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF24160F), Color(0xFF3A2519), Color(0xFF5B3923)],
                  ),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 10,
                      right: 10,
                      child: SizedBox(
                        width: 78,
                        height: 48,
                        child: SvgPicture.asset("assets/images/bakery_illustration.svg", fit: BoxFit.contain),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Всласть",
                            style: GoogleFonts.alice(
                              color: lightGold,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              fontStyle: FontStyle.italic,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "— PREMIUM —",
                            style: TextStyle(color: gold.withOpacity(.85), fontSize: 9, letterSpacing: 2.5, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "PREMIUM MEMBER",
                                      style: TextStyle(color: gold, fontSize: 9.5, letterSpacing: 1.2, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      "Sergey Kolesnikov",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.alice(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      "№ 000 123 456",
                                      style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: gold.withOpacity(.5), width: 1),
                                    ),
                                    child: Image.asset("assets/images/qr_demo.png", fit: BoxFit.contain),
                                  ),
                                  const SizedBox(height: 5),
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      "Покажите QR\nна кассе",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: gold.withOpacity(.9), fontSize: 9, height: 1.25),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    Expanded(child: _BalanceCard(balance: 1250, approxValue: "≈ 1 250 ₽")),
                    SizedBox(width: 10),
                    Expanded(child: _LevelCard(levelName: "Premium", current: 1250, target: 2000)),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text("Ваши привилегии", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: brown)),
                  Text("Все привилегии  ›", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: muted)),
                ],
              ),

              const SizedBox(height: 8),

              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    Expanded(child: _BenefitTile(iconAsset: "assets/icons/gift.svg", title: "Подарок\nко дню рождения")),
                    SizedBox(width: 10),
                    Expanded(child: _BenefitTile(iconAsset: "assets/icons/bread.svg", title: "Ранний доступ\nк новинкам")),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    Expanded(child: _BenefitTile(iconAsset: "assets/icons/premium.svg", title: "Персональные\nпредложения")),
                    SizedBox(width: 10),
                    Expanded(child: _BenefitTile(iconAsset: "assets/icons/crown_1.svg", title: "Приоритетный\nпредзаказ")),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text("История начислений", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: brown)),
                  Text("Вся история  ›", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: muted)),
                ],
              ),

              const SizedBox(height: 10),

              // Названия обобщены до "Покупка" (без привязки к конкретному
              // товару) по вашей просьбе. Важное правило для реальных
              // данных: если покупка оплачивалась (полностью или частично)
              // бонусами — начисление за эту же покупку не показывается,
              // т.е. на одну покупку не может быть одновременно и "+" за
              // начисление, и "−" за списание. Ниже это три разных, не
              // связанных друг с другом события/даты.
              const _HistoryTile(title: "Покупка", date: "Сегодня, 10:30", amount: "+120", positive: true, balance: "1 250"),
              const SizedBox(height: 6),
              const _HistoryTile(title: "Покупка", date: "Вчера, 16:45", amount: "+350", positive: true, balance: "1 130"),
              const SizedBox(height: 6),
              const _HistoryTile(title: "Оплата бонусами", date: "12 июля, 14:20", amount: "−200", positive: false, balance: "780"),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FullQrScreen()));
                  },
                  icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                  label: const Text("Показать QR кассиру", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _goldIcon(String asset, double size) {
  return SvgPicture.asset(
    asset,
    width: size,
    height: size,
    colorFilter: const ColorFilter.mode(LoyaltyScreen.brown, BlendMode.srcIn),
  );
}

class _BalanceCard extends StatelessWidget {
  final int balance;
  final String approxValue;
  const _BalanceCard({required this.balance, required this.approxValue});

  @override
  Widget build(BuildContext context) {
    final formattedBalance = _formatThousands(balance);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(color: LoyaltyScreen.lightGold, shape: BoxShape.circle),
            child: _goldIcon("assets/icons/zvezda.svg", 18),
          ),
          const SizedBox(height: 5),
          const Text("Ваш баланс", style: TextStyle(fontSize: 10.5, color: LoyaltyScreen.muted)),
          const SizedBox(height: 3),
          Text(
            formattedBalance,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: LoyaltyScreen.brown, height: 1.05),
          ),
          const Text("бонусов", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: LoyaltyScreen.brown)),
          const SizedBox(height: 4),
          Text(approxValue, style: const TextStyle(fontSize: 10, color: LoyaltyScreen.muted)),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final String levelName;
  final int current;
  final int target;
  const _LevelCard({required this.levelName, required this.current, required this.target});

  @override
  Widget build(BuildContext context) {
    final remaining = target - current;
    final progress = (current / target).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(color: LoyaltyScreen.lightGold, shape: BoxShape.circle),
            child: _goldIcon("assets/icons/crown_1.svg", 18),
          ),
          const SizedBox(height: 5),
          const Text("Ваш уровень", style: TextStyle(fontSize: 10.5, color: LoyaltyScreen.muted)),
          const SizedBox(height: 2),
          Text(levelName, style: GoogleFonts.alice(fontSize: 19, fontWeight: FontWeight.w700, color: LoyaltyScreen.brown)),
          const SizedBox(height: 5),
          Text(
            "До следующего уровня\nосталось $remaining бонусов",
            style: const TextStyle(fontSize: 9.5, color: LoyaltyScreen.muted, height: 1.2),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: const Color(0xFFF0E6D2),
              valueColor: const AlwaysStoppedAnimation<Color>(LoyaltyScreen.brown),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${_formatThousands(current)} / ${_formatThousands(target)}",
            style: const TextStyle(fontSize: 9.5, color: LoyaltyScreen.muted),
          ),
        ],
      ),
    );
  }
}

String _formatThousands(int value) {
  final s = value.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i != 0 && (s.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(s[i]);
  }
  return buffer.toString();
}

class _BenefitTile extends StatelessWidget {
  final String iconAsset;
  final String title;
  const _BenefitTile({required this.iconAsset, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(color: LoyaltyScreen.lightGold, shape: BoxShape.circle),
            child: _goldIcon(iconAsset, 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: LoyaltyScreen.brown, fontSize: 10.5, fontWeight: FontWeight.w700, height: 1.15),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final String title;
  final String date;
  final String amount;
  final bool positive;
  final String balance;
  const _HistoryTile({required this.title, required this.date, required this.amount, required this.positive, required this.balance});

  @override
  Widget build(BuildContext context) {
    final amountColor = positive ? LoyaltyScreen.green : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          SizedBox(width: 38, child: Text(amount, style: TextStyle(color: amountColor, fontSize: 13, fontWeight: FontWeight.w700))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: LoyaltyScreen.brown, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(date, style: const TextStyle(color: LoyaltyScreen.muted, fontSize: 10.5)),
              ],
            ),
          ),
          Text(balance, style: const TextStyle(color: LoyaltyScreen.brown, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(width: 5),
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(color: LoyaltyScreen.gold, shape: BoxShape.circle),
            child: const Center(child: Text("Б", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
          ),
        ],
      ),
    );
  }
}

class FullQrScreen extends StatelessWidget {
  const FullQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoyaltyScreen.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: LoyaltyScreen.background,
        centerTitle: true,
        iconTheme: const IconThemeData(color: LoyaltyScreen.brown),
        title: Text("Карта лояльности", style: GoogleFonts.alice(color: LoyaltyScreen.brown, fontWeight: FontWeight.w700, fontSize: 20)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 24, offset: const Offset(0, 10))],
              ),
              child: Image.asset("assets/images/qr_demo.png", width: 260, height: 260, fit: BoxFit.contain),
            ),
            const SizedBox(height: 24),
            const Text("Покажите QR кассиру", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: LoyaltyScreen.brown)),
            const SizedBox(height: 6),
            const Text("Бонусы будут начислены автоматически", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 32),
            SizedBox(
              width: 240,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(elevation: 0, backgroundColor: LoyaltyScreen.gold, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Закрыть", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
DARTEOF
echo 'lib/screens/loyalty_screen.dart — записан'

mkdir -p lib/screens
cat > lib/screens/main_screen.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/home/screens/home_screen.dart';
import '../providers/tab_navigation_controller.dart';
import 'catalog_screen.dart';
import 'loyalty_screen.dart';
import 'favorite_screen.dart';
import 'cart_screen.dart';

import '../features/home/widgets/bottom_nav_bar.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // currentIndex теперь живёт в TabNavigationController, а не в локальном
    // State — так с любого push-экрана (например, «Заказ принят») можно
    // переключить активную вкладку на «Главная» через
    // context.read<TabNavigationController>().goToHome().
    final currentIndex = context.watch<TabNavigationController>().currentIndex;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F1),

      body: IndexedStack(
        index: currentIndex,
        children: const [
          HomeScreen(),
          CatalogScreen(),
          LoyaltyScreen(),
          FavoriteScreen(),
          CartScreen(),
        ],
      ),

      bottomNavigationBar: PremiumBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) => context.read<TabNavigationController>().setIndex(index),
      ),
    );
  }
}
DARTEOF
echo 'lib/screens/main_screen.dart — записан'

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
  /// заказ (обычно "Каталог") — после оформления корзина уже очищена,
  /// возвращаться в чекаут или каталог с прежним состоянием смысла нет.
  /// Простого popUntil(isFirst) недостаточно: он вернёт на MainScreen, но
  /// активная вкладка там останется прежней (IndexedStack не сбрасывается
  /// сам по себе) — поэтому сначала явно переключаем вкладку на "Главная".
  void _goHome(BuildContext context) {
    context.read<TabNavigationController>().goToHome();
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
                      onTap: () => _goHome(context),
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
cat > lib/screens/product_detail_screen.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../theme/app_theme.dart';
import '../utils/toast.dart';

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
                // TODO: подключить логику предзаказа.
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
echo 'lib/screens/product_detail_screen.dart — записан'

mkdir -p lib/screens
cat > lib/screens/profile_screen.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

/// Экран «Профиль» — показывается вместо «Вход/Регистрация», когда
/// пользователь уже входил в приложение раньше (AuthProvider.isLoggedIn).
/// Сейчас это минимальная заглушка с данными и кнопкой «Выйти» — по мере
/// появления бэкенда замените на реальные данные пользователя, историю,
/// настройки и т.д.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
                  Expanded(child: Text('Профиль', style: AppTextStyles.screenTitle)),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.person, size: 40, color: AppColors.primaryBrown),
              ),
              const SizedBox(height: 16),
              Text(
                auth.displayName?.isNotEmpty == true ? auth.displayName! : 'Гость Всласть',
                style: AppTextStyles.authHeading,
              ),
              const SizedBox(height: 4),
              Text('Вы вошли в приложение', style: AppTextStyles.rowLabelMuted),
              const SizedBox(height: 32),
              // TODO: здесь разместите реальные данные пользователя —
              // телефон, email, адреса доставки, способы оплаты и т.д.
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) Navigator.of(context).maybePop();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.primaryBrown, width: 1.4),
                    ),
                    alignment: Alignment.center,
                    child: Text('Выйти',
                        style: AppTextStyles.rowLabel.copyWith(color: AppColors.primaryBrown)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
DARTEOF
echo 'lib/screens/profile_screen.dart — записан'

mkdir -p lib/theme
cat > lib/theme/app_theme.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Цветовая палитра проекта Всласть — на основе фирменного брендбука
/// (CMYK 30/5/0/0 небо, 30/30/0/0 лаванда, 0/25/0/0 роза, 0/5/30/0 ваниль,
/// 5/65/60/80 графит). Философия 70/15/10/5: молочный фон — графит для
/// текста/кнопок — один пастельный акцент на экран — пастель для бейджей.
///
/// ВАЖНО: имя `primaryBrown` — историческое, осталось от прежней
/// коричневой палитры. Сейчас в нём графит, не коричневый — переименовать
/// стоит отдельным заходом (это потребует правки во всех файлах, где он
/// используется), сейчас меняем только значения токенов.
class AppColors {
  AppColors._();

  // Фон — молочный (70%)
  static const Color background = Color(0xFFFAF7F1);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Графит (15%) — текст, кнопки, ключевые элементы.
  static const Color primaryBrown = Color(0xFF201C1A);
  static const Color primaryBrownDark = Color(0xFF14100F);

  // Второстепенные поверхности (поиск, чипы, плашка корзины)
  static const Color surfaceMuted = Color(0xFFF1ECE3);
  static const Color surfaceMutedDark = Color(0xFFE7E0D3);

  // Текст
  static const Color textPrimary = Color(0xFF201C1A);
  static const Color textSecondary = Color(0xFF8A8177);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Фирменная пастель (10%) — один акцент на экран/категорию.
  static const Color accentSky = Color(0xFFB3F2FF);
  static const Color accentLavender = Color(0xFFB3B3FF);
  static const Color accentRose = Color(0xFFFFBFFF);
  static const Color accentVanilla = Color(0xFFFFF2B3);

  // Бейджи (5%) — сейчас всё ещё сплошная заливка с белым текстом (это
  // предстоит переделать в "типографические капсулы" отдельным шагом —
  // см. пункт 9 брендбука). ХИТ — графит, НОВИНКА/АКЦИЯ — более
  // насыщенные варианты лаванды/розы, чтобы белый текст оставался читаемым.
  static const Color badgeHit = Color(0xFF201C1A);
  static const Color badgeNew = Color(0xFF7A7AD1);
  static const Color badgePromo = Color(0xFFCC6FCC);

  static const Color divider = Color(0xFFEDE7DB);
  static const Color shadow = Color(0x14201C1A);

  /// Насыщенный вариант лавандового — для ссылок/тегов на светлом фоне.
  /// Сами accentSky/Lavender/Rose/Vanilla слишком бледные для мелкого
  /// текста (плохо читаются) — они для крупных поверхностей/подложек.
  static const Color linkAccent = Color(0xFF6B6BC7);

  // --- Мои заказы: статусы ---
  static const Color statusPendingBg = Color(0xFFFFF2B3);
  static const Color statusPendingText = Color(0xFF8A7328);
  static const Color statusSuccessBg = Color(0xFFDCEEDB);
  static const Color statusSuccessText = Color(0xFF4C8A55);

  // --- Вход/Регистрация и др.: акцентная кнопка ---
  // Брендбук прямо просит не использовать золотой градиент — раньше
  // здесь была коричнево-золотая заливка ("Иду за покупками", "Оплатить
  // по СБП" и т.д.). Оставил структуру (эти кнопки собраны через
  // LinearGradient) нетронутой в самих виджетах, но обе точки
  // градиента теперь ведут на один и тот же графит — визуально это
  // сплошная кнопка без "золота", без необходимости трогать код кнопок.
  static const Color accentGradientStart = Color(0xFF201C1A);
  static const Color accentGradientEnd = Color(0xFF201C1A);
}

class AppTextStyles {
  AppTextStyles._();

  /// Заголовок экрана «Каталог» — витринный serif-шрифт.
  static TextStyle screenTitle = GoogleFonts.alice(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryBrown,
    height: 1.1,
  );

  static TextStyle searchHint = GoogleFonts.jost(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static TextStyle categoryChip = GoogleFonts.jost(
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static TextStyle productName = GoogleFonts.jost(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.15,
  );

  static TextStyle productPrice = GoogleFonts.jost(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle badgeLabel = GoogleFonts.jost(
    fontSize: 9,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
    letterSpacing: 0.2,
  );

  static TextStyle cartBarText = GoogleFonts.jost(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle cartBarButton = GoogleFonts.jost(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
  );

  static TextStyle preorderButton = GoogleFonts.jost(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
  );

  // --- Оформление заказа / Подтверждение заказа ---

  /// Заголовок экранов «Оформление заказа» и «Заказ принят!».
  static TextStyle screenTitleSmall = GoogleFonts.alice(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryBrown,
    height: 1.15,
  );

  /// Подзаголовки секций: «Ваш заказ», «Способ получения», «Состав заказа».
  static TextStyle sectionLabel = GoogleFonts.jost(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Счётчик рядом с заголовком секции: «4 товара».
  static TextStyle sectionCounter = GoogleFonts.jost(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static TextStyle orderItemName = GoogleFonts.jost(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static TextStyle orderItemPrice = GoogleFonts.jost(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle receiptQty = GoogleFonts.jost(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  /// Обычный текст строки (пункт меню, значение поля).
  static TextStyle rowLabel = GoogleFonts.jost(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle rowLabelMuted = GoogleFonts.jost(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.35,
  );

  static TextStyle rowValue = GoogleFonts.jost(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle totalLabel = GoogleFonts.jost(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle totalValue = GoogleFonts.jost(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle infoNote = GoogleFonts.jost(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.35,
  );

  static TextStyle optionTitle = GoogleFonts.jost(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle optionSubtitle = GoogleFonts.jost(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // --- Мои заказы ---

  static TextStyle orderNumber = GoogleFonts.jost(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  static TextStyle orderTitle = GoogleFonts.alice(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static TextStyle statusPillLabel = GoogleFonts.jost(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  // --- Вход/Регистрация ---

  static TextStyle authLogoTitle = GoogleFonts.alice(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryBrown,
  );

  static TextStyle authTagline = GoogleFonts.jost(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.linkAccent,
    letterSpacing: 0.6,
  );

  static TextStyle authHeading = GoogleFonts.alice(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryBrown,
  );

  static TextStyle fieldLabel = GoogleFonts.jost(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle linkText = GoogleFonts.jost(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.linkAccent,
  );

  static TextStyle checkboxText = GoogleFonts.jost(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // --- Карточка товара ---

  static TextStyle productDetailTitle = GoogleFonts.alice(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryBrown,
    height: 1.15,
  );

  static TextStyle productDetailPrice = GoogleFonts.jost(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle ratingValue = GoogleFonts.jost(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle descriptionText = GoogleFonts.jost(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle nutritionValue = GoogleFonts.jost(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle nutritionLabel = GoogleFonts.jost(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
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

mkdir -p lib/utils
cat > lib/utils/toast.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Плавно появляющееся и гаснущее уведомление поверх текущего экрана
/// (не привязано к Scaffold — использует ближайший Overlay, поэтому
/// работает из любого места, включая карточки товара на Главной).
class FadeToast {
  static void show(
    BuildContext context,
    String message, {
    IconData icon = Icons.favorite,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _FadeToast(
        message: message,
        icon: icon,
        onDismissed: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _FadeToast extends StatefulWidget {
  final String message;
  final IconData icon;
  final VoidCallback onDismissed;

  const _FadeToast({
    required this.message,
    required this.icon,
    required this.onDismissed,
  });

  @override
  State<_FadeToast> createState() => _FadeToastState();
}

class _FadeToastState extends State<_FadeToast> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 1400), () async {
      if (!mounted) return;
      await _controller.reverse();
      widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 24,
      right: 24,
      bottom: 110,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _opacity,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primaryBrown,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: AppColors.shadow, blurRadius: 14, offset: Offset(0, 6)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: 18, color: Colors.white),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      widget.message,
                      style: AppTextStyles.cartBarText.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
DARTEOF
echo 'lib/utils/toast.dart — записан'

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
cat > lib/widgets/product_card.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../theme/app_theme.dart';
import '../utils/toast.dart';

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
                              // TODO: подключить логику предзаказа.
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
echo 'lib/widgets/product_card.dart — записан'

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
cat > lib/widgets/screen_banner.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Промо-баннер в верхней части экрана (Каталог, Корзина и т.д.):
/// изображение на всю ширину со скруглёнными углами, лёгким затемнением
/// снизу для читаемости текста и коротким заголовком/подзаголовком.
class ScreenBanner extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String? subtitle;
  final double height;

  const ScreenBanner({
    super.key,
    required this.imageUrl,
    required this.title,
    this.subtitle,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.surfaceMuted,
                child: const Icon(Icons.image_outlined,
                    size: 32, color: AppColors.textSecondary),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0),
                      Colors.black.withOpacity(0.45),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTextStyles.rowLabelMuted.copyWith(color: Colors.white70),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
DARTEOF
echo 'lib/widgets/screen_banner.dart — записан'

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
                  overflow: TextOverflow.ellipsis,
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

echo ''
echo 'Готово. Проверьте pubspec.yaml — нужны:'
echo '  provider, google_fonts, shared_preferences'
echo 'Затем: flutter pub get && flutter clean && flutter run'
