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
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return store.items;
    }
    return store.items
        .where((promotion) =>
            promotion.title.toLowerCase().contains(normalizedQuery))
        .toList();
  }

  Future<void> _add() async {
    final promotion = await Navigator.push<Promotion>(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminPromotionEditScreen(),
      ),
    );

    if (promotion != null && mounted) {
      setState(() => store.add(promotion));
    }
  }

  Future<void> _edit(Promotion promotion) async {
    final result = await Navigator.push<Promotion>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminPromotionEditScreen(promotion: promotion),
      ),
    );

    if (result != null && mounted) {
      setState(() => store.update(result));
    }
  }

  Future<void> _remove(Promotion promotion) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить предложение?'),
        content: Text('«${promotion.title}» будет удалено.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => store.remove(promotion.id));
    }
  }

  void _duplicate(Promotion promotion) {
    final now = DateTime.now();
    store.add(
      Promotion(
        id: 'promo-${now.microsecondsSinceEpoch}',
        title: '${promotion.title} — копия',
        description: promotion.description,
        bannerAsset: promotion.bannerAsset,
        bannerBytes: promotion.bannerBytes,
        pricingType: promotion.pricingType,
        discountPercent: promotion.discountPercent,
        products: promotion.products,
        isAvailable: false,
        createdAt: now,
        updatedAt: now,
      ),
    );
    setState(() {});
  }

  void _showMore(Promotion promotion) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                promotion.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Редактировать'),
              onTap: () {
                Navigator.pop(sheetContext);
                _edit(promotion);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Дублировать'),
              onTap: () {
                Navigator.pop(sheetContext);
                _duplicate(promotion);
              },
            ),
            ListTile(
              leading: Icon(
                promotion.isAvailable
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              title: Text(
                promotion.isAvailable
                    ? 'Сделать недоступным'
                    : 'Сделать доступным',
              ),
              onTap: () {
                store.setAvailability(promotion.id, !promotion.isAvailable);
                Navigator.pop(sheetContext);
                setState(() {});
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
              ),
              title: const Text('Удалить'),
              onTap: () {
                Navigator.pop(sheetContext);
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
                        child: const Icon(
                          Icons.chevron_left,
                          color: AppColors.primaryBrown,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Акции и спецпредложения',
                        style: AppTextStyles.screenTitle,
                      ),
                    ),
                    GestureDetector(
                      onTap: _add,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add,
                              size: 17,
                              color: AppColors.primaryBrown,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Добавить',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.primaryBrown,
                              ),
                            ),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: AppColors.divider),
                    ),
                  ),
                ),
              ),
            ),
            if (items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('Предложения не найдены')),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                sliver: SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final promotion = items[index];
                    return _PromotionRow(
                      promotion: promotion,
                      onToggle: (value) {
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
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback onMore;

  const _PromotionRow({
    required this.promotion,
    required this.onToggle,
    required this.onTap,
    required this.onMore,
  });

  String _productsLabel(int count) {
    final lastDigit = count % 10;
    final lastTwoDigits = count % 100;
    if (lastDigit == 1 && lastTwoDigits != 11) {
      return 'товар';
    }
    if ([2, 3, 4].contains(lastDigit) &&
        ![12, 13, 14].contains(lastTwoDigits)) {
      return 'товара';
    }
    return 'товаров';
  }

  @override
  Widget build(BuildContext context) {
    final Widget image = promotion.bannerBytes != null
        ? Image.memory(
            Uint8List.fromList(promotion.bannerBytes!),
            width: 94,
            height: 70,
            fit: BoxFit.cover,
          )
        : promotion.bannerAsset != null
            ? Image.asset(
                promotion.bannerAsset!,
                width: 94,
                height: 70,
                fit: BoxFit.cover,
              )
            : Container(
                width: 94,
                height: 70,
                color: AppColors.surfaceMuted,
                child: const Icon(
                  Icons.image_outlined,
                  color: AppColors.primaryBrown,
                ),
              );

    final productCount = promotion.products.length;
    final priceText = promotion.pricingType == PromotionPricingType.discountPercent
        ? '−${promotion.discountPercent ?? 0}%'
        : 'спеццена';

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              child: image,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promotion.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$productCount ${_productsLabel(productCount)} · $priceText',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    promotion.isAvailable
                        ? 'Доступно клиентам'
                        : 'Скрыто от клиентов',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: promotion.isAvailable
                          ? AppColors.primaryBrown
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: promotion.isAvailable,
              onChanged: onToggle,
              activeTrackColor: AppColors.primaryBrown,
            ),
            IconButton(
              onPressed: onMore,
              icon: const Icon(
                Icons.more_vert,
                color: AppColors.textSecondary,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
