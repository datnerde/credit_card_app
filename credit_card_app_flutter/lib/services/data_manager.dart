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
  static const int _dataVersion = 1;

  late Box<String> _cardsBox;
  late Box<String> _preferencesBox;
  bool _initialized = false;

  Future<void> initialize() async {
    try {
      _cardsBox = await Hive.openBox<String>(_cardsBoxName);
      _preferencesBox = await Hive.openBox<String>(_preferencesBoxName);
      await _migrateIfNeeded();
      _initialized = true;
    } catch (e) {
      // If Hive fails to open (corrupted), delete and retry
      await Hive.deleteBoxFromDisk(_cardsBoxName);
      await Hive.deleteBoxFromDisk(_preferencesBoxName);
      _cardsBox = await Hive.openBox<String>(_cardsBoxName);
      _preferencesBox = await Hive.openBox<String>(_preferencesBoxName);
      _initialized = true;
    }
  }

  Future<void> _migrateIfNeeded() async {
    final storedVersion = int.tryParse(_preferencesBox.get('dataVersion') ?? '0') ?? 0;
    if (storedVersion < _dataVersion) {
      await _preferencesBox.put('dataVersion', _dataVersion.toString());
    }
  }

  void _ensureInitialized() {
    if (!_initialized) throw StateError('DataManager not initialized. Call initialize() first.');
  }

  // MARK: - Cards CRUD

  Future<List<CreditCard>> fetchCards() async {
    _ensureInitialized();
    final cards = <CreditCard>[];
    for (final json in _cardsBox.values) {
      try {
        cards.add(CreditCard.fromJson(jsonDecode(json) as Map<String, dynamic>));
      } catch (_) {
        // Skip corrupted entries
      }
    }
    return cards;
  }

  Future<void> saveCard(CreditCard card) async {
    _ensureInitialized();
    await _cardsBox.put(card.id, jsonEncode(card.toJson()));
  }

  Future<void> updateCard(CreditCard card) async {
    _ensureInitialized();
    await _cardsBox.put(card.id, jsonEncode(card.toJson()));
  }

  Future<void> deleteCard(String cardId) async {
    _ensureInitialized();
    await _cardsBox.delete(cardId);
  }

  // MARK: - User Preferences

  Future<UserPreferences> loadUserPreferences() async {
    _ensureInitialized();
    try {
      final json = _preferencesBox.get('userPreferences');
      if (json != null) {
        return UserPreferences.fromJson(jsonDecode(json) as Map<String, dynamic>);
      }
    } catch (_) {
      // Return defaults on corrupted data
    }
    return UserPreferences();
  }

  Future<void> saveUserPreferences(UserPreferences prefs) async {
    _ensureInitialized();
    await _preferencesBox.put('userPreferences', jsonEncode(prefs.toJson()));
  }

  // MARK: - Onboarding

  Future<bool> hasCompletedOnboarding() async {
    _ensureInitialized();
    return _preferencesBox.get('onboardingComplete') == 'true';
  }

  Future<void> completeOnboarding() async {
    _ensureInitialized();
    await _preferencesBox.put('onboardingComplete', 'true');
  }

  // MARK: - Sample Data

  Future<void> loadSampleData() async {
    _ensureInitialized();
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
