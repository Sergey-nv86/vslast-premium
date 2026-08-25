import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminLoyaltyScreen extends StatefulWidget {
  const AdminLoyaltyScreen({super.key});

  @override
  State<AdminLoyaltyScreen> createState() => _AdminLoyaltyScreenState();
}

class _AdminLoyaltyScreenState extends State<AdminLoyaltyScreen> {
  static const Color bg = Color(0xFFF8F4EE);
  static const Color brown = Color(0xFF2E1C13);
  static const Color gold = Color(0xFFD6A54B);
  static const Color muted = Color(0xFF9A8C7C);
  static const Color border = Color(0xFFE7DFD2);

  final SupabaseClient _supabase = Supabase.instance.client;
  final MobileScannerController _scannerController = MobileScannerController();

  final TextEditingController _cardController = TextEditingController();
  final TextEditingController _purchaseAmountController =
      TextEditingController();
  final TextEditingController _redeemAmountController = TextEditingController();

  bool _loading = false;
  bool _scannerVisible = false;
  bool _cardFound = false;

  String? _error;
  String? _success;

  Map<String, dynamic>? _account;
  Map<String, dynamic>? _profile;

  @override
  void dispose() {
    _scannerController.dispose();
    _cardController.dispose();
    _purchaseAmountController.dispose();
    _redeemAmountController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // QR SCANNER
  // ------------------------------------------------------------

  void _openScanner() {
    FocusScope.of(context).unfocus();

    setState(() {
      _scannerVisible = true;
      _error = null;
      _success = null;
    });
  }

  void _closeScanner() {
    setState(() {
      _scannerVisible = false;
    });
  }

  Future<void> _onQrDetected(BarcodeCapture capture) async {
    if (!_scannerVisible || _loading) return;

    String? value;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();

      if (raw != null && raw.isNotEmpty) {
        value = raw;
        break;
      }
    }

    if (value == null || value.isEmpty) return;

    // QR карты может содержать просто VSL-12345678.
    // На будущее здесь можно будет принимать JSON от кассы.
    final cardNumber = _extractCardNumber(value);

    setState(() {
      _scannerVisible = false;
      _cardController.text = cardNumber;
    });

    await _findCard(cardNumber);
  }

  String _extractCardNumber(String value) {
    final clean = value.trim();

    // Простой QR:
    // VSL-89870620
    if (RegExp(r'^VSL-\d{8}$', caseSensitive: false).hasMatch(clean)) {
      return clean.toUpperCase();
    }

    // Если QR в будущем будет JSON:
    // {"card_number":"VSL-89870620"}
    try {
      final decoded = RegExp(
        r'"card_number"\s*:\s*"([^"]+)"',
        caseSensitive: false,
      ).firstMatch(clean);

      if (decoded != null) {
        return decoded.group(1)!.trim().toUpperCase();
      }
    } catch (_) {}

    return clean;
  }

  // ------------------------------------------------------------
  // SEARCH CARD
  // ------------------------------------------------------------

  Future<void> _findCard([String? value]) async {
    final cardNumber = (value ?? _cardController.text).trim();

    if (cardNumber.isEmpty) {
      _showError('Введите номер карты или отсканируйте QR-код.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
      _cardFound = false;
      _account = null;
      _profile = null;
    });

    try {
      final account = await _supabase
          .from('loyalty_accounts')
          .select('''
            id,
            user_id,
            card_number,
            bonus_balance,
            cumulative_purchases,
            level,
            created_at,
            updated_at
          ''')
          .eq('card_number', cardNumber.toUpperCase())
          .maybeSingle();

      if (account == null) {
        throw Exception('Карта $cardNumber не найдена.');
      }

      final userId = account['user_id']?.toString();

      Map<String, dynamic>? profile;

      if (userId != null && userId.isNotEmpty) {
        profile = await _supabase
            .from('profiles')
            .select('''
              id,
              first_name,
              last_name,
              display_name,
              phone,
              email,
              city
            ''')
            .eq('id', userId)
            .maybeSingle();
      }

      if (!mounted) return;

      setState(() {
        _account = Map<String, dynamic>.from(account);
        _profile = profile == null ? null : Map<String, dynamic>.from(profile);
        _cardFound = true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = _cleanError(e);
      });
    }
  }

  // ------------------------------------------------------------
  // ACCRUE
  // ------------------------------------------------------------

  Future<void> _accrueBonuses() async {
    if (!_cardFound || _account == null) {
      _showError('Сначала найдите карту.');
      return;
    }

    final amount = _parsePurchaseAmount();

    if (amount <= 0) {
      _showError('Введите сумму покупки.');
      return;
    }

    final confirmed = await _confirmAction(
      title: 'Начислить бонусы?',
      message:
          'Сумма покупки: ${_formatMoney(amount)} ₽\n'
          'Процент будет определён автоматически по уровню карты.',
      confirmText: 'Начислить',
    );

    if (!confirmed) return;

    await _executeRpc(
      rpcName: 'admin_loyalty_accrue',
      amount: amount,
      successPrefix: 'Бонусы успешно начислены.',
    );
  }

  // ------------------------------------------------------------
  // REDEEM
  // ------------------------------------------------------------

  Future<void> _redeemBonuses() async {
    if (!_cardFound || _account == null) {
      _showError('Сначала найдите карту.');
      return;
    }

    final amount = _parseRedeemAmount();

    if (amount <= 0) {
      _showError('Введите количество бонусов для списания.');
      return;
    }

    final currentBalance = _toInt(_account?['bonus_balance']);

    if (amount > currentBalance) {
      _showError(
        'Недостаточно бонусов. Доступно: ${_formatMoney(currentBalance)}.',
      );
      return;
    }

    final confirmed = await _confirmAction(
      title: 'Списать бонусы?',
      message:
          'Будет списано бонусов: ${_formatMoney(amount)}\n\n'
          'Текущий баланс: ${_formatMoney(currentBalance)}\n'
          'Новый баланс: ${_formatMoney(currentBalance - amount)}',
      confirmText: 'Списать',
    );

    if (!confirmed) return;

    await _executeRpc(
      rpcName: 'admin_loyalty_redeem',
      amount: amount,
      successPrefix: 'Бонусы успешно списаны.',
    );
  }

  // ------------------------------------------------------------
  // RPC
  // ------------------------------------------------------------

  Future<void> _executeRpc({
    required String rpcName,
    required int amount,
    required String successPrefix,
  }) async {
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      final cardNumber = _cardController.text.trim().toUpperCase();

      final result = await _supabase.rpc(
        rpcName,
        params: rpcName == 'admin_loyalty_redeem'
            ? {'p_card_number': cardNumber, 'p_bonus_amount': amount}
            : {'p_card_number': cardNumber, 'p_purchase_amount': amount},
      );

      if (!mounted) return;

      final data = _rpcMap(result);

      final bonusBalance = data?['bonus_balance'];
      final bonusAmount = data?['bonus_amount'];
      final level = data?['level'];

      String message = successPrefix;

      if (bonusAmount != null) {
        message += '\nБонусов: ${_formatMoney(_toInt(bonusAmount))}';
      }

      if (level != null) {
        message += '\nУровень: ${_levelName(level.toString())}';
      }

      if (bonusBalance != null) {
        message += '\nБаланс: ${_formatMoney(_toInt(bonusBalance))} бонусов';
      }

      setState(() {
        _loading = false;
        _success = message;
      });

      if (rpcName == 'admin_loyalty_redeem') {
        _redeemAmountController.clear();
      } else {
        _purchaseAmountController.clear();
      }

      await _findCard(cardNumber);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = _cleanError(e);
      });
    }
  }

  Map<String, dynamic>? _rpcMap(dynamic value) {
    if (value == null) return null;

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    if (value is List && value.isNotEmpty && value.first is Map) {
      return Map<String, dynamic>.from(value.first);
    }

    return null;
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _scannerVisible ? _buildScanner() : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: border),
              ),
              child: const Icon(Icons.chevron_left_rounded, color: brown),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Лояльность',
                style: TextStyle(
                  color: brown,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  Widget _buildScanner() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: _onQrDetected,
              ),
              Center(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 30,
                child: Column(
                  children: [
                    const Text(
                      'Наведите камеру на QR-код карты',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        shadows: [Shadow(blurRadius: 5, color: Colors.black54)],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Карта «Всласть»',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .9),
                        fontSize: 12,
                        shadows: const [
                          Shadow(blurRadius: 5, color: Colors.black54),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          color: bg,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: _closeScanner,
              style: OutlinedButton.styleFrom(
                foregroundColor: brown,
                side: const BorderSide(color: border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'Отмена',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScannerButton(),
          const SizedBox(height: 8),
          _buildManualCardSearch(),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _buildMessage(
              _error!,
              const Color(0xFFF8E9E5),
              const Color(0xFF9C4034),
            ),
          ],
          if (_success != null) ...[
            const SizedBox(height: 12),
            _buildMessage(
              _success!,
              const Color(0xFFEAF6ED),
              const Color(0xFF287D45),
            ),
          ],
          if (_cardFound) ...[
            const SizedBox(height: 8),
            _buildCustomerCard(),
            const SizedBox(height: 8),
            _buildOperationCard(),
          ],
          if (_loading) ...[
            const SizedBox(height: 10),
            const Center(child: CircularProgressIndicator(color: gold)),
          ],
        ],
      ),
    );
  }

  Widget _buildScannerButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : _openScanner,
        icon: const Icon(Icons.qr_code_scanner_rounded, size: 24),
        label: const Text(
          'Сканировать QR-код карты',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: brown,
          foregroundColor: Colors.white,
          disabledBackgroundColor: brown.withValues(alpha: .5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
      ),
    );
  }

  Widget _buildManualCardSearch() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Номер карты',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: brown,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cardController,
                  textCapitalization: TextCapitalization.characters,
                  onTap: () {
                    if (_cardController.text.isEmpty) {
                      _cardController.text = 'VSL-';
                      _cardController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _cardController.text.length),
                      );
                    }
                  },
                  onChanged: (value) {
                    final upper = value.toUpperCase();

                    if (!upper.startsWith('VSL-')) {
                      final digits = upper
                          .replaceFirst(RegExp(r'^VSL-?'), '')
                          .replaceAll(RegExp(r'[^0-9]'), '');

                      final result = 'VSL-$digits';

                      _cardController.value = TextEditingValue(
                        text: result,
                        selection: TextSelection.collapsed(
                          offset: result.length,
                        ),
                      );
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'VSL-00000000',
                    filled: true,
                    fillColor: bg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : () => _findCard(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text(
                    'Найти',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard() {
    final account = _account!;
    final profile = _profile;

    final level = account['level']?.toString() ?? 'silver';
    final bonusBalance = _toInt(account['bonus_balance']);
    final purchases = _toInt(account['cumulative_purchases']);

    final name = _profileName(profile);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _levelColor(level).withValues(alpha: .14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: _levelColor(level),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: brown,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      account['card_number']?.toString() ?? '—',
                      style: const TextStyle(
                        fontSize: 12,
                        letterSpacing: .8,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
              _LevelBadge(level: level),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: border),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _CustomerMetric(
                  label: 'Бонусы',
                  value: _formatMoney(bonusBalance),
                ),
              ),
              Container(width: 1, height: 35, color: border),
              Expanded(
                child: _CustomerMetric(
                  label: 'Покупки',
                  value: '${_formatMoney(purchases)} ₽',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOperationCard() {
    final level = _account?['level']?.toString() ?? 'silver';
    final percent = _bonusPercent(level);
    final currentBalance = _toInt(_account?['bonus_balance']);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Операции с бонусами',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: brown,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            'Уровень ${_levelName(level)} · начисление $percent%',
            style: const TextStyle(fontSize: 11, color: muted),
          ),

          const SizedBox(height: 7),

          const Text(
            'Начисление',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3D332C),
            ),
          ),

          const SizedBox(height: 2),

          const Text(
            'Укажите сумму покупки — бонусы рассчитаются автоматически.',
            style: TextStyle(fontSize: 10.5, height: 1.2, color: muted),
          ),

          const SizedBox(height: 6),

          TextField(
            controller: _purchaseAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            textInputAction: TextInputAction.done,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Сумма покупки',
              hintText: 'Например, 5000',
              suffixText: '₽',
              isDense: true,
              filled: true,
              fillColor: bg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 7),

          SizedBox(
            width: double.infinity,
            height: 43,
            child: ElevatedButton(
              onPressed: _loading ? null : _accrueBonuses,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D4A),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFB8C7BE),
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: const Text(
                'Начислить бонусы',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Container(height: 1, color: border),

          const SizedBox(height: 7),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Списание',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3D332C),
                  ),
                ),
              ),
              Text(
                'Баланс: ${_formatMoney(currentBalance)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: muted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 2),

          const Text(
            'Укажите количество бонусов, которое нужно списать.',
            style: TextStyle(fontSize: 10.5, height: 1.2, color: muted),
          ),

          const SizedBox(height: 6),

          TextField(
            controller: _redeemAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            textInputAction: TextInputAction.done,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Бонусы для списания',
              hintText: 'Например, 500',
              suffixText: 'бонусов',
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFFFF7F5),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE8C8C2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE8C8C2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFC94B3C),
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 7),

          SizedBox(
            width: double.infinity,
            height: 43,
            child: ElevatedButton(
              onPressed: _loading ? null : _redeemBonuses,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC43D32),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFD8AAA5),
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: const Text(
                'Списать бонусы',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'При списании уровень и накопленные покупки не изменяются.',
            style: TextStyle(fontSize: 9.5, height: 1.2, color: muted),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(String message, Color background, Color foreground) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: foreground,
          fontSize: 12.5,
          height: 1.35,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------

  int _parsePurchaseAmount() {
    final clean = _purchaseAmountController.text
        .replaceAll(' ', '')
        .replaceAll(',', '.');

    return double.tryParse(clean)?.round() ?? 0;
  }

  int _parseRedeemAmount() {
    final clean = _redeemAmountController.text
        .replaceAll(' ', '')
        .replaceAll(',', '.');

    return double.tryParse(clean)?.round() ?? 0;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _bonusPercent(String level) {
    switch (level.toLowerCase()) {
      case 'premium':
        return 5;
      case 'gold':
        return 3;
      case 'silver':
      default:
        return 1;
    }
  }

  String _levelName(String level) {
    switch (level.toLowerCase()) {
      case 'premium':
        return 'Premium';
      case 'gold':
        return 'GOLD';
      default:
        return 'Silver';
    }
  }

  Color _levelColor(String level) {
    switch (level.toLowerCase()) {
      case 'premium':
        return const Color(0xFF252525);
      case 'gold':
        return const Color(0xFFC79535);
      case 'silver':
      default:
        return const Color(0xFF7D858C);
    }
  }

  String _profileName(Map<String, dynamic>? profile) {
    if (profile == null) return 'Клиент';

    final displayName = profile['display_name']?.toString().trim();

    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final first = profile['first_name']?.toString().trim() ?? '';
    final last = profile['last_name']?.toString().trim() ?? '';

    final parts = <String>[
      if (first.isNotEmpty) first,
      if (last.isNotEmpty) last,
    ];

    return parts.isEmpty ? 'Клиент' : parts.join(' ');
  }

  String _formatMoney(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(' ');
      }

      buffer.write(digits[i]);
    }

    return '${value < 0 ? '-' : ''}$buffer';
  }

  String _cleanError(Object error) {
    var text = error.toString();

    text = text.replaceFirst('PostgrestException(message: ', '');
    text = text.replaceFirst('Exception: ', '');

    return text;
  }

  void _showError(String message) {
    if (!mounted) return;

    setState(() {
      _error = message;
      _success = null;
    });
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmText,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            title,
            style: const TextStyle(color: brown, fontWeight: FontWeight.w700),
          ),
          content: Text(
            message,
            style: const TextStyle(color: muted, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена', style: TextStyle(color: muted)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: brown,
                foregroundColor: Colors.white,
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result == true;
  }
}

// ------------------------------------------------------------
// SMALL UI COMPONENTS
// ------------------------------------------------------------

class _LevelBadge extends StatelessWidget {
  final String level;

  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final color = _color(level);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _name(level),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  static String _name(String level) {
    switch (level.toLowerCase()) {
      case 'premium':
        return 'PREMIUM';
      case 'gold':
        return 'GOLD';
      default:
        return 'SILVER';
    }
  }

  static Color _color(String level) {
    switch (level.toLowerCase()) {
      case 'premium':
        return const Color(0xFF252525);
      case 'gold':
        return const Color(0xFFC79535);
      default:
        return const Color(0xFF7D858C);
    }
  }
}

class _CustomerMetric extends StatelessWidget {
  final String label;
  final String value;

  const _CustomerMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: _AdminLoyaltyScreenState.brown,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: _AdminLoyaltyScreenState.muted,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}
