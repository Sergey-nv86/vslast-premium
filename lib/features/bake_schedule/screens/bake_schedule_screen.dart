import 'package:flutter/material.dart';

import '../../../models/product.dart';
import '../../../services/bake_schedule_service.dart';
import '../../../theme/app_theme.dart';
import 'preorder_checkout_screen.dart';

class BakeScheduleScreen extends StatefulWidget {
  const BakeScheduleScreen({super.key});

  @override
  State<BakeScheduleScreen> createState() => _BakeScheduleScreenState();
}

class _BakeScheduleScreenState extends State<BakeScheduleScreen> {
  late DateTime _weekStart;
  late DateTime _selectedDate;

  Map<DateTime, List<Product>> _schedule = {};

  final Map<DateTime, Map<String, int>> _selected = {};

  bool _loading = true;
  final bool _submitting = false;


  static const _weekDays = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Ограничение по сроку предварительного заказа снято.
    // Предзаказ можно оформить начиная с сегодняшнего дня.
    // Окончательное решение принимает администратор.

    // Загружаем неделю, в которую входит сегодняшний день.
    _weekStart = today.subtract(
      Duration(days: today.weekday - DateTime.monday),
    );

    // Сразу открываем сегодняшний день.
    _selectedDate = today;

    _load();
  }

  Future<void> _load() async {
    try {
      final data = await BakeScheduleService.instance.loadWeek(
        startDate: _weekStart,
      );

      if (!mounted) return;

      setState(() {
        _schedule = data;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showError('Не удалось загрузить график запеков');
    }
  }

  DateTime _key(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isDateAvailable(DateTime date) {
    return !_key(date).isBefore(_key(DateTime.now()));
  }

  List<Product> get _products => _schedule[_key(_selectedDate)] ?? <Product>[];

  Map<String, int> _selectedFor(DateTime date) {
    return _selected[_key(date)] ?? <String, int>{};
  }

  int _quantity(Product product) {
    return _selectedFor(_selectedDate)[product.id] ?? 0;
  }

  void _changeQuantity(Product product, int value) {
    if (!_isDateAvailable(_selectedDate)) {
      return;
    }

    final key = _key(_selectedDate);

    final day = Map<String, int>.from(_selected[key] ?? <String, int>{});

    if (value <= 0) {
      day.remove(product.id);
    } else {
      day[product.id] = value;
    }

    setState(() {
      if (day.isEmpty) {
        _selected.remove(key);
      } else {
        _selected[key] = day;
      }
    });
  }

  int get _totalSelected {
    var total = 0;

    for (final day in _selected.values) {
      for (final quantity in day.values) {
        total += quantity;
      }
    }

    return total;
  }

  int get _daysSelected {
    return _selected.values.where((day) => day.isNotEmpty).length;
  }

  Future<void> _submit() async {
    if (_submitting) return;

    if (_totalSelected == 0) {
      _showError('Выберите хлеб для предзаказа');
      return;
    }

    final selections = <DateTime, Map<Product, int>>{};

    for (final entry in _selected.entries) {
      final productsById = <String, Product>{
        for (final product in _schedule[entry.key] ?? <Product>[])
          product.id: product,
      };

      final day = <Product, int>{};

      for (final item in entry.value.entries) {
        final product = productsById[item.key];

        if (product != null && item.value > 0) {
          day[product] = item.value;
        }
      }

      if (day.isNotEmpty) {
        selections[entry.key] = day;
      }
    }

    if (selections.isEmpty) {
      _showError('Выберите хлеб для предзаказа');
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PreorderCheckoutScreen(
          selections: selections,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _selected.clear();
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_month(date.month)}';
  }

  String _month(int month) {
    const months = [
      '',
      'янв.',
      'февр.',
      'мар.',
      'апр.',
      'мая',
      'июн.',
      'июл.',
      'авг.',
      'сент.',
      'окт.',
      'нояб.',
      'дек.',
    ];

    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('График запеков', style: AppTextStyles.screenTitle),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _weekStrip(),
                Expanded(child: _dayContent()),
              ],
            ),
      bottomNavigationBar: _totalSelected == 0
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryBrown,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Предзаказ · $_totalSelected шт. · $_daysSelected дн.',
                        ),
                ),
              ),
            ),
    );
  }

  Widget _weekStrip() {
    return SizedBox(
      height: 78,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = _weekStart.add(Duration(days: index));
          final available = _isDateAvailable(date);
          final selected = _key(date) == _key(_selectedDate);
          final hasSelected = _selectedFor(date).isNotEmpty;

          return GestureDetector(
            onTap: available
                ? () {
                    setState(() {
                      _selectedDate = date;
                    });
                  }
                : null,
            child: Opacity(
              opacity: available ? 1.0 : 0.45,
              child: Container(
                width: 64,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryBrown : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? AppColors.primaryBrown
                        : AppColors.divider,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _weekDays[index],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    if (hasSelected)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white
                              : AppColors.primaryBrown,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dayContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      children: [
        Text(_formatDate(_selectedDate), style: AppTextStyles.sectionLabel),
        const SizedBox(height: 4),
        Text(
          'Хлеб, который будет выпекаться в этот день',
          style: AppTextStyles.rowLabelMuted,
        ),
        const SizedBox(height: 16),

        if (_products.isEmpty)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.bakery_dining_outlined,
                  size: 34,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 10),
                Text(
                  'На этот день пока нет запеков',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.rowLabelMuted.copyWith(),
                ),
              ],
            ),
          )
        else
          ..._products.map(_productRow),

        if (_products.isNotEmpty) const SizedBox(height: 12),

        if (_products.isNotEmpty)
          Text(
            'Можно выбрать хлеб на несколько разных дней. '
            'Все выбранные позиции попадут в одну форму предзаказа.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }

  Widget _productRow(Product product) {
    final quantity = _quantity(product);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: quantity > 0 ? AppColors.primaryBrown : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.price} ₽',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: quantity == 0
                      ? null
                      : () => _changeQuantity(product, quantity - 1),
                  icon: const Icon(Icons.remove, size: 18),
                ),
                SizedBox(
                  width: 24,
                  child: Text(
                    '$quantity',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => _changeQuantity(product, quantity + 1),
                  icon: const Icon(Icons.add, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
