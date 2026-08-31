import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/product.dart';
import '../../../services/bake_schedule_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/selectable_option_card.dart';

class PreorderCheckoutScreen extends StatefulWidget {
  final Map<DateTime, Map<Product, int>> selections;

  const PreorderCheckoutScreen({super.key, required this.selections});

  @override
  State<PreorderCheckoutScreen> createState() => _PreorderCheckoutScreenState();
}

class _PreorderCheckoutScreenState extends State<PreorderCheckoutScreen> {
  String _deliveryMethod = 'pickup';
  String _paymentMethod = 'onlineSbp';

  String? _deliveryAddress;
  String? _comment;

  bool _submitting = false;

  Map<DateTime, Map<Product, int>> get _selections => widget.selections;

  int get _totalCount {
    var total = 0;

    for (final day in _selections.values) {
      for (final quantity in day.values) {
        total += quantity;
      }
    }

    return total;
  }

  int get _itemsTotal {
    var total = 0;

    for (final day in _selections.values) {
      for (final entry in day.entries) {
        total += entry.key.price * entry.value;
      }
    }

    return total;
  }

  int get _daysCount {
    return _selections.values.where((items) => items.isNotEmpty).length;
  }

  List<DateTime> get _dates {
    final dates = _selections.keys.toList()..sort();
    return dates;
  }

  Future<void> _selectDeliveryAddress() async {
    final controller = TextEditingController(text: _deliveryAddress ?? '');

    final address = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Адрес доставки', style: AppTextStyles.sectionLabel),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Введите адрес',
                  filled: true,
                  fillColor: AppColors.surfaceMuted,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    final value = controller.text.trim();

                    if (value.isEmpty) {
                      return;
                    }

                    Navigator.pop(context, value);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBrown,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Сохранить',
                      style: AppTextStyles.cartBarButton,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();

    if (address != null && mounted) {
      setState(() {
        _deliveryAddress = address;
        _deliveryMethod = 'delivery';
      });
    }
  }

  Future<void> _editComment() async {
    final controller = TextEditingController(text: _comment ?? '');

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Комментарий к заказу', style: AppTextStyles.sectionLabel),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Например: не звонить в домофон',
                  filled: true,
                  fillColor: AppColors.surfaceMuted,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context, controller.text.trim());
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBrown,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Сохранить',
                      style: AppTextStyles.cartBarButton,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();

    if (result != null && mounted) {
      setState(() {
        _comment = result.isEmpty ? null : result;
      });
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;

    if (_selections.isEmpty) {
      _showError('Выберите хлеб для предзаказа');
      return;
    }

    if (_deliveryMethod == 'delivery' &&
        (_deliveryAddress == null || _deliveryAddress!.trim().isEmpty)) {
      _showError('Укажите адрес доставки');
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      _showError('Для оформления предзаказа необходимо войти в аккаунт');
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final selections = <DateTime, Map<String, int>>{};

      for (final entry in _selections.entries) {
        final date = DateTime(entry.key.year, entry.key.month, entry.key.day);

        final items = <String, int>{};

        for (final item in entry.value.entries) {
          items[item.key.id] = item.value;
        }

        if (items.isNotEmpty) {
          selections[date] = items;
        }
      }

      final orders = await BakeScheduleService.instance.createPreorders(
        selections: selections,
        comment: _comment,
      );

      if (!mounted) return;

      setState(() {
        _submitting = false;
      });

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Предзаказ оформлен'),
          content: Text(
            orders.length == 1
                ? 'Создан предзаказ на выбранную дату.'
                : 'Создано предзаказов: ${orders.length}. '
                      'Каждый предзаказ привязан к своей дате.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Готово'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _submitting = false;
      });

      _showError(error.toString());
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  String _formatDate(DateTime date) {
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

    return '${date.day} ${months[date.month]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
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
                          size: 24,
                          color: AppColors.primaryBrown,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Оформление предзаказа',
                        style: AppTextStyles.screenTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Ваш предзаказ',
                        style: AppTextStyles.sectionLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$_totalCount шт.',
                      style: AppTextStyles.sectionCounter,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),

            for (final date in _dates)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _DayOrderCard(
                    date: date,
                    items: _selections[date]!,
                    dateFormatter: _formatDate,
                  ),
                ),
              ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _Section(
                  title: 'Способ получения',
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableOptionCard(
                          icon: Icons.shopping_bag_outlined,
                          title: 'Самовывоз',
                          subtitle: 'ул. Пионерская, 12',
                          selected: _deliveryMethod == 'pickup',
                          onTap: () {
                            setState(() {
                              _deliveryMethod = 'pickup';
                              _deliveryAddress = null;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SelectableOptionCard(
                          icon: Icons.delivery_dining_outlined,
                          title: 'Доставка',
                          subtitle: _deliveryAddress ?? 'Указать адрес',
                          selected: _deliveryMethod == 'delivery',
                          onTap: _selectDeliveryAddress,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _Section(
                  title: 'Способ оплаты',
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableOptionCard(
                          icon: Icons.qr_code,
                          title: 'СБП онлайн',
                          subtitle: 'Администратор выставит QR-код',
                          selected: _paymentMethod == 'onlineSbp',
                          onTap: () {
                            setState(() {
                              _paymentMethod = 'onlineSbp';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SelectableOptionCard(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'При получении',
                          subtitle: 'Наличными или картой',
                          selected: _paymentMethod == 'cash',
                          onTap: () {
                            setState(() {
                              _paymentMethod = 'cash';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              sliver: SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: _editComment,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          color: AppColors.primaryBrown,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _comment ?? 'Добавить комментарий',
                            style: TextStyle(
                              color: _comment == null
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _PriceSummary(
                  itemsTotal: _itemsTotal,
                  daysCount: _daysCount,
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'После подтверждения будет создан отдельный '
                  'предзаказ на каждую выбранную дату.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              sliver: SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: _submitting ? null : _submit,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    decoration: BoxDecoration(
                      color: _submitting
                          ? AppColors.primaryBrown.withValues(alpha: 0.6)
                          : AppColors.primaryBrown,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    alignment: Alignment.center,
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Подтвердить предзаказ',
                            style: AppTextStyles.cartBarButton,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayOrderCard extends StatelessWidget {
  final DateTime date;
  final Map<Product, int> items;
  final String Function(DateTime) dateFormatter;

  const _DayOrderCard({
    required this.date,
    required this.items,
    required this.dateFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final total = items.entries.fold<int>(
      0,
      (sum, entry) => sum + entry.key.price * entry.value,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AppColors.primaryBrown,
              ),
              const SizedBox(width: 8),
              Text(
                dateFormatter(date),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$total ₽',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final entry in items.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key.name,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  Text(
                    '${entry.value} × ${entry.key.price} ₽',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.sectionLabel),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _PriceSummary extends StatelessWidget {
  final int itemsTotal;
  final int daysCount;

  const _PriceSummary({required this.itemsTotal, required this.daysCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: Text('Товары')),
              Text('$itemsTotal ₽'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(child: Text('Даты')),
              Text('$daysCount'),
            ],
          ),
          const Divider(height: 22),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Итого',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '$itemsTotal ₽',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
