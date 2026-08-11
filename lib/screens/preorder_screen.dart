import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import '../widgets/category_chip.dart';
import 'auth_screen.dart';
import 'favorite_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

/// Экран «Предзаказ» в фирменном стиле Всласть — открывается с кнопки
/// «Предзаказ» на карточке товара (в каталоге, на карточке товара и т.д.)
/// для товаров с inStock == false.
///
/// Шаг выбора веса показывается ТОЛЬКО если [Product.showsWeightSelector]
/// (категория "торты" или явный признак "весовой") — для остальных
/// товаров (эклер, булочка и т.п.) этого шага просто нет в дереве
/// виджетов, поэтому высота экрана естественным образом меньше — никакого
/// отдельного расчёта высоты не нужно, Column сама короче без лишнего шага.
class PreorderScreen extends StatefulWidget {
  final Product product;

  const PreorderScreen({super.key, required this.product});

  @override
  State<PreorderScreen> createState() => _PreorderScreenState();
}

class _PreorderScreenState extends State<PreorderScreen> {
  static const List<String> _weightOptions = ['1 кг', '1.5 кг', '2 кг', '3 кг'];
  static const List<String> _timeSlots = [
    '10:00', '12:00', '14:00', '16:00', '18:00', '20:00',
  ];

  int _quantity = 1;
  late String _selectedWeight = _weightOptions.first;
  DateTime _pickupDate = DateTime.now().add(const Duration(days: 1));
  late String _pickupTime = _timeSlots[4];
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickupDate.isBefore(now) ? now : _pickupDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _pickupDate = picked);
  }

  Future<void> _pickTime() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            for (final slot in _timeSlots)
              ListTile(
                title: Text(slot, style: AppTextStyles.rowLabel),
                trailing: slot == _pickupTime
                    ? const Icon(Icons.check, color: AppColors.primaryBrown)
                    : null,
                onTap: () => Navigator.pop(sheetContext, slot),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected != null) setState(() => _pickupTime = selected);
  }

  void _openProfileMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final hasAccount = context.read<AuthProvider>().isLoggedIn;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.person_outline, color: AppColors.primaryBrown),
                title: Text('Профиль', style: AppTextStyles.rowLabel),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => hasAccount
                          ? const ProfileScreen()
                          : const AuthScreen(initialMode: AuthMode.register),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite_border, color: AppColors.primaryBrown),
                title: Text('Избранное', style: AppTextStyles.rowLabel),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FavoriteScreen()),
                  );
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.receipt_long_outlined, color: AppColors.primaryBrown),
                title: Text('Мои заказы', style: AppTextStyles.rowLabel),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OrdersScreen()),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _submit() {
    // TODO: отправить предзаказ на бэкенд (товар, количество, вес,
    // дата/время получения, комментарий).
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (dialogContext) => _PreorderConfirmedDialog(
        onDone: () {
          Navigator.of(dialogContext).pop();
          Navigator.of(context).maybePop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  _RoundButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Text(
                      'Предзаказ',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.screenTitleSmall,
                    ),
                  ),
                  _RoundButton(icon: Icons.person_outline, onTap: _openProfileMenu),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProductSummaryCard(product: product),
                    const SizedBox(height: 22),

                    _Section(
                      number: 1,
                      title: 'Количество',
                      child: _QuantityStepper(
                        quantity: _quantity,
                        onDecrement: () =>
                            setState(() => _quantity = (_quantity - 1).clamp(1, 99)),
                        onIncrement: () =>
                            setState(() => _quantity = (_quantity + 1).clamp(1, 99)),
                      ),
                    ),

                    if (product.showsWeightSelector) ...[
                      const SizedBox(height: 20),
                      _Section(
                        number: 2,
                        title: 'Вес торта',
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _weightOptions
                              .map((w) => CategoryChip(
                                    label: w,
                                    selected: w == _selectedWeight,
                                    onTap: () => setState(() => _selectedWeight = w),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    _Section(
                      number: product.showsWeightSelector ? 3 : 2,
                      title: 'Дата получения',
                      child: _DropdownField(
                        icon: Icons.calendar_today_outlined,
                        label: formatRuDateWithYear(_pickupDate),
                        onTap: _pickDate,
                      ),
                    ),

                    const SizedBox(height: 20),
                    _Section(
                      number: product.showsWeightSelector ? 4 : 3,
                      title: 'Время получения',
                      child: _DropdownField(
                        icon: Icons.access_time,
                        label: _pickupTime,
                        onTap: _pickTime,
                      ),
                    ),

                    const SizedBox(height: 20),
                    _Section(
                      number: product.showsWeightSelector ? 5 : 4,
                      title: 'Комментарий',
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          controller: _commentController,
                          maxLines: 3,
                          style: AppTextStyles.rowLabel,
                          decoration: InputDecoration(
                            hintText:
                                'Например: поздравительная надпись, оформление, пожелания...',
                            hintStyle: AppTextStyles.searchHint,
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline,
                              size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'После оформления предзаказа администратор свяжется '
                              'с вами для подтверждения деталей заказа.',
                              style: AppTextStyles.rowLabelMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: _submit,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 17),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBrown,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          alignment: Alignment.center,
                          child:
                              Text('Оформить предзаказ', style: AppTextStyles.cartBarButton),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductSummaryCard extends StatelessWidget {
  final Product product;

  const _ProductSummaryCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              product.imageUrl,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 96,
                height: 96,
                color: AppColors.surfaceMuted,
                child: const Icon(Icons.bakery_dining_outlined,
                    size: 28, color: AppColors.textSecondary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: AppTextStyles.orderTitle),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.public, size: 14, color: AppColors.statusPendingText),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Временно отсутствует в наличии',
                        style: AppTextStyles.statusPillLabel
                            .copyWith(color: AppColors.statusPendingText),
                      ),
                    ),
                  ],
                ),
                if (product.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    product.description!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.rowLabelMuted,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final int number;
  final String title;
  final Widget child;

  const _Section({required this.number, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$number. $title', style: AppTextStyles.fieldLabel),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _button(Icons.remove, onDecrement),
        SizedBox(
          width: 48,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: AppTextStyles.orderTitle,
          ),
        ),
        _button(Icons.add, onIncrement),
      ],
    );
  }

  Widget _button(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: AppColors.surfaceMuted,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: AppColors.primaryBrown),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DropdownField({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: AppTextStyles.rowLabel)),
            const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: Icon(icon, size: 20, color: AppColors.primaryBrown),
      ),
    );
  }
}

class _PreorderConfirmedDialog extends StatelessWidget {
  final VoidCallback onDone;

  const _PreorderConfirmedDialog({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.statusSuccessBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 28, color: AppColors.statusSuccessText),
            ),
            const SizedBox(height: 16),
            Text('Предзаказ оформлен', style: AppTextStyles.orderTitle),
            const SizedBox(height: 8),
            Text(
              'Спасибо! В ближайшее время администратор свяжется с вами '
              'для подтверждения заказа.',
              textAlign: TextAlign.center,
              style: AppTextStyles.rowLabelMuted,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: onDone,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBrown,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  alignment: Alignment.center,
                  child: Text('Понятно', style: AppTextStyles.cartBarButton),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
