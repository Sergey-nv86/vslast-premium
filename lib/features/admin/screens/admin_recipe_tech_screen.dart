import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/recipe_tech_service.dart';

class AdminRecipeTechScreen extends StatefulWidget {
  const AdminRecipeTechScreen({super.key});
  @override
  State<AdminRecipeTechScreen> createState() => _AdminRecipeTechScreenState();
}

class _AdminRecipeTechScreenState extends State<AdminRecipeTechScreen> {
  static const bg = Color(0xFFF8F4EE);
  static const brown = Color(0xFF8B5E3C);
  static const dark = Color(0xFF3B281F);
  static const muted = Color(0xFF806F65);
  final picker = ImagePicker();
  final photos = <XFile>[];
  Map<String, dynamic>? result;
  bool busy = false;
  String? error;

  List<Map<String, dynamic>> get items => ((result?['items'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  Future<void> addPhoto(bool camera) async {
    if (photos.length >= 8) {
      showError('Можно добавить не более 8 фотографий');
      return;
    }
    try {
      if (camera) {
        final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 82, maxWidth: 2200);
        if (file != null && mounted) setState(() => photos.add(file));
      } else {
        final files = await picker.pickMultiImage(imageQuality: 82, maxWidth: 2200);
        if (mounted) {
          final remaining = 8 - photos.length;
          setState(() => photos.addAll(files.take(remaining)));
          if (files.length > remaining) showError('Добавлены первые 8 фотографий');
        }
      }
    } catch (e) { showError('Не удалось добавить фото: ' + e.toString()); }
  }

  Future<void> calculate() async {
    if (photos.isEmpty || busy) return;
    if (photos.length > 8) { showError('Можно добавить не более 8 фотографий'); return; }
    setState(() { busy = true; error = null; result = null; });
    try {
      final images = <Map<String, dynamic>>[];
      for (final file in photos) {
        final lower = file.name.toLowerCase();
        final mime = lower.endsWith('.png') ? 'image/png' : lower.endsWith('.webp') ? 'image/webp' : 'image/jpeg';
        images.add({'mime_type': mime, 'data': base64Encode(await file.readAsBytes())});
      }
      final data = await RecipeTechService.instance.analyze(images);
      if (!mounted) return;
      setState(() => result = data);
      await collectPrices();
      if (mounted) await askNameQuantitySave();
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally { if (mounted) setState(() => busy = false); }
  }

  double? toBase(num q, String unit, String base) {
    final u = unit.toLowerCase().trim();
    if (base == 'g') {
      if (['г','гр','g','грамм','грамма'].contains(u)) return q.toDouble();
      if (['кг','kg'].contains(u)) return q * 1000;
    }
    if (base == 'ml') {
      if (['мл','ml'].contains(u)) return q.toDouble();
      if (['л','l'].contains(u)) return q * 1000;
    }
    if (base == 'pcs' && ['шт','pcs','pc'].contains(u)) return q.toDouble();
    return null;
  }

  Future<void> collectPrices() async {
    final missing = ((result?['missing_prices'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    for (final ingredient in missing) {
      if (!mounted) return;
      await priceDialog(ingredient);
    }
    if (missing.isEmpty) return;
    final updated = items;
    for (final item in updated) {
      try {
        final row = await RecipeTechService.instance.instancePriceLookup(item['ingredient_id'].toString());
        final qty = toBase(item['quantity'] as num, item['unit'].toString(), item['base_unit'].toString());
        final per = row?['price_per_base_unit'] as num?;
        item['line_cost'] = qty != null && per != null ? double.parse((qty * per).toStringAsFixed(2)) : null;
        item['price_missing'] = per == null;
        item['conversion_missing'] = qty == null;
      } catch (_) {}
    }
    final absent = updated.where((x) => x['price_missing'] == true).length;
    final conversionIssues = updated.where((x) => x['conversion_missing'] == true).length;
    final incomplete = updated.any((x) => x['line_cost'] == null);
    if (!mounted) return;
    setState(() {
      result!['items'] = updated;
      result!['missing_prices'] = updated.where((x) => x['price_missing'] == true).toList();
      result!['total_cost'] = !incomplete ? updated.fold<double>(0, (s, x) => s + ((x['line_cost'] as num?)?.toDouble() ?? 0)) : null;
      result!['calculation_status'] = absent == 0 && conversionIssues == 0 ? 'ready' : 'needs_prices';
    });
  }

  Future<void> priceDialog(Map<String, dynamic> ingredient) async {
    final price = TextEditingController();
    final quantity = TextEditingController(text: '1');
    final base = ingredient['unit']?.toString() ?? 'g';
    String unit = base == 'ml' ? 'l' : base == 'pcs' ? 'pcs' : 'kg';
    final units = base == 'ml' ? ['l', 'ml'] : base == 'pcs' ? ['pcs'] : ['kg', 'g'];
    await showDialog<void>(context: context, barrierDismissible: false, builder: (ctx) => StatefulBuilder(builder: (ctx, refresh) => AlertDialog(
      title: const Text('Добавить цену ингредиента'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Align(alignment: Alignment.centerLeft, child: Text(ingredient['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w700))),
        const SizedBox(height: 12),
        TextField(controller: price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Цена, ₽', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: quantity, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Количество в упаковке', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(value: units.contains(unit) ? unit : units.first, decoration: const InputDecoration(labelText: 'Единица измерения', border: OutlineInputBorder()), items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(), onChanged: (v) => refresh(() => unit = v ?? unit)),
        const SizedBox(height: 6),
        const Text('Введите цену и размер упаковки', style: TextStyle(fontSize: 12, color: muted)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Пропустить')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: brown, foregroundColor: Colors.white),
          onPressed: () async {
            final p = double.tryParse(price.text.replaceAll(',', '.'));
            final q = double.tryParse(quantity.text.replaceAll(',', '.'));
            if (p == null || p < 0 || q == null || q <= 0) return;
            try {
              await RecipeTechService.instance.saveIngredientPrice(ingredientId: ingredient['id'].toString(), purchasePrice: p, purchaseQuantity: q, purchaseUnit: unit);
              if (ctx.mounted) Navigator.pop(ctx);
            } catch (e) { showError('Не удалось сохранить цену: ' + e.toString()); }
          },
          child: const Text('Сохранить'),
        ),
      ],
    )));
    price.dispose(); quantity.dispose();
  }

  Future<void> askNameQuantitySave() async {
    final analysis = Map<String, dynamic>.from(result!['analysis'] as Map);
    final name = TextEditingController(text: analysis['product_name']?.toString() ?? '');
    final yieldQty = analysis['yield_quantity'] as num?;
    final yieldUnit = analysis['yield_unit']?.toString();
    final qty = TextEditingController(text: yieldQty?.toString() ?? '1');
    final accepted = await showDialog<bool>(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
      title: const Text('Наименование продукта и количество'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Наименование продукта', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: qty, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: yieldQty == null ? 'Количество замесов' : 'Количество готового продукта', suffixText: yieldUnit ?? 'замесов', border: const OutlineInputBorder())),
        const SizedBox(height: 8),
        Text(result!['total_cost'] == null ? 'Себестоимость неполная: проверьте отсутствующие цены.' : 'Себестоимость рецептуры: ' + money(result!['total_cost'] as num) + ' ₽', style: const TextStyle(fontSize: 12, color: muted)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: brown, foregroundColor: Colors.white), onPressed: () => Navigator.pop(ctx, true), child: const Text('Сохранить ТТК')),
      ],
    ));
    final productName = name.text.trim();
    final amount = double.tryParse(qty.text.replaceAll(',', '.'));
    name.dispose(); qty.dispose();
    if (accepted != true || productName.isEmpty || amount == null || amount <= 0 || !mounted) return;
    try {
      final nutrition = result!['nutrition_per_100'] is Map ? Map<String, dynamic>.from(result!['nutrition_per_100'] as Map) : null;
      await RecipeTechService.instance.saveCard(
        name: productName, technology: analysis['technology']?.toString() ?? '',
        storageConditions: analysis['storage_conditions']?.toString(),
        qualityDescription: analysis['quality_description']?.toString(),
        yieldQuantity: yieldQty, yieldUnit: yieldUnit, items: items,
        totalCost: result!['total_cost'] as num?, nutritionPer100: nutrition,
        nutritionStatus: result!['nutrition_status']?.toString() ?? 'incomplete',
        calculationStatus: result!['calculation_status']?.toString() ?? 'needs_prices',
        photoCount: photos.length,
      );
      final baseCost = result!['total_cost'] as num?;
      setState(() => result!['requested_cost'] = baseCost == null ? null : (yieldQty != null && yieldQty > 0 ? baseCost * amount / yieldQty : baseCost * amount));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Технологическая карта сохранена')));
    } catch (e) { showError('Не удалось сохранить ТТК: ' + e.toString()); }
  }

  String money(num v) => v.toStringAsFixed(2).replaceAll('.', ',');
  void showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final analysis = result?['analysis'] is Map ? Map<String, dynamic>.from(result!['analysis'] as Map) : null;
    final nutrition = result?['nutrition_per_100'] is Map ? Map<String, dynamic>.from(result!['nutrition_per_100'] as Map) : null;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(backgroundColor: bg, elevation: 0, title: const Text('Технологические карты', style: TextStyle(color: dark, fontWeight: FontWeight.w700)), iconTheme: const IconThemeData(color: brown)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(color: Colors.white, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Фотография рецепта', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: dark)),
          const SizedBox(height: 6),
          const Text('Добавьте до 8 страниц рецептуры. Фотографируйте лист целиком, без бликов.', style: TextStyle(color: muted)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            OutlinedButton.icon(onPressed: busy ? null : () => addPhoto(true), icon: const Icon(Icons.camera_alt_outlined), label: const Text('Камера')),
            OutlinedButton.icon(onPressed: busy ? null : () => addPhoto(false), icon: const Icon(Icons.photo_library_outlined), label: const Text('Галерея')),
          ]),
          ...photos.asMap().entries.map((e) => ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.image_outlined, color: brown), title: Text(e.value.name, maxLines: 1, overflow: TextOverflow.ellipsis), trailing: IconButton(onPressed: busy ? null : () => setState(() => photos.removeAt(e.key)), icon: const Icon(Icons.close)))),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(
            onPressed: photos.isEmpty || busy ? null : calculate,
            style: ElevatedButton.styleFrom(backgroundColor: brown, foregroundColor: Colors.white),
            icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.calculate_outlined),
            label: Text(busy ? 'Анализирую рецепт…' : 'Рассчитать'),
          )),
        ]))),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: Colors.red))),
        if (analysis != null) ...[
          const SizedBox(height: 16),
          Card(color: Colors.white, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(analysis['product_name']?.toString() ?? 'Рецептура', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: dark)),
            const SizedBox(height: 12),
            const Text('Состав', style: TextStyle(fontWeight: FontWeight.w700, color: dark)),
            ...items.map((x) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [
              Expanded(child: Text(x['ingredient_name'].toString())),
              Text(x['quantity'].toString() + ' ' + x['unit'].toString()),
              const SizedBox(width: 8),
              Text(x['line_cost'] == null ? (x['conversion_missing'] == true ? 'проверьте единицу' : 'нет цены') : money(x['line_cost'] as num) + ' ₽', style: TextStyle(color: x['line_cost'] == null ? Colors.red : muted, fontSize: 12)),
            ]))),
            const Divider(height: 24),
            const Text('Технология приготовления', style: TextStyle(fontWeight: FontWeight.w700, color: dark)),
            const SizedBox(height: 6),
            Text(analysis['technology']?.toString() ?? 'Не указана', style: const TextStyle(color: muted, height: 1.4)),
            if (analysis['storage_conditions'] != null && analysis['storage_conditions'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Условия хранения', style: TextStyle(fontWeight: FontWeight.w700, color: dark)),
              Text(analysis['storage_conditions'].toString(), style: const TextStyle(color: muted)),
            ],
            if (analysis['quality_description'] != null && analysis['quality_description'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Показатели качества', style: TextStyle(fontWeight: FontWeight.w700, color: dark)),
              Text(analysis['quality_description'].toString(), style: const TextStyle(color: muted)),
            ],
            if ((analysis['notes'] as List? ?? []).isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Требует проверки', style: TextStyle(color: brown, fontWeight: FontWeight.w700)),
              ...((analysis['notes'] as List).map((n) => Text('• ' + n.toString(), style: const TextStyle(color: muted, fontSize: 13)))),
            ],
            const Divider(height: 24),
            summary('Выход по рецептуре', analysis['yield_quantity'] == null ? 'Не указан' : analysis['yield_quantity'].toString() + ' ' + (analysis['yield_unit']?.toString() ?? '')),
            summary('Себестоимость рецептуры', result!['total_cost'] == null ? 'Не рассчитана — нет цены' : money(result!['total_cost'] as num) + ' ₽'),
            summary(result!['nutrition_status'] == 'estimated' ? 'КБЖУ на 100 г (оценка)' : 'КБЖУ на 100 г', nutrition == null ? 'Недостаточно данных' : 'К ' + nutrition['calories'].toString() + ' · Б ' + nutrition['protein'].toString() + ' · Ж ' + nutrition['fat'].toString() + ' · У ' + nutrition['carbs'].toString()),
            if (result!['requested_cost'] != null) summary('Стоимость введённого количества', money(result!['requested_cost'] as num) + ' ₽'),
          ]))),
        ],
      ]),
    );
  }

  Widget summary(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Text(label, style: const TextStyle(color: muted, fontSize: 13))),
      const SizedBox(width: 10),
      Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(color: dark, fontWeight: FontWeight.w600, fontSize: 13))),
    ]),
  );
}
