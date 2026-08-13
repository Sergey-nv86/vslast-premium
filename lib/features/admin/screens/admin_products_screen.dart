import 'package:flutter/material.dart';
import '../../../data/mock_products.dart';
import '../../../models/product.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/toast.dart';

/// Экран «Товары» админ-панели. Пока временно открывается тапом по значку
/// в правом верхнем углу Dashboard (см. admin_dashboard_screen.dart) — до
/// появления отдельной вкладки в нижней навигации.
///
/// Переиспользует существующую модель Product и mockProducts (те же
/// данные, что видит клиент в «Каталоге»), а не заводит отдельную
/// admin-модель — так список товаров не может разъехаться с тем, что
/// реально показывается покупателю.
class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  String _query = '';
  ProductCategory? _category; // null = "Все товары"

  /// Переключатель "в наличии" — локальное состояние экрана поверх
  /// mockProducts (который сам по себе неизменяемый источник данных,
  /// общий с клиентским приложением). В реальном приложении это будет
  /// запись в БД/API, а не переопределение на клиенте.
  final Map<String, bool> _stockOverrides = {};

  bool _inStock(Product p) => _stockOverrides[p.id] ?? p.inStock;

  List<Product> get _filtered => mockProducts.where((p) {
    final matchesCategory = _category == null || p.category == _category;
    final q = _query.trim().toLowerCase();
    final matchesQuery = q.isEmpty || p.name.toLowerCase().contains(q);
    return matchesCategory && matchesQuery;
  }).toList();

  int _countFor(ProductCategory? category) => category == null
      ? mockProducts.length
      : mockProducts.where((p) => p.category == category).length;

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header(context)),
            SliverToBoxAdapter(child: _search()),
            SliverToBoxAdapter(child: _categoryChips()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final product = items[i];
                  return _ProductRow(
                    product: product,
                    inStock: _inStock(product),
                    onToggleStock: (value) => setState(() => _stockOverrides[product.id] = value),
                    onMore: () => _showMoreSheet(context, product),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(child: _footer(items.length)),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(Icons.chevron_left, color: AppColors.primaryBrown),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text('Товары', style: AppTextStyles.screenTitle)),
        GestureDetector(
          onTap: () => FadeToast.show(context, 'Добавление товара — скоро', icon: Icons.add),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, size: 17, color: AppColors.primaryBrown),
                const SizedBox(width: 5),
                Text('Добавить', style: AppTextStyles.rowLabel.copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _search() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
    child: TextField(
      onChanged: (v) => setState(() => _query = v),
      decoration: InputDecoration(
        hintText: 'Поиск товаров',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
      ),
    ),
  );

  Widget _categoryChips() => SizedBox(
    height: 44,
    child: ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      scrollDirection: Axis.horizontal,
      itemCount: ProductCategory.values.length + 1,
      separatorBuilder: (context, index) => const SizedBox(width: 8),
      itemBuilder: (context, i) {
        final category = i == 0 ? null : ProductCategory.values[i - 1];
        final label = i == 0 ? 'Все товары' : ProductCategory.values[i - 1].label;
        final selected = _category == category;
        return ChoiceChip(
          label: Text('$label ${_countFor(category)}'),
          selected: selected,
          onSelected: (_) => setState(() => _category = category),
          selectedColor: AppColors.primaryBrown,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppColors.primaryBrown,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          side: const BorderSide(color: AppColors.divider),
        );
      },
    ),
  );

  Widget _footer(int shown) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
    child: Text(
      'Показано товаров: $shown из ${mockProducts.length}',
      style: AppTextStyles.rowLabelMuted,
    ),
  );

  void _showMoreSheet(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.name, style: AppTextStyles.rowLabel.copyWith(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 16),
              _sheetAction(context, Icons.edit_outlined, 'Редактировать товар'),
              _sheetAction(context, Icons.attach_money_outlined, 'Изменить цену'),
              _sheetAction(context, Icons.category_outlined, 'Изменить категорию'),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetAction(BuildContext context, IconData icon, String label) => InkWell(
    onTap: () {
      Navigator.of(context).pop();
      FadeToast.show(context, '$label — скоро', icon: icon);
    },
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

class _ProductRow extends StatelessWidget {
  final Product product;
  final bool inStock;
  final ValueChanged<bool> onToggleStock;
  final VoidCallback onMore;

  const _ProductRow({
    required this.product,
    required this.inStock,
    required this.onToggleStock,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.divider),
    ),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            product.imageUrl,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 56,
              height: 56,
              color: AppColors.surfaceMuted,
              alignment: Alignment.center,
              child: const Icon(Icons.bakery_dining_outlined, color: AppColors.primaryBrown),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.rowLabel.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 3),
              Text(
                '${product.category.label} · ${product.weightLabel}',
                style: AppTextStyles.rowLabelMuted.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                '${product.price} ₽',
                style: AppTextStyles.rowLabel.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Switch(
          value: inStock,
          onChanged: onToggleStock,
          activeTrackColor: AppColors.primaryBrown,
        ),
        IconButton(
          onPressed: onMore,
          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    ),
  );
}
