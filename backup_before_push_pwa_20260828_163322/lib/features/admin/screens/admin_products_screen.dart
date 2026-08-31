
import 'package:flutter/material.dart';

import '../../../models/product.dart';
import '../../../services/product_service.dart';
import '../../../theme/app_theme.dart';

import '../models/admin_product_meta.dart';
import 'admin_product_edit_screen.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final ProductService _productService = ProductService.instance;

  final TextEditingController _searchController = TextEditingController();

  String _query = '';

  ProductCategory? _category;

  List<Product> _products = [];

  final Map<String, AdminProductMeta> _metas = {};

  bool _loading = true;

  String? _error;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      final value = _searchController.text;

      if (value == _query) {
        return;
      }

      setState(() {
        _query = value;
      });
    });

    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // LOAD
  // ---------------------------------------------------------------------------

  Future<void> _loadProducts() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final products = await _productService.getProducts();

      if (!mounted) {
        return;
      }

      setState(() {
        _products = products;

        _metas.clear();

        for (int i = 0; i < products.length; i++) {
          _metas[products[i].id] = AdminProductMeta.demoSeed(products[i], i);
        }

        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  // ---------------------------------------------------------------------------
  // FILTER
  // ---------------------------------------------------------------------------

  List<Product> get _filtered {
    final query = _query.trim().toLowerCase();

    return _products.where((product) {
      final matchesCategory =
          _category == null || product.category == _category;

      final matchesQuery =
          query.isEmpty || product.name.toLowerCase().contains(query);

      return matchesCategory && matchesQuery;
    }).toList();
  }

  int _countFor(ProductCategory? category) {
    if (category == null) {
      return _products.length;
    }

    return _products.where((product) => product.category == category).length;
  }

  // ---------------------------------------------------------------------------
  // STOCK
  // ---------------------------------------------------------------------------

  Product _withInStock(Product product, bool inStock) {
    return Product(
      id: product.id,
      name: product.name,
      price: product.price,
      imageUrl: product.imageUrl,
      category: product.category,
      badge: product.badge,
      inStock: inStock,
      isWeighed: product.isWeighed,
      rating: product.rating,
      reviewsCount: product.reviewsCount,
      weightLabel: product.weightLabel,
      description: product.description,
      caloriesPer100g: product.caloriesPer100g,
      proteinPer100g: product.proteinPer100g,
      fatPer100g: product.fatPer100g,
      carbsPer100g: product.carbsPer100g,
      composition: product.composition,
      galleryImages: product.galleryImages,
    );
  }

  Future<void> _toggleStock(Product product, bool value) async {
    final index = _products.indexWhere((item) => item.id == product.id);

    if (index == -1) {
      return;
    }

    final updated = _withInStock(product, value);

    setState(() {
      _products[index] = updated;
    });

    try {
      await _productService.updateProduct(updated);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _products[index] = product;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось сохранить изменение: $error')),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // ADD PRODUCT
  // ---------------------------------------------------------------------------

  Future<void> _openAdd() async {
    final result = await Navigator.of(context).push<AdminProductEditResult>(
      MaterialPageRoute(builder: (_) => const AdminProductEditScreen()),
    );

    if (!mounted ||
        result == null ||
        result.deleted ||
        result.product == null) {
      return;
    }

    try {
      setState(() {
        _loading = true;
      });

      // Сначала создаём товар, чтобы получить Supabase ID.
      var savedProduct = await _productService.createProduct(result.product!);

      // Загружаем фотографии последовательно, чтобы не удерживать
      // всю галерею в памяти одновременно.
      if (result.pickedPhotos.isNotEmpty) {
        final galleryUrls = <String>[];

        for (var i = 0; i < result.pickedPhotos.length; i++) {
          final photo = result.pickedPhotos[i];
          final bytes = await photo.readAsBytes();

          final name = photo.name;
          final dot = name.lastIndexOf('.');
          final extension =
              dot >= 0 && dot < name.length - 1
                  ? name.substring(dot + 1)
                  : 'jpg';

          final url = await _productService.uploadProductGalleryImage(
            productId: savedProduct.id,
            bytes: bytes,
            extension: extension,
            index: i,
          );

          galleryUrls.add(url);
        }

        if (galleryUrls.isNotEmpty) {
          await _productService.updateProductGallery(
            productId: savedProduct.id,
            galleryImages: galleryUrls,
          );

          savedProduct =
              await _productService.getProduct(savedProduct.id) ?? savedProduct;
        }
      }


      if (!mounted) {
        return;
      }

      setState(() {
        _products.add(savedProduct);
        _metas[savedProduct.id] = result.meta ?? AdminProductMeta.blank();
        _loading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Товар успешно добавлен')));
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      _showSaveError('Не удалось добавить товар', error);
    }
  }

  Future<void> _openEdit(Product product) async {
    final result = await Navigator.of(context).push<AdminProductEditResult>(
      MaterialPageRoute(
        builder: (_) =>
            AdminProductEditScreen(product: product, meta: _metas[product.id]),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    if (result.deleted) {
      try {
        setState(() {
          _loading = true;
          _error = null;
        });

        await _productService.deleteProduct(product.id);

        if (!mounted) {
          return;
        }

        setState(() {
          _products.removeWhere((item) => item.id == product.id);
          _metas.remove(product.id);
          _loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Товар удалён из каталога')),
        );
      } catch (error) {
        if (!mounted) {
          return;
        }

        setState(() {
          _loading = false;
        });

        _showSaveError('Не удалось удалить товар', error);
      }

      return;
    }

    if (result.product == null) {
      return;
    }

    try {
      setState(() {
        _loading = true;
      });

      var savedProduct = await _productService.updateProduct(result.product!);

      // Новые фотографии добавляем к уже существующей галерее.
      // Загружаем их последовательно, чтобы не держать всю галерею
      // в памяти одновременно.
      if (result.pickedPhotos.isNotEmpty) {
        final galleryUrls = <String>[];

        for (var i = 0; i < result.pickedPhotos.length; i++) {
          final photo = result.pickedPhotos[i];
          final bytes = await photo.readAsBytes();

          final name = photo.name;
          final dot = name.lastIndexOf('.');
          final extension =
              dot >= 0 && dot < name.length - 1
                  ? name.substring(dot + 1)
                  : 'jpg';

          final url = await _productService.uploadProductGalleryImage(
            productId: savedProduct.id,
            bytes: bytes,
            extension: extension,
            index: savedProduct.gallery.length + i,
          );

          galleryUrls.add(url);
        }

        if (galleryUrls.isNotEmpty) {
          final updatedGallery = [...savedProduct.gallery, ...galleryUrls];

          await _productService.updateProductGallery(
            productId: savedProduct.id,
            galleryImages: updatedGallery,
          );

          savedProduct =
              await _productService.getProduct(savedProduct.id) ?? savedProduct;
        }
      }

      if (!mounted) {
        return;
      }

      final index = _products.indexWhere((item) => item.id == savedProduct.id);

      setState(() {
        if (index >= 0) {
          _products[index] = savedProduct;
        }

        _metas[savedProduct.id] =
            result.meta ?? _metas[savedProduct.id] ?? AdminProductMeta.blank();

        _loading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Изменения сохранены')));
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      _showSaveError('Не удалось сохранить изменения', error);
    }
  }

  void _showSaveError(String title, Object error) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(error.toString())),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProducts,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _header(context)),
              SliverToBoxAdapter(child: _topSummary()),
              SliverToBoxAdapter(child: _search()),
              SliverToBoxAdapter(child: _categoryChips()),

              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SliverFillRemaining(hasScrollBody: false, child: _errorState())
              else if (_filtered.isEmpty)
                SliverFillRemaining(hasScrollBody: false, child: _emptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  sliver: SliverList.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final product = _filtered[index];

                      return _ProductRow(
                        product: product,
                        onToggleStock: (value) => _toggleStock(product, value),
                        onMore: () => _showMoreSheet(context, product),
                        onTap: () => _openEdit(product),
                      );
                    },
                  ),
                ),

              if (!_loading && _error == null)
                SliverToBoxAdapter(child: _footer(_filtered.length)),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(
                Icons.chevron_left,
                color: AppColors.primaryBrown,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Товары', style: AppTextStyles.screenTitle),
                const SizedBox(height: 2),
                Text(
                  '${_products.length} позиций в каталоге',
                  style: AppTextStyles.rowLabelMuted,
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: _openAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryBrown,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 17, color: Colors.white),
                  SizedBox(width: 5),
                  Text(
                    'Добавить',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SUMMARY
  // ---------------------------------------------------------------------------

  Widget _topSummary() {
    final available = _products.where((product) => product.inStock).length;

    final unavailable = _products.length - available;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              title: 'В наличии',
              value: available.toString(),
              icon: Icons.check_circle_outline,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryCard(
              title: 'Нет в наличии',
              value: unavailable.toString(),
              icon: Icons.remove_circle_outline,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryCard(
              title: 'Всего',
              value: _products.length.toString(),
              icon: Icons.inventory_2_outlined,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SEARCH
  // ---------------------------------------------------------------------------

  Widget _search() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Поиск по товарам',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  onPressed: () => _searchController.clear(),
                  icon: const Icon(Icons.close_rounded),
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: const BorderSide(
              color: AppColors.primaryBrown,
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CATEGORIES
  // ---------------------------------------------------------------------------

  Widget _categoryChips() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        scrollDirection: Axis.horizontal,
        itemCount: ProductCategory.values.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final category = index == 0
              ? null
              : ProductCategory.values[index - 1];

          final label = index == 0
              ? 'Все'
              : ProductCategory.values[index - 1].label;

          final selected = _category == category;

          return ChoiceChip(
            label: Text('$label ${_countFor(category)}'),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _category = category;
              });
            },
            selectedColor: AppColors.primaryBrown,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.primaryBrown,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
            side: const BorderSide(color: AppColors.divider),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STATES
  // ---------------------------------------------------------------------------

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 46,
              color: AppColors.primaryBrown,
            ),
            const SizedBox(height: 14),
            const Text(
              'Не удалось загрузить товары',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
            const SizedBox(height: 8),
            Text(
              'Проверьте соединение с базой данных.',
              textAlign: TextAlign.center,
              style: AppTextStyles.rowLabelMuted,
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _loadProducts,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 44,
              color: AppColors.primaryBrown,
            ),
            const SizedBox(height: 12),
            const Text(
              'Товары не найдены',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
            const SizedBox(height: 6),
            Text(
              'Измените поисковый запрос или категорию.',
              textAlign: TextAlign.center,
              style: AppTextStyles.rowLabelMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer(int shown) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Text(
        'Показано товаров: $shown из ${_products.length}',
        style: AppTextStyles.rowLabelMuted,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MORE
  // ---------------------------------------------------------------------------

  void _showMoreSheet(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: AppTextStyles.rowLabel.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 14),
                _sheetAction(
                  context,
                  Icons.edit_outlined,
                  'Редактировать товар',
                  () {
                    Navigator.of(context).pop();

                    _openEdit(product);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetAction(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 19, color: AppColors.primaryBrown),
            const SizedBox(width: 14),
            Text(label, style: AppTextStyles.rowLabel),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SUMMARY CARD
// =============================================================================

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: AppColors.primaryBrown),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.rowLabelMuted.copyWith(fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// PRODUCT ROW
// =============================================================================

class _ProductRow extends StatelessWidget {
  final Product product;

  final ValueChanged<bool> onToggleStock;

  final VoidCallback onMore;
  final VoidCallback onTap;

  const _ProductRow({
    required this.product,
    required this.onToggleStock,
    required this.onMore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            _ProductImage(imageUrl: product.imageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${product.price} ₽',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.primaryBrown,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    product.inStock ? 'В наличии' : 'Нет в наличии',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: product.inStock
                          ? Colors.green.shade700
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch.adaptive(
                  value: product.inStock,
                  onChanged: onToggleStock,
                ),
                IconButton(
                  onPressed: onMore,
                  icon: const Icon(Icons.more_vert, size: 21),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// PRODUCT IMAGE
// =============================================================================

class _ProductImage extends StatelessWidget {
  final String imageUrl;

  const _ProductImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final isNetwork =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: SizedBox(
        width: 64,
        height: 64,
        child: imageUrl.isEmpty
            ? _placeholder()
            : isNetwork
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _placeholder(),
              )
            : Image.asset(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _placeholder(),
              ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceMuted,
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.primaryBrown,
        size: 27,
      ),
    );
  }
}
