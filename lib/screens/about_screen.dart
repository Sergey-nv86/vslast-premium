// about_screen.dart
//
// Экран «О нас» для приложения «Всласть».
// Зависимость: google_fonts (добавить в pubspec.yaml, если ещё не подключён):
//   dependencies:
//     google_fonts: ^6.2.1
//
// Фото: положите присланное фото основателей в
//   assets/images/founders.jpg
// и убедитесь, что в pubspec.yaml прописано:
//   flutter:
//     assets:
//       - assets/images/
//
// Использование:
//   Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {

  Future<void> _openTelegram() async {
    final uri = Uri.parse('https://t.me/vslast_nv');

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Future<void> _openLocation() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query='
      'Нижневартовск%2C%20ул.%20Пионерская%2C%2012',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Future<void> _callBakery() async {
    final uri = Uri(scheme: 'tel', path: '+79129399754');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }


  const AboutScreen({super.key});

  // Палитра бренда (брендбук «Всласть»)
  static const Color _milky = Color(0xFFF7F3EE);
  static const Color _graphite = Color(0xFF2C2C2A);
  static const Color _graphiteSoft = Color(0xFF3A3A37);
  static const Color _lavenderBg = Color(0xFFDCD3EE);
  static const Color _lavenderText = Color(0xFF3C3489);
  static const Color _roseBg = Color(0xFFF4D9E4);
  static const Color _roseText = Color(0xFF72243E);
  static const Color _vanillaBg = Color(0xFFF3E7D3);
  static const Color _vanillaText = Color(0xFF412402);

  @override
  Widget build(BuildContext context) {
    // Основной текстовый стиль экрана — Playfair Display, 14px, w500
    final bodyStyle = GoogleFonts.playfairDisplay(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.65,
      color: _graphiteSoft,
    );

    return Scaffold(
      backgroundColor: _milky,
      body: CustomScrollView(
        slivers: [
          // ---------- Hero-баннер с фото и заголовком ----------
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            backgroundColor: _milky,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/founders.jpg',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: _vanillaBg,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          size: 48,
                          color: _graphiteSoft,
                        ),
                      );
                    },
                  ),
                  // Затемнение снизу для читаемости белого текста
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x0D1E1A14), // ~5% затемнение сверху
                          Color(0x8C14110D), // ~55% затемнение снизу
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 22,
                    right: 22,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Всласть',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 27,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Семейная пекарня-кондитерская · Нижневартовск · с 2023 года',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFE9E4DA),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---------- Контент ----------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTag(
                    label: 'НАШ ХЛЕБ',
                    background: _lavenderBg,
                    textColor: _lavenderText,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Мы начинали с малого: одной печи, одной закваски и желания '
                    'печь хлеб так, как его пекли до индустриализации — медленно '
                    'и честно. Наш хлеб проходит долгую ферментацию — от суток и '
                    'дольше. Мы ориентируемся на подход мастеров, которые сделали '
                    'изучение теста своим призванием: Людовика Ришара (Ludovic '
                    'Richard) с его вниманием к структуре мякиша и Джеффри '
                    'Хамельмана — автора одной из главных книг о ремесленном '
                    'хлебе в мире.',
                    style: bodyStyle,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'В составе — только то, что можно назвать вслух: мука, вода, '
                    'соль, закваска. Ни один этап у нас не автоматизирован — от '
                    'замеса до формовки всё делают руки пекаря.',
                    style: bodyStyle,
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTag(
                    label: 'НАШИ ДЕСЕРТЫ',
                    background: _roseBg,
                    textColor: _roseText,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Мы учимся у тех, кто определяет мировой уровень десертного '
                    'искусства: у корейской студии GaruHaru с их скульптурной '
                    'точностью, у Ханса Овандо (Hans Ovando) и его смелой работы '
                    'с текстурой и цветом, у Грегори Доуайена (Grégory Doyen) с '
                    'его французской строгостью формы. Внутри страны нас '
                    'вдохновляют Мария Селянина, Людмила Букина и Вера '
                    'Никандрова — кондитеры, которые доказали, что российская '
                    'школа может конкурировать на любом уровне.',
                    style: bodyStyle,
                  ),
                ],
              ),
            ),
          ),

          // ---------- Цитата-плашка ----------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                decoration: BoxDecoration(
                  color: _vanillaBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '«Мы не производство. Мы — семья, которая печёт хлеб и делает '
                  'десерты так, как хотела бы есть их сама.»',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    color: _vanillaText,
                  ),
                ),
              ),
            ),
          ),

          // ---------- Соцсети ----------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 26),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Telegram',
                    icon: const Icon(
                      Icons.telegram,
                      color: _graphite,
                    ),
                    onPressed: _openTelegram,
                  ),

                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Нижневартовск, ул. Пионерская, 12',
                    icon: const Icon(
                      Icons.location_on_outlined,
                      color: _graphite,
                    ),
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: context,
                        backgroundColor: _milky,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (sheetContext) {
                          return SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                18,
                                24,
                                24,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: _graphite.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 30,
                                    color: _graphite,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Всласть',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w600,
                                      color: _graphite,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Нижневартовск, ул. Пионерская, 12',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: _graphiteSoft,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '+7 912 933-97-54',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: _graphiteSoft,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            Navigator.pop(sheetContext);
                                            _openLocation();
                                          },
                                          icon: const Icon(
                                            Icons.directions_outlined,
                                          ),
                                          label: const Text('Маршрут'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: FilledButton.icon(
                                          onPressed: () {
                                            Navigator.pop(sheetContext);
                                            _callBakery();
                                          },
                                          icon: const Icon(Icons.phone_outlined),
                                          label: const Text('Позвонить'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Небольшая пастельная плашка-заголовок блока (НАШ ХЛЕБ / НАШИ ДЕСЕРТЫ)
class _SectionTag extends StatelessWidget {
  const _SectionTag({
    required this.label,
    required this.background,
    required this.textColor,
  });

  final String label;
  final Color background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.jost(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.8,
          color: textColor,
        ),
      ),
    );
  }
}