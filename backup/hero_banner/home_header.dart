import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: 330,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: double.infinity,
            height: 250 + top,
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
                          Colors.black.withOpacity(.45),
                          Colors.black.withOpacity(.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  left: 24,
                  top: top + 34,
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Доброе утро,\nСергей!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          height: 1.02,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Georgia',
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Испечено с любовью для Вас.',
                        style: TextStyle(color: Colors.white, fontSize: 17),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  right: 24,
                  top: top + 26,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_outline,
                      size: 30,
                      color: Colors.brown,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            left: 20,
            right: 20,
            top: top + 212,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
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
                  Icon(Icons.search, color: Color(0xff8C837D), size: 24),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Поиск хлеба, тортов, десертов...',
                      style: TextStyle(fontSize: 17, color: Color(0xff9C948D)),
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
