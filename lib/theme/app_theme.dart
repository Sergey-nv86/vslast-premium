import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Единые визуальные токены клиентского приложения «Всласть».
/// Бизнес-логика и существующие имена токенов сохранены для совместимости.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFFFAF8F5);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE8E4E0);
  static const Color primaryBrown = Color(0xFF4A3024);
  static const Color primaryBrownDark = Color(0xFF352118);
  static const Color caramel = Color(0xFFC4956A);
  static const Color cream = Color(0xFFF5E6D3);
  static const Color sage = Color(0xFF4A7C59);
  static const Color brickRed = Color(0xFFB5423F);
  static const Color accent = caramel;
  static const Color accentLight = cream;
  static const Color surfaceMuted = cream;
  static const Color surfaceMutedDark = Color(0xFFEAD8C2);
  static const Color textPrimary = Color(0xFF4A3024);
  static const Color textSecondary = Color(0xFF6B6560);
  static const Color rowLabelMuted = textSecondary;
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color accentSky = cream;
  static const Color accentLavender = cream;
  static const Color accentRose = cream;
  static const Color accentVanilla = cream;

  static const Color badgeHit = cream;
  static const Color badgeNew = cream;
  static const Color badgePromo = cream;

  static const Color divider = border;
  static const Color shadow = Color(0x0F4A3024);
  static const Color linkAccent = caramel;

  static const Color statusPendingBg = cream;
  static const Color statusPendingText = Color(0xFF7B6044);
  static const Color statusSuccessBg = Color(0xFFE5EFE7);
  static const Color statusSuccessText = sage;

  static const Color accentGradientStart = primaryBrown;
  static const Color accentGradientEnd = primaryBrown;
  static const Color success = sage;
  static const Color danger = brickRed;
}

class AppSpacing {
  AppSpacing._();
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppRadii {
  AppRadii._();
  static const double button = 12;
  static const double card = 20;
  static const double sheet = 24;
  static const double pill = 999;
}

class AppShadows {
  AppShadows._();
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0F4A3024), blurRadius: 24, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> button = [
    BoxShadow(color: Color(0x1FC4956A), blurRadius: 8, offset: Offset(0, 2)),
  ];
}

class AppTextStyles {
  AppTextStyles._();

  static TextStyle screenTitle = GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.w500, color: AppColors.textPrimary, height: 40 / 32);
  static TextStyle searchHint = GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static TextStyle categoryChip = GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500);
  static TextStyle productName = GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary, height: 1.3);
  static TextStyle productPrice = GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static TextStyle badgeLabel = GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: 0.1);
  static TextStyle cartBarText = GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary, height: 1.3);
  static TextStyle cartBarButton = GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textOnPrimary);
  static TextStyle preorderButton = GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textOnPrimary);
  static TextStyle screenTitleSmall = GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w500, color: AppColors.primaryBrown, height: 32 / 24);
  static TextStyle sectionLabel = GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static TextStyle sectionTitle = GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.textPrimary, height: 1.2);
  static TextStyle sectionCounter = GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static TextStyle body = GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.4);
  static TextStyle bodySecondary = GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.4);
  static TextStyle button = GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textOnPrimary);
  static TextStyle orderItemName = GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary, height: 1.25);
  static TextStyle orderItemPrice = GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static TextStyle receiptQty = GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static TextStyle rowLabel = GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
  static TextStyle rowLabelMuted = GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.35);
  static TextStyle rowValue = GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
  static TextStyle totalLabel = GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static TextStyle totalValue = GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static TextStyle infoNote = GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.35);
  static TextStyle optionTitle = GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static TextStyle optionSubtitle = GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static TextStyle orderNumber = GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static TextStyle orderTitle = GoogleFonts.playfairDisplay(fontSize: 17, fontWeight: FontWeight.w500, color: AppColors.textPrimary, height: 1.2);
  static TextStyle statusPillLabel = GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600);
  static TextStyle authLogoTitle = GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.w500, color: AppColors.primaryBrown);
  static TextStyle authTagline = GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.linkAccent, letterSpacing: 0.6);
  static TextStyle authHeading = GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w500, color: AppColors.primaryBrown);
  static TextStyle fieldLabel = GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
  static TextStyle linkText = GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.linkAccent);
  static TextStyle checkboxText = GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.4);
  static TextStyle productDetailTitle = GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w500, color: AppColors.primaryBrown, height: 1.15);
  static TextStyle productDetailPrice = GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static TextStyle ratingValue = GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static TextStyle descriptionText = GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.5);
  static TextStyle nutritionValue = GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static TextStyle nutritionLabel = GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
}

String formatPrice(int price) {
  final digits = price.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    final posFromEnd = digits.length - i;
    buffer.write(digits[i]);
    if (posFromEnd > 1 && posFromEnd % 3 == 1) buffer.write('\u00A0');
  }
  return '${buffer.toString()} ₽';
}

String pluralizeItems(int count) {
  final mod10 = count % 10;
  final mod100 = count % 100;
  if (mod10 == 1 && mod100 != 11) return 'товар';
  if (mod10 >= 2 && mod10 <= 4 && !(mod100 >= 12 && mod100 <= 14)) return 'товара';
  return 'товаров';
}
