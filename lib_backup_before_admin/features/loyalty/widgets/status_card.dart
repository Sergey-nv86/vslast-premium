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
