import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String image;
  final String title;
  final int price;
  final String? badge;

  const ProductCard({
    super.key,
    required this.image,
    required this.title,
    required this.price,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: SizedBox(
                  height: 96,
                  width: double.infinity,
                  child: Image.asset(image, fit: BoxFit.cover),
                ),
              ),

              if (badge != null)
                Positioned(
                  left: 7,
                  top: 7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffD96A28),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Georgia',
                      ),
                    ),
                  ),
                ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(9, 6, 9, 0),
            child: SizedBox(
              height: 22,
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  height: 1.05,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff2D2621),
                  fontFamily: 'Georgia',
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(9, 3, 7, 6),
            child: Row(
              children: [
                Text(
                  "$price ₽",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff2D2621),
                    fontFamily: 'Georgia',
                  ),
                ),
                const Spacer(),
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xff7B4A22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
