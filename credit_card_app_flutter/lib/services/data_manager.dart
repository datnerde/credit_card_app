import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/credit_card.dart';
import '../models/card_type.dart';
import '../models/user_preferences.dart';
import '../models/spending_category.dart';
import '../models/point_type.dart';

class DataManager {
  static const String _cardsBoxName = 'cards';
  static const String _preferencesBoxName = 'preferences';

  late Box<String> _cardsBox;
  late Box<String> _preferencesBox;

  Future<void> initialize() async {
    _cardsBox = await Hive.openBox<String>(_cardsBoxName);
    _preferencesBox = await Hive.openBox<String>(_preferencesBoxName);
  }

  // MARK: - Cards CRUD

  Future<List<CreditCard>> fetchCards() async {
    return _cardsBox.values.map((json) {
      return CreditCard.fromJson(jsonDecode(json) as Map<String, dynamic>);
    }).toList();
  }

  Future<void> saveCard(CreditCard card) async {
    await _cardsBox.put(card.id, jsonEncode(card.toJson()));
  }

  Future<void> updateCard(CreditCard card) async {
    await _cardsBox.put(card.id, jsonEncode(card.toJson()));
  }

  Future<void> deleteCard(String cardId) async {
    await _cardsBox.delete(cardId);
  }

  // MARK: - User Preferences

  Future<UserPreferences> loadUserPreferences() async {
    final json = _preferencesBox.get('userPreferences');
    if (json != null) {
      return UserPreferences.fromJson(jsonDecode(json) as Map<String, dynamic>);
    }
    return UserPreferences();
  }

  Future<void> saveUserPreferences(UserPreferences prefs) async {
    await _preferencesBox.put('userPreferences', jsonEncode(prefs.toJson()));
  }

  // MARK: - Onboarding

  Future<bool> hasCompletedOnboarding() async {
    return _preferencesBox.get('onboardingComplete') == 'true';
  }

  Future<void> completeOnboarding() async {
    await _preferencesBox.put('onboardingComplete', 'true');
  }

  // MARK: - Sample Data

  Future<void> loadSampleData() async {
    final existingCards = await fetchCards();
    if (existingCards.isNotEmpty) return;

    final sampleCards = [
      CreditCard(
        name: 'Amex Gold',
        cardType: CardType.amexGold,
        spendingLimits: [
          SpendingLimit(
            category: SpendingCategory.groceries,
            limit: 25000,
            currentSpending: 8500,
            resetType: ResetType.annually,
          ),
        ],
      ),
      CreditCard(
        name: 'Chase Sapphire Reserve',
        cardType: CardType.chaseSapphireReserve,
      ),
      CreditCard(
        name: 'Chase Freedom Flex',
        cardType: CardType.chaseFreedomFlex,
        quarterlyBonus: QuarterlyBonus(
          category: SpendingCategory.groceries,
          multiplier: 5.0,
          pointType: PointType.ultimateRewards,
          limit: 1500,
          currentSpending: 450,
        ),
      ),
      CreditCard(
        name: 'Robinhood Gold Card',
        cardType: CardType.robinhoodGold,
      ),
      CreditCard(
        name: 'Amex Blue Cash Preferred',
        cardType: CardType.amexBlueCashPreferred,
        spendingLimits: [
          SpendingLimit(
            category: SpendingCategory.groceries,
            limit: 6000,
            currentSpending: 3200,
            resetType: ResetType.annually,
          ),
        ],
      ),
    ];

    for (final card in sampleCards) {
      await saveCard(card);
    }
  }

  Future<void> clearAllCards() async {
    await _cardsBox.clear();
  }
}
