import '../models/credit_card.dart';
import '../models/spending_category.dart';
import '../models/point_type.dart';
import '../models/user_preferences.dart';
import '../models/card_type.dart';
import 'nlp_processor.dart';

class RecommendationResponse {
  final CardRecommendation? primaryRecommendation;
  final CardRecommendation? secondaryRecommendation;
  final String reasoning;
  final List<String> warnings;
  final List<String> suggestions;
  final double confidence;

  RecommendationResponse({
    this.primaryRecommendation,
    this.secondaryRecommendation,
    this.reasoning = '',
    this.warnings = const [],
    this.suggestions = const [],
    this.confidence = 1.0,
  });
}

class _CardScore {
  final CreditCard card;
  final SpendingCategory category;
  final double baseScore;
  final double categoryScore;
  final double preferenceScore;
  final double limitScore;
  final double totalScore;
  final String reasoning;

  _CardScore({
    required this.card,
    required this.category,
    required this.baseScore,
    required this.categoryScore,
    required this.preferenceScore,
    required this.limitScore,
    required this.totalScore,
    required this.reasoning,
  });
}

class RecommendationEngine {
  final NLPProcessor _nlpProcessor = NLPProcessor();
  final Map<String, RecommendationResponse> _cache = {};
  static const int _cacheMaxSize = 100;

  static const Map<SpendingCategory, List<(SpendingCategory, double)>> _categoryFallbacks = {
    SpendingCategory.coffee: [(SpendingCategory.dining, 0.8), (SpendingCategory.restaurants, 0.7)],
    SpendingCategory.fastFood: [(SpendingCategory.dining, 0.85), (SpendingCategory.restaurants, 0.8)],
    SpendingCategory.restaurants: [(SpendingCategory.dining, 0.9)],
    SpendingCategory.airfare: [(SpendingCategory.travel, 0.85)],
    SpendingCategory.hotels: [(SpendingCategory.travel, 0.8)],
    SpendingCategory.wholeFoods: [(SpendingCategory.groceries, 0.95)],
    SpendingCategory.costco: [(SpendingCategory.groceries, 0.7)],
    SpendingCategory.amazon: [(SpendingCategory.online, 0.9)],
    SpendingCategory.target: [(SpendingCategory.general, 0.6)],
    SpendingCategory.walmart: [(SpendingCategory.groceries, 0.6), (SpendingCategory.general, 0.5)],
    SpendingCategory.transit: [(SpendingCategory.travel, 0.6)],
    SpendingCategory.streaming: [(SpendingCategory.entertainment, 0.7)],
  };

  // Synchronous instant recommendation
  RecommendationResponse getInstantRecommendation({
    required SpendingCategory category,
    required List<CreditCard> userCards,
    required UserPreferences userPreferences,
  }) {
    if (userCards.isEmpty) {
      return RecommendationResponse(
        reasoning: 'Please add your credit cards first to get personalized recommendations.',
      );
    }

    var scoredCards = _scoreCards(userCards, category, null, userPreferences);

    // Try fallback categories if no specific match
    final hasCategoryMatch = scoredCards.any((s) => s.categoryScore > 1.0);
    if (!hasCategoryMatch) {
      final fallbacks = _categoryFallbacks[category];
      if (fallbacks != null) {
        for (final (fallbackCategory, scoreMultiplier) in fallbacks) {
          final fallbackScored = _scoreCards(userCards, fallbackCategory, null, userPreferences);
          for (final card in fallbackScored.where((c) => c.categoryScore > 1.0)) {
            scoredCards.add(_CardScore(
              card: card.card,
              category: category,
              baseScore: card.baseScore,
              categoryScore: card.categoryScore * scoreMultiplier,
              preferenceScore: card.preferenceScore,
              limitScore: card.limitScore,
              totalScore: card.totalScore * scoreMultiplier,
              reasoning: card.reasoning,
            ));
          }
        }
      }
    }

    final recommendations = _filterAndRank(scoredCards);

    if (recommendations.isEmpty) {
      return RecommendationResponse(
        reasoning: 'No suitable cards found for ${category.displayName}.',
        warnings: ['Consider adding a card with rewards for this category.'],
      );
    }

    final primary = recommendations[0];
    final primaryRec = _createRecommendation(primary, 1);
    final secondaryRec = recommendations.length > 1 ? _createRecommendation(recommendations[1], 2) : null;

    var reasoning = 'Use **${primary.card.name}** for ${category.displayName.toLowerCase()}';
    final reward = primary.card.rewardCategories.where(
      (r) => r.category == category || r.category == SpendingCategory.general,
    ).firstOrNull;
    if (reward != null) {
      reasoning += ' — ${reward.multiplier.toStringAsFixed(0)}x ${reward.pointType.displayName}';
    }
    reasoning += '.';

    final limit = primary.card.spendingLimits.where((s) => s.category == category).firstOrNull;
    if (limit != null) {
      if (limit.isLimitReached) {
        reasoning += ' Limit reached for this category.';
      } else if (limit.isWarningThreshold) {
        reasoning += ' Almost at your spending limit.';
      }
    }

    final bonus = primary.card.quarterlyBonus;
    if (bonus != null && bonus.category == category) {
      final remaining = bonus.limit - bonus.currentSpending;
      if (remaining > 0) {
        reasoning += ' Q${bonus.quarter} bonus active — \$${remaining.toInt()} remaining at ${bonus.multiplier.toStringAsFixed(0)}x!';
      }
    }

    return RecommendationResponse(
      primaryRecommendation: primaryRec,
      secondaryRecommendation: secondaryRec,
      reasoning: reasoning,
      warnings: _generateWarnings(recommendations),
      suggestions: _generateSuggestions(recommendations, category, userPreferences),
    );
  }

  // Async recommendation from query text
  RecommendationResponse getRecommendation({
    required String query,
    required List<CreditCard> userCards,
    required UserPreferences userPreferences,
  }) {
    // Check cache
    final cacheKey = query.toLowerCase().trim();
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    if (userCards.isEmpty) {
      return RecommendationResponse(
        reasoning: 'Please add your credit cards first.',
      );
    }

    final parsed = _nlpProcessor.parseQuery(query);
    final category = parsed.spendingCategory ?? SpendingCategory.general;

    final response = getInstantRecommendation(
      category: category,
      userCards: userCards,
      userPreferences: userPreferences,
    );

    // Cache result
    _cache[cacheKey] = response;
    if (_cache.length > _cacheMaxSize) {
      _cache.remove(_cache.keys.first);
    }

    return response;
  }

  List<_CardScore> _scoreCards(
    List<CreditCard> cards,
    SpendingCategory category,
    String? merchant,
    UserPreferences preferences,
  ) {
    return cards.where((c) => c.isActive).map((card) {
      final baseScore = 1.0;
      final categoryScore = _calculateCategoryScore(card, category);
      final preferenceScore = _calculatePreferenceScore(card, preferences);
      final limitScore = _calculateLimitScore(card, category);

      final totalScore = (baseScore * 0.1) +
          (categoryScore * 0.6) +
          (preferenceScore * 0.2) +
          (limitScore * 0.1);

      final reasoning = _generateReasoning(card, category, categoryScore, limitScore);

      return _CardScore(
        card: card,
        category: category,
        baseScore: baseScore,
        categoryScore: categoryScore,
        preferenceScore: preferenceScore,
        limitScore: limitScore,
        totalScore: totalScore,
        reasoning: reasoning,
      );
    }).toList();
  }

  double _calculateCategoryScore(CreditCard card, SpendingCategory category) {
    final reward = card.rewardCategories.where(
      (r) => r.category == category && r.isActive,
    ).firstOrNull;

    if (reward == null) return 1.0;

    final bonus = card.quarterlyBonus;
    if (bonus != null && bonus.category == category) {
      return reward.multiplier > bonus.multiplier ? reward.multiplier : bonus.multiplier;
    }

    return reward.multiplier;
  }

  double _calculatePreferenceScore(CreditCard card, UserPreferences preferences) {
    final hasPreferred = card.rewardCategories.any(
      (r) => r.pointType == preferences.preferredPointSystem,
    );
    return hasPreferred ? 1.2 : 1.0;
  }

  double _calculateLimitScore(CreditCard card, SpendingCategory category) {
    final limit = card.spendingLimits.where((s) => s.category == category).firstOrNull;
    if (limit == null) return 1.0;

    final usage = limit.limit > 0 ? limit.currentSpending / limit.limit : 0.0;
    if (usage >= 1.0) return 0.0;
    if (usage >= 0.85) return 0.5;
    return 1.0;
  }

  List<_CardScore> _filterAndRank(List<_CardScore> scored) {
    final sorted = List<_CardScore>.from(scored)..sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return sorted.where((s) => s.totalScore > 0).take(2).toList();
  }

  CardRecommendation _createRecommendation(_CardScore score, int rank) {
    final limit = score.card.spendingLimits.where((s) => s.category == score.category).firstOrNull;
    return CardRecommendation(
      cardId: score.card.id,
      cardName: score.card.name,
      cardType: score.card.cardType,
      category: score.category,
      multiplier: score.categoryScore,
      pointType: _getPointType(score.card, score.category),
      reasoning: score.reasoning,
      currentSpending: limit?.currentSpending ?? 0.0,
      limit: limit?.limit ?? 0.0,
      isLimitReached: score.limitScore == 0.0,
      rank: rank,
    );
  }

  PointType _getPointType(CreditCard card, SpendingCategory category) {
    return card.rewardCategories
            .where((r) => r.category == category)
            .firstOrNull
            ?.pointType ??
        (card.rewardCategories.isNotEmpty ? card.rewardCategories.first.pointType : PointType.cashBack);
  }

  String _generateReasoning(CreditCard card, SpendingCategory category, double score, double limitScore) {
    var reasoning = '';
    final reward = card.rewardCategories.where((r) => r.category == category).firstOrNull;
    if (reward != null) {
      reasoning += '${card.name} offers ${reward.multiplier}x ${reward.pointType.shortName} on ${category.displayName.toLowerCase()}.';
    }
    final limit = card.spendingLimits.where((s) => s.category == category).firstOrNull;
    if (limit != null) {
      reasoning += ' \$${limit.remainingAmount.toStringAsFixed(0)} remaining.';
      if (limitScore == 0.0) reasoning += ' Limit reached.';
      else if (limitScore == 0.5) reasoning += ' Limit almost reached.';
    }
    return reasoning;
  }

  List<String> _generateWarnings(List<_CardScore> recommendations) {
    final warnings = <String>[];
    for (final rec in recommendations) {
      if (rec.limitScore == 0.0) {
        warnings.add('${rec.card.name} has reached its limit for this category.');
      } else if (rec.limitScore == 0.5) {
        warnings.add('${rec.card.name} is approaching its limit.');
      }
    }
    return warnings;
  }

  List<String> _generateSuggestions(List<_CardScore> recommendations, SpendingCategory category, UserPreferences prefs) {
    final suggestions = <String>[];
    if (recommendations.every((r) => r.totalScore < 2.0)) {
      suggestions.add('Consider adding a card with better rewards for ${category.displayName.toLowerCase()}.');
    }
    if (prefs.preferredPointSystem != PointType.membershipRewards) {
      suggestions.add('Prioritize cards earning ${prefs.preferredPointSystem.shortName} points.');
    }
    return suggestions;
  }
}
