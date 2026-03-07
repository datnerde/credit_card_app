import 'package:uuid/uuid.dart';
import 'spending_category.dart';
import 'point_type.dart';
import 'card_type.dart';

const _uuid = Uuid();

class CreditCard {
  final String id;
  String name;
  CardType cardType;
  List<RewardCategory> rewardCategories;
  QuarterlyBonus? quarterlyBonus;
  List<SpendingLimit> spendingLimits;
  bool isActive;
  final DateTime createdAt;
  DateTime updatedAt;

  CreditCard({
    String? id,
    required this.name,
    required this.cardType,
    List<RewardCategory>? rewardCategories,
    this.quarterlyBonus,
    List<SpendingLimit>? spendingLimits,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        rewardCategories = (rewardCategories != null && rewardCategories.isNotEmpty)
            ? rewardCategories
            : cardType.defaultRewards,
        spendingLimits = spendingLimits ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'cardType': cardType.name,
        'rewardCategories': rewardCategories.map((r) => r.toJson()).toList(),
        'quarterlyBonus': quarterlyBonus?.toJson(),
        'spendingLimits': spendingLimits.map((s) => s.toJson()).toList(),
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CreditCard.fromJson(Map<String, dynamic> json) {
    final ct = CardType.values.firstWhere(
      (e) => e.name == json['cardType'],
      orElse: () => CardType.custom,
    );
    return CreditCard(
      id: json['id'] as String,
      name: json['name'] as String,
      cardType: ct,
      rewardCategories: (json['rewardCategories'] as List?)
              ?.map((r) => RewardCategory.fromJson(r as Map<String, dynamic>))
              .toList() ??
          ct.defaultRewards,
      quarterlyBonus: json['quarterlyBonus'] != null
          ? QuarterlyBonus.fromJson(json['quarterlyBonus'] as Map<String, dynamic>)
          : null,
      spendingLimits: (json['spendingLimits'] as List?)
              ?.map((s) => SpendingLimit.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  CreditCard copyWith({
    String? name,
    CardType? cardType,
    List<RewardCategory>? rewardCategories,
    QuarterlyBonus? quarterlyBonus,
    List<SpendingLimit>? spendingLimits,
    bool? isActive,
  }) {
    return CreditCard(
      id: id,
      name: name ?? this.name,
      cardType: cardType ?? this.cardType,
      rewardCategories: rewardCategories ?? this.rewardCategories,
      quarterlyBonus: quarterlyBonus ?? this.quarterlyBonus,
      spendingLimits: spendingLimits ?? this.spendingLimits,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class RewardCategory {
  final String id;
  SpendingCategory category;
  double multiplier;
  PointType pointType;
  bool isActive;

  RewardCategory({
    String? id,
    required this.category,
    required this.multiplier,
    required this.pointType,
    this.isActive = true,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'multiplier': multiplier,
        'pointType': pointType.name,
        'isActive': isActive,
      };

  factory RewardCategory.fromJson(Map<String, dynamic> json) {
    return RewardCategory(
      id: json['id'] as String,
      category: SpendingCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => SpendingCategory.general,
      ),
      multiplier: (json['multiplier'] as num).toDouble(),
      pointType: PointType.values.firstWhere(
        (e) => e.name == json['pointType'],
        orElse: () => PointType.cashBack,
      ),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class QuarterlyBonus {
  SpendingCategory category;
  double multiplier;
  PointType pointType;
  double limit;
  double currentSpending;
  int quarter;
  int year;

  QuarterlyBonus({
    required this.category,
    required this.multiplier,
    required this.pointType,
    required this.limit,
    this.currentSpending = 0.0,
    int? quarter,
    int? year,
  })  : quarter = quarter ?? _currentQuarter,
        year = year ?? DateTime.now().year;

  static int get _currentQuarter => ((DateTime.now().month - 1) ~/ 3) + 1;

  double get usagePercentage {
    if (limit <= 0) return 0.0;
    return (currentSpending / limit).clamp(0.0, 1.0);
  }

  double get remainingAmount => (limit - currentSpending).clamp(0.0, double.infinity);
  bool get isLimitReached => currentSpending >= limit;

  Map<String, dynamic> toJson() => {
        'category': category.name,
        'multiplier': multiplier,
        'pointType': pointType.name,
        'limit': limit,
        'currentSpending': currentSpending,
        'quarter': quarter,
        'year': year,
      };

  factory QuarterlyBonus.fromJson(Map<String, dynamic> json) {
    return QuarterlyBonus(
      category: SpendingCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => SpendingCategory.general,
      ),
      multiplier: (json['multiplier'] as num).toDouble(),
      pointType: PointType.values.firstWhere(
        (e) => e.name == json['pointType'],
        orElse: () => PointType.cashBack,
      ),
      limit: (json['limit'] as num).toDouble(),
      currentSpending: (json['currentSpending'] as num?)?.toDouble() ?? 0.0,
      quarter: json['quarter'] as int,
      year: json['year'] as int,
    );
  }
}

class SpendingLimit {
  final String id;
  SpendingCategory category;
  double limit;
  double currentSpending;
  DateTime resetDate;
  ResetType resetType;

  SpendingLimit({
    String? id,
    required this.category,
    required this.limit,
    this.currentSpending = 0.0,
    DateTime? resetDate,
    this.resetType = ResetType.annually,
  })  : id = id ?? _uuid.v4(),
        resetDate = resetDate ?? DateTime.now();

  double get usagePercentage {
    if (limit <= 0 || currentSpending < 0) return 0.0;
    final pct = currentSpending / limit;
    return pct.isNaN || pct.isInfinite ? 0.0 : pct;
  }

  double get remainingAmount => (limit - currentSpending).clamp(0.0, double.infinity);
  bool get isLimitReached => currentSpending >= limit;
  bool get isWarningThreshold => usagePercentage >= 0.85;

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'limit': limit,
        'currentSpending': currentSpending,
        'resetDate': resetDate.toIso8601String(),
        'resetType': resetType.name,
      };

  factory SpendingLimit.fromJson(Map<String, dynamic> json) {
    return SpendingLimit(
      id: json['id'] as String,
      category: SpendingCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => SpendingCategory.general,
      ),
      limit: (json['limit'] as num).toDouble(),
      currentSpending: (json['currentSpending'] as num?)?.toDouble() ?? 0.0,
      resetDate: DateTime.parse(json['resetDate'] as String),
      resetType: ResetType.values.firstWhere(
        (e) => e.name == json['resetType'],
        orElse: () => ResetType.annually,
      ),
    );
  }
}

enum ResetType {
  monthly('Monthly'),
  quarterly('Quarterly'),
  annually('Annually'),
  never('Never');

  const ResetType(this.displayName);
  final String displayName;
}

class CardRecommendation {
  final String id;
  final String cardId;
  final String cardName;
  final CardType? cardType;
  final SpendingCategory category;
  final double multiplier;
  final PointType pointType;
  final String reasoning;
  final double currentSpending;
  final double limit;
  final bool isLimitReached;
  final int rank;

  CardRecommendation({
    String? id,
    required this.cardId,
    required this.cardName,
    this.cardType,
    required this.category,
    required this.multiplier,
    required this.pointType,
    required this.reasoning,
    this.currentSpending = 0.0,
    this.limit = 0.0,
    this.isLimitReached = false,
    this.rank = 1,
  }) : id = id ?? _uuid.v4();
}
