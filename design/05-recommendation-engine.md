# Recommendation Engine & Algorithms

## Core Recommendation Algorithm

### 1. Input Processing
```swift
struct RecommendationRequest {
    let userQuery: String
    let spendingCategory: SpendingCategory?
    let merchant: String?
    let amount: Double?
    let userPreferences: UserPreferences
    let userCards: [CreditCard]
}

struct RecommendationResponse {
    let primaryRecommendation: CardRecommendation
    let secondaryRecommendation: CardRecommendation?
    let reasoning: String
    let warnings: [String]
    let suggestions: [String]
}
```

### 2. Main Recommendation Flow
```swift
class RecommendationEngine {
    func getRecommendation(for request: RecommendationRequest) -> RecommendationResponse {
        // 1. Parse user query
        let parsedQuery = parseUserQuery(request.userQuery)
        
        // 2. Determine spending category
        let category = determineSpendingCategory(parsedQuery, request.spendingCategory)
        
        // 3. Score all cards
        let scoredCards = scoreCards(
            cards: request.userCards,
            category: category,
            merchant: request.merchant,
            preferences: request.userPreferences
        )
        
        // 4. Filter and rank recommendations
        let recommendations = filterAndRankRecommendations(scoredCards)
        
        // 5. Generate response
        return generateResponse(recommendations, category, request.userPreferences)
    }
}
```

## Card Scoring Algorithm

### 1. Base Score Calculation
```swift
struct CardScore {
    let card: CreditCard
    let baseScore: Double
    let categoryScore: Double
    let preferenceScore: Double
    let limitScore: Double
    let totalScore: Double
    let reasoning: String
}

func scoreCard(_ card: CreditCard, category: SpendingCategory, preferences: UserPreferences) -> CardScore {
    // Base score (1x points)
    let baseScore = 1.0
    
    // Category-specific score
    let categoryScore = calculateCategoryScore(card, category)
    
    // Preference score (bonus for preferred point system)
    let preferenceScore = calculatePreferenceScore(card, preferences)
    
    // Limit availability score
    let limitScore = calculateLimitScore(card, category)
    
    // Total weighted score
    let totalScore = (baseScore * 0.1) + 
                    (categoryScore * 0.6) + 
                    (preferenceScore * 0.2) + 
                    (limitScore * 0.1)
    
    return CardScore(
        card: card,
        baseScore: baseScore,
        categoryScore: categoryScore,
        preferenceScore: preferenceScore,
        limitScore: limitScore,
        totalScore: totalScore,
        reasoning: generateReasoning(card, category, categoryScore, limitScore)
    )
}
```

### 2. Category Score Calculation
```swift
func calculateCategoryScore(_ card: CreditCard, _ category: SpendingCategory) -> Double {
    // Find matching reward category
    guard let rewardCategory = card.rewardCategories.first(where: { 
        $0.category == category && $0.isActive 
    }) else {
        return 1.0 // Default 1x points
    }
    
    // Check quarterly bonus
    if let quarterlyBonus = card.quarterlyBonus,
       quarterlyBonus.category == category {
        return max(rewardCategory.multiplier, quarterlyBonus.multiplier)
    }
    
    return rewardCategory.multiplier
}
```

### 3. Preference Score Calculation
```swift
func calculatePreferenceScore(_ card: CreditCard, _ preferences: UserPreferences) -> Double {
    // Check if card offers preferred point system
    let hasPreferredPoints = card.rewardCategories.contains { 
        $0.pointType == preferences.preferredPointSystem 
    }
    
    return hasPreferredPoints ? 1.2 : 1.0 // 20% bonus for preferred points
}
```

### 4. Limit Score Calculation
```swift
func calculateLimitScore(_ card: CreditCard, _ category: SpendingCategory) -> Double {
    guard let spendingLimit = card.spendingLimits.first(where: { 
        $0.category == category 
    }) else {
        return 1.0 // No limit = no penalty
    }
    
    let usagePercentage = spendingLimit.currentSpending / spendingLimit.limit
    
    // Score based on remaining capacity
    if usagePercentage >= 1.0 {
        return 0.0 // Limit reached
    } else if usagePercentage >= 0.85 {
        return 0.5 // Warning threshold
    } else {
        return 1.0 // Plenty of capacity
    }
}
```

## Natural Language Processing

### 1. Query Parsing
```swift
struct ParsedQuery {
    let spendingCategory: SpendingCategory?
    let merchant: String?
    let amount: Double?
    let intent: QueryIntent
    let confidence: Double
}

enum QueryIntent {
    case cardRecommendation
    case spendingUpdate
    case limitCheck
    case generalQuestion
}

func parseUserQuery(_ query: String) -> ParsedQuery {
    let lowercasedQuery = query.lowercased()
    
    // Extract spending category
    let category = extractSpendingCategory(lowercasedQuery)
    
    // Extract merchant
    let merchant = extractMerchant(lowercasedQuery)
    
    // Extract amount
    let amount = extractAmount(lowercasedQuery)
    
    // Determine intent
    let intent = determineIntent(lowercasedQuery)
    
    return ParsedQuery(
        spendingCategory: category,
        merchant: merchant,
        amount: amount,
        intent: intent,
        confidence: calculateConfidence(category, merchant, amount)
    )
}
```

### 2. Category Extraction
```swift
func extractSpendingCategory(_ query: String) -> SpendingCategory? {
    let categoryKeywords: [SpendingCategory: [String]] = [
        .groceries: ["grocery", "groceries", "food", "supermarket", "market"],
        .dining: ["dining", "restaurant", "dinner", "lunch", "breakfast", "eat", "food"],
        .travel: ["travel", "flight", "hotel", "vacation", "trip"],
        .gas: ["gas", "fuel", "gasoline", "petrol"],
        .online: ["online", "internet", "web", "ecommerce"],
        .drugstores: ["drugstore", "pharmacy", "medicine", "drug"],
        .streaming: ["streaming", "netflix", "spotify", "hulu", "disney"],
        .transit: ["transit", "transportation", "uber", "lyft", "taxi"],
        .costco: ["costco"],
        .amazon: ["amazon"],
        .wholeFoods: ["whole foods", "wholefoods"],
        .target: ["target"],
        .walmart: ["walmart"]
    ]
    
    for (category, keywords) in categoryKeywords {
        if keywords.contains(where: { query.contains($0) }) {
            return category
        }
    }
    
    return nil
}
```

### 3. Merchant Extraction
```swift
func extractMerchant(_ query: String) -> String? {
    let merchants = merchantMappings.keys
    
    for merchant in merchants {
        if query.contains(merchant) {
            return merchant
        }
    }
    
    return nil
}
```

## Response Generation

### 1. Reasoning Generation
```swift
func generateReasoning(_ card: CreditCard, _ category: SpendingCategory, _ score: Double, _ limitScore: Double) -> String {
    var reasoning = ""
    
    // Base reasoning
    if let rewardCategory = card.rewardCategories.first(where: { $0.category == category }) {
        reasoning += "\(card.name) offers \(rewardCategory.multiplier)x \(rewardCategory.pointType.rawValue) points on \(category.rawValue.lowercased())."
    }
    
    // Limit information
    if let spendingLimit = card.spendingLimits.first(where: { $0.category == category }) {
        let remaining = spendingLimit.limit - spendingLimit.currentSpending
        reasoning += " You have $\(String(format: "%.0f", remaining)) remaining in your limit."
        
        if limitScore == 0.0 {
            reasoning += " ⚠️ Limit reached - consider using another card."
        } else if limitScore == 0.5 {
            reasoning += " ⚠️ Limit almost reached."
        }
    }
    
    return reasoning
}
```

### 2. Warning Generation
```swift
func generateWarnings(_ recommendations: [CardScore]) -> [String] {
    var warnings: [String] = []
    
    for recommendation in recommendations {
        if recommendation.limitScore == 0.0 {
            warnings.append("\(recommendation.card.name) has reached its limit for this category.")
        } else if recommendation.limitScore == 0.5 {
            warnings.append("\(recommendation.card.name) is approaching its limit.")
        }
    }
    
    return warnings
}
```

## Advanced Features

### 1. Seasonal Bonus Detection
```swift
func checkSeasonalBonuses(_ card: CreditCard, _ category: SpendingCategory) -> Double {
    let currentQuarter = Calendar.current.component(.quarter, from: Date())
    let currentYear = Calendar.current.component(.year, from: Date())
    
    if let quarterlyBonus = card.quarterlyBonus,
       quarterlyBonus.category == category,
       quarterlyBonus.quarter == currentQuarter,
       quarterlyBonus.year == currentYear {
        return quarterlyBonus.multiplier
    }
    
    return 0.0
}
```

### 2. Multi-Card Optimization
```swift
func optimizeMultiCardStrategy(_ cards: [CreditCard], _ amount: Double, _ category: SpendingCategory) -> [CardRecommendation] {
    var recommendations: [CardRecommendation] = []
    
    // Sort cards by score
    let scoredCards = cards.map { scoreCard($0, category, userPreferences) }
        .sorted { $0.totalScore > $1.totalScore }
    
    // Check if splitting payment across multiple cards is beneficial
    for (index, scoredCard) in scoredCards.enumerated() {
        if index < 2 { // Top 2 cards
            let recommendation = CardRecommendation(
                cardId: scoredCard.card.id,
                cardName: scoredCard.card.name,
                category: category,
                multiplier: scoredCard.categoryScore,
                pointType: getPointType(scoredCard.card, category),
                reasoning: scoredCard.reasoning,
                currentSpending: getCurrentSpending(scoredCard.card, category),
                limit: getLimit(scoredCard.card, category),
                isLimitReached: scoredCard.limitScore == 0.0,
                rank: index + 1
            )
            recommendations.append(recommendation)
        }
    }
    
    return recommendations
}
```

## Performance Optimization

### 1. Caching Strategy
```swift
class RecommendationCache {
    private var cache: [String: RecommendationResponse] = [:]
    private let cacheExpiration: TimeInterval = 300 // 5 minutes
    
    func getCachedRecommendation(for key: String) -> RecommendationResponse? {
        // Implementation with expiration check
    }
    
    func cacheRecommendation(_ response: RecommendationResponse, for key: String) {
        // Implementation with timestamp
    }
}
```

### 2. Pre-computed Scores
```swift
class ScorePrecomputer {
    func precomputeScores(for cards: [CreditCard]) {
        // Pre-compute common category scores
        // Store in memory for faster access
    }
}
```

## Testing Scenarios

### 1. Basic Recommendations
- Groceries at Whole Foods → Amex Gold
- Dining at restaurant → Amex Gold
- Gas station → Chase Freedom (if in quarterly bonus)

### 2. Limit Scenarios
- Card at 90% limit → Warning + alternative suggestion
- Card at 100% limit → Alternative card only

### 3. Preference Scenarios
- User prefers UR → Chase cards prioritized
- User prefers MR → Amex cards prioritized

### 4. Edge Cases
- No cards added → Guidance message
- All limits reached → Best base rewards card
- Unrecognized category → General recommendation 