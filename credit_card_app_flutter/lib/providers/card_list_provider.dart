import 'package:flutter/foundation.dart';
import '../models/credit_card.dart';
import '../models/card_type.dart';
import '../models/spending_category.dart';
import '../services/data_manager.dart';
import '../services/analytics_service.dart';

enum SortOption { name, cardType, recentlyAdded, activeFirst }

class CardListProvider extends ChangeNotifier {
  final DataManager _dataManager;
  final _analytics = AnalyticsService();

  List<CreditCard> _cards = [];
  CreditCard? _selectedCard;
  String _searchText = '';
  SortOption _sortOption = SortOption.recentlyAdded;
  bool _isLoading = false;
  String? _errorMessage;

  CardListProvider(this._dataManager);

  // Getters
  List<CreditCard> get cards => _cards;
  CreditCard? get selectedCard => _selectedCard;
  String get searchText => _searchText;
  SortOption get sortOption => _sortOption;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<CreditCard> get filteredCards {
    var result = List<CreditCard>.from(_cards);

    if (_searchText.isNotEmpty) {
      final lower = _searchText.toLowerCase();
      result = result.where((c) =>
          c.name.toLowerCase().contains(lower) ||
          c.cardType.displayName.toLowerCase().contains(lower)).toList();
    }

    switch (_sortOption) {
      case SortOption.name:
        result.sort((a, b) => a.name.compareTo(b.name));
      case SortOption.cardType:
        result.sort((a, b) => a.cardType.displayName.compareTo(b.cardType.displayName));
      case SortOption.recentlyAdded:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case SortOption.activeFirst:
        result.sort((a, b) {
          if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
          return b.createdAt.compareTo(a.createdAt);
        });
    }

    return result;
  }

  int get totalCards => _cards.length;
  int get activeCards => _cards.where((c) => c.isActive).length;

  Future<void> loadCards() async {
    _isLoading = true;
    notifyListeners();
    try {
      _cards = await _dataManager.fetchCards();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load cards: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCard(CreditCard card) async {
    try {
      await _dataManager.saveCard(card);
      _cards.add(card);
      _analytics.trackCardAdded(card.cardType.name);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to add card: $e';
      notifyListeners();
    }
  }

  Future<void> updateCard(CreditCard card) async {
    try {
      await _dataManager.updateCard(card);
      final idx = _cards.indexWhere((c) => c.id == card.id);
      if (idx >= 0) _cards[idx] = card;
      if (_selectedCard?.id == card.id) _selectedCard = card;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update card: $e';
      notifyListeners();
    }
  }

  Future<void> deleteCard(String cardId) async {
    try {
      final card = _cards.firstWhere((c) => c.id == cardId);
      await _dataManager.deleteCard(cardId);
      _cards.removeWhere((c) => c.id == cardId);
      if (_selectedCard?.id == cardId) _selectedCard = null;
      _analytics.trackCardDeleted(card.cardType.name);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete card: $e';
      notifyListeners();
    }
  }

  Future<void> loadSampleData() async {
    _isLoading = true;
    notifyListeners();
    await _dataManager.loadSampleData();
    await loadCards();
  }

  void selectCard(CreditCard? card) {
    _selectedCard = card;
    notifyListeners();
  }

  void setSearchText(String text) {
    _searchText = text;
    notifyListeners();
  }

  void setSortOption(SortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void toggleCardActive(String cardId) {
    final idx = _cards.indexWhere((c) => c.id == cardId);
    if (idx >= 0) {
      _cards[idx].isActive = !_cards[idx].isActive;
      _cards[idx].updatedAt = DateTime.now();
      _dataManager.updateCard(_cards[idx]);
      notifyListeners();
    }
  }
}
