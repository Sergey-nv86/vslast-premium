import 'package:flutter/material.dart';

class AdaptiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget tablet;
  final Widget desktop;

  const AdaptiveLayout({
    super.key,
    required this.mobile,
    required this.tablet,
    required this.desktop,
  });

  static bool isMobile(double width) => width < 760;
  static bool isTablet(double width) => width >= 760 && width < 1200;
  static bool isDesktop(double width) => width >= 1200;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (isDesktop(width)) return desktop;
    if (isTablet(width)) return tablet;
    return mobile;
  }
}
