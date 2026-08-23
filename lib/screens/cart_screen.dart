import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/order_item_tile.dart';
import 'checkout_screen.dart';

/// Корзина.
///
/// В одной корзине могут находиться одновременно:
/// - товары в наличии;
/// - товары с признаком предзаказа.
///
/// Если есть хотя бы один preorder-товар, вся корзина оформляется
/// одним предзаказом на общую дату и время.
///
/// Дата/время не принадлежат конкретному товару.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String? _promoCode;

  void _openCheckout(BuildContext context) {
    final cart = context.read<CartProvider>();

    if (cart.isPreorder) {
      if (cart.preorderDate == null ||
          cart.preorderTime == null ||
          cart.preorderTime!.isEmpty) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Выберите дату и время предзаказа.')),
          );
        return;
      }
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CheckoutScreen()));
  }

  Future<void> _editPromoCode() async {
    final controller = TextEditingController(text: _promoCode);

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
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
            Text('Промокод', style: AppTextStyles.sectionLabel),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Например: SALE10',
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
                onTap: () => Navigator.pop(context, controller.text.trim()),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBrown,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: Text('Применить', style: AppTextStyles.cartBarButton),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    controller.dispose();

    if (result != null) {
      setState(() {
        _promoCode = result.isEmpty ? null : result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final entries = cart.items.entries.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: entries.isEmpty
            ? const _EmptyCartState()
            : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).maybePop(),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: 44,
                              height: 44,
                              margin: const EdgeInsets.only(right: 12),
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Корзина',
                                  style: AppTextStyles.screenTitle,
                                ),
                                Text(
                                  '${cart.totalCount} ${pluralizeItems(cart.totalCount)}',
                                  style: AppTextStyles.rowLabelMuted,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final entry = entries[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: OrderItemTile(
                            product: entry.key,
                            quantity: entry.value,
                          ),
                        );
                      }, childCount: entries.length),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _PromoCodeRow(
                        code: _promoCode,
                        onTap: _editPromoCode,
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _CartSummary(
                        itemsTotal: cart.totalSum,
                        isPreorder: cart.isPreorder,
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                    sliver: SliverToBoxAdapter(
                      child: SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: () => _openCheckout(context),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 17),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBrown,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              cart.isPreorder
                                  ? 'Оформить предзаказ'
                                  : 'Оформить заказ',
                              style: AppTextStyles.cartBarButton,
                            ),
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

class _PromoCodeRow extends StatelessWidget {
  final String? code;
  final VoidCallback onTap;

  const _PromoCodeRow({required this.code, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasCode = code != null && code!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(
              hasCode ? Icons.check_circle : Icons.confirmation_number_outlined,
              size: 20,
              color: hasCode
                  ? AppColors.statusSuccessText
                  : AppColors.primaryBrown,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasCode ? 'Промокод $code применён' : 'Промокод',
                style: AppTextStyles.rowLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!hasCode)
              Text(
                'Применить',
                style: AppTextStyles.rowLabel.copyWith(
                  color: AppColors.linkAccent,
                ),
              ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final int itemsTotal;
  final bool isPreorder;

  const _CartSummary({required this.itemsTotal, required this.isPreorder});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row('Сумма товаров', formatPrice(itemsTotal)),
        const SizedBox(height: 8),
        _row(isPreorder ? 'Самовывоз' : 'Самовывоз', 'Бесплатно'),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1, color: AppColors.divider),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Итого', style: AppTextStyles.totalLabel),
            Text(formatPrice(itemsTotal), style: AppTextStyles.totalValue),
          ],
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.rowLabelMuted),
        Text(value, style: AppTextStyles.rowValue),
      ],
    );
  }
}

class _EmptyCartState extends StatelessWidget {
  const _EmptyCartState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.only(right: 12),
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
              Expanded(
                child: Text('Корзина', style: AppTextStyles.screenTitle),
              ),
            ],
          ),
          const Spacer(),
          Icon(
            Icons.shopping_bag_outlined,
            size: 40,
            color: AppColors.textSecondary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text('Корзина пуста', style: AppTextStyles.sectionLabel),
          const SizedBox(height: 6),
          Text(
            'Добавьте товары из каталога, '
            'чтобы оформить заказ',
            textAlign: TextAlign.center,
            style: AppTextStyles.rowLabelMuted,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
