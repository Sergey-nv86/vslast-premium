/// Форматирование дат на русском языке без подключения пакета intl —
/// чтобы не тянуть лишнюю зависимость и не настраивать локализацию
/// только ради пары строк на экранах заказа.
const List<String> _ruMonthsGenitive = [
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];

String _twoDigits(int value) => value.toString().padLeft(2, '0');

/// 25 -> "25 июля"
String formatRuDate(DateTime date) {
  return '${date.day} ${_ruMonthsGenitive[date.month - 1]}';
}

/// -> "25 июля 2026"
String formatRuDateWithYear(DateTime date) {
  return '${date.day} ${_ruMonthsGenitive[date.month - 1]} ${date.year}';
}

/// -> "25 июля 2026, 10:45"
String formatRuDateTime(DateTime date) {
  final time = '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
  return '${formatRuDateWithYear(date)}, $time';
}

/// -> "10:32"
String formatRuTime(DateTime date) =>
    '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';

/// Для поля "Когда забрать": добавляет "Сегодня," / "Завтра,", если применимо.
String formatPickupDateLabel(DateTime date) {
  final now = DateTime.now();
  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  if (isSameDay(date, now)) return 'Сегодня, ${formatRuDate(date)}';
  final tomorrow = now.add(const Duration(days: 1));
  if (isSameDay(date, tomorrow)) return 'Завтра, ${formatRuDate(date)}';
  return formatRuDate(date);
}
