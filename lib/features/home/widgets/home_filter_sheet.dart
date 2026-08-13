import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/product.dart';
import '../../../theme/app_theme.dart';
import '../models/home_filter_state.dart';

/// Модальное окно "Фильтр" на Главной — выбор категорий и дополнительных
/// параметров (Хит/Новинка/Акция — те же бейджи, что уже есть у товаров).
/// В отличие от чипов категорий над витриной (которые просто прокручивают
/// список к нужному разделу, ничего не скрывая), этот фильтр РЕАЛЬНО
/// сужает список показанных товаров.
///
/// Возвращает новый [HomeFilterState] по кнопке "Показать" или null, если
/// закрыли без применения (свайп/тап мимо) — в этом случае вызывающий код
/// не должен менять текущий фильтр.
Future<HomeFilterState?> showHomeFilterSheet(
  BuildContext context, {
  required HomeFilterState current,
}) {
  return showModalBottomSheet<HomeFilterState>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _HomeFilterSheet(initial: current),
  );
}

class _HomeFilterSheet extends StatefulWidget {
  final HomeFilterState initial;
  const _HomeFilterSheet({required this.initial});

  @override
  State<_HomeFilterSheet> createState() => _HomeFilterSheetState();
}

class _HomeFilterSheetState extends State<_HomeFilterSheet> {
  late Set<ProductCategory> _categories = Set.of(widget.initial.categories);
  late Set<ProductBadge> _badges = Set.of(widget.initial.badges);

  void _toggleCategory(ProductCategory c) {
    setState(() {
      if (_categories.contains(c)) {
        _categories.remove(c);
      } else {
        _categories.add(c);
      }
    });
  }

  void _toggleBadge(ProductBadge b) {
    setState(() {
      if (_badges.contains(b)) {
        _badges.remove(b);
      } else {
        _badges.add(b);
      }
    });
  }

  void _reset() => setState(() {
    _categories = {};
    _badges = {};
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Фильтр',
                  style: GoogleFonts.alice(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (_categories.isNotEmpty || _badges.isNotEmpty)
                  TextButton(
                    onPressed: _reset,
                    child: const Text('Сбросить', style: TextStyle(color: AppColors.linkAccent)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Категории', style: AppTextStyles.rowLabel.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ProductCategory.values
                  .map((c) => _FilterChip(
                        label: c.label,
                        selected: _categories.contains(c),
                        onTap: () => _toggleCategory(c),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            Text('Особые отметки', style: AppTextStyles.rowLabel.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ProductBadge.values
                  .map((b) => _FilterChip(
                        label: b.label,
                        selected: _badges.contains(b),
                        onTap: () => _toggleBadge(b),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(
                  HomeFilterState(categories: _categories, badges: _badges),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Показать'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBrown : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primaryBrown : AppColors.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
