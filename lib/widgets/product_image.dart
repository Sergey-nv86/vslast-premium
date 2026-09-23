import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Универсальное изображение товара.
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
    return url.startsWith('http://') || url.startsWith('https://');
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

  Widget _buildImage(String url, int decodeWidth) {
    final image = _isNetworkImage
        ? Image.network(
            _optimizedNetworkUrl(url, decodeWidth),
            fit: BoxFit.contain,
            cacheWidth: decodeWidth,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stackTrace) => _placeholder(),
          )
        : Image.asset(
            url,
            fit: BoxFit.contain,
            cacheWidth: decodeWidth,
            errorBuilder: (context, error, stackTrace) => _placeholder(),
          );

    return image;
  }

  Widget _image() {
    final url = imageUrl.trim();
    if (url.isEmpty) return _placeholder();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth && constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 600.0;
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final decodeWidth = (width * dpr).clamp(160.0, 1200.0).round();

        // The background fills the card, while the foreground keeps the
        // complete product visible. This avoids the excessive crop caused by
        // BoxFit.cover without leaving an empty image area.
        final background = _buildImage(url, decodeWidth);
        final foreground = _buildImage(url, decodeWidth);

        return Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Opacity(
                opacity: 0.28,
                child: background,
              ),
            ),
            Container(color: AppColors.surfaceMuted.withValues(alpha: 0.34)),
            foreground,
          ],
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
