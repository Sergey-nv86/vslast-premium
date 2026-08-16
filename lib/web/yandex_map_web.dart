import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

@JS('VslastYandexMap')
external JSObject? get _vslastYandexMap;

@JS('VslastYandexMap.create')
external JSPromise<JSAny?> _createMap(
  JSString elementId,
  JSNumber latitude,
  JSNumber longitude,
  JSNumber zoom,
);

@JS('VslastYandexMap.moveTo')
external void _moveMap(
  JSString elementId,
  JSNumber latitude,
  JSNumber longitude,
  JSNumber zoom,
);

@JS('VslastYandexMap.destroy')
external void _destroyMap(JSString elementId);

class YandexWebMap extends StatefulWidget {
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
  State<YandexWebMap> createState() => _YandexWebMapState();
}

class _YandexWebMapState extends State<YandexWebMap> {
  static int _counter = 0;

  late final String _viewType;
  late final String _elementId;

  web.EventListener? _mapReadyListener;
  web.EventListener? _mapMovedListener;

  bool _created = false;
  bool _creating = false;

  @override
  void initState() {
    super.initState();

    final id = _counter++;

    _viewType = 'vslast-yandex-map-$id';
    _elementId = '$_viewType-element';

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final element = web.HTMLDivElement()
          ..id = _elementId
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.minWidth = '0'
          ..style.minHeight = '0'
          ..style.display = 'block';

        return element;
      },
    );

    _mapReadyListener = (web.Event event) {
      final customEvent = event as web.CustomEvent;
      final detail = customEvent.detail;

      if (detail == null) return;

      final detailObject = detail.dartify();

      if (detailObject is Map &&
          detailObject['id'] == _elementId &&
          mounted) {
        setState(() {
          _created = true;
          _creating = false;
        });
      }
    }.toJS;

    _mapMovedListener = (web.Event event) {
      final customEvent = event as web.CustomEvent;
      final detail = customEvent.detail;

      if (detail == null) return;

      final detailObject = detail.dartify();

      if (detailObject is! Map) return;
      if (detailObject['id'] != _elementId) return;

      final latitude = detailObject['latitude'];
      final longitude = detailObject['longitude'];
      final zoom = detailObject['zoom'];

      if (latitude is num &&
          longitude is num &&
          zoom is num &&
          widget.onCameraChanged != null) {
        widget.onCameraChanged!({
          'latitude': latitude.toDouble(),
          'longitude': longitude.toDouble(),
          'zoom': zoom.toDouble(),
        });
      }
    }.toJS;

    web.window.addEventListener(
      'vslast-map-ready',
      _mapReadyListener!,
    );

    web.window.addEventListener(
      'vslast-map-moved',
      _mapMovedListener!,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _waitForElementAndCreateMap();
    });
  }

  Future<void> _waitForElementAndCreateMap() async {
    if (!mounted || _created || _creating) return;

    _creating = true;

    for (int i = 0; i < 50; i++) {
      if (!mounted) return;

      final element = web.document.getElementById(_elementId);

      if (element != null) {
        await _createMapInstance();
        return;
      }

      await Future<void>.delayed(
        const Duration(milliseconds: 50),
      );
    }

    _creating = false;

    debugPrint(
      'Yandex Web Map: DOM element not found after waiting: $_elementId',
    );
  }

  Future<void> _createMapInstance() async {
    try {
      if (_vslastYandexMap == null) {
        _creating = false;
        debugPrint('VslastYandexMap не найден');
        return;
      }

      final element = web.document.getElementById(_elementId);

      if (element == null) {
        _creating = false;
        debugPrint(
          'Yandex Web Map: element not found: $_elementId',
        );
        return;
      }

      debugPrint(
        'Создание Yandex Web Map: $_elementId',
      );

      await _createMap(
        _elementId.toJS,
        widget.latitude.toJS,
        widget.longitude.toJS,
        widget.zoom.toJS,
      ).toDart;

      if (mounted) {
        setState(() {
          _created = true;
          _creating = false;
        });
      }
    } catch (e, stackTrace) {
      _creating = false;

      debugPrint(
        'Ошибка создания Yandex Web Map: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );
    }
  }

  @override
  void didUpdateWidget(covariant YandexWebMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_created) return;

    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude ||
        oldWidget.zoom != widget.zoom) {
      _moveMapInstance();
    }
  }

  void _moveMapInstance() {
    try {
      if (_vslastYandexMap == null) return;

      _moveMap(
        _elementId.toJS,
        widget.latitude.toJS,
        widget.longitude.toJS,
        widget.zoom.toJS,
      );
    } catch (e) {
      debugPrint(
        'Ошибка перемещения Yandex Web Map: $e',
      );
    }
  }

  @override
  void dispose() {
    if (_mapMovedListener != null) {
      web.window.removeEventListener(
        'vslast-map-moved',
        _mapMovedListener!,
      );
    }

    if (_mapReadyListener != null) {
      web.window.removeEventListener(
        'vslast-map-ready',
        _mapReadyListener!,
      );
    }

    try {
      if (_vslastYandexMap != null) {
        _destroyMap(_elementId.toJS);
      }
    } catch (_) {}

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(
      viewType: _viewType,
    );
  }
}
