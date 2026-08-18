enum LoyaltyLevel { silver, gold, premium }

class LoyaltyLevelInfo {
  final LoyaltyLevel level;
  final String name;
  final int bonusPercent;
  final int? minPurchases;
  final int? maxPurchases;

  const LoyaltyLevelInfo({
    required this.level,
    required this.name,
    required this.bonusPercent,
    this.minPurchases,
    this.maxPurchases,
  });

  bool get isPremium => level == LoyaltyLevel.premium;

  static const silver = LoyaltyLevelInfo(
    level: LoyaltyLevel.silver,
    name: 'SILVER',
    bonusPercent: 2,
    minPurchases: 0,
    maxPurchases: 30000,
  );

  static const gold = LoyaltyLevelInfo(
    level: LoyaltyLevel.gold,
    name: 'GOLD',
    bonusPercent: 3,
    minPurchases: 30001,
    maxPurchases: 100000,
  );

  static const premium = LoyaltyLevelInfo(
    level: LoyaltyLevel.premium,
    name: 'PREMIUM',
    bonusPercent: 5,
    minPurchases: 100001,
    maxPurchases: null,
  );

  static LoyaltyLevelInfo fromPurchases(int amount) {
    if (amount >= 100001) {
      return premium;
    }

    if (amount >= 30001) {
      return gold;
    }

    return silver;
  }

  String get bonusDescription => '$bonusPercent% бонусами';

  String get rangeDescription {
    switch (level) {
      case LoyaltyLevel.silver:
        return 'До 30 000 ₽';
      case LoyaltyLevel.gold:
        return '30 001–100 000 ₽';
      case LoyaltyLevel.premium:
        return 'От 100 001 ₽';
    }
  }
}

class LoyaltyAccount {
  final String clientName;
  final String cardNumber;
  final int bonusBalance;
  final int cumulativePurchases;

  const LoyaltyAccount({
    required this.clientName,
    required this.cardNumber,
    required this.bonusBalance,
    required this.cumulativePurchases,
  });

  LoyaltyLevelInfo get level =>
      LoyaltyLevelInfo.fromPurchases(cumulativePurchases);

  int? get nextLevelThreshold {
    switch (level.level) {
      case LoyaltyLevel.silver:
        return 30001;
      case LoyaltyLevel.gold:
        return 100001;
      case LoyaltyLevel.premium:
        return null;
    }
  }

  int? get purchasesToNextLevel {
    final target = nextLevelThreshold;

    if (target == null) {
      return null;
    }

    final remaining = target - cumulativePurchases;

    return remaining > 0 ? remaining : 0;
  }

  double get progressToNextLevel {
    switch (level.level) {
      case LoyaltyLevel.silver:
        return (cumulativePurchases / 30001).clamp(0.0, 1.0);

      case LoyaltyLevel.gold:
        return ((cumulativePurchases - 30001) / (100001 - 30001)).clamp(
          0.0,
          1.0,
        );

      case LoyaltyLevel.premium:
        return 1.0;
    }
  }
}
