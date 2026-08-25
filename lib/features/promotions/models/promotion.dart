import 'package:flutter/material.dart';

/// Одна акция/спецпредложение — баннер + список товаров-участников
/// (id из mockProducts, тот же каталог, что и везде в приложении).
///
/// Пока баннер рисуется цветом/градиентом + иконкой, а не фотографией —
/// специальных промо-фото пока нет в assets, а плейсхолдер поверх чужого
/// товарного фото выглядел бы недостоверно. Когда появятся баннерные
/// изображения — добавьте поле imageAsset и переключите _PromoBanner на
/// Image.asset, ничего в остальной логике экрана менять не придётся.
class Promotion {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> productIds;

  const Promotion({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.productIds,
  });
}

const mockPromotions = <Promotion>[
  Promotion(
    id: 'back_to_school',
    title: 'Скоро в школу',
    subtitle: 'Сладкий стол для линейки и первых дней учёбы',
    icon: Icons.school_outlined,
    color: Color(0xFF6B7FB8),
    productIds: [
      'napoleon_cake',
      'cheesecake_cherry',
      'eclair_chocolate',
      'dacquoise',
    ],
  ),
  Promotion(
    id: 'ciabatta_discount',
    title: 'Скидка на чиабатту −15%',
    subtitle: 'Только на этой неделе',
    icon: Icons.local_offer_outlined,
    color: Color(0xFFB5804A),
    productIds: ['ciabatta'],
  ),
  Promotion(
    id: 'weekend_breakfast',
    title: 'Выходные с завтраком',
    subtitle: 'Свежая выпечка к утреннему кофе',
    icon: Icons.free_breakfast_outlined,
    color: Color(0xFF7A9B76),
    productIds: ['croissant_butter', 'brioche', 'grain_bun'],
  ),
];
