import Foundation

struct RecommendationResponse {
    let primaryRecommendation: CardRecommendation?
    let secondaryRecommendation: CardRecommendation?
    let reasoning: String
    let warnings: [String]
    let suggestions: [String]
    let confidence: Double
    
    init(primaryRecommendation: CardRecommendation? = nil,
         secondaryRecommendation: CardRecommendation? = nil,
         reasoning: String = "",
         warnings: [String] = [],
         suggestions: [String] = [],
         confidence: Double = 1.0) {
        self.primaryRecommendation = primaryRecommendation
        self.secondaryRecommendation = secondaryRecommendation
        self.reasoning = reasoning
        self.warnings = warnings
        self.suggestions = suggestions
        self.confidence = confidence
    }
}

struct ParsedQuery {
    let originalQuery: String
    let spendingCategory: SpendingCategory?
    let merchant: String?
    let amount: Double?
    let intent: QueryIntent
    
    init(originalQuery: String,
         spendingCategory: SpendingCategory? = nil,
         merchant: String? = nil,
         amount: Double? = nil,
         intent: QueryIntent = .recommendation) {
        self.originalQuery = originalQuery
        self.spendingCategory = spendingCategory
        self.merchant = merchant
        self.amount = amount
        self.intent = intent
    }
}

enum QueryIntent {
    case recommendation
    case spendingUpdate
    case limitInquiry
    case cardManagement
}