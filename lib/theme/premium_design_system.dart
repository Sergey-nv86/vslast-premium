import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Единая Premium design system клиентского приложения «Всласть».
///
/// Этот файл — источник визуальных токенов для новых и постепенно
/// обновляемых экранов. Существующие legacy-токены в app_theme.dart
/// сохраняются для обратной совместимости.
class VslastColors {
  VslastColors._();

  static const background = Color(0xFFFAF8F5);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B6560);
  static const accent = Color(0xFFC4956A);
  static const accentLight = Color(0xFFF5E6D3);
  static const success = Color(0xFF4A7C59);
  static const danger = Color(0xFFB5423F);
  static const divider = Color(0xFFE8E4E0);

  static const shadow = Color(0x0F1A1A1A);
  static const shadowStrong = Color(0x1F1A1A1A);
}

class VslastRadii {
  VslastRadii._();

  static const card = 20.0;
  static const modal = 24.0;
  static const button = 12.0;
  static const field = 16.0;
  static const pill = 999.0;
}

class VslastSpacing {
  VslastSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

class VslastTextStyles {
  VslastTextStyles._();

  static TextStyle get h1 => GoogleFonts.playfairDisplay(
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w500,
    color: VslastColors.textPrimary,
  );

  static TextStyle get h2 => GoogleFonts.playfairDisplay(
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w500,
    color: VslastColors.textPrimary,
  );

  static TextStyle get h3 => GoogleFonts.inter(
    fontSize: 17,
    height: 24 / 17,
    fontWeight: FontWeight.w500,
    color: VslastColors.textPrimary,
  );

  static TextStyle get body => GoogleFonts.inter(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    color: VslastColors.textPrimary,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w500,
    color: VslastColors.textPrimary,
  );

  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 13,
    height: 16 / 13,
    fontWeight: FontWeight.w400,
    color: VslastColors.textSecondary,
  );

  static TextStyle get micro => GoogleFonts.inter(
    fontSize: 11,
    height: 12 / 11,
    fontWeight: FontWeight.w500,
    color: VslastColors.textSecondary,
  );
}

class VslastDesignSystem {
  VslastDesignSystem._();

  static ThemeData get theme {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: VslastColors.background,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: VslastColors.accent,
            brightness: Brightness.light,
          ).copyWith(
            primary: VslastColors.textPrimary,
            onPrimary: VslastColors.surface,
            secondary: VslastColors.accent,
            onSecondary: VslastColors.textPrimary,
            surface: VslastColors.surface,
            onSurface: VslastColors.textPrimary,
            error: VslastColors.danger,
            onError: VslastColors.surface,
          ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: VslastTextStyles.h1,
        headlineMedium: VslastTextStyles.h2,
        titleLarge: VslastTextStyles.h3,
        bodyLarge: VslastTextStyles.body,
        bodyMedium: VslastTextStyles.body,
        labelLarge: VslastTextStyles.bodyMedium,
        bodySmall: VslastTextStyles.caption,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: VslastColors.background,
        foregroundColor: VslastColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VslastColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VslastRadii.field),
          borderSide: const BorderSide(color: VslastColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VslastRadii.field),
          borderSide: const BorderSide(color: VslastColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VslastRadii.field),
          borderSide: const BorderSide(color: VslastColors.accent, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VslastColors.textPrimary,
          foregroundColor: VslastColors.surface,
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VslastRadii.button),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VslastColors.textPrimary,
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: VslastColors.divider),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VslastRadii.button),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: VslastColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
