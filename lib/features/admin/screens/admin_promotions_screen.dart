import 'dart:typed_data';

import 'package:flutter/material.dart';

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
  final PromotionStore store = PromotionStore.instance;
  String query = '';

  List<Promotion> get items {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return store.items;
    return store.items.where((p) => p.title.toLowerCase().contains(q)).toList();
  }

  Future<void> _add() async {
    final promotion = await Navigator.push<Promotion>(
      context,
      MaterialPageRoute(builder: (_) => const AdminPromotionEditScreen()),
    );
    if (!mounted || promotion == null) return;
    setState(() => store.add(promotion));
  }

  Future<void> _edit(Promotion promotion) async {
    final result = await Navigator.push<Promotion>(
      context,
      MaterialPageRoute(builder: (_) => AdminPromotionEditScreen(promotion: promotion)),
    );
    if (!mounted || result == null) return;
    setState(() => store.update(result));
  }

  void _remove(Promotion promotion) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить предложение?'),
        content: Text('«${promotion.title}» будет удалено.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              store.remove(promotion.id);
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
    store.add(
      Promotion(
        id: 'promo-${DateTime.now().microsecondsSinceEpoch}',
        title: '${promotion.title} — копия',
        description: promotion.description,
        bannerAsset: promotion.bannerAsset,
        bannerBytes: promotion.bannerBytes,
        type: promotion.type,
        discountPercent: promotion.discountPercent,
        offerPrice: promotion.offerPrice,
        products: promotion.products,
        isAvailable: false,
        startDate: promotion.startDate,
        endDate: promotion.endDate,
        sortOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    setState(() {});
  }

  void _showMore(Promotion promotion) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(promotion.title, style: const TextStyle(fontWeight: FontWeight.w700))),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Редактировать'),
              onTap: () {
                Navigator.pop(context);
                _edit(promotion);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Дублировать'),
              onTap: () {
                Navigator.pop(context);
                _duplicate(promotion);
              },
            ),
            ListTile(
              leading: Icon(promotion.isAvailable ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              title: Text(promotion.isAvailable ? 'Сделать недоступным' : 'Сделать доступным'),
              onTap: () {
                store.setAvailability(promotion.id, !promotion.isAvailable);
                Navigator.pop(context);
                setState(() {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Удалить'),
              onTap: () {
                Navigator.pop(context);
                _remove(promotion);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.maybePop(context),
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
                    Expanded(child: Text('Акции и спецпредложения', style: AppTextStyles.screenTitle)),
                    GestureDetector(
                      onTap: _add,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(14)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 17, color: AppColors.primaryBrown),
                            SizedBox(width: 5),
                            Text('Добавить', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primaryBrown)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: TextField(
                  onChanged: (value) => setState(() => query = value),
                  decoration: InputDecoration(
                    hintText: 'Поиск акций и спецпредложений',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: AppColors.divider)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: AppColors.divider)),
                  ),
                ),
              ),
            ),
            if (items.isEmpty)
              const SliverFillRemaining(hasScrollBody: false, child: Center(child: Text('Предложения не найдены')))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                sliver: SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final promotion = items[index];
                    return _PromotionRow(
                      promotion: promotion,
                      toggle: (value) {
                        store.setAvailability(promotion.id, value);
                        setState(() {});
                      },
                      onTap: () => _edit(promotion),
                      onMore: () => _showMore(promotion),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PromotionRow extends StatelessWidget {
  final Promotion promotion;
  final ValueChanged<bool> toggle;
  final VoidCallback onTap;
  final VoidCallback onMore;

  const _PromotionRow({required this.promotion, required this.toggle, required this.onTap, required this.onMore});

  String _typeText() {
    switch (promotion.type) {
      case PromotionType.collection:
        return 'Подборка';
      case PromotionType.discount:
        return 'Скидка −${promotion.discountPercent ?? 0}%';
      case PromotionType.specialPrice:
        return 'Спеццена';
      case PromotionType.bundle:
        return 'Набор · ${promotion.offerPrice ?? 0} ₽';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget image;
    if (promotion.bannerBytes != null) {
      image = Image.memory(Uint8List.fromList(promotion.bannerBytes!), width: 94, height: 70, fit: BoxFit.cover);
    } else if (promotion.bannerAsset != null) {
      image = Image.asset(promotion.bannerAsset!, width: 94, height: 70, fit: BoxFit.cover);
    } else {
      image = Container(width: 94, height: 70, color: AppColors.surfaceMuted, child: const Icon(Icons.image_outlined, color: AppColors.primaryBrown));
    }

    final count = promotion.products.length;
    final word = count % 10 == 1 && count % 100 != 11
        ? 'товар'
        : ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100) ? 'товара' : 'товаров');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.divider)),
        child: Row(
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(12), child: image),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(promotion.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('$count $word · ${_typeText()}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 5),
                  Text(promotion.isScheduledOut ? 'Вне периода показа' : (promotion.isAvailable ? 'Доступно клиентам' : 'Скрыто от клиентов'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: promotion.isAvailable && !promotion.isScheduledOut ? AppColors.primaryBrown : AppColors.textSecondary)),
                ],
              ),
            ),
            Switch(value: promotion.isAvailable, onChanged: toggle, activeTrackColor: AppColors.primaryBrown),
            IconButton(onPressed: onMore, icon: const Icon(Icons.more_vert, color: AppColors.textSecondary), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
          ],
        ),
      ),
    );
  }
}
