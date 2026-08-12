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
