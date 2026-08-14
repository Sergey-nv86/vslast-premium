import 'package:flutter/material.dart';
import '../../../data/mock_products.dart';
import '../../../theme/app_theme.dart';
import '../models/promotion.dart';
import '../models/promotion_store.dart';
import 'admin_promotion_edit_screen.dart';

class AdminPromotionsScreen extends StatefulWidget {
  const AdminPromotionsScreen({super.key});

  @override
  State<AdminPromotionsScreen> createState() => _AdminPromotionsScreenState();
}

class _AdminPromotionsScreenState extends State<AdminPromotionsScreen> {
  final _store = PromotionStore.instance;
  String _query = '';

  List<Promotion> get _items {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _store.items;
    return _store.items.where((p) => p.title.toLowerCase().contains(q)).toList();
  }

  Future<void> _add() async {
    final result = await Navigator.of(context).push<Promotion>(
      MaterialPageRoute(builder: (_) => const AdminPromotionEditScreen()),
    );
    if (result != null) setState(() => _store.add(result));
  }

  Future<void> _edit(Promotion promotion) async {
    final result = await Navigator.of(context).push<Promotion>(
      MaterialPageRoute(builder: (_) => AdminPromotionEditScreen(promotion: promotion)),
    );
    if (result != null) setState(() => _store.update(result));
  }

  void _delete(Promotion promotion) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить предложение?'),
        content: Text('«${promotion.title}» будет удалено из списка.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryBrown),
            onPressed: () {
              _store.remove(promotion.id);
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _duplicate(Promotion promotion) {
    final copy = Promotion(
      id: 'promo-${DateTime.now().microsecondsSinceEpoch}',
      title: '${promotion.title} — копия',
      description: promotion.description,
      bannerAsset: promotion.bannerAsset,
      bannerBytes: promotion.bannerBytes,
      pricingType: promotion.pricingType,
      discountPercent: promotion.discountPercent,
      products: promotion.products,
      isAvailable: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _store.add(copy);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header()),
            SliverToBoxAdapter(child: _search()),
            if (_items.isEmpty)
              const SliverFillRemaining(hasScrollBody: false, child: Center(child: Text('Предложения не найдены')))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                sliver: SliverList.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) => _PromotionRow(
                    promotion: _items[index],
                    productCount: _items[index].products.length,
                    onToggle: (value) {
                      _store.setAvailability(_items[index].id, value);
                      setState(() {});
                    },
                    onTap: () => _edit(_items[index]),
                    onMore: () => _showMore(_items[index]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.divider)),
                child: const Icon(Icons.chevron_left, color: AppColors.primaryBrown),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text('Акции и спецпредложения', style: AppTextStyles.screenTitle)),
            GestureDetector(
              onTap: _add,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(14)),
                child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.add, size: 17, color: AppColors.primaryBrown),
                  SizedBox(width: 5),
                  Text('Добавить', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primaryBrown)),
                ]),
              ),
            ),
          ],
        ),
      );

  Widget _search() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            hintText: 'Поиск акций и спецпредложений',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.divider)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.divider)),
          ),
        ),
      );

  void _showMore(Promotion promotion) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Align(alignment: Alignment.centerLeft, child: Text(promotion.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
            const SizedBox(height: 12),
            ListTile(leading: const Icon(Icons.edit_outlined, color: AppColors.primaryBrown), title: const Text('Редактировать'), onTap: () { Navigator.pop(context); _edit(promotion); }),
            ListTile(leading: const Icon(Icons.copy_outlined, color: AppColors.primaryBrown), title: const Text('Дублировать'), onTap: () { Navigator.pop(context); _duplicate(promotion); }),
            ListTile(leading: Icon(promotion.isAvailable ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.primaryBrown), title: Text(promotion.isAvailable ? 'Сделать недоступным' : 'Сделать доступным'), onTap: () { _store.setAvailability(promotion.id, !promotion.isAvailable); Navigator.pop(context); setState(() {}); }),
            ListTile(leading: const Icon(Icons.delete_outline, color: Colors.redAccent), title: const Text('Удалить'), onTap: () { Navigator.pop(context); _delete(promotion); }),
          ]),
        ),
      ),
    );
  }
}

class _PromotionRow extends StatelessWidget {
  final Promotion promotion;
  final int productCount;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback onMore;

  const _PromotionRow({required this.promotion, required this.productCount, required this.onToggle, required this.onTap, required this.onMore});

  @override
  Widget build(BuildContext context) {
    final banner = promotion.bannerBytes != null
        ? Image.memory(Uint8List.fromList(promotion.bannerBytes!), width: 94, height: 70, fit: BoxFit.cover)
        : promotion.bannerAsset != null
            ? Image.asset(promotion.bannerAsset!, width: 94, height: 70, fit: BoxFit.cover)
            : Container(width: 94, height: 70, color: AppColors.surfaceMuted, child: const Icon(Icons.image_outlined, color: AppColors.primaryBrown));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.divider)),
        child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: banner),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(promotion.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('$productCount ${_productsWord(productCount)} · ${promotion.pricingType == PromotionPricingType.discountPercent ? '−${promotion.discountPercent ?? 0}%' : 'спеццена'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 5),
            Text(promotion.isAvailable ? 'Доступно клиентам' : 'Скрыто от клиентов', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: promotion.isAvailable ? AppColors.primaryBrown : AppColors.textSecondary)),
          ])),
          Switch(value: promotion.isAvailable, onChanged: onToggle, activeTrackColor: AppColors.primaryBrown),
          IconButton(onPressed: onMore, icon: const Icon(Icons.more_vert, color: AppColors.textSecondary), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
        ]),
      ),
    );
  }

  String _productsWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) return 'товар';
    if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) return 'товара';
    return 'товаров';
  }
}
