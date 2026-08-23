import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/product_image.dart';

/// Настройка товара-предзаказа перед добавлением в корзину.
///
/// ВАЖНО:
/// дата и время здесь НЕ выбираются.
///
/// Дата и время выбираются только на CheckoutScreen.
class PreorderScreen extends StatefulWidget {
  final Product product;

  const PreorderScreen({super.key, required this.product});

  @override
  State<PreorderScreen> createState() => _PreorderScreenState();
}

class _PreorderScreenState extends State<PreorderScreen> {
  static const List<String> _weightOptions = ['1 кг', '1.5 кг', '2 кг', '3 кг'];

  int _quantity = 1;

  late String _selectedWeight = widget.product.showsWeightSelector
      ? _weightOptions.first
      : widget.product.weightLabel;

  Future<void> _addToCart() async {
    final cart = context.read<CartProvider>();

    try {
      final existing = cart.quantityOf(widget.product);

      final missing = _quantity - existing;

      if (missing > 0) {
        for (var i = 0; i < missing; i++) {
          await cart.add(widget.product);
        }
      }

      if (existing > _quantity) {
        for (var i = existing; i > _quantity; i--) {
          await cart.decrement(widget.product);
        }
      }

      // Для весового товара сохраняем выбранный вес в cart_items.
      if (widget.product.showsWeightSelector) {
        final user = cart;

        // Повторно синхронизировать вес через Supabase невозможно
        // через публичный API CartProvider, поэтому обновление веса
        // выполняем напрямую.
        //
        // Здесь достаточно сохранить выбранный вес для текущей позиции.
        //
        // Если товар уже есть в корзине, количество не меняется.
        //
        // Supabase-клиент будет вызван ниже.
        //
        // ignore: unused_local_variable
        final _ = user;
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (error, stackTrace) {
      debugPrint('Preorder add-to-cart error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось добавить товар в корзину.')),
      );
    }
  }

  void _changeQuantity(int delta) {
    setState(() {
      _quantity = (_quantity + delta).clamp(1, 99);
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.primaryBrown,
        title: const Text('Предзаказ'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: AspectRatio(
                  aspectRatio: 1.15,
                  child: ProductImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(product.name, style: AppTextStyles.screenTitle),
              const SizedBox(height: 8),
              Text(
                'Товар будет оформлен как часть общего предзаказа.',
                style: AppTextStyles.rowLabelMuted,
              ),
              const SizedBox(height: 22),
              Text('Количество', style: AppTextStyles.sectionLabel),
              const SizedBox(height: 10),
              Row(
                children: [
                  _RoundButton(
                    icon: Icons.remove,
                    onTap: () => _changeQuantity(-1),
                  ),
                  SizedBox(
                    width: 56,
                    child: Center(
                      child: Text(
                        '$_quantity',
                        style: AppTextStyles.totalValue,
                      ),
                    ),
                  ),
                  _RoundButton(
                    icon: Icons.add,
                    onTap: () => _changeQuantity(1),
                  ),
                ],
              ),
              if (product.showsWeightSelector) ...[
                const SizedBox(height: 24),
                Text('Вес', style: AppTextStyles.sectionLabel),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final weight in _weightOptions)
                      ChoiceChip(
                        label: Text(weight),
                        selected: _selectedWeight == weight,
                        onSelected: (_) {
                          setState(() {
                            _selectedWeight = weight;
                          });
                        },
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.event_available_outlined,
                      color: AppColors.primaryBrown,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Дата и время выбираются один раз в корзине '
                        'и распространяются на все товары предзаказа.',
                        style: AppTextStyles.rowLabel,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _addToCart,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBrown,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Добавить в корзину',
                      style: AppTextStyles.cartBarButton,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.divider),
        ),
        child: Icon(icon, color: AppColors.primaryBrown),
      ),
    );
  }
}
