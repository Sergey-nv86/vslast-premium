import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/order_item_tile.dart';
import 'checkout_screen.dart';

/// Корзина.
///
/// В одной корзине могут находиться одновременно товары в наличии и
/// товары с признаком предзаказа. Бизнес-правила корзины не изменяются.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String? _promoCode;

  void _openCheckout(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    );
  }

  Future<void> _editPromoCode() async {
    final controller = TextEditingController(text: _promoCode);

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                prefixIcon: const Icon(Icons.local_offer_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primaryBrown),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _PrimaryButton(
              label: 'Применить',
              onTap: () => Navigator.pop(context, controller.text.trim()),
            ),
          ],
        ),
      ),
    );

    controller.dispose();

    if (result != null) {
      setState(() => _promoCode = result.isEmpty ? null : result);
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
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          _BackButton(onTap: () => Navigator.of(context).maybePop()),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Корзина', style: AppTextStyles.screenTitle),
                                const SizedBox(height: 2),
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
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final entry = entries[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0F1A1A1A),
                                  blurRadius: 20,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: OrderItemTile(
                              product: entry.key,
                              quantity: entry.value,
                            ),
                          );
                        },
                        childCount: entries.length,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _PromoCodeRow(code: _promoCode, onTap: _editPromoCode),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _CartSummary(
                        itemsTotal: cart.totalSum,
                        isPreorder: cart.isPreorder,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                    sliver: SliverToBoxAdapter(
                      child: _PrimaryButton(
                        label: cart.isPreorder ? 'Оформить предзаказ' : 'Оформить заказ',
                        onTap: () => _openCheckout(context),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Назад',
      child: Material(
        color: AppColors.surface,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 19, color: AppColors.primaryBrown),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: AppColors.primaryBrown,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Text(label, style: AppTextStyles.cartBarButton),
          ),
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
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(
                hasCode ? Icons.check_circle_outline : Icons.local_offer_outlined,
                size: 21,
                color: hasCode ? AppColors.statusSuccessText : AppColors.primaryBrown,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasCode ? 'Промокод $code применён' : 'Добавить промокод',
                  style: AppTextStyles.rowLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!hasCode)
                Text(
                  'Применить',
                  style: AppTextStyles.rowLabel.copyWith(color: AppColors.primaryBrown),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
            ],
          ),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _row('Сумма товаров', formatPrice(itemsTotal)),
          const SizedBox(height: 10),
          _row('Самовывоз', 'Бесплатно'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Итого', style: AppTextStyles.totalLabel),
              Text(formatPrice(itemsTotal), style: AppTextStyles.totalValue),
            ],
          ),
          if (isPreorder) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.event_available_outlined, size: 17, color: AppColors.primaryBrown),
                const SizedBox(width: 7),
                Text('В корзине есть товар для предзаказа', style: AppTextStyles.rowLabelMuted),
              ],
            ),
          ],
        ],
      ),
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        children: [
          Row(
            children: [
              _BackButton(onTap: () => Navigator.of(context).maybePop()),
              const SizedBox(width: 12),
              Expanded(child: Text('Корзина', style: AppTextStyles.screenTitle)),
            ],
          ),
          const Spacer(),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(Icons.shopping_bag_outlined, size: 30, color: AppColors.primaryBrown),
          ),
          const SizedBox(height: 18),
          Text('Корзина пуста', style: AppTextStyles.sectionLabel),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              'Добавьте товары из каталога, чтобы оформить заказ.',
              textAlign: TextAlign.center,
              style: AppTextStyles.rowLabelMuted,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
