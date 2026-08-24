import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/mock_products.dart';
import '../../../models/product.dart';
import '../../../theme/app_theme.dart';
import '../models/promotion.dart';

class AdminPromotionEditScreen extends StatefulWidget {
  final Promotion? promotion;
  const AdminPromotionEditScreen({super.key, this.promotion});

  @override
  State<AdminPromotionEditScreen> createState() => _AdminPromotionEditScreenState();
}

class _AdminPromotionEditScreenState extends State<AdminPromotionEditScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _discount = TextEditingController();
  final _offerPrice = TextEditingController();
  final _picker = ImagePicker();
  final Set<String> _selectedIds = {};
  final Map<String, int> _specialPrices = {};

  PromotionType _type = PromotionType.collection;
  String? _bannerAsset;
  Uint8List? _bannerBytes;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final p = widget.promotion;
    if (p == null) return;
    _title.text = p.title;
    _description.text = p.description;
    _discount.text = p.discountPercent?.toString() ?? '';
    _offerPrice.text = p.offerPrice?.toString() ?? '';
    _type = p.type;
    _bannerAsset = p.bannerAsset;
    if (p.bannerBytes != null) _bannerBytes = Uint8List.fromList(p.bannerBytes!);
    _selectedIds.addAll(p.products.map((e) => e.productId));
    for (final item in p.products) {
      if (item.specialPrice != null) _specialPrices[item.productId] = item.specialPrice!;
    }
    _startDate = p.startDate;
    _endDate = p.endDate;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _discount.dispose();
    _offerPrice.dispose();
    super.dispose();
  }

  Future<void> _pickBanner() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 82, maxWidth: 1600);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() { _bannerBytes = bytes; _bannerAsset = null; });
  }

  Future<void> _selectProducts() async {
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) {
        final selected = Set<String>.from(_selectedIds);
        return StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
          title: const Text('Выберите товары'),
          content: SizedBox(
            width: 520,
            height: 430,
            child: ListView.separated(
              itemCount: mockProducts.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final product = mockProducts[index];
                return CheckboxListTile(
                  value: selected.contains(product.id),
                  onChanged: (value) => setDialogState(() => value == true ? selected.add(product.id) : selected.remove(product.id)),
                  secondary: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.asset(product.imageUrl, width: 48, height: 48, fit: BoxFit.cover)),
                  title: Text(product.name),
                  subtitle: Text('${product.price} ₽ · ${product.category.label}'),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            FilledButton(onPressed: () => Navigator.pop(context, selected), child: const Text('Добавить выбранные')),
          ],
        ));
      },
    );
    if (result == null) return;
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(result);
      _specialPrices.removeWhere((id, _) => !_selectedIds.contains(id));
    });
  }

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final current = start ? _startDate : _endDate;
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year),
      lastDate: DateTime(2035),
      initialDate: current ?? now,
    );
    if (selected == null) return;
    setState(() { if (start) _startDate = selected; else _endDate = selected; });
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) return _message('Введите название предложения');
    if (_selectedIds.isEmpty) return _message('Добавьте хотя бы один товар');
    if (_bannerBytes == null && _bannerAsset == null) return _message('Загрузите баннер');
    if (_startDate != null && _endDate != null && _endDate!.isBefore(_startDate!)) return _message('Дата окончания не может быть раньше даты начала');

    final discount = int.tryParse(_discount.text.trim());
    if (_type == PromotionType.discount && (discount == null || discount < 1 || discount > 99)) return _message('Скидка должна быть от 1 до 99%');
    final offerPrice = int.tryParse(_offerPrice.text.trim());
    if (_type == PromotionType.bundle && (offerPrice == null || offerPrice <= 0)) return _message('Укажите цену набора');
    if (_type == PromotionType.specialPrice) {
      for (final id in _selectedIds) {
        final price = _specialPrices[id];
        if (price == null || price <= 0) return _message('Укажите специальную цену для каждого товара');
      }
    }

    final old = widget.promotion;
    final promotion = Promotion(
      id: old?.id ?? 'promo-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      description: _description.text.trim(),
      bannerAsset: _bannerAsset,
      bannerBytes: _bannerBytes?.toList(),
      type: _type,
      discountPercent: _type == PromotionType.discount ? discount : null,
      offerPrice: _type == PromotionType.bundle ? offerPrice : null,
      products: _selectedIds.map((id) => PromotionProduct(productId: id, specialPrice: _type == PromotionType.specialPrice ? _specialPrices[id] : null)).toList(),
      isAvailable: old?.isAvailable ?? false,
      startDate: _startDate,
      endDate: _endDate,
      sortOrder: old?.sortOrder ?? 0,
      createdAt: old?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    Navigator.of(context).pop(promotion);
  }

  void _message(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final editing = widget.promotion != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20)),
        title: Text(editing ? 'Редактирование предложения' : 'Акция / спецпредложение', style: AppTextStyles.screenTitleSmall.copyWith(fontSize: 22)),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: Color(0xFFB8ADA0))),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 34),
          children: [
            _label('Название'),
            _UnderlineField(controller: _title, hintText: 'Например, Скоро в школу', textStyle: const TextStyle(fontSize: 20, height: 1.25)),
            const SizedBox(height: 18),
            _label('Описание'),
            _UnderlineField(controller: _description, hintText: 'Короткое описание для клиента', maxLines: 2, textStyle: const TextStyle(fontSize: 18, height: 1.3)),
            const SizedBox(height: 18),
            _BannerPicker(asset: _bannerAsset, bytes: _bannerBytes, onPick: _pickBanner),
            const SizedBox(height: 24),
            _section('Тип предложения'),
            const SizedBox(height: 10),
            _PromotionTypeSelector(value: _type, onChanged: (value) => setState(() => _type = value)),
            const SizedBox(height: 14),
            AnimatedSwitcher(duration: const Duration(milliseconds: 160), child: _typeSpecificField()),
            const SizedBox(height: 24),
            _section('Период показа'),
            const SizedBox(height: 10),
            Row(children: [Expanded(child: _DateField(label: 'Начало', date: _startDate, onTap: () => _pickDate(start: true))), const SizedBox(width: 12), Expanded(child: _DateField(label: 'Окончание', date: _endDate, onTap: () => _pickDate(start: false)))]),
            const SizedBox(height: 24),
            Row(children: [Expanded(child: _section('Товары предложения')), TextButton.icon(onPressed: _selectProducts, icon: const Icon(Icons.add_rounded, size: 22), label: const Text('Добавить'), style: TextButton.styleFrom(foregroundColor: AppColors.primaryBrown, padding: const EdgeInsets.symmetric(horizontal: 4), textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)))]),
            const SizedBox(height: 8),
            if (_selectedIds.isEmpty) _emptyProducts() else ..._selectedIds.map(_productRow),
            const SizedBox(height: 22),
            SizedBox(height: 52, child: FilledButton(onPressed: _save, style: FilledButton.styleFrom(backgroundColor: AppColors.primaryBrown, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))), child: const Text('Записать', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
          ],
        ),
      ),
    );
  }

  Widget _typeSpecificField() {
    switch (_type) {
      case PromotionType.collection: return const SizedBox.shrink(key: ValueKey('collection'));
      case PromotionType.discount: return _CompactInput(key: const ValueKey('discount'), controller: _discount, label: 'Скидка', suffix: '%', keyboardType: TextInputType.number);
      case PromotionType.specialPrice: return const _InfoBox(key: ValueKey('special'), text: 'Спеццена задаётся отдельно для каждого выбранного товара ниже.');
      case PromotionType.bundle: return _CompactInput(key: const ValueKey('bundle'), controller: _offerPrice, label: 'Цена набора', suffix: '₽', keyboardType: TextInputType.number);
    }
  }

  Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 3), child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textSecondary)));
  Widget _section(String text) => Text(text, style: AppTextStyles.screenTitleSmall.copyWith(fontSize: 21));

  Widget _emptyProducts() => Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.divider)), child: const Column(children: [Icon(Icons.inventory_2_outlined, size: 30, color: AppColors.textSecondary), SizedBox(height: 7), Text('Товары ещё не выбраны', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)), SizedBox(height: 3), Text('Добавьте товары, которые должны попасть в предложение.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 12))]));

  Widget _productRow(String id) {
    final product = mockProducts.firstWhere((p) => p.id == id);
    final special = _specialPrices[id];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.divider)),
      child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(product.imageUrl, width: 72, height: 72, fit: BoxFit.cover)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, height: 1.15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          if (_type == PromotionType.specialPrice) _specialPriceEditor(product, special)
          else if (_type == PromotionType.discount) Text('${product.price} ₽ → ${_discountedPrice(product)} ₽', style: const TextStyle(color: AppColors.primaryBrown, fontSize: 14, fontWeight: FontWeight.w600))
          else if (_type == PromotionType.bundle) Text('${product.price} ₽ · в наборе', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14))
          else Text('${product.price} ₽', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ])),
        IconButton(onPressed: () => setState(() { _selectedIds.remove(id); _specialPrices.remove(id); }), icon: const Icon(Icons.delete_outline_rounded, size: 23), color: AppColors.textSecondary),
      ]),
    );
  }

  Widget _specialPriceEditor(Product product, int? special) => Row(children: [
    Text('${product.price} ₽', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, decoration: TextDecoration.lineThrough)),
    const SizedBox(width: 8),
    SizedBox(width: 105, height: 38, child: TextFormField(initialValue: special?.toString() ?? '', keyboardType: TextInputType.number, decoration: InputDecoration(suffixText: '₽', hintText: 'Цена', contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), filled: true, fillColor: AppColors.surfaceMuted, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), onChanged: (value) { final price = int.tryParse(value); if (price != null && price > 0) _specialPrices[product.id] = price; else _specialPrices.remove(product.id); setState(() {}); })),
  ]);

  int _discountedPrice(Product product) => (product.price * (100 - (int.tryParse(_discount.text) ?? 0)) / 100).round();
}

class _UnderlineField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final TextStyle textStyle;
  const _UnderlineField({required this.controller, required this.hintText, this.maxLines = 1, required this.textStyle});
  @override
  Widget build(BuildContext context) => TextField(controller: controller, maxLines: maxLines, style: textStyle, decoration: InputDecoration(hintText: hintText, hintStyle: textStyle.copyWith(color: AppColors.textSecondary.withValues(alpha: .55)), enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.divider)), focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryBrown, width: 1.5)), contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0)));
}

class _BannerPicker extends StatelessWidget {
  final String? asset;
  final Uint8List? bytes;
  final VoidCallback onPick;
  const _BannerPicker({this.asset, this.bytes, required this.onPick});
  @override
  Widget build(BuildContext context) {
    final image = bytes != null ? Image.memory(bytes!, fit: BoxFit.cover) : asset != null ? Image.asset(asset!, fit: BoxFit.cover) : null;
    return GestureDetector(onTap: onPick, child: Container(height: 150, decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.divider)), clipBehavior: Clip.antiAlias, child: image ?? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate_outlined, size: 34, color: AppColors.primaryBrown), SizedBox(height: 8), Text('Добавить баннер', style: TextStyle(fontWeight: FontWeight.w700)), SizedBox(height: 3), Text('Широкое изображение для карточки предложения', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))])));
  }
}

class _PromotionTypeSelector extends StatelessWidget {
  final PromotionType value;
  final ValueChanged<PromotionType> onChanged;
  const _PromotionTypeSelector({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: PromotionType.values.map((type) => ChoiceChip(label: Text(type.label), selected: value == type, onSelected: (_) => onChanged(type), selectedColor: AppColors.surfaceMuted, labelStyle: TextStyle(fontWeight: value == type ? FontWeight.w700 : FontWeight.w500, color: value == type ? AppColors.primaryBrown : AppColors.textSecondary))).toList());
}

class _CompactInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final TextInputType keyboardType;
  const _CompactInput({super.key, required this.controller, required this.label, required this.suffix, required this.keyboardType});
  @override
  Widget build(BuildContext context) => SizedBox(width: 220, child: TextField(controller: controller, keyboardType: keyboardType, decoration: InputDecoration(labelText: label, suffixText: suffix, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.divider)))));
}

class _InfoBox extends StatelessWidget {
  final String text;
  const _InfoBox({super.key, required this.text});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(14)), child: Row(children: [const Icon(Icons.info_outline, color: AppColors.primaryBrown), const SizedBox(width: 10), Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)))]));
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  const _DateField({required this.label, required this.date, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final value = date == null ? 'Не задано' : '${date!.day.toString().padLeft(2, '0')}.${date!.month.toString().padLeft(2, '0')}.${date!.year}';
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)), child: Row(children: [const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primaryBrown), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)), const SizedBox(height: 3), Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))]))])));
  }
}
