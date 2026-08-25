import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/mock_products.dart';
import '../models/product.dart';
import '../providers/favorites_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

/// Экран «Избранное» — товары, отмеченные сердечком в «Каталоге» (или
/// прямо на «Главной»). Используется и как вкладка нижней панели
/// (IndexedStack — тогда кнопка "назад" ничего не делает), и как
/// push-экран из меню профиля (тогда кнопка "назад" возвращает обратно).
class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  void _openProductDetails(BuildContext context, Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  static const double _cardTextBlockHeight = 84;
  static const double _gridSpacing = 10;
  static const int _crossAxisCount = 3;

  SliverGridDelegateWithFixedCrossAxisCount _buildGridDelegate(
    BuildContext context,
    double horizontalPadding,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth =
        (screenWidth -
            horizontalPadding * 2 -
            _gridSpacing * (_crossAxisCount - 1)) /
        _crossAxisCount;
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: _crossAxisCount,
      mainAxisSpacing: _gridSpacing,
      crossAxisSpacing: _gridSpacing,
      mainAxisExtent: itemWidth + _cardTextBlockHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final favoriteProducts = mockProducts
        .where((p) => favorites.isFavorite(p))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 44,
                        height: 44,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.divider,
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.chevron_left,
                          size: 24,
                          color: AppColors.primaryBrown,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Избранное',
                        style: AppTextStyles.screenTitle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              sliver: favoriteProducts.isEmpty
                  ? const SliverToBoxAdapter(child: _EmptyFavorites())
                  : SliverGrid(
                      gridDelegate: _buildGridDelegate(context, 20),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => ProductCard(
                          product: favoriteProducts[index],
                          onOpenDetails: (p) => _openProductDetails(context, p),
                        ),
                        childCount: favoriteProducts.length,
                      ),
                    ),
            ),
          ],
        ),
      ),
      // Нижняя панель навигации намеренно не реализуется здесь —
      // используется текущая панель проекта.
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(
            Icons.favorite_border,
            size: 40,
            color: AppColors.textSecondary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text('Пока нет избранных товаров', style: AppTextStyles.sectionLabel),
          const SizedBox(height: 6),
          Text(
            'Нажмите на сердечко на карточке товара,\nчтобы добавить его сюда',
            textAlign: TextAlign.center,
            style: AppTextStyles.rowLabelMuted,
          ),
        ],
      ),
    );
  }
}
