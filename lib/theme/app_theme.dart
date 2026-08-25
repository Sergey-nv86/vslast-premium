import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Цветовая палитра проекта Всласть — на основе фирменного брендбука
/// (CMYK 30/5/0/0 небо, 30/30/0/0 лаванда, 0/25/0/0 роза, 0/5/30/0 ваниль,
/// 5/65/60/80 графит). Философия 70/15/10/5: молочный фон — графит для
/// текста/кнопок — один пастельный акцент на экран — пастель для бейджей.
///
/// ВАЖНО: имя `primaryBrown` — историческое, осталось от прежней
/// коричневой палитры. Сейчас в нём графит, не коричневый — переименовать
/// стоит отдельным заходом (это потребует правки во всех файлах, где он
/// используется), сейчас меняем только значения токенов.
class AppColors {
  AppColors._();

  // Фон — молочный (70%)
  static const Color background = Color(0xFFFAF7F1);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Графит (15%) — текст, кнопки, ключевые элементы.
  static const Color primaryBrown = Color(0xFF201C1A);
  static const Color primaryBrownDark = Color(0xFF14100F);

  // Второстепенные поверхности (поиск, чипы, плашка корзины)
  static const Color surfaceMuted = Color(0xFFF1ECE3);
  static const Color surfaceMutedDark = Color(0xFFE7E0D3);

  // Текст
  static const Color textPrimary = Color(0xFF201C1A);
  static const Color textSecondary = Color(0xFF8A8177);
  // Приглушённый цвет подписей строк/дней недели.
  static const Color rowLabelMuted = textSecondary;
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Фирменная пастель (10%) — один акцент на экран/категорию.
  static const Color accentSky = Color(0xFFB3F2FF);
  static const Color accentLavender = Color(0xFFB3B3FF);
  static const Color accentRose = Color(0xFFFFBFFF);
  static const Color accentVanilla = Color(0xFFFFF2B3);

  // Бейджи (5%) — сейчас всё ещё сплошная заливка с белым текстом (это
  // предстоит переделать в "типографические капсулы" отдельным шагом —
  // см. пункт 9 брендбука). ХИТ — графит, НОВИНКА/АКЦИЯ — более
  // насыщенные варианты лаванды/розы, чтобы белый текст оставался читаемым.
  static const Color badgeHit = Color(0xFF201C1A);
  static const Color badgeNew = Color(0xFF7A7AD1);
  static const Color badgePromo = Color(0xFFCC6FCC);

  static const Color divider = Color(0xFFEDE7DB);
  static const Color shadow = Color(0x14201C1A);

  /// Насыщенный вариант лавандового — для ссылок/тегов на светлом фоне.
  /// Сами accentSky/Lavender/Rose/Vanilla слишком бледные для мелкого
  /// текста (плохо читаются) — они для крупных поверхностей/подложек.
  static const Color linkAccent = Color(0xFF6B6BC7);

  // --- Мои заказы: статусы ---
  static const Color statusPendingBg = Color(0xFFFFF2B3);
  static const Color statusPendingText = Color(0xFF8A7328);
  static const Color statusSuccessBg = Color(0xFFDCEEDB);
  static const Color statusSuccessText = Color(0xFF4C8A55);

  // --- Вход/Регистрация и др.: акцентная кнопка ---
  // Брендбук прямо просит не использовать золотой градиент — раньше
  // здесь была коричнево-золотая заливка ("Иду за покупками", "Оплатить
  // по СБП" и т.д.). Оставил структуру (эти кнопки собраны через
  // LinearGradient) нетронутой в самих виджетах, но обе точки
  // градиента теперь ведут на один и тот же графит — визуально это
  // сплошная кнопка без "золота", без необходимости трогать код кнопок.
  static const Color accentGradientStart = Color(0xFF201C1A);
  static const Color accentGradientEnd = Color(0xFF201C1A);
}

class AppTextStyles {
  AppTextStyles._();

  /// Заголовок экрана «Каталог» — витринный serif-шрифт.
  static TextStyle screenTitle = GoogleFonts.alice(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryBrown,
    height: 1.1,
  );

  static TextStyle searchHint = GoogleFonts.jost(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static TextStyle categoryChip = GoogleFonts.jost(
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static TextStyle productName = GoogleFonts.jost(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.15,
  );

  static TextStyle productPrice = GoogleFonts.jost(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle badgeLabel = GoogleFonts.jost(
    fontSize: 9,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
    letterSpacing: 0.2,
  );

  static TextStyle cartBarText = GoogleFonts.jost(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle cartBarButton = GoogleFonts.jost(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
  );

  static TextStyle preorderButton = GoogleFonts.jost(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
  );

  // --- Оформление заказа / Подтверждение заказа ---

  /// Заголовок экранов «Оформление заказа» и «Заказ принят!».
  static TextStyle screenTitleSmall = GoogleFonts.alice(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryBrown,
    height: 1.15,
  );

  /// Подзаголовки секций: «Ваш заказ», «Способ получения», «Состав заказа».
  static TextStyle sectionLabel = GoogleFonts.jost(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Счётчик рядом с заголовком секции: «4 товара».
  static TextStyle sectionCounter = GoogleFonts.jost(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static TextStyle orderItemName = GoogleFonts.jost(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static TextStyle orderItemPrice = GoogleFonts.jost(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle receiptQty = GoogleFonts.jost(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  /// Обычный текст строки (пункт меню, значение поля).
  static TextStyle rowLabel = GoogleFonts.jost(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle rowLabelMuted = GoogleFonts.jost(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.35,
  );

  static TextStyle rowValue = GoogleFonts.jost(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle totalLabel = GoogleFonts.jost(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle totalValue = GoogleFonts.jost(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle infoNote = GoogleFonts.jost(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.35,
  );

  static TextStyle optionTitle = GoogleFonts.jost(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle optionSubtitle = GoogleFonts.jost(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // --- Мои заказы ---

  static TextStyle orderNumber = GoogleFonts.jost(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  static TextStyle orderTitle = GoogleFonts.alice(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static TextStyle statusPillLabel = GoogleFonts.jost(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  // --- Вход/Регистрация ---

  static TextStyle authLogoTitle = GoogleFonts.alice(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryBrown,
  );

  static TextStyle authTagline = GoogleFonts.jost(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.linkAccent,
    letterSpacing: 0.6,
  );

  static TextStyle authHeading = GoogleFonts.alice(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryBrown,
  );

  static TextStyle fieldLabel = GoogleFonts.jost(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle linkText = GoogleFonts.jost(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.linkAccent,
  );

  static TextStyle checkboxText = GoogleFonts.jost(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // --- Карточка товара ---

  static TextStyle productDetailTitle = GoogleFonts.alice(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryBrown,
    height: 1.15,
  );

  static TextStyle productDetailPrice = GoogleFonts.jost(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle ratingValue = GoogleFonts.jost(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle descriptionText = GoogleFonts.jost(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle nutritionValue = GoogleFonts.jost(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle nutritionLabel = GoogleFonts.jost(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}

/// Форматирует цену с разделителем разрядов и знаком ₽.
/// 1540 -> "1 540 ₽"
String formatPrice(int price) {
  final digits = price.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    final posFromEnd = digits.length - i;
    buffer.write(digits[i]);
    if (posFromEnd > 1 && posFromEnd % 3 == 1) {
      buffer.write('\u00A0'); // неразрывный пробел
    }
  }
  return '${buffer.toString()} ₽';
}

/// Склонение слова «товар» под число.
/// 1 -> товар, 2-4 -> товара, 5+ -> товаров
String pluralizeItems(int count) {
  final mod10 = count % 10;
  final mod100 = count % 100;
  if (mod10 == 1 && mod100 != 11) return 'товар';
  if (mod10 >= 2 && mod10 <= 4 && !(mod100 >= 12 && mod100 <= 14)) {
    return 'товара';
  }
  return 'товаров';
}
