import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Универсальное изображение товара.
///
/// Поддерживает:
/// - локальные Flutter assets;
/// - http/https URL из Supabase Storage;
/// - пустой или некорректный URL с fallback-placeholder.
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

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();

    if (url.isEmpty) {
      return _placeholder();
    }

    Widget image;

    if (_isNetworkImage) {
      image = Image.network(
        url,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _placeholder();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return _placeholder();
        },
      );
    } else {
      image = Image.asset(
        url,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _placeholder();
        },
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }
}
