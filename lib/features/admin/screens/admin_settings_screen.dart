import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/permission.dart';
import '../guards/admin_guard.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  static const bg = Color(0xFFF8F4EE);
  static const brown = Color(0xFF8B5E3C);
  static const dark = Color(0xFF3B281F);
  static const muted = Color(0xFF806F65);

  final _deliveryMinController = TextEditingController();
  final _pickupDiscountController = TextEditingController();
  final _goldThresholdController = TextEditingController();
  final _premiumThresholdController = TextEditingController();
  final _silverBonusController = TextEditingController();
  final _goldBonusController = TextEditingController();
  final _premiumBonusController = TextEditingController();

  bool _deliveryEnabled = true;
  bool _loading = true;
  bool _saving = false;

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _deliveryMinController.dispose();
    _pickupDiscountController.dispose();
    _goldThresholdController.dispose();
    _premiumThresholdController.dispose();
    _silverBonusController.dispose();
    _goldBonusController.dispose();
    _premiumBonusController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final row = await _supabase
          .from('order_settings')
          .select('delivery_enabled,delivery_min_order,pickup_discount,loyalty_gold_threshold,loyalty_premium_threshold,loyalty_silver_bonus_percent,loyalty_gold_bonus_percent,loyalty_premium_bonus_percent')
          .eq('id', 1)
          .single();

      if (!mounted) return;

      setState(() {
        _deliveryEnabled = row['delivery_enabled'] != false;
        _deliveryMinController.text = '${row['delivery_min_order'] ?? 1500}';
        _pickupDiscountController.text = '${row['pickup_discount'] ?? 10}';
        _goldThresholdController.text = '${row['loyalty_gold_threshold'] ?? 50000}';
        _premiumThresholdController.text = '${row['loyalty_premium_threshold'] ?? 150000}';
        _silverBonusController.text = '${row['loyalty_silver_bonus_percent'] ?? 1}';
        _goldBonusController.text = '${row['loyalty_gold_bonus_percent'] ?? 3}';
        _premiumBonusController.text = '${row['loyalty_premium_bonus_percent'] ?? 5}';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('Не удалось загрузить настройки: $e');
    }
  }

  int? _intValue(TextEditingController controller) => int.tryParse(controller.text.trim());
  double? _doubleValue(TextEditingController controller) => double.tryParse(controller.text.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    if (_saving) return;

    final deliveryMin = _intValue(_deliveryMinController);
    final pickupDiscount = _doubleValue(_pickupDiscountController);
    final goldThreshold = _intValue(_goldThresholdController);
    final premiumThreshold = _intValue(_premiumThresholdController);
    final silverBonus = _doubleValue(_silverBonusController);
    final goldBonus = _doubleValue(_goldBonusController);
    final premiumBonus = _doubleValue(_premiumBonusController);

    if (deliveryMin == null || deliveryMin < 0) {
      _showError('Минимальная сумма доставки должна быть числом не меньше 0');
      return;
    }
    if (pickupDiscount == null || pickupDiscount < 0 || pickupDiscount > 100) {
      _showError('Скидка за самовывоз должна быть от 0 до 100%');
      return;
    }
    if (goldThreshold == null || goldThreshold < 0 || premiumThreshold == null || premiumThreshold <= goldThreshold) {
      _showError('Порог Premium должен быть больше порога Gold');
      return;
    }
    for (final value in [silverBonus, goldBonus, premiumBonus]) {
      if (value == null || value < 0 || value > 100) {
        _showError('Процент бонусов должен быть от 0 до 100%');
        return;
      }
    }

    setState(() => _saving = true);

    try {
      await _supabase.from('order_settings').update({
        'delivery_enabled': _deliveryEnabled,
        'delivery_min_order': deliveryMin,
        'pickup_discount': pickupDiscount,
        'loyalty_gold_threshold': goldThreshold,
        'loyalty_premium_threshold': premiumThreshold,
        'loyalty_silver_bonus_percent': silverBonus,
        'loyalty_gold_bonus_percent': goldBonus,
        'loyalty_premium_bonus_percent': premiumBonus,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', 1);

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Настройки сохранены'), behavior: SnackBarBehavior.floating));
    } catch (e) {
      if (mounted) _showError('Не удалось сохранить настройки: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return AdminGuard(
      permission: Permission.viewDashboard,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text('Настройки', style: TextStyle(color: dark, fontWeight: FontWeight.w700)),
          iconTheme: const IconThemeData(color: brown),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: brown))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _SectionCard(
                    title: 'Доставка',
                    icon: Icons.delivery_dining_outlined,
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Доставка доступна'),
                        subtitle: Text(_deliveryEnabled ? 'Клиенты могут выбрать доставку' : 'Доставка отключена для новых заказов', style: const TextStyle(color: muted, fontSize: 12)),
                        value: _deliveryEnabled,
                        activeThumbColor: brown,
                        onChanged: (value) => setState(() => _deliveryEnabled = value),
                      ),
                      _NumberField(controller: _deliveryMinController, label: 'Минимальная сумма заказа для доставки, ₽', suffix: '₽'),
                      const SizedBox(height: 12),
                      _NumberField(controller: _pickupDiscountController, label: 'Скидка за самовывоз, %', suffix: '%'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Программа лояльности',
                    icon: Icons.card_membership_outlined,
                    children: [
                      const Text('Пороги накопительных покупок', style: TextStyle(fontWeight: FontWeight.w700, color: dark)),
                      const SizedBox(height: 10),
                      _NumberField(controller: _goldThresholdController, label: 'Gold — от суммы, ₽', suffix: '₽'),
                      const SizedBox(height: 12),
                      _NumberField(controller: _premiumThresholdController, label: 'Premium — от суммы, ₽', suffix: '₽'),
                      const SizedBox(height: 18),
                      const Text('Начисление бонусов', style: TextStyle(fontWeight: FontWeight.w700, color: dark)),
                      const SizedBox(height: 10),
                      _NumberField(controller: _silverBonusController, label: 'Silver, %', suffix: '%'),
                      const SizedBox(height: 12),
                      _NumberField(controller: _goldBonusController, label: 'Gold, %', suffix: '%'),
                      const SizedBox(height: 12),
                      _NumberField(controller: _premiumBonusController, label: 'Premium, %', suffix: '%'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(backgroundColor: brown, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                      child: _saving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Сохранить настройки', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AdminSettingsScreenStateColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 42, height: 42, decoration: const BoxDecoration(color: Color(0xFFF1E8E0), shape: BoxShape.circle), child: Icon(icon, color: AdminSettingsScreenStateColors.brown)),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AdminSettingsScreenStateColors.dark)),
        ]),
        const SizedBox(height: 14),
        ...children,
      ]),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  const _NumberField({required this.controller, required this.label, required this.suffix});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, suffixText: suffix, filled: true, fillColor: const Color(0xFFFAF8F5), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEADFD5))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEADFD5))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF8B5E3C), width: 1.4))),
    );
  }
}

class AdminSettingsScreenStateColors {
  static const brown = Color(0xFF8B5E3C);
  static const dark = Color(0xFF3B281F);
  static const border = Color(0xFFEADFD5);
}
