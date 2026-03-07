import 'package:flutter/foundation.dart';
import '../models/credit_card.dart';
import '../models/card_type.dart';
import '../models/spending_category.dart';
import '../models/point_type.dart';
import '../services/data_manager.dart';

class AddCardProvider extends ChangeNotifier {
  final DataManager _dataManager;

  String cardName = '';
  CardType selectedCardType = CardType.custom;
  bool isActive = true;
  List<RewardCategory> rewardCategories = [];
  bool hasQuarterlyBonus = false;
  QuarterlyBonus? quarterlyBonus;
  List<SpendingLimit> spendingLimits = [];

  CreditCard? _editingCard;
  bool get isEditing => _editingCard != null;

  List<String> _validationErrors = [];
  List<String> get validationErrors => _validationErrors;

  AddCardProvider(this._dataManager);

  bool get isFormValid {
    _validationErrors = [];
    if (cardName.trim().isEmpty) _validationErrors.add('Card name is required');
    if (selectedCardType != CardType.custom && rewardCategories.isEmpty) {
      _validationErrors.add('At least one reward category required');
    }
    return _validationErrors.isEmpty;
  }

  void loadCard(CreditCard card) {
    _editingCard = card;
    cardName = card.name;
    selectedCardType = card.cardType;
    isActive = card.isActive;
    rewardCategories = List.from(card.rewardCategories);
    quarterlyBonus = card.quarterlyBonus;
    hasQuarterlyBonus = card.quarterlyBonus != null;
    spendingLimits = List.from(card.spendingLimits);
    notifyListeners();
  }

  void loadDefaultsForCardType(CardType type) {
    selectedCardType = type;
    if (cardName.isEmpty || CardType.values.any((ct) => ct.displayName == cardName)) {
      cardName = type.displayName;
    }
    rewardCategories = List.from(type.defaultRewards);
    notifyListeners();
  }

  void toggleCategory(SpendingCategory category) {
    final idx = rewardCategories.indexWhere((r) => r.category == category);
    if (idx >= 0) {
      rewardCategories.removeAt(idx);
    } else {
      rewardCategories.add(RewardCategory(
        category: category,
        multiplier: 1.0,
        pointType: rewardCategories.isNotEmpty ? rewardCategories.first.pointType : PointType.cashBack,
      ));
    }
    notifyListeners();
  }

  void updateMultiplier(SpendingCategory category, double multiplier) {
    final idx = rewardCategories.indexWhere((r) => r.category == category);
    if (idx >= 0) {
      rewardCategories[idx].multiplier = multiplier;
      notifyListeners();
    }
  }

  void updatePointType(SpendingCategory category, PointType pointType) {
    final idx = rewardCategories.indexWhere((r) => r.category == category);
    if (idx >= 0) {
      rewardCategories[idx].pointType = pointType;
      notifyListeners();
    }
  }

  CreditCard buildCard() {
    if (isEditing) {
      return _editingCard!.copyWith(
        name: cardName,
        cardType: selectedCardType,
        rewardCategories: rewardCategories,
        quarterlyBonus: hasQuarterlyBonus ? quarterlyBonus : null,
        spendingLimits: spendingLimits,
        isActive: isActive,
      );
    }
    return CreditCard(
      name: cardName,
      cardType: selectedCardType,
      rewardCategories: rewardCategories,
      quarterlyBonus: hasQuarterlyBonus ? quarterlyBonus : null,
      spendingLimits: spendingLimits,
      isActive: isActive,
    );
  }

  void resetForm() {
    _editingCard = null;
    cardName = '';
    selectedCardType = CardType.custom;
    isActive = true;
    rewardCategories = [];
    hasQuarterlyBonus = false;
    quarterlyBonus = null;
    spendingLimits = [];
    _validationErrors = [];
    notifyListeners();
  }
}
