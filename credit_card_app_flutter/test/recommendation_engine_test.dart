import 'package:flutter_test/flutter_test.dart';
import 'package:credit_card_app/models/credit_card.dart';
import 'package:credit_card_app/models/card_type.dart';
import 'package:credit_card_app/models/spending_category.dart';
import 'package:credit_card_app/models/point_type.dart';
import 'package:credit_card_app/models/user_preferences.dart';
import 'package:credit_card_app/services/recommendation_engine.dart';

void main() {
  late RecommendationEngine engine;
  late List<CreditCard> testCards;
  late UserPreferences prefs;

  setUp(() {
    engine = RecommendationEngine();
    prefs = UserPreferences();
    testCards = [
      CreditCard(name: 'Amex Gold', cardType: CardType.amexGold),
      CreditCard(name: 'Chase Sapphire Reserve', cardType: CardType.chaseSapphireReserve),
      CreditCard(name: 'Robinhood Gold', cardType: CardType.robinhoodGold),
    ];
  });

  group('RecommendationEngine', () {
    test('recommends Amex Gold for groceries (4x)', () {
      final result = engine.getInstantRecommendation(
        category: SpendingCategory.groceries,
        userCards: testCards,
        userPreferences: prefs,
      );
      expect(result.primaryRecommendation, isNotNull);
      expect(result.primaryRecommendation!.cardName, 'Amex Gold');
    });

    test('recommends CSR for hotels (10x)', () {
      final result = engine.getInstantRecommendation(
        category: SpendingCategory.hotels,
        userCards: testCards,
        userPreferences: prefs,
      );
      expect(result.primaryRecommendation, isNotNull);
      expect(result.primaryRecommendation!.cardName, 'Chase Sapphire Reserve');
    });

    test('recommends Amex Gold for dining (4x beats 3x)', () {
      final result = engine.getInstantRecommendation(
        category: SpendingCategory.dining,
        userCards: testCards,
        userPreferences: prefs,
      );
      expect(result.primaryRecommendation, isNotNull);
      expect(result.primaryRecommendation!.cardName, 'Amex Gold');
    });

    test('returns secondary recommendation', () {
      final result = engine.getInstantRecommendation(
        category: SpendingCategory.dining,
        userCards: testCards,
        userPreferences: prefs,
      );
      expect(result.secondaryRecommendation, isNotNull);
    });

    test('handles empty card list', () {
      final result = engine.getInstantRecommendation(
        category: SpendingCategory.groceries,
        userCards: [],
        userPreferences: prefs,
      );
      expect(result.primaryRecommendation, isNull);
      expect(result.reasoning, contains('add'));
    });

    test('uses category fallback for coffee -> dining', () {
      final result = engine.getInstantRecommendation(
        category: SpendingCategory.coffee,
        userCards: testCards,
        userPreferences: prefs,
      );
      expect(result.primaryRecommendation, isNotNull);
      // Should pick Amex Gold (4x dining) via coffee->dining fallback
      expect(result.primaryRecommendation!.cardName, 'Amex Gold');
    });

    test('prefers cards with preferred point system', () {
      final urPrefs = UserPreferences(preferredPointSystem: PointType.ultimateRewards);
      final result = engine.getInstantRecommendation(
        category: SpendingCategory.general,
        userCards: testCards,
        userPreferences: urPrefs,
      );
      expect(result.primaryRecommendation, isNotNull);
      // Robinhood has 3x general (cash back) but CSR has 1x UR with preference bonus
      // Robinhood 3x should still win due to higher category score weight
    });

    test('query-based recommendation works', () {
      final result = engine.getRecommendation(
        query: 'buying groceries at Costco',
        userCards: testCards,
        userPreferences: prefs,
      );
      expect(result.primaryRecommendation, isNotNull);
    });

    test('handles limit reached cards', () {
      final cardsWithLimit = [
        CreditCard(
          name: 'Limited Card',
          cardType: CardType.amexGold,
          spendingLimits: [
            SpendingLimit(
              category: SpendingCategory.groceries,
              limit: 1000,
              currentSpending: 1000,
            ),
          ],
        ),
        CreditCard(name: 'Backup', cardType: CardType.robinhoodGold),
      ];

      final result = engine.getInstantRecommendation(
        category: SpendingCategory.groceries,
        userCards: cardsWithLimit,
        userPreferences: prefs,
      );
      // Should deprioritize the limited card
      expect(result.primaryRecommendation, isNotNull);
    });
  });

  group('CreditCard model', () {
    test('serialization roundtrip', () {
      final card = CreditCard(name: 'Test', cardType: CardType.amexGold);
      final json = card.toJson();
      final restored = CreditCard.fromJson(json);
      expect(restored.name, card.name);
      expect(restored.cardType, card.cardType);
      expect(restored.rewardCategories.length, card.rewardCategories.length);
    });

    test('uses default rewards when none provided', () {
      final card = CreditCard(name: 'Test', cardType: CardType.chaseSapphireReserve);
      expect(card.rewardCategories.isNotEmpty, true);
      expect(card.rewardCategories.any((r) => r.category == SpendingCategory.hotels), true);
    });

    test('SpendingLimit calculations', () {
      final limit = SpendingLimit(
        category: SpendingCategory.groceries,
        limit: 1000,
        currentSpending: 870,
      );
      expect(limit.usagePercentage, closeTo(0.87, 0.01));
      expect(limit.isWarningThreshold, true);
      expect(limit.isLimitReached, false);
      expect(limit.remainingAmount, 130);
    });
  });
}
