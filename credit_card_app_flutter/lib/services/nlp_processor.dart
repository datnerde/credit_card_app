import '../models/spending_category.dart';
import '../models/merchant.dart';

class ParsedQuery {
  final SpendingCategory? spendingCategory;
  final String? merchant;
  final double? amount;
  final QueryIntent intent;
  final double confidence;

  ParsedQuery({
    this.spendingCategory,
    this.merchant,
    this.amount,
    required this.intent,
    required this.confidence,
  });
}

enum QueryIntent {
  cardRecommendation,
  spendingUpdate,
  limitCheck,
  generalQuestion,
}

class QueryValidationResult {
  final bool isValid;
  final String? error;
  QueryValidationResult({required this.isValid, this.error});
}

class NLPProcessor {
  static const _categoryKeywords = <SpendingCategory, List<String>>{
    SpendingCategory.groceries: ['grocery', 'groceries', 'food', 'supermarket', 'market', 'produce'],
    SpendingCategory.dining: ['dining', 'restaurant', 'dinner', 'lunch', 'breakfast', 'eat', 'meal', 'eating out'],
    SpendingCategory.travel: ['travel', 'flight', 'hotel', 'vacation', 'trip', 'airline', 'booking'],
    SpendingCategory.gas: ['gas', 'fuel', 'gasoline', 'petrol', 'filling up', 'gas station'],
    SpendingCategory.online: ['online', 'internet', 'web', 'ecommerce', 'online shopping'],
    SpendingCategory.drugstores: ['drugstore', 'pharmacy', 'medicine', 'cvs', 'walgreens'],
    SpendingCategory.streaming: ['streaming', 'netflix', 'spotify', 'hulu', 'disney'],
    SpendingCategory.transit: ['transit', 'transportation', 'uber', 'lyft', 'taxi', 'ride'],
    SpendingCategory.office: ['office', 'supply', 'staples', 'office depot'],
    SpendingCategory.phone: ['phone', 'mobile', 'cell', 'wireless'],
    SpendingCategory.costco: ['costco', 'wholesale'],
    SpendingCategory.amazon: ['amazon', 'amzn'],
    SpendingCategory.wholeFoods: ['whole foods', 'wholefoods', 'organic'],
    SpendingCategory.target: ['target'],
    SpendingCategory.walmart: ['walmart', 'wal-mart'],
    SpendingCategory.airfare: ['airfare', 'airline ticket', 'plane ticket', 'flight ticket'],
    SpendingCategory.hotels: ['hotel', 'lodging', 'accommodation', 'stay'],
    SpendingCategory.restaurants: ['restaurant', 'fine dining'],
    SpendingCategory.fastFood: ['fast food', 'quick service', 'drive thru'],
    SpendingCategory.coffee: ['coffee', 'starbucks', 'dunkin', 'cafe'],
  };

  ParsedQuery parseQuery(String query) {
    final lower = query.toLowerCase();
    final category = _extractCategory(lower);
    final merchant = _extractMerchant(lower);
    final amount = _extractAmount(lower);
    final intent = _determineIntent(lower);
    final confidence = _calculateConfidence(category, merchant, amount, intent);

    return ParsedQuery(
      spendingCategory: category,
      merchant: merchant,
      amount: amount,
      intent: intent,
      confidence: confidence,
    );
  }

  QueryValidationResult validateQuery(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return QueryValidationResult(isValid: false, error: 'Query cannot be empty');
    if (trimmed.length < 3) return QueryValidationResult(isValid: false, error: 'Query is too short');
    if (trimmed.length > 500) return QueryValidationResult(isValid: false, error: 'Query is too long');
    return QueryValidationResult(isValid: true);
  }

  SpendingCategory? _extractCategory(String query) {
    for (final entry in _categoryKeywords.entries) {
      if (entry.value.any((kw) => query.contains(kw))) {
        return entry.key;
      }
    }
    return null;
  }

  String? _extractMerchant(String query) {
    for (final merchant in merchantMappings.keys) {
      if (query.contains(merchant)) return merchant;
    }
    return null;
  }

  double? _extractAmount(String query) {
    final regex = RegExp(r'\$?(\d+(?:\.\d{2})?)');
    final match = regex.firstMatch(query);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }

  QueryIntent _determineIntent(String query) {
    if (query.contains('spent') || query.contains('spending') || query.contains('update') || query.contains('track')) {
      return QueryIntent.spendingUpdate;
    }
    if (query.contains('limit') || query.contains('remaining') || query.contains('how much') || query.contains('progress')) {
      return QueryIntent.limitCheck;
    }
    return QueryIntent.cardRecommendation;
  }

  double _calculateConfidence(SpendingCategory? category, String? merchant, double? amount, QueryIntent intent) {
    var confidence = 0.0;
    if (category != null) confidence += 0.4;
    if (merchant != null) confidence += 0.3;
    if (amount != null) confidence += 0.2;
    if (intent == QueryIntent.cardRecommendation) confidence += 0.1;
    else if (intent == QueryIntent.spendingUpdate || intent == QueryIntent.limitCheck) confidence += 0.05;
    return confidence.clamp(0.0, 1.0);
  }

  static const commonQueries = [
    'What card should I use for groceries?',
    'Which card is best for dining out?',
    "I'm buying gas, which card?",
    'Shopping at Amazon, what card?',
    'Going to Costco, best card?',
    'Dining at a restaurant tonight',
    'Booking a flight to Europe',
    'Filling up at the gas station',
    'Buying groceries at Whole Foods',
    'Shopping online at Target',
  ];
}
