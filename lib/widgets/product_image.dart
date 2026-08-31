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

  Widget _image() {
    final url = imageUrl.trim();

    if (url.isEmpty) {
      return _placeholder();
    }

    if (_isNetworkImage) {
      return Image.network(
        url,
        fit: fit,
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
      errorBuilder: (
        context,
        error,
        stackTrace,
      ) {
        return _placeholder();
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
