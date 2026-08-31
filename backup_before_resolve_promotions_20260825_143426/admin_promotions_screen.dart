import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../models/promotion.dart';
import '../models/promotion_store.dart';
import '../services/promotion_service.dart';
import 'admin_promotion_edit_screen.dart';

class AdminPromotionsScreen extends StatefulWidget {
  const AdminPromotionsScreen({super.key});

  @override
  State<AdminPromotionsScreen> createState() => _AdminPromotionsScreenState();
}

class _AdminPromotionsScreenState extends State<AdminPromotionsScreen> {
  final PromotionStore store = PromotionStore.instance;
  final PromotionService service = PromotionService.instance;

  String query = '';
  bool _loading = true;
  String? _error;

  List<Promotion> get items {
    final q = query.trim().toLowerCase();

    final source = store.items;

    if (q.isEmpty) return source;

    return source.where((p) => p.title.toLowerCase().contains(q)).toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final promotions = await service.getPromotions();

      store
        ..clear()
        ..addAll(promotions);

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _add() async {
    final promotion = await Navigator.push<Promotion>(
      context,
      MaterialPageRoute(builder: (_) => const AdminPromotionEditScreen()),
    );
    if (!mounted || promotion == null) return;

    try {
      final saved = await service.createPromotion(promotion);

      store.add(saved);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        _showError(e);
      }
    }
  }

  Future<void> _edit(Promotion promotion) async {
    final result = await Navigator.push<Promotion>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminPromotionEditScreen(promotion: promotion),
      ),
    );
    if (!mounted || result == null) return;

    try {
      final saved = await service.updatePromotion(result);

      store.update(saved);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        _showError(e);
      }
    }
  }

  void _remove(Promotion promotion) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить предложение?'),
        content: Text('«${promotion.title}» будет удалено.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);

              () async {
                try {
                  await service.deletePromotion(promotion.id);
                  store.remove(promotion.id);

                  if (mounted) {
                    setState(() {});
                  }
                } catch (e) {
                  if (mounted) {
                    _showError(e);
                  }
                }
              }();
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  Future<void> _duplicate(Promotion promotion) async {
    try {
      final copy = await service.duplicatePromotion(promotion);

      store.add(copy);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        _showError(e);
      }
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Не удалось сохранить акцию: $error')),
      );
  }

  void _showMore(Promotion promotion) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      builder: (_) => SafeArea(
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
                final value = !promotion.isAvailable;
                Navigator.pop(context);

                () async {
                  try {
                    await service.setAvailability(promotion.id, value);

                    store.setAvailability(promotion.id, value);

                    if (mounted) {
                      setState(() {});
                    }
                  } catch (e) {
                    if (mounted) {
                      _showError(e);
                    }
                  }
                }();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
              ),
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
<<<<<<< HEAD
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Не удалось загрузить акции',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _load,
                        child: const Text('Повторить'),
                      ),
                    ],
=======
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
                    Expanded(
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
>>>>>>> origin/feature/client-ui-redesign
                  ),
                ),
              )
            : CustomScrollView(
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
                          Expanded(
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
                        itemBuilder: (_, index) {
                          final promotion = items[index];
                          return _PromotionRow(
                            promotion: promotion,
                            toggle: (value) {
                              () async {
                                try {
                                  await service.setAvailability(
                                    promotion.id,
                                    value,
                                  );

                                  store.setAvailability(promotion.id, value);

                                  if (mounted) {
                                    setState(() {});
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    _showError(e);
                                  }
                                }
                              }();
                            },
                            onTap: () => _edit(promotion),
                            onMore: () => _showMore(promotion),
                          );
                        },
                      ),
                    ),
                ],
              ),
<<<<<<< HEAD
=======
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
>>>>>>> origin/feature/client-ui-redesign
      ),
    );
  }
}

class _PromotionRow extends StatelessWidget {
  final Promotion promotion;
  final ValueChanged<bool> toggle;
  final VoidCallback onTap;
  final VoidCallback onMore;

  const _PromotionRow({
    required this.promotion,
    required this.toggle,
    required this.onTap,
    required this.onMore,
  });

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
      image = Image.memory(
        Uint8List.fromList(promotion.bannerBytes!),
        width: 94,
        height: 70,
        fit: BoxFit.cover,
      );
<<<<<<< HEAD
    } else if (promotion.bannerAsset != null &&
        promotion.bannerAsset!.isNotEmpty) {
      final banner = promotion.bannerAsset!;
      if (banner.startsWith('http://') || banner.startsWith('https://')) {
        image = Image.network(
          banner,
          width: 94,
          height: 70,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            width: 94,
            height: 70,
            color: AppColors.surfaceMuted,
            child: const Icon(
              Icons.image_outlined,
              color: AppColors.primaryBrown,
            ),
          ),
        );
      } else {
        image = Image.asset(
          banner,
          width: 94,
          height: 70,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            width: 94,
            height: 70,
            color: AppColors.surfaceMuted,
            child: const Icon(
              Icons.image_outlined,
              color: AppColors.primaryBrown,
            ),
          ),
        );
      }
=======
    } else if (promotion.bannerAsset != null) {
      image = Image.asset(
        promotion.bannerAsset!,
        width: 94,
        height: 70,
        fit: BoxFit.cover,
      );
>>>>>>> origin/feature/client-ui-redesign
    } else {
      image = Container(
        width: 94,
        height: 70,
        color: AppColors.surfaceMuted,
        child: const Icon(Icons.image_outlined, color: AppColors.primaryBrown),
      );
    }

    final count = promotion.products.length;
    final word = count % 10 == 1 && count % 100 != 11
        ? 'товар'
        : ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)
              ? 'товара'
              : 'товаров');

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
            ClipRRect(borderRadius: BorderRadius.circular(12), child: image),
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
                    '$count $word · ${_typeText()}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    promotion.isScheduledOut
                        ? 'Вне периода показа'
                        : (promotion.isAvailable
                              ? 'Доступно клиентам'
                              : 'Скрыто от клиентов'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: promotion.isAvailable && !promotion.isScheduledOut
                          ? AppColors.primaryBrown
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: promotion.isAvailable,
              onChanged: toggle,
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
      ),
    );
  }
}
