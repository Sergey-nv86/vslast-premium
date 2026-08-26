import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/order.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import '../widgets/order_item_tile.dart';
import '../widgets/selectable_option_card.dart';
import 'delivery_address_screen.dart';
import 'order_confirmation_screen.dart';

/// Экран «Оформление заказа».
///
/// Заказ создаётся через Supabase RPC:
/// create_order_from_cart
///
/// Источником истины для:
/// - номера заказа;
/// - суммы товаров;
/// - скидки за самовывоз;
/// - стоимости доставки;
/// - итоговой суммы
///
/// является PostgreSQL-функция create_order_from_cart().
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  /// Вся корзина становится предзаказом, если содержит
  /// хотя бы один товар с inStock == false.

  static const List<String> _timeSlots = [
    '11:00 – 12:00',
    '12:00 – 13:00',
    '13:00 – 14:00',
    '14:00 – 15:00',
    '15:00 – 16:00',
    '16:00 – 17:00',
    '17:00 – 18:00',
    '18:00 – 19:00',
  ];

  DeliveryMethod _deliveryMethod = DeliveryMethod.pickup;
  PaymentMethod _paymentMethod = PaymentMethod.onlineSbp;

  DateTime _pickupDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  late String _pickupTimeSlot;

  String? _comment;
  String? _deliveryAddress;

  bool _isSubmitting = false;

  // Процент скидки за самовывоз из public.order_settings.
  int _pickupDiscountPercent = 0;

  @override
  void initState() {
    super.initState();

    // 11:00–12:00 по умолчанию.
    _pickupTimeSlot = _timeSlots[0];
    _loadOrderSettings();
  }

  Future<void> _loadOrderSettings() async {
    try {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('order_settings')
          .select('pickup_discount')
          .eq('id', 1)
          .maybeSingle();

      if (!mounted || response == null) return;

      final value = response['pickup_discount'];

      final percent = value is num
          ? value.round()
          : int.tryParse(value.toString()) ?? 0;

      if (percent < 0 || percent > 100) return;

      setState(() {
        _pickupDiscountPercent = percent;
      });
    } catch (error) {
      debugPrint('Не удалось загрузить скидку за самовывоз: $error');
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _pickupDate.isBefore(now) ? now : _pickupDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );

    if (picked != null && mounted) {
      setState(() {
        _pickupDate = picked;
      });
    }
  }

  Future<void> _pickTimeSlot() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _TimeSlotSheet(slots: _timeSlots, selected: _pickupTimeSlot);
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _pickupTimeSlot = selected;
      });
    }
  }

  Future<void> _selectDelivery() async {
    final address = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => DeliveryAddressScreen(initialAddress: _deliveryAddress),
      ),
    );

    if (address != null && mounted) {
      setState(() {
        _deliveryMethod = DeliveryMethod.delivery;
        _deliveryAddress = address;
      });
    }
  }

  Future<void> _editComment() async {
    final controller = TextEditingController(text: _comment);

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

  /// Создание заказа через Supabase RPC.
  ///
  /// ВАЖНО:
  /// Номер заказа НЕ генерируется в Flutter.
  /// Его создаёт PostgreSQL через:
  ///
  /// nextval('public.orders_order_number_seq')
  ///
  /// внутри create_order_from_cart().
  Future<void> _submitOrder(CartProvider cart) async {
    if (_isSubmitting) return;

    if (cart.isEmpty) {
      _showError('Корзина пуста');
      return;
    }

    if (_deliveryMethod == DeliveryMethod.delivery &&
        (_deliveryAddress == null || _deliveryAddress!.trim().isEmpty)) {
      _showError('Укажите адрес доставки');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Для предзаказа дата и время являются общими для всей корзины
    // и выбираются в CartScreen через CartProvider.
    // Для обычного заказа используются значения CheckoutScreen.
    final orderDate = cart.isPreorder ? cart.preorderDate : _pickupDate;

    final orderTimeSlot = cart.isPreorder ? cart.preorderTime : _pickupTimeSlot;

    if (cart.isPreorder &&
        (orderDate == null || orderTimeSlot == null || orderTimeSlot.isEmpty)) {
      _showError('Выберите дату и время предзаказа');
      return;
    }

    try {
      final supabase = Supabase.instance.client;

      final response = await supabase.rpc(
        'create_order_from_cart',
        params: {
          'p_delivery_method': _deliveryMethod.name,
          'p_payment_method': _paymentMethod.name,

          // Для preorder дата и время берутся из CartProvider.
          // Для обычного заказа используются локальные значения Checkout.
          'p_pickup_date': orderDate!.toIso8601String().split('T').first,

          'p_pickup_time_slot': orderTimeSlot!,

          'p_delivery_address': _deliveryMethod == DeliveryMethod.delivery
              ? _deliveryAddress?.trim()
              : null,

          'p_comment': (_comment == null || _comment!.trim().isEmpty)
              ? null
              : _comment!.trim(),
        },
      );

      if (!mounted) return;

      if (response == null) {
        throw Exception('Сервер не вернул данные созданного заказа');
      }

      Map<String, dynamic> result;

      if (response is List && response.isNotEmpty) {
        result = Map<String, dynamic>.from(response.first as Map);
      } else if (response is Map) {
        result = Map<String, dynamic>.from(response);
      } else {
        throw Exception('Неожиданный формат ответа сервера');
      }

      final orderId = result['order_id']?.toString();

      if (orderId == null || orderId.isEmpty) {
        throw Exception('Сервер не вернул ID заказа');
      }

      final orderNumber = _parseInt(result['order_number']);

      final itemsTotal = _parseInt(result['items_total']);

      final pickupDiscount = _parseInt(result['pickup_discount']);

      final deliveryCost = _parseInt(result['delivery_cost']);

      final total = _parseInt(result['total']);

      if (orderNumber == null) {
        throw Exception('Сервер не вернул номер заказа');
      }

      if (itemsTotal == null) {
        throw Exception('Сервер не вернул сумму товаров');
      }

      if (pickupDiscount == null) {
        throw Exception('Сервер не вернул скидку за самовывоз');
      }

      if (deliveryCost == null) {
        throw Exception('Сервер не вернул стоимость доставки');
      }

      if (total == null) {
        throw Exception('Сервер не вернул итоговую сумму');
      }

      // Снимок товаров для экрана подтверждения.
      //
      // Сам заказ уже создан в БД.
      // Эти данные нужны только для отображения
      // пользователю на следующем экране.
      final items = cart.items.entries
          .map(
            (entry) =>
                OrderItemSnapshot(product: entry.key, quantity: entry.value),
          )
          .toList();

      final order = OrderSummary(
        orderId: orderId,
        orderNumber: orderNumber,
        createdAt: DateTime.now(),
        items: items,
        comment: _comment,
        deliveryMethod: _deliveryMethod,
        pickupDate: orderDate,
        pickupTimeSlot: orderTimeSlot,
        paymentMethod: _paymentMethod,
        deliveryAddress: _deliveryMethod == DeliveryMethod.delivery
            ? _deliveryAddress
            : null,
        itemsTotal: itemsTotal,
        pickupDiscount: pickupDiscount,
        deliveryCost: deliveryCost,
        total: total,
      );

      // Важно:
      // RPC уже удалил cart_items в БД.
      //
      // Теперь очищаем локальную корзину,
      // чтобы UI приложения соответствовал БД.
      cart.clearLocal();

      if (!mounted) return;

      // Проверяем серверную сумму.
      //
      // OrderSummary.total может быть рассчитан из локальных
      // товаров и deliveryCost, но сервер также учитывает
      // pickup_discount.
      //
      // Поэтому для диагностики выводим серверные значения.
      debugPrint(
        'ORDER CREATED: '
        'id=$orderId, '
        'number=$orderNumber, '
        'itemsTotal=$itemsTotal, '
        'pickupDiscount=$pickupDiscount, '
        'deliveryCost=$deliveryCost, '
        'total=$total',
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderConfirmationScreen(order: order),
        ),
      );
    } on PostgrestException catch (error) {
      if (!mounted) return;

      debugPrint(
        'create_order_from_cart PostgrestException: '
        'code=${error.code}, '
        'message=${error.message}, '
        'details=${error.details}, '
        'hint=${error.hint}',
      );

      _showError(_friendlySupabaseError(error));
    } catch (error, stackTrace) {
      if (!mounted) return;

      debugPrint('create_order_from_cart error: $error');

      debugPrint('create_order_from_cart stackTrace: $stackTrace');

      _showError('Не удалось оформить заказ. Попробуйте ещё раз.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  String _friendlySupabaseError(PostgrestException error) {
    final message = error.message.trim();

    if (message.isNotEmpty) {
      return message;
    }

    return 'Не удалось оформить заказ. Попробуйте ещё раз.';
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final entries = cart.items.entries.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: entries.isEmpty
            ? _EmptyCartState(onBack: () => Navigator.of(context).maybePop())
            : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    sliver: const SliverToBoxAdapter(child: _Header()),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Ваш заказ', style: AppTextStyles.sectionLabel),
                          Text(
                            '${cart.totalCount} '
                            '${pluralizeItems(cart.totalCount)}',
                            style: AppTextStyles.sectionCounter,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final entry = entries[index];

                        return Column(
                          children: [
                            OrderItemTile(
                              product: entry.key,
                              quantity: entry.value,
                            ),
                            if (index != entries.length - 1)
                              const Divider(
                                height: 1,
                                color: AppColors.divider,
                              ),
                          ],
                        );
                      }, childCount: entries.length),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _CommentRow(
                        comment: _comment,
                        onTap: _editComment,
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _Section(
                        title: 'Способ получения',
                        child: Row(
                          children: [
                            Expanded(
                              child: SelectableOptionCard(
                                icon: Icons.shopping_bag_outlined,
                                title: DeliveryMethod.pickup.title,
                                subtitle: DeliveryMethod.pickup.subtitle,
                                selected:
                                    _deliveryMethod == DeliveryMethod.pickup,
                                onTap: () {
                                  setState(() {
                                    _deliveryMethod = DeliveryMethod.pickup;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SelectableOptionCard(
                                icon: Icons.delivery_dining_outlined,
                                title: DeliveryMethod.delivery.title,
                                subtitle:
                                    _deliveryMethod ==
                                            DeliveryMethod.delivery &&
                                        _deliveryAddress != null
                                    ? _deliveryAddress!
                                    : DeliveryMethod.delivery.subtitle,
                                selected:
                                    _deliveryMethod == DeliveryMethod.delivery,
                                onTap: _selectDelivery,
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
                        title: 'Когда забрать',
                        child: Row(
                          children: [
                            Expanded(
                              child: _DropdownField(
                                icon: Icons.calendar_today_outlined,
                                label: cart.isPreorder
                                    ? (cart.preorderDate == null
                                          ? 'Дата из корзины'
                                          : formatPickupDateLabel(
                                              cart.preorderDate!,
                                            ))
                                    : formatPickupDateLabel(_pickupDate),
                                onTap: cart.isPreorder
                                    ? () {}
                                    : () {
                                        _pickDate();
                                      },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DropdownField(
                                icon: Icons.access_time,
                                label: cart.isPreorder
                                    ? (cart.preorderTime ?? 'Время из корзины')
                                    : _pickupTimeSlot,
                                onTap: cart.isPreorder
                                    ? () {}
                                    : () {
                                        _pickTimeSlot();
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
                      child: _Section(
                        title: 'Способ оплаты',
                        child: Row(
                          children: [
                            Expanded(
                              child: SelectableOptionCard(
                                icon: Icons.qr_code,
                                title: PaymentMethod.onlineSbp.title,
                                subtitle: 'Администратор выставит QR-код',
                                selected:
                                    _paymentMethod == PaymentMethod.onlineSbp,
                                onTap: () {
                                  setState(() {
                                    _paymentMethod = PaymentMethod.onlineSbp;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SelectableOptionCard(
                                icon: Icons.account_balance_wallet_outlined,
                                title: PaymentMethod.cash.title,
                                subtitle: PaymentMethod.cash.subtitle,
                                selected: _paymentMethod == PaymentMethod.cash,
                                onTap: () {
                                  setState(() {
                                    _paymentMethod = PaymentMethod.cash;
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
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _PriceSummary(
                        itemsTotal: cart.totalSum,
                        deliveryLabel: _deliveryMethod.title,
                        deliveryCost: _deliveryMethod == DeliveryMethod.pickup
                            ? 0
                            : null,
                        pickupDiscountPercent:
                            _deliveryMethod == DeliveryMethod.pickup
                            ? _pickupDiscountPercent
                            : 0,
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    sliver: const SliverToBoxAdapter(child: _InfoNote()),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    sliver: SliverToBoxAdapter(
                      child: SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: _isSubmitting
                              ? null
                              : () => _submitOrder(cart),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 17),
                            decoration: BoxDecoration(
                              color: _isSubmitting
                                  ? AppColors.primaryBrown.withValues(
                                      alpha: 0.6,
                                    )
                                  : AppColors.primaryBrown,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            alignment: Alignment.center,
                            child: _isSubmitting
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
                                    'Заказать',
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

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider, width: 1),
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
            'Оформление заказа',
            style: AppTextStyles.screenTitleSmall,
          ),
        ),
      ],
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

class _CommentRow extends StatelessWidget {
  final String? comment;
  final VoidCallback onTap;

  const _CommentRow({required this.comment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasComment = comment != null && comment!.isNotEmpty;

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
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.primaryBrown,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasComment ? comment! : 'Добавить комментарий к заказу',
                style: AppTextStyles.rowLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DropdownField({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primaryBrown),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.rowLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeSlotSheet extends StatelessWidget {
  final List<String> slots;
  final String selected;

  const _TimeSlotSheet({required this.slots, required this.selected});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Когда забрать', style: AppTextStyles.sectionLabel),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: slots.length,
                itemBuilder: (context, index) {
                  final slot = slots[index];

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(slot, style: AppTextStyles.rowLabel),
                    trailing: slot == selected
                        ? const Icon(Icons.check, color: AppColors.primaryBrown)
                        : null,
                    onTap: () => Navigator.pop(context, slot),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceSummary extends StatelessWidget {
  final int itemsTotal;
  final String deliveryLabel;

  /// null — «Уточняется».
  /// 0 — «Бесплатно».
  /// иначе — сумма.
  final int? deliveryCost;

  /// Процент скидки за самовывоз.
  final int pickupDiscountPercent;

  const _PriceSummary({
    required this.itemsTotal,
    required this.deliveryLabel,
    required this.deliveryCost,
    required this.pickupDiscountPercent,
  });

  @override
  Widget build(BuildContext context) {
    final pickupDiscount = pickupDiscountPercent > 0
        ? (itemsTotal * pickupDiscountPercent / 100).round()
        : 0;

    final total = itemsTotal - pickupDiscount + (deliveryCost ?? 0);

    final deliveryValue = deliveryCost == null
        ? 'Уточняется'
        : (deliveryCost == 0 ? 'Бесплатно' : formatPrice(deliveryCost!));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _row('Сумма товаров', formatPrice(itemsTotal)),
          const SizedBox(height: 8),
          _row(deliveryLabel, deliveryValue),

          if (pickupDiscount > 0) ...[
            const SizedBox(height: 8),
            _row('Скидка за самовывоз', '−${formatPrice(pickupDiscount)}'),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Итого', style: AppTextStyles.totalLabel),
              Text(formatPrice(total), style: AppTextStyles.totalValue),
            ],
          ),
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

class _InfoNote extends StatelessWidget {
  const _InfoNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 18,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Все заказы подтверждаются администратором. '
              'После подтверждения мы пришлём вам уведомление.',
              style: AppTextStyles.infoNote,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCartState extends StatelessWidget {
  final VoidCallback onBack;

  const _EmptyCartState({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          const _Header(),
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
            'Добавьте товары из каталога, чтобы оформить заказ',
            textAlign: TextAlign.center,
            style: AppTextStyles.rowLabelMuted,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
