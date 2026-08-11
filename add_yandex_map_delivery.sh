#!/bin/bash
set -e
#
# Подключает настоящую карту Яндекса на экран «Адрес доставки»:
#  - карта почти на весь экран, пин закреплён по центру, карта двигается
#    под ним (тащишь карту — двигаешь точку, как в Яндекс.Еде)
#  - обратное геокодирование координаты пина в адрес (HTTP Geocoder API)
#  - кнопка-иконка "определить моё местоположение" (geolocator)
#  - карта при открытии сразу центрируется на выбранном в профиле городе
#
# ТРЕБУЕТ РУЧНОЙ НАСТРОЙКИ — без неё экран не соберётся/не заработает,
# подробности в финальном сообщении и в комментариях самих файлов.
#
# ЗАПУСК: из корня проекта
#   cd /Users/sukolesnikov/Projects/vslast_premium
#   bash add_yandex_map_delivery.sh

mkdir -p lib

mkdir -p lib/providers
cat > lib/providers/location_provider.dart << 'DARTEOF'
import 'package:flutter/foundation.dart';

/// Выбранный пользователем город. Список городов сейчас фиксированный —
/// расширите под реальные города доставки/самовывоза, когда появятся.
class LocationProvider extends ChangeNotifier {
  static const List<String> availableCities = [
    'Нижневартовск',
    'Екатеринбург',
    'Санкт-Петербург',
  ];

  /// Координаты центра города — чтобы карта на экране доставки открывалась
  /// сразу в нужном месте, а не где-то в океане по умолчанию.
  static const Map<String, (double, double)> cityCenters = {
    'Нижневартовск': (60.9344, 76.5531),
    'Екатеринбург': (56.8389, 60.6057),
    'Санкт-Петербург': (59.9311, 30.3609),
  };

  String _city = availableCities.first;

  String get city => _city;

  (double, double) get cityCenter => cityCenters[_city]!;

  void setCity(String city) {
    if (!availableCities.contains(city) || city == _city) return;
    _city = city;
    notifyListeners();
  }
}
DARTEOF
echo 'lib/providers/location_provider.dart — обновлён'

mkdir -p lib/utils
cat > lib/utils/yandex_geocoder.dart << 'DARTEOF'
import 'dart:convert';
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

  static const String _apiKey = 'ВСТАВЬТЕ_СЮДА_КЛЮЧ_HTTP_GEOCODER';

  /// [lat] — широта, [lon] — долгота. Возвращает строку адреса или null,
  /// если ключ не настроен, запрос не удался, или ничего не найдено.
  static Future<String?> reverseGeocode(double lat, double lon) async {
    if (_apiKey == 'ВСТАВЬТЕ_СЮДА_КЛЮЧ_HTTP_GEOCODER' || _apiKey.isEmpty) {
      return null;
    }
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
      if (response.statusCode != 200) return null;

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final members = data['response']?['GeoObjectCollection']?['featureMember'];
      if (members is! List || members.isEmpty) return null;

      final geoObject = members.first['GeoObject'];
      final text = geoObject?['metaDataProperty']?['GeocoderMetaData']?['text'];
      return text is String ? text : null;
    } catch (_) {
      // Сеть недоступна / geocoder вернул неожиданный формат — молча
      // отступаем к ручному вводу адреса, это не критическая ошибка.
      return null;
    }
  }
}
DARTEOF
echo 'lib/utils/yandex_geocoder.dart — обновлён'

mkdir -p lib/screens
cat > lib/screens/delivery_address_screen.dart << 'DARTEOF'
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import '../providers/location_provider.dart';
import '../theme/app_theme.dart';
import '../utils/toast.dart';
import '../utils/yandex_geocoder.dart';

/// Экран ввода адреса доставки в фирменном стиле Всласть — карта Яндекса
/// почти на весь экран, пин закреплён по центру экрана, карта двигается
/// под ним (стандартный паттерн "перетащи карту, чтобы поставить точку",
/// как в Яндекс.Еде/Delivery-приложениях).
///
/// ================================ ВАЖНО ================================
/// Этот файл использует пакет yandex_mapkit (нативный SDK) и geolocator —
/// я не могу их скомпилировать и проверить здесь: у меня нет ни живого
/// Flutter-окружения с iOS/Android рантаймом, ни вашего API-ключа Яндекса.
/// Написано по документации пакета максимально аккуратно, но конкретные
/// названия параметров/колбэков (особенно `onCameraPositionChanged`) могли
/// немного измениться между версиями yandex_mapkit — если при сборке
/// Xcode/Gradle укажет на несовпадение сигнатуры, пришлите мне текст
/// ошибки, я поправлю под вашу версию пакета за один проход, как обычно.
///
/// ЧТО НУЖНО НАСТРОИТЬ У СЕБЯ (без этого экран не заработает):
///   1. pubspec.yaml — добавить зависимости (см. итоговое сообщение).
///   2. Ключ Yandex MapKit SDK — получить на
///      https://developer.tech.yandex.ru/services, вписать в main.dart
///      (см. инструкцию, которую я пришлю отдельно).
///   3. Ключ Yandex HTTP Geocoder — отдельный ключ, см.
///      lib/utils/yandex_geocoder.dart.
///   4. iOS: Info.plist — NSLocationWhenInUseUsageDescription.
///      Android: AndroidManifest.xml — ACCESS_FINE_LOCATION.
/// =========================================================================
class DeliveryAddressScreen extends StatefulWidget {
  final String? initialAddress;

  const DeliveryAddressScreen({super.key, this.initialAddress});

  @override
  State<DeliveryAddressScreen> createState() => _DeliveryAddressScreenState();
}

class _DeliveryAddressScreenState extends State<DeliveryAddressScreen> {
  YandexMapController? _mapController;
  late final TextEditingController _addressController =
      TextEditingController(text: widget.initialAddress);
  final TextEditingController _commentController = TextEditingController();

  Point? _selectedPoint;
  bool _isLocating = false;
  bool _isGeocoding = false;
  Timer? _geocodeDebounce;

  @override
  void dispose() {
    _addressController.dispose();
    _commentController.dispose();
    _geocodeDebounce?.cancel();
    super.dispose();
  }

  Future<void> _onMapCreated(YandexMapController controller) async {
    _mapController = controller;
    final city = context.read<LocationProvider>().cityCenter;
    final point = Point(latitude: city.$1, longitude: city.$2);
    await controller.moveCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: point, zoom: 15)),
    );
    setState(() => _selectedPoint = point);
  }

  /// Вызывается, когда пользователь подвинул карту и отпустил палец —
  /// центр экрана (под закреплённым пином) стал новой выбранной точкой.
  void _onCameraSettled(Point target) {
    setState(() => _selectedPoint = target);
    _geocodeDebounce?.cancel();
    _geocodeDebounce = Timer(const Duration(milliseconds: 350), () {
      _reverseGeocode(target);
    });
  }

  Future<void> _reverseGeocode(Point point) async {
    setState(() => _isGeocoding = true);
    final address = await YandexGeocoder.reverseGeocode(
      point.latitude,
      point.longitude,
    );
    if (!mounted) return;
    setState(() {
      _isGeocoding = false;
      // Геокодер не настроен/недоступен — оставляем то, что человек уже
      // ввёл руками, ничего не затираем пустотой.
      if (address != null) _addressController.text = address;
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          FadeToast.show(context, 'Нужен доступ к геолокации в настройках',
              icon: Icons.location_disabled);
        }
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          FadeToast.show(context, 'Включите геолокацию на устройстве',
              icon: Icons.location_disabled);
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final point = Point(latitude: position.latitude, longitude: position.longitude);
      await _mapController?.moveCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: point, zoom: 16)),
        animation: const MapAnimation(type: MapAnimationType.smooth, duration: 0.4),
      );
      _onCameraSettled(point);
    } catch (_) {
      if (mounted) {
        FadeToast.show(context, 'Не удалось определить местоположение',
            icon: Icons.error_outline);
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _confirm() {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      FadeToast.show(context, 'Укажите адрес доставки', icon: Icons.error_outline);
      return;
    }
    final comment = _commentController.text.trim();
    final result = comment.isEmpty ? address : '$address ($comment)';
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Карта — почти на весь экран, под статус-баром и под нижней
          // панелью тоже (так же, как в вашем референсе).
          Positioned.fill(
            child: YandexMap(
              onMapCreated: _onMapCreated,
              onCameraPositionChanged: (position, reason, finished) {
                if (finished) _onCameraSettled(position.target);
              },
            ),
          ),

          // Закреплённый по центру экрана пин — карта двигается под ним,
          // сам он никогда не смещается.
          const IgnorePointer(
            child: Align(
              alignment: Alignment.center,
              child: Padding(
                // Небольшой сдвиг вверх, чтобы остриё пина указывало точно
                // в оптический центр, а не сама иконка целиком.
                padding: EdgeInsets.only(bottom: 36),
                child: Icon(Icons.location_on, size: 44, color: AppColors.primaryBrown),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                              color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 3)),
                        ],
                      ),
                      child: const Icon(Icons.chevron_left,
                          size: 24, color: AppColors.primaryBrown),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                              color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 3)),
                        ],
                      ),
                      child: Text('Адрес доставки', style: AppTextStyles.screenTitleSmall),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Кнопка "определить моё местоположение" — теперь иконка,
          // не текстовая ссылка (как в вашем референсе), плавающая над
          // картой снизу справа.
          Positioned(
            right: 16,
            bottom: 300,
            child: GestureDetector(
              onTap: _isLocating ? null : _useCurrentLocation,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 4)),
                  ],
                ),
                child: _isLocating
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primaryBrown),
                      )
                    : const Icon(Icons.my_location, size: 22, color: AppColors.primaryBrown),
              ),
            ),
          ),

          // Нижняя панель с адресом/комментарием/кнопкой — поверх карты,
          // с закруглёнными верхними углами.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: Offset(0, -4)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Адрес', style: AppTextStyles.fieldLabel),
                        if (_isGeocoding) ...[
                          const SizedBox(width: 8),
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                                strokeWidth: 1.6, color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: _addressController,
                        style: AppTextStyles.rowLabel,
                        decoration: InputDecoration(
                          hintText: 'Определяется по карте — или введите вручную',
                          hintStyle: AppTextStyles.searchHint,
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                          prefixIcon: const Icon(Icons.location_on_outlined,
                              size: 20, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Комментарий курьеру', style: AppTextStyles.fieldLabel),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: _commentController,
                        maxLines: 2,
                        style: AppTextStyles.rowLabel,
                        decoration: InputDecoration(
                          hintText: 'Например: домофон 45К, 3 этаж',
                          hintStyle: AppTextStyles.searchHint,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: _confirm,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 17),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBrown,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          alignment: Alignment.center,
                          child: Text('Подтвердить адрес',
                              style: AppTextStyles.cartBarButton),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
DARTEOF
echo 'lib/screens/delivery_address_screen.dart — обновлён'

echo ''
echo 'Готово с кодом. ОБЯЗАТЕЛЬНО прочитайте инструкцию по настройке в чате —'
echo 'без API-ключей и нативной настройки iOS/Android экран не соберётся.'
