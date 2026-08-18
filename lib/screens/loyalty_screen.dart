import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/loyalty_level.dart';

class LoyaltyScreen extends StatelessWidget {
  const LoyaltyScreen({super.key});

  static const background = Color(0xFFFAF7F1);
  static const text = Color(0xFF201C1A);
  static const muted = Color(0xFF81766B);
  static const divider = Color(0xFFE8E0D5);

  // Демонстрационные данные.
  //
  // В дальнейшем эти значения будут приходить из профиля клиента / Firebase.
  static const LoyaltyAccount account = LoyaltyAccount(
    clientName: 'Сергей Кolesников',
    cardNumber: '000 123 456',
    bonusBalance: 1250,
    cumulativePurchases: 1250,
  );

  @override
  Widget build(BuildContext context) {
    final level = account.level;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(onBack: () => Navigator.of(context).maybePop()),

                  const SizedBox(height: 18),

                  _PremiumCard(account: account),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Баланс',
                          value: '${_format(account.bonusBalance)} Б',
                          subtitle: '≈ ${_format(account.bonusBalance)} ₽',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.shopping_bag_outlined,
                          title: 'Покупки',
                          value: '${_format(account.cumulativePurchases)} ₽',
                          subtitle: level.rangeDescription,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  _SectionTitle(title: 'Ваш уровень'),

                  const SizedBox(height: 10),

                  _LevelStatusCard(account: account),

                  const SizedBox(height: 22),

                  _SectionTitle(title: 'Система бонусов'),

                  const SizedBox(height: 10),

                  const _TierRow(
                    level: LoyaltyLevel.silver,
                    range: 'до 30 000 ₽',
                    bonus: '2%',
                  ),

                  const SizedBox(height: 8),

                  const _TierRow(
                    level: LoyaltyLevel.gold,
                    range: '30 001–100 000 ₽',
                    bonus: '3%',
                  ),

                  const SizedBox(height: 8),

                  const _TierRow(
                    level: LoyaltyLevel.premium,
                    range: 'от 100 001 ₽',
                    bonus: '5%',
                  ),

                  const SizedBox(height: 22),

                  _SectionTitle(
                    title: 'Ваши привилегии',
                    action: 'Все привилегии',
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: const [
                      Expanded(
                        child: _BenefitTile(
                          icon: Icons.card_giftcard_outlined,
                          title: 'Подарок ко дню рождения',
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _BenefitTile(
                          icon: Icons.new_releases_outlined,
                          title: 'Ранний доступ к новинкам',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: const [
                      Expanded(
                        child: _BenefitTile(
                          icon: Icons.auto_awesome_outlined,
                          title: 'Персональные предложения',
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _BenefitTile(
                          icon: Icons.workspace_premium_outlined,
                          title: 'Приоритетный предзаказ',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  _SectionTitle(
                    title: 'История начислений',
                    action: 'Вся история',
                    onAction: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FullHistoryScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  const _HistoryTile(
                    title: 'Покупка',
                    date: 'Сегодня, 10:30',
                    amount: '+120',
                    balance: '1 250',
                    positive: true,
                  ),

                  const SizedBox(height: 8),

                  const _HistoryTile(
                    title: 'Покупка',
                    date: 'Вчера, 16:45',
                    amount: '+350',
                    balance: '1 130',
                    positive: true,
                  ),

                  const SizedBox(height: 8),

                  const _HistoryTile(
                    title: 'Оплата бонусами',
                    date: '12 августа, 14:20',
                    amount: '−200',
                    balance: '780',
                    positive: false,
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const FullQrScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.qr_code_2_rounded, size: 21),
                      label: const Text(
                        'Показать QR кассиру',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: text,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _format(int value) {
    final source = value.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < source.length; i++) {
      if (i > 0 && (source.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(source[i]);
    }

    return buffer.toString();
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: LoyaltyScreen.divider),
            ),
            child: const Icon(
              Icons.chevron_left_rounded,
              color: LoyaltyScreen.text,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              'Карта лояльности',
              style: GoogleFonts.alice(
                color: LoyaltyScreen.text,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }
}

class _PremiumCard extends StatelessWidget {
  final LoyaltyAccount account;

  const _PremiumCard({required this.account});

  @override
  Widget build(BuildContext context) {
    final level = account.level.level;

    final isSilver = level == LoyaltyLevel.silver;
    final isGold = level == LoyaltyLevel.gold;

    final background = isSilver
        ? const Color(0xFFD9DDE0)
        : isGold
        ? const Color(0xFFCDAA54)
        : const Color(0xFF111111);

    final foreground = isSilver || isGold
        ? const Color(0xFF201C1A)
        : Colors.white;

    final secondary = isSilver || isGold
        ? const Color(0xFF5F574F)
        : Colors.white70;

    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const FullQrScreen()));
      },
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 205),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .10),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: foreground.withValues(alpha: .05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 19, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'ВСЛАСТЬ',
                        style: GoogleFonts.alice(
                          color: foreground,
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .5,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        account.level.name,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 52),

                  Text(
                    account.clientName,
                    style: GoogleFonts.alice(
                      color: foreground,
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    '№ ${account.cardNumber}',
                    style: TextStyle(
                      color: secondary,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Text(
                        '${account.level.bonusPercent}%',
                        style: TextStyle(
                          color: foreground,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'бонусов с покупки',
                        style: TextStyle(
                          color: secondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 54,
                        height: 54,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Image.asset(
                          'assets/images/qr_demo.png',
                          fit: BoxFit.contain,
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
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LoyaltyScreen.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: LoyaltyScreen.text),
          const SizedBox(height: 9),
          Text(
            title,
            style: const TextStyle(color: LoyaltyScreen.muted, fontSize: 11),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: LoyaltyScreen.text,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: LoyaltyScreen.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _LevelStatusCard extends StatelessWidget {
  final LoyaltyAccount account;

  const _LevelStatusCard({required this.account});

  @override
  Widget build(BuildContext context) {
    final level = account.level;

    if (level.isPremium) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Максимальный уровень',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Вы получаете ${level.bonusPercent}% бонусов с каждой покупки',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final remaining = account.purchasesToNextLevel ?? 0;
    final target = account.nextLevelThreshold ?? 0;

    final nextLevel = level.level == LoyaltyLevel.silver
        ? LoyaltyLevelInfo.gold
        : LoyaltyLevelInfo.premium;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LoyaltyScreen.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                color: LoyaltyScreen.text,
                size: 21,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'До уровня ${nextLevel.name}',
                  style: const TextStyle(
                    color: LoyaltyScreen.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${_format(remaining)} ₽',
                style: const TextStyle(
                  color: LoyaltyScreen.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: account.progressToNextLevel,
              minHeight: 7,
              backgroundColor: const Color(0xFFEDE7DE),
              valueColor: const AlwaysStoppedAnimation(LoyaltyScreen.text),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Порог следующего уровня: ${_format(target)} ₽',
            style: const TextStyle(color: LoyaltyScreen.muted, fontSize: 10.5),
          ),
        ],
      ),
    );
  }

  static String _format(int value) {
    final source = value.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < source.length; i++) {
      if (i > 0 && (source.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(source[i]);
    }

    return buffer.toString();
  }
}

class _TierRow extends StatelessWidget {
  final LoyaltyLevel level;
  final String range;
  final String bonus;

  const _TierRow({
    required this.level,
    required this.range,
    required this.bonus,
  });

  @override
  Widget build(BuildContext context) {
    final info = switch (level) {
      LoyaltyLevel.silver => LoyaltyLevelInfo.silver,
      LoyaltyLevel.gold => LoyaltyLevelInfo.gold,
      LoyaltyLevel.premium => LoyaltyLevelInfo.premium,
    };

    final color = switch (level) {
      LoyaltyLevel.silver => const Color(0xFFD9DDE0),
      LoyaltyLevel.gold => const Color(0xFFCDAA54),
      LoyaltyLevel.premium => const Color(0xFF111111),
    };

    final textColor = level == LoyaltyLevel.premium
        ? Colors.white
        : LoyaltyScreen.text;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LoyaltyScreen.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(
              Icons.workspace_premium_rounded,
              size: 19,
              color: textColor,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.name,
                  style: const TextStyle(
                    color: LoyaltyScreen.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .7,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  range,
                  style: const TextStyle(
                    color: LoyaltyScreen.muted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            bonus,
            style: const TextStyle(
              color: LoyaltyScreen.text,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const _SectionTitle({
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.alice(
            color: LoyaltyScreen.text,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              child: Text(
                action!,
                style: const TextStyle(
                  color: LoyaltyScreen.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BenefitTile extends StatelessWidget {
  final IconData icon;
  final String title;

  const _BenefitTile({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LoyaltyScreen.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFF1ECE3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: LoyaltyScreen.text),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: LoyaltyScreen.text,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final String title;
  final String date;
  final String amount;
  final String balance;
  final bool positive;

  const _HistoryTile({
    required this.title,
    required this.date,
    required this.amount,
    required this.balance,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LoyaltyScreen.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: positive
                  ? const Color(0xFFE8F3EA)
                  : const Color(0xFFF7E9E5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              positive ? Icons.add_rounded : Icons.remove_rounded,
              size: 18,
              color: positive
                  ? const Color(0xFF31834A)
                  : const Color(0xFFB75A4A),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: LoyaltyScreen.text,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: const TextStyle(
                    color: LoyaltyScreen.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  color: positive
                      ? const Color(0xFF31834A)
                      : const Color(0xFFB75A4A),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$balance Б',
                style: const TextStyle(
                  color: LoyaltyScreen.muted,
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}



class FullHistoryScreen extends StatefulWidget {
  const FullHistoryScreen({super.key});

  @override
  State<FullHistoryScreen> createState() => _FullHistoryScreenState();
}

enum _HistoryFilter {
  all,
  earn,
  spend,
}

class _FullHistoryScreenState extends State<FullHistoryScreen> {
  _HistoryFilter _selectedFilter = _HistoryFilter.all;

  static const List<_HistoryItemData> _items = [
    _HistoryItemData(
      title: 'Покупка',
      date: 'Сегодня, 10:30',
      amount: '+120',
      balance: '1 250',
      positive: true,
    ),
    _HistoryItemData(
      title: 'Покупка',
      date: 'Вчера, 16:45',
      amount: '+350',
      balance: '1 130',
      positive: true,
    ),
    _HistoryItemData(
      title: 'Оплата бонусами',
      date: '12 августа, 14:20',
      amount: '−200',
      balance: '780',
      positive: false,
    ),
    _HistoryItemData(
      title: 'Покупка',
      date: '8 августа, 12:15',
      amount: '+620',
      balance: '980',
      positive: true,
    ),
    _HistoryItemData(
      title: 'Бонус за день рождения',
      date: '3 августа, 09:00',
      amount: '+1 000',
      balance: '360',
      positive: true,
    ),
  ];

  List<_HistoryItemData> get _filteredItems {
    switch (_selectedFilter) {
      case _HistoryFilter.all:
        return _items;

      case _HistoryFilter.earn:
        return _items
            .where((item) => item.positive)
            .toList();

      case _HistoryFilter.spend:
        return _items
            .where((item) => !item.positive)
            .toList();
    }
  }

  void _selectFilter(_HistoryFilter filter) {
    if (_selectedFilter == filter) {
      return;
    }

    setState(() {
      _selectedFilter = filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems;

    return Scaffold(
      backgroundColor: LoyaltyScreen.background,
      appBar: AppBar(
        backgroundColor: LoyaltyScreen.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 19,
          ),
          color: LoyaltyScreen.text,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'История начислений',
          style: GoogleFonts.alice(
            color: LoyaltyScreen.text,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: _HistoryFilterChip(
                  title: 'Все',
                  selected: _selectedFilter == _HistoryFilter.all,
                  onTap: () => _selectFilter(_HistoryFilter.all),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HistoryFilterChip(
                  title: 'Начисления',
                  selected: _selectedFilter == _HistoryFilter.earn,
                  onTap: () => _selectFilter(_HistoryFilter.earn),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HistoryFilterChip(
                  title: 'Списания',
                  selected: _selectedFilter == _HistoryFilter.spend,
                  onTap: () => _selectFilter(_HistoryFilter.spend),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          if (filteredItems.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 32,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: LoyaltyScreen.divider,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 30,
                    color: LoyaltyScreen.muted,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Операций пока нет',
                    style: const TextStyle(
                      color: LoyaltyScreen.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else
            ...List.generate(
              filteredItems.length,
              (index) {
                final item = filteredItems[index];

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == filteredItems.length - 1
                        ? 0
                        : 8,
                  ),
                  child: _HistoryTile(
                    title: item.title,
                    date: item.date,
                    amount: item.amount,
                    balance: item.balance,
                    positive: item.positive,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _HistoryItemData {
  final String title;
  final String date;
  final String amount;
  final String balance;
  final bool positive;

  const _HistoryItemData({
    required this.title,
    required this.date,
    required this.amount,
    required this.balance,
    required this.positive,
  });
}

class _HistoryFilterChip extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _HistoryFilterChip({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? LoyaltyScreen.text
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? LoyaltyScreen.text
                : LoyaltyScreen.divider,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selected
                ? Colors.white
                : LoyaltyScreen.text,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class FullQrScreen extends StatelessWidget {
  const FullQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final account = LoyaltyScreen.account;

    return Scaffold(
      backgroundColor: LoyaltyScreen.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: LoyaltyScreen.divider),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: LoyaltyScreen.text,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'QR-код',
                        style: GoogleFonts.alice(
                          color: LoyaltyScreen.text,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),

              const Spacer(),

              Text(
                'Покажите QR кассиру',
                style: GoogleFonts.alice(
                  color: LoyaltyScreen.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Карта ${account.level.name} · ${account.level.bonusPercent}% бонусов',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: LoyaltyScreen.muted,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 28),

              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: LoyaltyScreen.divider),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .07),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/qr_demo.png',
                  width: 260,
                  height: 260,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 22),

              Text(
                account.clientName,
                style: GoogleFonts.alice(
                  color: LoyaltyScreen.text,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                '№ ${account.cardNumber}',
                style: const TextStyle(
                  color: LoyaltyScreen.muted,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LoyaltyScreen.text,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  child: const Text(
                    'Закрыть',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
