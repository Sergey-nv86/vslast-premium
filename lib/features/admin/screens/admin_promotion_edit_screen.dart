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
  final _picker = ImagePicker();
  PromotionPricingType _pricingType = PromotionPricingType.discountPercent;
  String? _bannerAsset;
  Uint8List? _bannerBytes;
  final Map<String, int> _specialPrices = {};
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    final p = widget.promotion;
    if (p != null) {
      _title.text = p.title;
      _description.text = p.description;
      _discount.text = p.discountPercent?.toString() ?? '';
      _pricingType = p.pricingType;
      _bannerAsset = p.bannerAsset;
      if (p.bannerBytes != null) _bannerBytes = Uint8List.fromList(p.bannerBytes!);
      _selectedIds.addAll(p.products.map((item) => item.productId));
      for (final item in p.products) {
        if (item.specialPrice != null) _specialPrices[item.productId] = item.specialPrice!;
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _discount.dispose();
    super.dispose();
  }

  Future<void> _pickBanner() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 82, maxWidth: 1600);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _bannerBytes = bytes;
      _bannerAsset = null;
    });
  }

  Future<void> _selectProducts() async {
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) {
        final selected = Set<String>.from(_selectedIds);
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
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
                    onChanged: (value) => setDialogState(() {
                      if (value == true) {
                        selected.add(product.id);
                      } else {
                        selected.remove(product.id);
                      }
                    }),
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
          );
        });
      },
    );
    if (result != null) setState(() {
      _selectedIds
        ..clear()
        ..addAll(result);
    });
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) return _message('Введите название предложения');
    if (_selectedIds.isEmpty) return _message('Добавьте хотя бы один товар');
    if (_bannerBytes == null && _bannerAsset == null) return _message('Загрузите баннер');

    final discount = int.tryParse(_discount.text.trim());
    if (_pricingType == PromotionPricingType.discountPercent && (discount == null || discount < 1 || discount > 99)) {
      return _message('Скидка должна быть от 1 до 99%');
    }
    if (_pricingType == PromotionPricingType.specialPrice) {
      for (final id in _selectedIds) {
        final price = _specialPrices[id];
        if (price == null || price <= 0) return _message('Укажите специальную цену для каждого товара');
      }
    }

    final products = _selectedIds.map((id) => PromotionProduct(productId: id, specialPrice: _pricingType == PromotionPricingType.specialPrice ? _specialPrices[id] : null)).toList();
    final old = widget.promotion;
    final promotion = Promotion(
      id: old?.id ?? 'promo-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      description: _description.text.trim(),
      bannerAsset: _bannerAsset,
      bannerBytes: _bannerBytes?.toList(),
      pricingType: _pricingType,
      discountPercent: _pricingType == PromotionPricingType.discountPercent ? discount : null,
      products: products,
      isAvailable: old?.isAvailable ?? false,
      createdAt: old?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    Navigator.of(context).pop(promotion);
  }

  void _message(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(widget.promotion == null ? 'Акция / спецпредложение' : 'Редактирование предложения'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _sectionTitle('Баннер'),
          const SizedBox(height: 10),
          _BannerPicker(asset: _bannerAsset, bytes: _bannerBytes, onPick: _pickBanner),
          const SizedBox(height: 22),
          _sectionTitle('Основная информация'),
          const SizedBox(height: 10),
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Название предложения', hintText: 'Например, Скоро в школу')),
          const SizedBox(height: 12),
          TextField(controller: _description, maxLines: 3, decoration: const InputDecoration(labelText: 'Описание', hintText: 'Короткое описание для клиента')),
          const SizedBox(height: 22),
          _sectionTitle('Условия предложения'),
          const SizedBox(height: 10),
          SegmentedButton<PromotionPricingType>(
            segments: const [
              ButtonSegment(value: PromotionPricingType.discountPercent, label: Text('Скидка %')),
              ButtonSegment(value: PromotionPricingType.specialPrice, label: Text('Спеццена')),
            ],
            selected: {_pricingType},
            onSelectionChanged: (value) => setState(() => _pricingType = value.first),
          ),
          const SizedBox(height: 12),
          if (_pricingType == PromotionPricingType.discountPercent)
            TextField(controller: _discount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Скидка', suffixText: '%')),
          const SizedBox(height: 22),
          Row(children: [
            Expanded(child: _sectionTitle('Товары по акции')),
            TextButton.icon(onPressed: _selectProducts, icon: const Icon(Icons.add), label: const Text('Добавить товары')),
          ]),
          const SizedBox(height: 8),
          if (_selectedIds.isEmpty)
            _emptyProducts()
          else
            ..._selectedIds.map(_productRow),
          const SizedBox(height: 28),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Записать', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryBrown, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text, style: AppTextStyles.screenTitle.copyWith(fontSize: 19));

  Widget _emptyProducts() => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
        child: const Column(children: [Icon(Icons.inventory_2_outlined, size: 32, color: AppColors.primaryBrown), SizedBox(height: 8), Text('Товары ещё не выбраны'), Text('Добавьте товары, которые должны попасть в предложение.')]),
      );

  Widget _productRow(String id) {
    final product = mockProducts.firstWhere((p) => p.id == id);
    final special = _specialPrices[id];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
      child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset(product.imageUrl, width: 58, height: 58, fit: BoxFit.cover)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          if (_pricingType == PromotionPricingType.specialPrice)
            Row(children: [Text('${product.price} ₽', style: const TextStyle(decoration: TextDecoration.lineThrough, color: AppColors.textSecondary)), const SizedBox(width: 8), SizedBox(width: 105, child: TextField(controller: TextEditingController(text: special?.toString() ?? ''), keyboardType: TextInputType.number, onChanged: (value) => _specialPrices[id] = int.tryParse(value) ?? 0, decoration: const InputDecoration(isDense: true, labelText: 'Цена')))])
          else
            Text('${product.price} ₽ → ${_discountedPrice(product)} ₽', style: const TextStyle(color: AppColors.primaryBrown, fontWeight: FontWeight.w600)),
        ])),
        IconButton(onPressed: () => setState(() { _selectedIds.remove(id); _specialPrices.remove(id); }), icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary)),
      ]),
    );
  }

  int _discountedPrice(Product product) {
    final discount = int.tryParse(_discount.text) ?? 0;
    return (product.price * (100 - discount) / 100).round();
  }
}

class _BannerPicker extends StatelessWidget {
  final String? asset;
  final Uint8List? bytes;
  final VoidCallback onPick;
  const _BannerPicker({this.asset, this.bytes, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final Widget image = bytes != null
        ? Image.memory(bytes!, fit: BoxFit.cover, width: double.infinity, height: 190)
        : asset != null
            ? Image.asset(asset!, fit: BoxFit.cover, width: double.infinity, height: 190)
            : Container(height: 190, color: AppColors.surfaceMuted, child: const Icon(Icons.add_photo_alternate_outlined, size: 42, color: AppColors.primaryBrown));
    return Column(children: [
      ClipRRect(borderRadius: BorderRadius.circular(18), child: image),
      const SizedBox(height: 8),
      OutlinedButton.icon(onPressed: onPick, icon: const Icon(Icons.photo_library_outlined), label: Text(asset == null && bytes == null ? 'Добавить баннер' : 'Изменить баннер')),
    ]);
  }
}
