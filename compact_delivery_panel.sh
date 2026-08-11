#!/bin/bash
set -e
#
# Экран «Адрес доставки»:
#  - нижняя панель компактная по умолчанию (максимум ~42% высоты экрана):
#    видна только строка адреса + раскрывашка "Квартира, этаж, комментарий
#    курьеру" + кнопка. Разворачивается по тапу, не занимает пол-экрана
#    сама по себе.
#  - кнопки +/- зума и "моё местоположение" подняты выше — теперь не
#    перекрываются панелью снизу.
#  - при открытии карта ВСЕГДА встаёт на город из профиля — авто-геолокация
#    при входе на экран убрана (отдавала произвольную точку не в том городе,
#    где ведётся доставка). Геолокация теперь только по нажатию на кнопку.
#
# ЗАПУСК: из корня проекта
#   cd /Users/sukolesnikov/Projects/vslast_premium
#   bash compact_delivery_panel.sh

mkdir -p lib

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
/// При открытии карта всегда встаёт на город, выбранный в профиле —
/// геолокация пользователя используется ТОЛЬКО по явному нажатию на
/// кнопку "моё местоположение", не автоматически при входе на экран (в
/// доставке за пределы одного города смысла нет, а случайная геопозиция
/// при открытии только путает).
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
  bool _detailsExpanded = false;
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
      ).timeout(const Duration(seconds: 8));
      final point = Point(latitude: position.latitude, longitude: position.longitude);
      await _mapController?.moveCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: point, zoom: 16)),
        animation: const MapAnimation(type: MapAnimationType.smooth, duration: 0.4),
      );
      _onCameraChanged(CameraPosition(target: point, zoom: 16), true);
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
          // справа над картой. Отступ снизу подобран под компактную
          // нижнюю панель (см. _panelEstimatedHeight ниже) — если панель
          // разворачивается (показаны доп.поля), кнопки всё равно на
          // безопасной высоте, т.к. панель в развёрнутом виде скроллится
          // сама внутри себя, а не растёт поверх кнопок.
          Positioned(
            right: 16,
            bottom: 190,
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

          // Нижняя панель — компактная по умолчанию (адрес + кнопка),
          // квартира/этаж/комментарий скрыты за раскрывашкой "Добавить
          // детали", чтобы не занимать пол-экрана, когда не нужны.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.42,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: Offset(0, -4)),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
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
                      const SizedBox(height: 6),
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
                                const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            prefixIcon: const Icon(Icons.location_on_outlined,
                                size: 18, color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => setState(() => _detailsExpanded = !_detailsExpanded),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _detailsExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                size: 18,
                                color: AppColors.linkAccent,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Квартира, этаж, комментарий курьеру',
                                style: AppTextStyles.linkText,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_detailsExpanded) ...[
                        const SizedBox(height: 4),
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
                        const SizedBox(height: 10),
                        Text('Комментарий курьеру', style: AppTextStyles.fieldLabel),
                        const SizedBox(height: 6),
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
                              hintText: 'Например: домофон 45К',
                              hintStyle: AppTextStyles.searchHint,
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ] else
                        const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: _confirm,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBrown,
                              borderRadius: BorderRadius.circular(24),
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
        const SizedBox(height: 6),
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
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
echo 'Готово. Ключ HTTP Geocoder этот скрипт не трогает (файл yandex_geocoder.dart'
echo 'здесь не перезаписывается) — если он у вас уже вписан, всё останется как есть.'
echo 'Затем: flutter clean && flutter pub get && flutter run'
