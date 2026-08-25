import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  static const Color background = Color(0xFFF8F4EE);
  static const Color brown = Color(0xFF2E1C13);
  static const Color gold = Color(0xFFD6A54B);
  static const Color lightGold = Color(0xFFF7E3B8);
  static const Color muted = Color(0xFF9A8C7C);

  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loading = true;
  String? _error;

  String _userName = 'Пользователь';
  String _cardNumber = '—';
  int _bonusBalance = 0;
  int _cumulativePurchases = 0;
  String _level = 'Silver';

  List<_LoyaltyTransaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadLoyalty();
  }

  Future<void> _loadLoyalty() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Пользователь не авторизован');
      }

      // ------------------------------------------------------------
      // PROFILE
      // ------------------------------------------------------------

      final profile = await _supabase
          .from('profiles')
          .select('first_name, last_name, display_name')
          .eq('id', user.id)
          .maybeSingle();

      String userName = 'Пользователь';

      if (profile != null) {
        final displayName = profile['display_name']?.toString().trim();
        final firstName = profile['first_name']?.toString().trim();
        final lastName = profile['last_name']?.toString().trim();

        if (displayName != null && displayName.isNotEmpty) {
          userName = displayName;
        } else {
          final parts = <String>[
            if (firstName != null && firstName.isNotEmpty) firstName,
            if (lastName != null && lastName.isNotEmpty) lastName,
          ];

          if (parts.isNotEmpty) {
            userName = parts.join(' ');
          }
        }
      }

      // ------------------------------------------------------------
      // LOYALTY ACCOUNT
      // ------------------------------------------------------------

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
          .eq('user_id', user.id)
          .maybeSingle();

      if (account == null) {
        throw Exception('Для пользователя ещё не создана карта лояльности.');
      }

      final bonusBalance = _toInt(account['bonus_balance']);
      final cumulativePurchases = _toInt(account['cumulative_purchases']);

      final level = account['level']?.toString().trim();

      final cardNumber = account['card_number']?.toString().trim() ?? '';

      if (cardNumber.isEmpty) {
        throw Exception('У карты лояльности отсутствует номер.');
      }

      // ------------------------------------------------------------
      // TRANSACTIONS
      // ------------------------------------------------------------

      final transactionRows = await _supabase
          .from('loyalty_transactions')
          .select('''
            id,
            user_id,
            type,
            amount,
            description,
            order_id,
            created_at
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(20);

      final transactions = (transactionRows as List)
          .map(
            (row) =>
                _LoyaltyTransaction.fromMap(Map<String, dynamic>.from(row)),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _userName = userName;
        _cardNumber = cardNumber;
        _bonusBalance = bonusBalance;
        _cumulativePurchases = cumulativePurchases;
        _level = _normalizeLevel(level);
        _transactions = transactions;
        _loading = false;
      });
    } catch (error) {
      debugPrint('DEBUG loyalty LOAD ERROR: $error');

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _normalizeLevel(String? value) {
    switch (value?.toLowerCase()) {
      case 'silver':
        return 'Silver';
      case 'gold':
        return 'GOLD';
      case 'premium':
        return 'Premium';
      default:
        return 'Silver';
    }
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
  }

  int get _bonusPercent {
    switch (_level.toLowerCase()) {
      case 'premium':
        return 5;
      case 'gold':
        return 3;
      case 'silver':
      default:
        return 1;
    }
  }

  int? get _nextLevelTarget {
    switch (_level.toLowerCase()) {
      case 'silver':
        return 50000;
      case 'gold':
        return 150000;
      case 'premium':
        return null;
      default:
        return 50000;
    }
  }

  double get _levelProgress {
    final target = _nextLevelTarget;

    if (target == null) {
      return 1.0;
    }

    if (_cumulativePurchases <= 0) {
      return 0;
    }

    return (_cumulativePurchases / target).clamp(0.0, 1.0);
  }

  int? get _remainingToNextLevel {
    final target = _nextLevelTarget;

    if (target == null) {
      return null;
    }

    final remaining = target - _cumulativePurchases;

    return remaining > 0 ? remaining : 0;
  }

  List<_Privilege> get _privileges {
    switch (_level.toLowerCase()) {
      case 'premium':
        return const [
          _Privilege(
            iconAsset: 'assets/icons/gift.svg',
            title: 'Подарок ко дню рождения',
            description: 'Специальный подарок от «Всласть»',
          ),
          _Privilege(
            iconAsset: 'assets/icons/bread.svg',
            title: 'Ранний доступ к новинкам',
            description: 'Попробуйте новые продукты раньше остальных',
          ),
          _Privilege(
            iconAsset: 'assets/icons/premium.svg',
            title: 'Специальные предложения',
            description: 'Персональные предложения для вашего уровня',
          ),
          _Privilege(
            iconAsset: 'assets/icons/crown_1.svg',
            title: 'Приоритетный предзаказ',
            description: 'Закажите сезонные и праздничные коллекции заранее',
          ),
        ];

      case 'gold':
        return const [
          _Privilege(
            iconAsset: 'assets/icons/gift.svg',
            title: 'Подарок ко дню рождения',
            description: 'Специальный подарок от «Всласть»',
          ),
          _Privilege(
            iconAsset: 'assets/icons/bread.svg',
            title: 'Первыми узнаёте о новинках',
            description: 'Будьте среди первых, кто узнает о новинках',
          ),
          _Privilege(
            iconAsset: 'assets/icons/premium.svg',
            title: 'Персональные предложения',
            description: 'Специальные предложения для вашего уровня',
          ),
        ];

      case 'silver':
      default:
        return const [
          _Privilege(
            iconAsset: 'assets/icons/zvezda.svg',
            title: '1% бонусами с каждой покупки',
            description: 'Получайте бонусы за каждую покупку',
          ),
          _Privilege(
            iconAsset: 'assets/icons/premium.svg',
            title: 'Бонусы для следующих покупок',
            description: 'Используйте накопленные бонусы при оплате',
          ),
          _Privilege(
            iconAsset: 'assets/icons/crown_1.svg',
            title: 'Персональные предложения',
            description: 'Получайте специальные предложения «Всласть»',
          ),
        ];
    }
  }

  Future<void> _refresh() async {
    await _loadLoyalty();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: gold))
            : RefreshIndicator(
                color: gold,
                backgroundColor: Colors.white,
                onRefresh: _refresh,
                child: _error != null
                    ? _ErrorView(message: _error!, onRetry: _loadLoyalty)
                    : _buildContent(),
              ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),

          // КАРТА
          _buildLoyaltyCard(),

          const SizedBox(height: 10),

          // БАЛАНС + УРОВЕНЬ
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _BalanceCard(
                    balance: _bonusBalance,
                    approxValue: '≈ ${_formatThousands(_bonusBalance)} ₽',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _LevelCard(
                    levelName: _level,
                    current: _cumulativePurchases,
                    target: _nextLevelTarget,
                    progress: _levelProgress,
                    remaining: _remainingToNextLevel,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ПРИВИЛЕГИИ
          _buildPrivileges(),

          const SizedBox(height: 14),

          // ИСТОРИЯ
          _buildHistory(),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE7DFD2)),
            ),
            child: const Icon(
              Icons.chevron_left_rounded,
              color: brown,
              size: 20,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              'Карта лояльности',
              style: GoogleFonts.alice(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: brown,
              ),
            ),
          ),
        ),
        const SizedBox(width: 36),
      ],
    );
  }

  // ==============================================================
  // LOYALTY CARD
  // ==============================================================

  Widget _buildLoyaltyCard() {
    final theme = _cardTheme;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FullQrScreen(
              cardNumber: _cardNumber,
              userName: _userName,
              level: _level,
            ),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.gradient,
          ),
          border: theme.borderColor == null
              ? null
              : Border.all(color: theme.borderColor!, width: 1),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor,
              blurRadius: 22,
              offset: const Offset(0, 11),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 10,
              right: 10,
              child: SizedBox(
                width: 78,
                height: 48,
                child: Opacity(
                  opacity: theme.illustrationOpacity,
                  child: SvgPicture.asset(
                    'assets/images/bakery_illustration.svg',
                    fit: BoxFit.contain,
                    colorFilter: theme.illustrationColor == null
                        ? null
                        : ColorFilter.mode(
                            theme.illustrationColor!,
                            BlendMode.srcIn,
                          ),
                  ),
                ),
              ),
            ),

            // Декоративные точки
            Positioned(
              right: 28,
              bottom: 22,
              child: Opacity(
                opacity: .18,
                child: Row(
                  children: [
                    _dot(theme.accentColor),
                    const SizedBox(width: 5),
                    _dot(theme.accentColor),
                    const SizedBox(width: 5),
                    _dot(theme.accentColor),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Всласть',
                    style: GoogleFonts.alice(
                      color: theme.logoColor,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      height: 1,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    '— ${_level.toUpperCase()} —',
                    style: TextStyle(
                      color: theme.accentColor,
                      fontSize: 9,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_level.toUpperCase()} MEMBER',
                              style: TextStyle(
                                color: theme.accentColor,
                                fontSize: 9.5,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              _userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.alice(
                                color: theme.primaryText,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              '$_bonusPercent% бонусами',
                              style: TextStyle(
                                color: theme.primaryText,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            const SizedBox(height: 12),

                            Text(
                              '№ ${_formatCardNumber(_cardNumber)}',
                              style: TextStyle(
                                color: theme.secondaryText,
                                fontSize: 11,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Маленький QR прямо на карте.
                      // Нажатие на всю карту открывает большой QR.
                      Container(
                        width: 80,
                        height: 80,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.accentColor.withValues(alpha: .55),
                          ),
                        ),
                        child: QrImageView(
                          data: _qrData,
                          version: QrVersions.auto,
                          size: 68,
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Colors.black,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  // Единый формат для будущей интеграции с кассой.
  String get _qrData {
    final cleanCardNumber = _cardNumber.replaceAll(RegExp(r'\s+'), '');

    return 'VSLAST|CARD|$cleanCardNumber';
  }

  _LoyaltyCardTheme get _cardTheme {
    switch (_level.toLowerCase()) {
      case 'gold':
        return const _LoyaltyCardTheme(
          gradient: [Color(0xFFC89B3C), Color(0xFFE3C16F), Color(0xFFB98225)],
          primaryText: Color(0xFF2A1A0E),
          secondaryText: Color(0xFF4C3518),
          logoColor: Color(0xFF2A1A0E),
          accentColor: Color(0xFF6C4B19),
          shadowColor: Color(0x4D9C741E),
          borderColor: Color(0xFFEAD18A),
          illustrationColor: Color(0xFF5B401A),
          illustrationOpacity: .55,
        );

      case 'premium':
        return const _LoyaltyCardTheme(
          gradient: [Color(0xFF101010), Color(0xFF252525), Color(0xFF080808)],
          primaryText: Colors.white,
          secondaryText: Color(0xFFD8D0C5),
          logoColor: Color(0xFFF5E6C8),
          accentColor: Color(0xFFD6A54B),
          shadowColor: Color(0x59000000),
          borderColor: Color(0x665B4A32),
          illustrationColor: Color(0xFFD6A54B),
          illustrationOpacity: .38,
        );

      case 'silver':
      default:
        return const _LoyaltyCardTheme(
          gradient: [Color(0xFFE8E8E8), Color(0xFFC9CDD0), Color(0xFFF0F0F0)],
          primaryText: Color(0xFF252525),
          secondaryText: Color(0xFF5E6265),
          logoColor: Color(0xFF252525),
          accentColor: Color(0xFF62676B),
          shadowColor: Color(0x3D555555),
          borderColor: Color(0xFFEDEDED),
          illustrationColor: Color(0xFF5D6265),
          illustrationOpacity: .35,
        );
    }
  }

  // ==============================================================
  // PRIVILEGES
  // ==============================================================

  Widget _buildPrivileges() {
    final privileges = _privileges;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ваши привилегии',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: brown,
          ),
        ),

        const SizedBox(height: 8),

        for (int i = 0; i < privileges.length; i += 2) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _BenefitTile(privilege: privileges[i])),
                const SizedBox(width: 10),
                Expanded(
                  child: i + 1 < privileges.length
                      ? _BenefitTile(privilege: privileges[i + 1])
                      : const SizedBox(),
                ),
              ],
            ),
          ),
          if (i + 2 < privileges.length) const SizedBox(height: 8),
        ],
      ],
    );
  }

  // ==============================================================
  // HISTORY
  // ==============================================================

  Widget _buildHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'История начислений',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: brown,
          ),
        ),

        const SizedBox(height: 10),

        if (_transactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'История операций пока пуста',
              style: TextStyle(fontSize: 13, color: muted),
            ),
          )
        else
          ..._transactions.map(
            (transaction) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _HistoryTile(transaction: transaction),
            ),
          ),
      ],
    );
  }

  String _formatCardNumber(String value) {
    if (value.isEmpty || value == '—') {
      return '—';
    }

    final clean = value.replaceAll(RegExp(r'\s+'), '');

    final groups = <String>[];

    for (int i = 0; i < clean.length; i += 4) {
      final end = (i + 4).clamp(0, clean.length);
      groups.add(clean.substring(i, end));
    }

    return groups.join(' ');
  }
}

// ==================================================================
// CARD THEME
// ==================================================================

class _LoyaltyCardTheme {
  final List<Color> gradient;
  final Color primaryText;
  final Color secondaryText;
  final Color logoColor;
  final Color accentColor;
  final Color shadowColor;
  final Color? borderColor;
  final Color? illustrationColor;
  final double illustrationOpacity;

  const _LoyaltyCardTheme({
    required this.gradient,
    required this.primaryText,
    required this.secondaryText,
    required this.logoColor,
    required this.accentColor,
    required this.shadowColor,
    required this.borderColor,
    required this.illustrationColor,
    required this.illustrationOpacity,
  });
}

// ==================================================================
// BALANCE CARD
// ==================================================================

class _BalanceCard extends StatelessWidget {
  final int balance;
  final String approxValue;

  const _BalanceCard({required this.balance, required this.approxValue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              color: _LoyaltyScreenState.lightGold,
              shape: BoxShape.circle,
            ),
            child: _goldIcon('assets/icons/zvezda.svg', 18),
          ),

          const SizedBox(height: 5),

          const Text(
            'Ваш баланс',
            style: TextStyle(fontSize: 10.5, color: _LoyaltyScreenState.muted),
          ),

          const SizedBox(height: 3),

          Text(
            _formatThousands(balance),
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: _LoyaltyScreenState.brown,
              height: 1.05,
            ),
          ),

          const Text(
            'бонусов',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _LoyaltyScreenState.brown,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            approxValue,
            style: const TextStyle(
              fontSize: 10,
              color: _LoyaltyScreenState.muted,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// LEVEL CARD
// ==================================================================

class _LevelCard extends StatelessWidget {
  final String levelName;
  final int current;
  final int? target;
  final double progress;
  final int? remaining;

  const _LevelCard({
    required this.levelName,
    required this.current,
    required this.target,
    required this.progress,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final isPremium = levelName.toLowerCase() == 'premium';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              color: _LoyaltyScreenState.lightGold,
              shape: BoxShape.circle,
            ),
            child: _goldIcon('assets/icons/crown_1.svg', 18),
          ),

          const SizedBox(height: 5),

          const Text(
            'Ваш уровень',
            style: TextStyle(fontSize: 10.5, color: _LoyaltyScreenState.muted),
          ),

          const SizedBox(height: 2),

          Text(
            levelName,
            style: GoogleFonts.alice(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: _LoyaltyScreenState.brown,
            ),
          ),

          const SizedBox(height: 5),

          if (isPremium)
            const Text(
              'Вы достигли максимального уровня',
              style: TextStyle(
                fontSize: 9.5,
                color: _LoyaltyScreenState.muted,
                height: 1.2,
              ),
            )
          else
            Text(
              'До следующего уровня\n'
              'осталось ${_formatThousands(remaining ?? 0)} ₽',
              style: const TextStyle(
                fontSize: 9.5,
                color: _LoyaltyScreenState.muted,
                height: 1.2,
              ),
            ),

          const SizedBox(height: 6),

          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: const Color(0xFFF0E6D2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                _LoyaltyScreenState.brown,
              ),
            ),
          ),

          const SizedBox(height: 4),

          if (isPremium)
            Text(
              '${_formatThousands(current)} ₽',
              style: const TextStyle(
                fontSize: 9.5,
                color: _LoyaltyScreenState.muted,
              ),
            )
          else
            Text(
              '${_formatThousands(current)} / '
              '${_formatThousands(target ?? 0)} ₽',
              style: const TextStyle(
                fontSize: 9.5,
                color: _LoyaltyScreenState.muted,
              ),
            ),
        ],
      ),
    );
  }
}

// ==================================================================
// PRIVILEGE
// ==================================================================

class _Privilege {
  final String iconAsset;
  final String title;
  final String description;

  const _Privilege({
    required this.iconAsset,
    required this.title,
    required this.description,
  });
}

class _BenefitTile extends StatelessWidget {
  final _Privilege privilege;

  const _BenefitTile({required this.privilege});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              color: _LoyaltyScreenState.lightGold,
              shape: BoxShape.circle,
            ),
            child: _goldIcon(privilege.iconAsset, 18),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  privilege.title,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: _LoyaltyScreenState.brown,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  privilege.description,
                  style: const TextStyle(
                    fontSize: 9,
                    height: 1.2,
                    color: _LoyaltyScreenState.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// HISTORY
// ==================================================================

class _HistoryTile extends StatelessWidget {
  final _LoyaltyTransaction transaction;

  const _HistoryTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final positive = transaction.amount >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: positive
                  ? const Color(0xFFEAF6ED)
                  : const Color(0xFFF8E9E5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              positive ? Icons.add_rounded : Icons.remove_rounded,
              color: positive
                  ? const Color(0xFF2E9C56)
                  : const Color(0xFFB45A4C),
              size: 20,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _LoyaltyScreenState.brown,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.formattedDate,
                  style: const TextStyle(
                    fontSize: 10,
                    color: _LoyaltyScreenState.muted,
                  ),
                ),
              ],
            ),
          ),

          Text(
            '${positive ? '+' : ''}${transaction.amount}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: positive
                  ? const Color(0xFF2E9C56)
                  : const Color(0xFFB45A4C),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// TRANSACTION
// ==================================================================

class _LoyaltyTransaction {
  final String type;
  final int amount;
  final String? description;
  final DateTime createdAt;

  const _LoyaltyTransaction({
    required this.type,
    required this.amount,
    required this.description,
    required this.createdAt,
  });

  factory _LoyaltyTransaction.fromMap(Map<String, dynamic> map) {
    return _LoyaltyTransaction(
      type: map['type']?.toString() ?? '',
      amount: _parseAmount(map['amount']),
      description: map['description']?.toString(),
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  static int _parseAmount(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String get title {
    if (description != null && description!.trim().isNotEmpty) {
      return description!.trim();
    }

    switch (type.toLowerCase()) {
      case 'purchase':
      case 'accrual':
      case 'earn':
      case 'bonus':
      case 'credit':
        return 'Начисление бонусов';

      case 'redeem':
      case 'spend':
      case 'writeoff':
      case 'debit':
        return 'Оплата бонусами';

      case 'birthday':
        return 'Подарок ко дню рождения';

      default:
        return amount >= 0 ? 'Начисление бонусов' : 'Списание бонусов';
    }
  }

  String get formattedDate {
    final local = createdAt.toLocal();

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day.$month.${local.year}, '
        '$hour:$minute';
  }
}

// ==================================================================
// QR SCREEN
// ==================================================================

class FullQrScreen extends StatelessWidget {
  final String cardNumber;
  final String userName;
  final String level;

  const FullQrScreen({
    super.key,
    required this.cardNumber,
    required this.userName,
    required this.level,
  });

  String get _qrData {
    final cleanCardNumber = cardNumber.replaceAll(RegExp(r'\s+'), '');

    return 'VSLAST|CARD|$cleanCardNumber';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _LoyaltyScreenState.background,
      appBar: AppBar(
        backgroundColor: _LoyaltyScreenState.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'QR-код карты',
          style: TextStyle(
            color: _LoyaltyScreenState.brown,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: _LoyaltyScreenState.brown),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  userName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.alice(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: _LoyaltyScreenState.brown,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  '$level • Карта № ${_formatCardNumber(cardNumber)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _LoyaltyScreenState.muted,
                  ),
                ),

                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 390),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .08),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE8E0D5)),
                        ),
                        child: QrImageView(
                          data: _qrData,
                          version: QrVersions.auto,
                          size: 270,
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Colors.black,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Colors.black,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Покажите QR-код кассиру',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _LoyaltyScreenState.brown,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'Код содержит идентификатор вашей '
                        'карты лояльности',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: _LoyaltyScreenState.muted,
                        ),
                      ),

                      const SizedBox(height: 18),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: _LoyaltyScreenState.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '№ ${_formatCardNumber(cardNumber)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: _LoyaltyScreenState.brown,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// HELPERS
// ==================================================================

Widget _goldIcon(String asset, double size) {
  return SvgPicture.asset(
    asset,
    width: size,
    height: size,
    colorFilter: const ColorFilter.mode(
      _LoyaltyScreenState.brown,
      BlendMode.srcIn,
    ),
  );
}

String _formatThousands(int value) {
  final negative = value < 0;
  final digits = value.abs().toString();

  final buffer = StringBuffer();

  for (int i = 0; i < digits.length; i++) {
    if (i != 0 && (digits.length - i) % 3 == 0) {
      buffer.write(' ');
    }

    buffer.write(digits[i]);
  }

  return '${negative ? '-' : ''}$buffer';
}

String _formatCardNumber(String value) {
  if (value.isEmpty || value == '—') {
    return '—';
  }

  final clean = value.replaceAll(RegExp(r'\s+'), '');

  final groups = <String>[];

  for (int i = 0; i < clean.length; i += 4) {
    final end = (i + 4).clamp(0, clean.length);
    groups.add(clean.substring(i, end));
  }

  return groups.join(' ');
}

// ==================================================================
// ERROR
// ==================================================================

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.credit_card_off_rounded,
              size: 52,
              color: _LoyaltyScreenState.muted,
            ),

            const SizedBox(height: 16),

            const Text(
              'Не удалось загрузить карту',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _LoyaltyScreenState.brown,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: _LoyaltyScreenState.muted,
              ),
            ),

            const SizedBox(height: 18),

            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: _LoyaltyScreenState.brown,
                foregroundColor: Colors.white,
              ),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
