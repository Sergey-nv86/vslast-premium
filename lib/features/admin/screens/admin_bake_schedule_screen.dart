import 'package:flutter/material.dart';

import '../../../models/product.dart';
import '../../../services/bake_schedule_service.dart';
import '../../../services/product_service.dart';

class AdminBakeScheduleScreen extends StatefulWidget {
  const AdminBakeScheduleScreen({super.key});

  @override
  State<AdminBakeScheduleScreen> createState() =>
      _AdminBakeScheduleScreenState();
}

class _AdminBakeScheduleScreenState extends State<AdminBakeScheduleScreen> {
  late DateTime _weekStart;
  late DateTime _selectedDate;

  Map<DateTime, List<Product>> _schedule = {};
  List<Product> _allProducts = [];

  bool _loading = true;
  bool _saving = false;

  static const _weekDays = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - DateTime.monday));

    _selectedDate = _weekStart;

    _load();
  }

  DateTime _key(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        BakeScheduleService.instance.loadWeek(startDate: _weekStart),
        ProductService.instance.getProducts(),
      ]);

      if (!mounted) return;

      setState(() {
        _schedule = results[0] as Map<DateTime, List<Product>>;
        _allProducts = results[1] as List<Product>;
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

  List<Product> get _dayProducts =>
      _schedule[_key(_selectedDate)] ?? <Product>[];

  Future<void> _addBread() async {
    final existingIds = _dayProducts.map((p) => p.id).toSet();

    final available = _allProducts
        .where(
          (product) =>
              (product.category == ProductCategory.bread ||
                  product.category == ProductCategory.pastry) &&
              !existingIds.contains(product.id),
        )
        .toList();

    if (available.isEmpty) {
      _showError('Нет доступного хлеба для добавления');
      return;
    }

    final product = await showModalBottomSheet<Product>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              const Text(
                'Добавить',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              ...available.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.name),
                  subtitle: Text('${item.price} ₽'),
                  trailing: const Icon(Icons.add_circle_outline),
                  onTap: () {
                    Navigator.of(context).pop(item);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (product == null || !mounted) return;

    setState(() {
      _schedule[_key(_selectedDate)] = [..._dayProducts, product];
    });

    await _save();
  }

  Future<void> _removeBread(Product product) async {
    setState(() {
      _schedule[_key(_selectedDate)] = _dayProducts
          .where((item) => item.id != product.id)
          .toList();
    });

    await _save();
  }

  Future<void> _save() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      await BakeScheduleService.instance.setProductsForDate(
        date: _selectedDate,
        products: _dayProducts,
      );
    } catch (error) {
      if (mounted) {
        _showError('Не удалось сохранить график');
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F4EE),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'График запеков',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF3B281F),
          ),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 18),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _weekStrip(),
                Expanded(child: _dayContent()),
              ],
            ),
    );
  }

  Widget _weekStrip() {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = _weekStart.add(Duration(days: index));

          final selected = _key(date) == _key(_selectedDate);

          final count = (_schedule[_key(date)] ?? []).length;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
            },
            child: Container(
              width: 68,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF8B5E3C) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF8B5E3C)
                      : const Color(0xFFEADFD5),
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
                      color: selected ? Colors.white : const Color(0xFF806F65),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : const Color(0xFF3B281F),
                    ),
                  ),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      color: selected
                          ? Colors.white70
                          : const Color(0xFF806F65),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dayContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Text(
          'Хлеб на ${_weekDays[_selectedDate.weekday - 1]} '
          '${_formatDate(_selectedDate)}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF3B281F),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Добавьте хлебы, которые будут выпекаться в этот день.',
          style: TextStyle(fontSize: 13, color: Color(0xFF806F65)),
        ),
        const SizedBox(height: 18),

        ..._dayProducts.map(
          (product) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEADFD5)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.bakery_dining_outlined,
                  color: Color(0xFF8B5E3C),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3B281F),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _removeBread(product),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF806F65),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 6),

        OutlinedButton.icon(
          onPressed: _saving ? null : _addBread,
          icon: const Icon(Icons.add),
          label: const Text('Добавить'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF8B5E3C),
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }
}
