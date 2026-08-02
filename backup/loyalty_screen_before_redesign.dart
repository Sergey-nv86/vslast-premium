import 'package:flutter/material.dart';

class LoyaltyScreen extends StatelessWidget {
  const LoyaltyScreen({super.key});

  static const Color background = Color(0xFFF8F4EE);
  static const Color brown = Color(0xFF2E1C13);
  static const Color gold = Color(0xFFD6A54B);
  static const Color lightGold = Color(0xFFF7E3B8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              //--------------------------------------------------
              // TITLE
              //--------------------------------------------------
              const Center(
                child: Text(
                  "Карта лояльности",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: brown,
                    letterSpacing: -.3,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              //--------------------------------------------------
              // PREMIUM CARD
              //--------------------------------------------------
              Container(
                height: 255,
                width: double.infinity,

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),

                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF24160F),
                      Color(0xFF3A2519),
                      Color(0xFF5B3923),
                    ],
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 30,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),

                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      //------------------------------------------------
                      Row(
                        children: [
                          const Icon(
                            Icons.bakery_dining_rounded,
                            color: gold,
                            size: 32,
                          ),

                          const SizedBox(width: 10),

                          const Text(
                            "Всласть",
                            style: TextStyle(
                              color: lightGold,
                              fontSize: 31,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const Spacer(),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 7,
                            ),

                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(30),
                            ),

                            child: const Text(
                              "PREMIUM",
                              style: TextStyle(
                                color: lightGold,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
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

                      const SizedBox(height: 4),

                      const Text(
                        "Премиальный гость",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),

                      const SizedBox(height: 18),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            width: 82,
                            height: 82,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Image.asset(
                              "assets/images/qr_demo.png",
                              fit: BoxFit.contain,
                            ),
                          ),

                          const SizedBox(width: 18),

                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "№ 0001 2026",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    letterSpacing: 2,
                                  ),
                                ),

                                SizedBox(height: 8),

                                Text(
                                  "Покажите QR на кассе",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              //--------------------------------------------------
              // BALANCE
              //--------------------------------------------------
              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      icon: Icons.workspace_premium_rounded,
                      title: "Баланс",
                      value: "1250",
                      subtitle: "бонусов",
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: _InfoCard(
                      icon: Icons.star_rounded,
                      title: "Уровень",
                      value: "Premium",
                      subtitle: "статус",
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              const Text(
                "Ваши привилегии",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: brown,
                ),
              ),

              const SizedBox(height: 16),
              _BenefitTile(
                icon: Icons.cake_outlined,
                title: "Подарок ко Дню рождения",
                subtitle: "Скидка 10% на праздничный торт",
              ),

              const SizedBox(height: 12),

              _BenefitTile(
                icon: Icons.auto_awesome_outlined,
                title: "Ранний доступ к новинкам",
                subtitle: "Первыми узнавайте о новых коллекциях",
              ),

              const SizedBox(height: 12),

              _BenefitTile(
                icon: Icons.restaurant_menu_outlined,
                title: "Закрытые дегустации",
                subtitle: "Эксклюзивные мероприятия для участников клуба",
              ),

              const SizedBox(height: 12),

              _BenefitTile(
                icon: Icons.schedule_outlined,
                title: "Приоритетный предзаказ",
                subtitle: "Резервируйте праздничную продукцию заранее",
              ),

              const SizedBox(height: 12),

              _BenefitTile(
                icon: Icons.local_offer_outlined,
                title: "Персональные предложения",
                subtitle: "Индивидуальные акции и специальные предложения",
              ),

              const SizedBox(height: 32),

              //--------------------------------------------------
              // HISTORY
              //--------------------------------------------------
              const Text(
                "История начислений",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: brown,
                ),
              ),

              const SizedBox(height: 16),

              _HistoryTile(date: "29.07.2026", bonus: "+120 Б", positive: true),

              const SizedBox(height: 10),

              _HistoryTile(date: "28.07.2026", bonus: "+350 Б", positive: true),

              const SizedBox(height: 10),

              _HistoryTile(
                date: "12.07.2026",
                bonus: "−200 Б",
                positive: false,
              ),

              const SizedBox(height: 34),

              //--------------------------------------------------
              // BUTTON
              //--------------------------------------------------
              SizedBox(
                height: 60,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FullQrScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: gold,
                    foregroundColor: brown,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.qr_code_2_rounded, size: 28),
                  label: const Text(
                    "Показать QR кассиру",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// INFO CARD
////////////////////////////////////////////////////////////

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 122,
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

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: LoyaltyScreen.gold, size: 28),

          const Spacer(),

          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: LoyaltyScreen.brown,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),

          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
////////////////////////////////////////////////////////////
/// BENEFIT TILE
////////////////////////////////////////////////////////////

class _BenefitTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xffF8F1E2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: LoyaltyScreen.gold, size: 26),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: LoyaltyScreen.brown,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    height: 1.4,
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

////////////////////////////////////////////////////////////
/// HISTORY TILE
////////////////////////////////////////////////////////////

class _HistoryTile extends StatelessWidget {
  final String date;
  final String bonus;
  final bool positive;

  const _HistoryTile({
    required this.date,
    required this.bonus,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),

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
          const Icon(
            Icons.receipt_long_rounded,
            color: Color(0xffC89B4D),
            size: 26,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Text(
              date,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: LoyaltyScreen.brown,
              ),
            ),
          ),

          Text(
            bonus,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: positive ? const Color(0xff2F9D57) : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}
////////////////////////////////////////////////////////////
/// FULL QR SCREEN
////////////////////////////////////////////////////////////

class FullQrScreen extends StatelessWidget {
  const FullQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoyaltyScreen.background,

      appBar: AppBar(
        backgroundColor: LoyaltyScreen.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: LoyaltyScreen.brown),
        title: const Text(
          "Карта лояльности",
          style: TextStyle(
            color: LoyaltyScreen.brown,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Container(
              padding: const EdgeInsets.all(22),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.08),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),

              child: Image.asset(
                "assets/images/qr_demo.png",
                width: 280,
                height: 280,
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              "Покажите QR-код кассиру",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: LoyaltyScreen.brown,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Бонусы будут начислены автоматически",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: 260,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: LoyaltyScreen.gold,
                  foregroundColor: LoyaltyScreen.brown,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "Закрыть",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
