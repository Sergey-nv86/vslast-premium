import 'package:flutter/services.dart';

/// Простой форматтер российского номера телефона без внешних пакетов:
/// вводимые цифры укладываются в маску "+7 (___) ___-__-__".
class RuPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Первая цифра всегда трактуется как код страны (7/8) и не показывается
    // отдельно — маска сама начинается с "+7".
    if (digits.startsWith('7') || digits.startsWith('8')) {
      digits = digits.substring(1);
    }
    if (digits.length > 10) digits = digits.substring(0, 10);

    final buffer = StringBuffer('+7 ');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '+7 ',
        selection: TextSelection.collapsed(offset: 3),
      );
    }

    buffer.write('(');
    buffer.write(digits.substring(0, digits.length.clamp(0, 3)));
    if (digits.length >= 3) buffer.write(') ');
    if (digits.length > 3) {
      buffer.write(digits.substring(3, digits.length.clamp(3, 6)));
    }
    if (digits.length >= 6) buffer.write('-');
    if (digits.length > 6) {
      buffer.write(digits.substring(6, digits.length.clamp(6, 8)));
    }
    if (digits.length >= 8) buffer.write('-');
    if (digits.length > 8) {
      buffer.write(digits.substring(8, digits.length.clamp(8, 10)));
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
