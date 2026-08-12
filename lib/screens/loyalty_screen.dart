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
                              // Раньше QR на самой карте был не кликабельным —
                              // открыть его в полный размер можно было только
                              // через кнопку "Показать QR кассиру" ниже.
                              // Теперь тап по самому QR тоже открывает FullQrScreen.
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => const FullQrScreen()));
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Column(
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
