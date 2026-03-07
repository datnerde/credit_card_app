import 'package:flutter/foundation.dart';
import '../models/credit_card.dart';
import '../models/spending_category.dart';
import '../models/user_preferences.dart';
import '../services/data_manager.dart';
import '../services/recommendation_engine.dart';
import '../services/analytics_service.dart';

enum PaymentFlowState {
  idle,
  analyzing,
  recommendationReady,
  processingPayment,
  paymentComplete,
  paymentFailed,
  acknowledged,
}

class SmartPayProvider extends ChangeNotifier {
  final DataManager _dataManager;
  final RecommendationEngine _engine = RecommendationEngine();
  final _analytics = AnalyticsService();

  PaymentFlowState _state = PaymentFlowState.idle;
  String _purchaseDescription = '';
  double? _purchaseAmount;
  SpendingCategory? _detectedCategory;
  String? _detectedMerchant;
  CardRecommendation? _recommendedCard;
  CardRecommendation? _secondaryCard;
  String _reasoning = '';
  List<String> _warnings = [];
  List<String> _suggestions = [];

  List<CreditCard> _userCards = [];
  UserPreferences _userPreferences = UserPreferences();

  SmartPayProvider(this._dataManager);

  // Getters
  PaymentFlowState get state => _state;
  String get purchaseDescription => _purchaseDescription;
  double? get purchaseAmount => _purchaseAmount;
  SpendingCategory? get detectedCategory => _detectedCategory;
  String? get detectedMerchant => _detectedMerchant;
  CardRecommendation? get recommendedCard => _recommendedCard;
  CardRecommendation? get secondaryCard => _secondaryCard;
  String get reasoning => _reasoning;
  List<String> get warnings => _warnings;
  List<String> get suggestions => _suggestions;
  bool get useApplePay => _userPreferences.useApplePay;
  bool get canAnalyze => _purchaseDescription.trim().length >= 3;

  double get estimatedPoints {
    if (_recommendedCard == null || _purchaseAmount == null) return 0;
    return _purchaseAmount! * _recommendedCard!.multiplier;
  }

  Future<void> loadData() async {
    _userCards = await _dataManager.fetchCards();
    _userPreferences = await _dataManager.loadUserPreferences();
    notifyListeners();
  }

  void selectCategory(SpendingCategory category) {
    _detectedCategory = category;
    _purchaseDescription = category.displayName;
    _analytics.trackRecommendation(category.name);

    final response = _engine.getInstantRecommendation(
      category: category,
      userCards: _userCards,
      userPreferences: _userPreferences,
    );

    _applyResponse(response);
    _state = PaymentFlowState.recommendationReady;
    notifyListeners();
  }

  void analyzePurchase() {
    if (!canAnalyze) return;

    _state = PaymentFlowState.analyzing;
    notifyListeners();

    final response = _engine.getRecommendation(
      query: _purchaseDescription,
      userCards: _userCards,
      userPreferences: _userPreferences,
    );

    _applyResponse(response);
    _state = PaymentFlowState.recommendationReady;
    notifyListeners();
  }

  void _applyResponse(RecommendationResponse response) {
    _recommendedCard = response.primaryRecommendation;
    _secondaryCard = response.secondaryRecommendation;
    _reasoning = response.reasoning;
    _warnings = response.warnings;
    _suggestions = response.suggestions;
    if (_recommendedCard != null) {
      _detectedCategory = _recommendedCard!.category;
    }
  }

  void setPurchaseDescription(String desc) {
    _purchaseDescription = desc;
    notifyListeners();
  }

  void setPurchaseAmount(double? amount) {
    _purchaseAmount = amount;
    notifyListeners();
  }

  void acknowledge() {
    _state = PaymentFlowState.acknowledged;
    notifyListeners();
  }

  void reset() {
    _state = PaymentFlowState.idle;
    _purchaseDescription = '';
    _purchaseAmount = null;
    _detectedCategory = null;
    _detectedMerchant = null;
    _recommendedCard = null;
    _secondaryCard = null;
    _reasoning = '';
    _warnings = [];
    _suggestions = [];
    notifyListeners();
  }
}
