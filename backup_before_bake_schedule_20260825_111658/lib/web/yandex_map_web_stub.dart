import 'package:flutter/widgets.dart';

class YandexWebMap extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double zoom;
  final ValueChanged<Map<String, double>>? onCameraChanged;

  const YandexWebMap({
    super.key,
    required this.latitude,
    required this.longitude,
    this.zoom = 15,
    this.onCameraChanged,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
