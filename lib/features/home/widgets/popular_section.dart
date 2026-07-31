import 'package:flutter/material.dart';

import 'product_card.dart';

class PopularSection extends StatelessWidget {
  const PopularSection({super.key});

  @override
  Widget build(BuildContext context) {
    final products = [
      const ProductCard(
        image: 'assets/images/cake_signature.jpg',
        title: 'Фирменный\nфисташковый торт',
        subtitle: 'Лидер продаж',
        price: 3900,
        badge: 'ТОП',
      ),
      const ProductCard(
        image: 'assets/images/bread_country.jpg',
        title: 'Деревенский хлеб\nна закваске',
        subtitle: 'Покупают каждый день',
        price: 450,
      ),
      const ProductCard(
        image: 'assets/images/dessert_tart.jpg',
        title: 'Тарт\nмалина',
        subtitle: 'Выбор гостей',
        price: 590,
      ),
      const ProductCard(
        image: 'assets/images/bread_french.jpg',
        title: 'Французский\nбагет',
        subtitle: 'Всегда свежий',
        price: 320,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              Text(
                "Популярное",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff2D2621),
                ),
              ),
              Spacer(),
              Text(
                "Все",
                style: TextStyle(
                  color: Color(0xff7B4A22),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xff7B4A22)),
            ],
          ),
        ),

        const SizedBox(height: 20),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            childAspectRatio: 0.68,
          ),
          itemBuilder: (context, index) => products[index],
        ),
      ],
    );
  }
}
