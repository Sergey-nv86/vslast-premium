import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: 305,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: double.infinity,
            height: 205 + top,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/hero_banner.jpg',
                    fit: BoxFit.cover,
                  ),
                ),

                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(.18),

                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  left: 24,
                  top: top + 26,
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Доброе утро,\nСергей!',
                        style: TextStyle(
                          color: const Color(0xFF4A2E1F),
                          fontSize: 22,

                          fontWeight: FontWeight.w600,
                          height: 1.12,
                          fontFamily: 'Georgia',
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Испечено с \nлюбовью для Вас.',
                        style: const TextStyle(
                          color: Color(0xFF5C4436),
                          fontSize: 12,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  right: 24,
                  top: top + 8,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 18,
                      color: Color(0xff7B4A22),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            left: 20,
            right: 20,
            top: top + 180,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(27),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.10),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  SizedBox(width: 22),
                  Icon(Icons.search, color: Color(0xff8C837D), size: 20),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Поиск хлеба, тортов, десертов...',
                      style: TextStyle(fontSize: 15, color: Color(0xff8C837D)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
