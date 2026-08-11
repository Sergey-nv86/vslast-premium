#!/bin/bash
set -e
#
# Экран «Адрес доставки»: кнопки +/- зума, автоопределение геолокации
# при открытии экрана (раньше карта всегда открывалась в одной и той же
# точке города), поля «Квартира»/«Этаж», в поле «Адрес» теперь только
# улица и дом (без страны/региона/города).
#
# !!! ВАЖНО: этот скрипт перезаписывает lib/utils/yandex_geocoder.dart —
# впишите туда свой ключ HTTP Geocoder заново после применения, он не
# сохраняется автоматически.
#
# ЗАПУСК: из корня проекта
#   cd /Users/sukolesnikov/Projects/vslast_premium
#   bash polish_delivery_map.sh

mkdir -p lib

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
          return [street, house].where((e) => e != null && e.isNotEmpty).join(', ');
        }
      }

      // Резервный вариант, если компонентов почему-то нет в ответе: берём
      // последние два сегмента полного адреса (обычно это и есть улица+дом).
      final text = metaData?['text'];
      if (text is String && text.isNotEmpty) {
        final parts = text.split(', ');
        return parts.length >= 2 ? parts.sublist(parts.length - 2).join(', ') : text;
      }
      return null;
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
/// При открытии экран сам пробует определить реальную геолокацию
/// пользователя и сразу центрирует карту на ней; если доступа к геолокации
/// нет (запрещён, отключён, симулятор без настроенной локации) — тихо
/// откатывается на координаты города, выбранного в профиле.
class DeliveryAddressScreen extends StatefulWidget {
  final String? initialAddress;

  const DeliveryAddressScreen({super.key, this.initialAddress});

  @override
  State<DeliveryAddressScreen> createState() => _DeliveryAddressScreenState();
}

class _DeliveryAddressScreenState extends State<DeliveryAddressScreen> {
  static const double _minZoom = 3;
  static const double _maxZoom = 19;

  YandexMapController? _mapController;
  late final TextEditingController _addressController =
      TextEditingController(text: widget.initialAddress);
  final TextEditingController _apartmentController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  Point? _selectedPoint;
  double _currentZoom = 15;
  bool _isLocating = false;
  bool _isGeocoding = false;
  Timer? _geocodeDebounce;

  @override
  void dispose() {
    _addressController.dispose();
    _apartmentController.dispose();
    _floorController.dispose();
    _commentController.dispose();
    _geocodeDebounce?.cancel();
    super.dispose();
  }

  Future<void> _onMapCreated(YandexMapController controller) async {
    _mapController = controller;

    // Сначала пробуем встать на реальную геолокацию пользователя, и только
    // если это не удалось — на координаты города из профиля. Раньше карта
    // всегда открывалась в одной и той же точке города, что и выглядело
    // как "случайный адрес", никак не связанный с пользователем.
    final located = await _moveToCurrentLocation(showErrors: false);
    if (located) return;

    final city = context.read<LocationProvider>().cityCenter;
    final point = Point(latitude: city.$1, longitude: city.$2);
    await controller.moveCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: point, zoom: _currentZoom)),
    );
    setState(() => _selectedPoint = point);
  }

  /// Вызывается, когда камера сдвинулась (перетаскивание, зум, программное
  /// перемещение) — держим зум и центр карты в актуальном состоянии.
  void _onCameraChanged(CameraPosition position, bool finished) {
    _currentZoom = position.zoom;
    if (!finished) return;
    setState(() => _selectedPoint = position.target);
    _geocodeDebounce?.cancel();
    _geocodeDebounce = Timer(const Duration(milliseconds: 350), () {
      _reverseGeocode(position.target);
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

  Future<void> _zoomBy(double delta) async {
    final target = _selectedPoint;
    if (target == null || _mapController == null) return;
    final newZoom = (_currentZoom + delta).clamp(_minZoom, _maxZoom);
    await _mapController!.moveCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: newZoom)),
      animation: const MapAnimation(type: MapAnimationType.smooth, duration: 0.2),
    );
    setState(() => _currentZoom = newZoom);
  }

  /// Возвращает true, если удалось определить и применить геолокацию.
  Future<bool> _moveToCurrentLocation({bool showErrors = true}) async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (showErrors && mounted) {
          FadeToast.show(context, 'Нужен доступ к геолокации в настройках',
              icon: Icons.location_disabled);
        }
        return false;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (showErrors && mounted) {
          FadeToast.show(context, 'Включите геолокацию на устройстве',
              icon: Icons.location_disabled);
        }
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 8));
      final point = Point(latitude: position.latitude, longitude: position.longitude);
      await _mapController?.moveCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: point, zoom: 16)),
        animation: const MapAnimation(type: MapAnimationType.smooth, duration: 0.4),
      );
      _onCameraChanged(CameraPosition(target: point, zoom: 16), true);
      return true;
    } catch (_) {
      if (showErrors && mounted) {
        FadeToast.show(context, 'Не удалось определить местоположение',
            icon: Icons.error_outline);
      }
      return false;
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    await _moveToCurrentLocation();
    if (mounted) setState(() => _isLocating = false);
  }

  void _confirm() {
    final street = _addressController.text.trim();
    if (street.isEmpty) {
      FadeToast.show(context, 'Укажите адрес доставки', icon: Icons.error_outline);
      return;
    }
    final apartment = _apartmentController.text.trim();
    final floor = _floorController.text.trim();
    final comment = _commentController.text.trim();

    final parts = <String>[street];
    if (apartment.isNotEmpty) parts.add('кв. $apartment');
    if (floor.isNotEmpty) parts.add('этаж $floor');
    var result = parts.join(', ');
    if (comment.isNotEmpty) result = '$result ($comment)';

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
                _onCameraChanged(position, finished);
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

          // Зум +/- и "моё местоположение" — колонка плавающих кнопок
          // справа над картой, стандартное расположение для карт.
          Positioned(
            right: 16,
            bottom: 330,
            child: Column(
              children: [
                _MapRoundButton(icon: Icons.add, onTap: () => _zoomBy(1)),
                const SizedBox(height: 8),
                _MapRoundButton(icon: Icons.remove, onTap: () => _zoomBy(-1)),
                const SizedBox(height: 16),
                _MapRoundButton(
                  icon: Icons.my_location,
                  onTap: _isLocating ? null : _useCurrentLocation,
                  loading: _isLocating,
                ),
              ],
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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Улица, дом', style: AppTextStyles.fieldLabel),
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _SmallField(
                              label: 'Квартира',
                              hint: 'Например: 45',
                              controller: _apartmentController,
                              keyboardType: TextInputType.text,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SmallField(
                              label: 'Этаж',
                              hint: 'Например: 3',
                              controller: _floorController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
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
                            hintText: 'Например: домофон 45К, встретить у подъезда',
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
          ),
        ],
      ),
    );
  }
}

class _SmallField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;

  const _SmallField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: AppTextStyles.rowLabel,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.searchHint,
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _MapRoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;

  const _MapRoundButton({required this.icon, required this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        child: loading
            ? const Padding(
                padding: EdgeInsets.all(13),
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primaryBrown),
              )
            : Icon(icon, size: 20, color: AppColors.primaryBrown),
      ),
    );
  }
}
DARTEOF
echo 'lib/screens/delivery_address_screen.dart — обновлён'

echo ''
echo '!!! Не забудьте вписать ключ HTTP Geocoder заново в lib/utils/yandex_geocoder.dart'
echo 'Затем: flutter clean && flutter pub get && flutter run'
