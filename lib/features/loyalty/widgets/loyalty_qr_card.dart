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
            color: Colors.black.withValues(alpha: .06),
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
