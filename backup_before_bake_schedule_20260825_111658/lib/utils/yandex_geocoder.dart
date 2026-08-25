import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Обратное геокодирование через HTTP Geocoder API Яндекса — координаты
/// точки на карте → человекочитаемый адрес.
///
/// ВАЖНО — это отдельный ключ, не тот же самый, что ключ MapKit SDK:
///   1. Получите ключ "JavaScript API и HTTP Geocoder" на
///      https://developer.tech.yandex.ru/services (бесплатный лимит есть).
///   2. Впишите его в [_apiKey] ниже.
/// Без ключа функция всегда будет возвращать null — поле «Адрес» на экране
/// доставки при этом остаётся обычным редактируемым текстовым полем, так
/// что пользователь всегда может ввести адрес руками, даже если геокодер
/// не настроен или недоступен.
class YandexGeocoder {
  YandexGeocoder._();

  static const String _apiKey = '2d225c71-fc41-4da2-9153-5e374a6c6f3e';

  /// true, если ключ реально вписан (не осталась заглушка). Экран доставки
  /// использует это, чтобы сразу показать понятную подсказку "введите
  /// адрес вручную" вместо бесконечного тихого ожидания.
  static bool get isConfigured =>
      _apiKey != 'ВСТАВЬТЕ_СЮДА_КЛЮЧ_HTTP_GEOCODER' && _apiKey.isNotEmpty;

  /// [lat] — широта, [lon] — долгота. Возвращает строку адреса или null,
  /// если ключ не настроен, запрос не удался, или ничего не найдено.
  static Future<String?> reverseGeocode(double lat, double lon) async {
    if (!isConfigured) return null;
    try {
      final uri = Uri.parse('https://geocode-maps.yandex.ru/1.x/').replace(
        queryParameters: {
          'apikey': _apiKey,
          'geocode': '$lon,$lat', // Яндекс ждёт "долгота,широта", не наоборот
          'format': 'json',
          'results': '1',
          'lang': 'ru_RU',
        },
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) {
        // Диагностика: смотрите консоль Xcode/Android Studio, если адрес
        // не определяется — здесь будет видна настоящая причина (неверный
        // ключ, лимит запросов исчерпан и т.п.), а не молчаливый null.
        debugPrint(
          'YandexGeocoder: HTTP ${response.statusCode} — ${response.body}',
        );
        return null;
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final members =
          data['response']?['GeoObjectCollection']?['featureMember'];
      if (members is! List || members.isEmpty) {
        debugPrint('YandexGeocoder: пустой результат для $lat,$lon');
        return null;
      }

      final geoObject = members.first['GeoObject'];
      final metaData = geoObject?['metaDataProperty']?['GeocoderMetaData'];

      // Полный текст выглядит как "Россия, ХМАО, Нижневартовск, ул. Мира, 12"
      // — для доставки нужны только улица и дом, без страны/региона/города.
      // Яндекс отдаёт разбор по компонентам с типами (kind) — берём именно
      // street/house, а не режем строку по запятым вслепую.
      final components = metaData?['Address']?['Components'];
      if (components is List) {
        String? street;
        String? house;
        for (final c in components) {
          final kind = c['kind'];
          final name = c['name'];
          if (kind == 'street' && name is String) street = name;
          if (kind == 'house' && name is String) house = name;
        }
        if (street != null || house != null) {
          return [
            street,
            house,
          ].where((e) => e != null && e.isNotEmpty).join(', ');
        }
      }

      // Резервный вариант, если компонентов почему-то нет в ответе: берём
      // последние два сегмента полного адреса (обычно это и есть улица+дом).
      final text = metaData?['text'];
      if (text is String && text.isNotEmpty) {
        final parts = text.split(', ');
        return parts.length >= 2
            ? parts.sublist(parts.length - 2).join(', ')
            : text;
      }
      debugPrint('YandexGeocoder: не нашёл ни компонентов, ни текста в ответе');
      return null;
    } catch (e) {
      // Сеть недоступна / geocoder вернул неожиданный формат — молча
      // отступаем к ручному вводу адреса (это не критическая ошибка для
      // пользователя), но логируем, чтобы при отладке было видно причину.
      debugPrint('YandexGeocoder: исключение — $e');
      return null;
    }
  }
}
