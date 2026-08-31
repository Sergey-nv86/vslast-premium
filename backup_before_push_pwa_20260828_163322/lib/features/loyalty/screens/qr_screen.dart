import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/loyalty_level.dart';

class QrScreen extends StatelessWidget {
  const QrScreen({super.key});

  static const LoyaltyAccount account = LoyaltyAccount(
    clientName: 'Сергей Кolesников',
    cardNumber: '000 123 456',
    bonusBalance: 1250,
    cumulativePurchases: 1250,
  );

  @override
  Widget build(BuildContext context) {
    final level = account.level;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE8E0D5)),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF201C1A),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'QR-код карты',
                        style: GoogleFonts.alice(
                          color: const Color(0xFF201C1A),
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),

              const Spacer(),

              Text(
                'Предъявите QR-код',
                textAlign: TextAlign.center,
                style: GoogleFonts.alice(
                  color: const Color(0xFF201C1A),
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Для начисления или списания бонусов',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF81766B), fontSize: 13),
              ),

              const SizedBox(height: 26),

              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE8E0D5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .07),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/qr_demo.png',
                  width: 260,
                  height: 260,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                account.clientName,
                style: GoogleFonts.alice(
                  color: const Color(0xFF201C1A),
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                '№ ${account.cardNumber}',
                style: const TextStyle(
                  color: Color(0xFF81766B),
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: level.level == LoyaltyLevel.premium
                      ? const Color(0xFF111111)
                      : level.level == LoyaltyLevel.gold
                      ? const Color(0xFFCDAA54)
                      : const Color(0xFFD9DDE0),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '${level.name} · ${level.bonusPercent}% бонусов',
                  style: TextStyle(
                    color: level.level == LoyaltyLevel.premium
                        ? Colors.white
                        : const Color(0xFF201C1A),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .5,
                  ),
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF201C1A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  child: const Text(
                    'Закрыть',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
