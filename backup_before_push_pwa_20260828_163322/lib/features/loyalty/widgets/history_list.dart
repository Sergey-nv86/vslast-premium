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
                color: Colors.black.withValues(alpha: .05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: item.color.withValues(alpha: .12),
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
