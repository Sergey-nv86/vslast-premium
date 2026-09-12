import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import '../providers/location_provider.dart';
import '../theme/app_theme.dart';
import '../utils/toast.dart';
import '../utils/yandex_geocoder.dart';
import '../web/yandex_map_web_stub.dart'
    if (dart.library.html) '../web/yandex_map_web.dart';

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

  late final TextEditingController _addressController = TextEditingController(
    text: widget.initialAddress,
  );

  final TextEditingController _apartmentController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  Point? _selectedPoint;

  double _currentZoom = 15;

  bool _isLocating = false;
  bool _isGeocoding = false;
  bool _detailsExpanded = false;

  Timer? _geocodeDebounce;
  bool _geocodeFailureShown = false;

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
      CameraUpdate.newCameraPosition(
        CameraPosition(target: point, zoom: _currentZoom),
      ),
    );

    if (!mounted) return;

    setState(() {
      _selectedPoint = point;
    });
  }

  void _onNativeCameraChanged(CameraPosition position, bool finished) {
    _currentZoom = position.zoom;

    if (!finished) return;

    setState(() {
      _selectedPoint = position.target;
    });

    _geocodeDebounce?.cancel();

    _geocodeDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _reverseGeocode(position.target),
    );
  }

  void _onWebCameraChanged(Map<String, double> data) {
    final latitude = data['latitude'];
    final longitude = data['longitude'];
    final zoom = data['zoom'];

    if (latitude == null || longitude == null) return;

    _currentZoom = zoom ?? _currentZoom;

    final point = Point(latitude: latitude, longitude: longitude);

    setState(() {
      _selectedPoint = point;
    });

    _geocodeDebounce?.cancel();

    _geocodeDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _reverseGeocode(point),
    );
  }

  Future<void> _reverseGeocode(Point point) async {
    if (!mounted) return;

    setState(() {
      _isGeocoding = true;
    });

    final address = await YandexGeocoder.reverseGeocode(
      point.latitude,
      point.longitude,
    );

    if (!mounted) return;

    setState(() {
      _isGeocoding = false;

      if (address != null && address.trim().isNotEmpty) {
        _addressController.text = address;
      }
    });

    if (address == null && !_geocodeFailureShown) {
      _geocodeFailureShown = true;

      if (!YandexGeocoder.isConfigured) {
        FadeToast.show(
          context,
          'Автоопределение адреса не настроено — введите вручную',
          icon: Icons.info_outline,
        );
      } else {
        FadeToast.show(
          context,
          'Не удалось определить адрес по карте — введите вручную',
          icon: Icons.error_outline,
        );
      }
    }
  }

  Future<void> _zoomBy(double delta) async {
    if (kIsWeb) return;

    final target = _selectedPoint;

    if (target == null || _mapController == null) return;

    final newZoom = (_currentZoom + delta).clamp(_minZoom, _maxZoom);

    await _mapController!.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: newZoom),
      ),
      animation: const MapAnimation(
        type: MapAnimationType.smooth,
        duration: 0.2,
      ),
    );

    if (!mounted) return;

    setState(() {
      _currentZoom = newZoom;
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLocating = true;
    });

    try {
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          FadeToast.show(
            context,
            'Нужен доступ к геолокации в настройках',
            icon: Icons.location_disabled,
          );
        }
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (mounted) {
          FadeToast.show(
            context,
            'Включите геолокацию на устройстве',
            icon: Icons.location_disabled,
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 8));

      final point = Point(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (kIsWeb) {
        _onWebCameraChanged({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'zoom': 16,
        });
      } else {
        await _mapController?.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: point, zoom: 16),
          ),
          animation: const MapAnimation(
            type: MapAnimationType.smooth,
            duration: 0.4,
          ),
        );

        _onNativeCameraChanged(CameraPosition(target: point, zoom: 16), true);
      }
    } catch (_) {
      if (mounted) {
        FadeToast.show(
          context,
          'Не удалось определить местоположение',
          icon: Icons.error_outline,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  void _confirm() {
    final street = _addressController.text.trim();

    if (street.isEmpty) {
      FadeToast.show(
        context,
        'Укажите адрес доставки',
        icon: Icons.error_outline,
      );
      return;
    }

    final apartment = _apartmentController.text.trim();
    final floor = _floorController.text.trim();

    if (apartment.isEmpty || floor.isEmpty) {
      _confirmMissingDetails();
      return;
    }

    _finishConfirm();
  }

  Future<void> _confirmMissingDetails() async {
    if (!_detailsExpanded) {
      setState(() {
        _detailsExpanded = true;
      });
    }

    final proceedWithoutFilling = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Квартира и этаж не указаны'),
        content: const Text(
          'Если это частный дом или доставка без '
          'квартиры/этажа — можно продолжить без них. '
          'Если нет — лучше заполнить, чтобы курьеру '
          'было проще вас найти.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Заполнить'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Продолжить без них'),
          ),
        ],
      ),
    );

    if (proceedWithoutFilling == true && mounted) {
      _finishConfirm();
    }
  }

  void _finishConfirm() {
    final street = _addressController.text.trim();
    final apartment = _apartmentController.text.trim();
    final floor = _floorController.text.trim();
    final comment = _commentController.text.trim();

    final apartmentText = apartment.isEmpty ? 'нет' : apartment;

    final floorText = floor.isEmpty ? 'нет' : floor;

    final parts = <String>[street, 'кв. $apartmentText', 'этаж $floorText'];

    var result = parts.join(', ');

    if (comment.isNotEmpty) {
      result = '$result ($comment)';
    }

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final city = context.watch<LocationProvider>().cityCenter;

    final initialLatitude = city.$1;
    final initialLongitude = city.$2;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          if (kIsWeb)
            Positioned.fill(
              child: YandexWebMap(
                latitude: initialLatitude,
                longitude: initialLongitude,
                zoom: _currentZoom,
                onCameraChanged: _onWebCameraChanged,
              ),
            )
          else
            Positioned.fill(
              child: YandexMap(
                onMapCreated: _onMapCreated,
                onCameraPositionChanged: (position, reason, finished) {
                  _onNativeCameraChanged(position, finished);
                },
              ),
            ),

          const IgnorePointer(
            child: Align(
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.only(bottom: 36),
                child: Icon(
                  Icons.location_on,
                  size: 44,
                  color: AppColors.primaryBrown,
                ),
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
                            color: AppColors.shadow,
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        size: 24,
                        color: AppColors.primaryBrown,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        'Адрес доставки',
                        style: AppTextStyles.screenTitleSmall,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (!kIsWeb)
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
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
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
                                strokeWidth: 1.6,
                                color: AppColors.textSecondary,
                              ),
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
                            hintText:
                                'Определяется по карте — или введите вручную',
                            hintStyle: AppTextStyles.searchHint,
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                            prefixIcon: const Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _detailsExpanded = !_detailsExpanded;
                          });
                        },
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
                        Text(
                          'Комментарий курьеру',
                          style: AppTextStyles.fieldLabel,
                        ),
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
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 12,
                              ),
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
                            child: Text(
                              'Подтвердить адрес',
                              style: AppTextStyles.cartBarButton,
                            ),
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
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 12,
              ),
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

  const _MapRoundButton({
    required this.icon,
    required this.onTap,
    this.loading = false,
  });

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
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: loading
            ? const Padding(
                padding: EdgeInsets.all(13),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryBrown,
                ),
              )
            : Icon(icon, size: 20, color: AppColors.primaryBrown),
      ),
    );
  }
}
