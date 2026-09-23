import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Универсальное изображение товара.
///
/// Поддерживает:
/// - локальные Flutter assets;
/// - http/https URL из Supabase Storage;
/// - безопасный fallback при пустом или некорректном URL.
///
/// Без flutter_cache_manager / sqflite.
/// Это исключает ошибку iOS:
/// "attempt to write a readonly database".

class ProductImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double iconSize;
  final BorderRadius? borderRadius;

  const ProductImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.iconSize = 36,
    this.borderRadius,
  });

  bool get _isNetworkImage {
    final url = imageUrl.trim().toLowerCase();

    return url.startsWith('http://') ||
        url.startsWith('https://');
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceMuted,
      alignment: Alignment.center,
      child: Icon(
        Icons.bakery_dining_outlined,
        size: iconSize,
        color: AppColors.textSecondary,
      ),
    );
  }

  String _optimizedNetworkUrl(String url, int width) {
    // Supabase Storage can resize public images server-side. This reduces
    // network transfer as well as decode memory; cacheWidth alone only limits
    // the decoded bitmap and still downloads the original file.
    try {
      final uri = Uri.parse(url);
      const marker = '/storage/v1/object/public/';
      final path = uri.path;
      final markerIndex = path.indexOf(marker);
      if (markerIndex < 0) return url;

      final renderPath = path.substring(0, markerIndex) +
          '/storage/v1/render/image/public/' +
          path.substring(markerIndex + marker.length);
      final query = Map<String, String>.from(uri.queryParameters)
        ..['width'] = width.toString();

      return uri.replace(path: renderPath, queryParameters: query).toString();
    } catch (_) {
      return url;
    }
  }

  Widget _image() {
    final url = imageUrl.trim();

    if (url.isEmpty) {
      return _placeholder();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth && constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 600.0;
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final decodeWidth = (width * dpr).clamp(160.0, 1200.0).round();

        if (_isNetworkImage) {
          final optimizedUrl = _optimizedNetworkUrl(url, decodeWidth);
          return Image.network(
            optimizedUrl,
            fit: fit,
            cacheWidth: decodeWidth,
            filterQuality: FilterQuality.medium,
            frameBuilder: (
              context,
              child,
              frame,
              wasSynchronouslyLoaded,
            ) {
              if (wasSynchronouslyLoaded || frame != null) {
                return child;
              }

              return _placeholder();
            },
            errorBuilder: (
              context,
              error,
              stackTrace,
            ) {
              return _placeholder();
            },
          );
        }

        return Image.asset(
          url,
          fit: fit,
          cacheWidth: decodeWidth,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return _placeholder();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = _image();

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }
}
