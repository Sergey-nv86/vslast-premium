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
                color: Colors.black.withValues(alpha: .05),
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
                backgroundColor: item.color.withValues(alpha: .12),
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
