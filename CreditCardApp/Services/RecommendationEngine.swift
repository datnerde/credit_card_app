import Foundation

class RecommendationEngine {
    private let nlpProcessor: NLPProcessor
    private var recommendationCache: [String: RecommendationResponse] = [:]
    private var cacheMaxSize: Int = 100
    
    init(nlpProcessor: NLPProcessor = NLPProcessor()) {
        self.nlpProcessor = nlpProcessor
    }
    
    // MARK: - Caching
    
    func getCachedRecommendation(for key: String) -> RecommendationResponse? {
        return recommendationCache[key]
    }
    
    func cacheRecommendation(_ response: RecommendationResponse, for key: String) {
        recommendationCache[key] = response
        
        // Simple LRU - remove oldest entries if cache gets too large
        if recommendationCache.count > cacheMaxSize {
            let keys = Array(recommendationCache.keys)
            let keysToRemove = keys.dropLast(cacheMaxSize)
            keysToRemove.forEach { recommendationCache.removeValue(forKey: $0) }
        }
    }
    
    // MARK: - Main Recommendation Flow
    
    func getRecommendation(for query: String, userCards: [CreditCard], userPreferences: UserPreferences) async throws -> RecommendationResponse {
        // Parse user query
        let parsedQuery = nlpProcessor.parseUserQuery(query)
        
        // Validate query
        let validation = nlpProcessor.validateQuery(query)
        guard validation.isValid else {
            throw RecommendationError.invalidQuery(validation.error ?? "Invalid query")
        }
        
        // Check if user has cards
        guard !userCards.isEmpty else {
            throw RecommendationError.noCardsAvailable
        }
        
        // Determine spending category
        let category = determineSpendingCategory(parsedQuery)
        
        // Score all cards
        let scoredCards = scoreCards(
            cards: userCards,
            category: category,
            merchant: parsedQuery.merchant,
            preferences: userPreferences
        )
        
        // Filter and rank recommendations
        let recommendations = filterAndRankRecommendations(scoredCards)
        
        // Generate response
        return generateResponse(recommendations, category, userPreferences, parsedQuery)
    }
    
    // MARK: - Card Scoring Algorithm
    
    private func scoreCards(cards: [CreditCard], category: SpendingCategory, merchant: String?, preferences: UserPreferences) -> [CardScore] {
        return cards.compactMap { card in
            guard card.isActive else { return nil }
            
            let baseScore = 1.0
            let categoryScore = calculateCategoryScore(card, category)
            let preferenceScore = calculatePreferenceScore(card, preferences)
            let limitScore = calculateLimitScore(card, category)
            
            // Weighted total score
            let totalScore = (baseScore * 0.1) + 
                           (categoryScore * 0.6) + 
                           (preferenceScore * 0.2) + 
                           (limitScore * 0.1)
            
            let reasoning = generateReasoning(card, category, categoryScore, limitScore)
            
            return CardScore(
                card: card,
                category: category,
                baseScore: baseScore,
                categoryScore: categoryScore,
                preferenceScore: preferenceScore,
                limitScore: limitScore,
                totalScore: totalScore,
                reasoning: reasoning
            )
        }
    }
    
    private func calculateCategoryScore(_ card: CreditCard, _ category: SpendingCategory) -> Double {
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
    
    private func calculatePreferenceScore(_ card: CreditCard, _ preferences: UserPreferences) -> Double {
        // Check if card offers preferred point system
        let hasPreferredPoints = card.rewardCategories.contains { 
            $0.pointType == preferences.preferredPointSystem 
        }
        
        return hasPreferredPoints ? 1.2 : 1.0 // 20% bonus for preferred points
    }
    
    private func calculateLimitScore(_ card: CreditCard, _ category: SpendingCategory) -> Double {
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
    
    // MARK: - Recommendation Filtering and Ranking
    
    private func filterAndRankRecommendations(_ scoredCards: [CardScore]) -> [CardScore] {
        // Sort by total score (highest first)
        let sortedCards = scoredCards.sorted { $0.totalScore > $1.totalScore }
        
        // Filter out cards with zero scores (limit reached)
        let availableCards = sortedCards.filter { $0.totalScore > 0 }
        
        // Return top 2 recommendations
        return Array(availableCards.prefix(2))
    }
    
    // MARK: - Response Generation
    
    private func generateResponse(_ recommendations: [CardScore], _ category: SpendingCategory, _ preferences: UserPreferences, _ parsedQuery: ParsedQuery) -> RecommendationResponse {
        guard let primaryRecommendation = recommendations.first else {
            return RecommendationResponse(
                primaryRecommendation: nil,
                secondaryRecommendation: nil,
                reasoning: "No suitable cards found for this category.",
                warnings: ["All cards have reached their limits for this category."],
                suggestions: ["Consider using a card with general rewards."]
            )
        }
        
        let secondaryRecommendation = recommendations.count > 1 ? recommendations[1] : nil
        
        // Generate primary recommendation
        let primaryCardRecommendation = createCardRecommendation(from: primaryRecommendation, rank: 1)
        let secondaryCardRecommendation = secondaryRecommendation.map { createCardRecommendation(from: $0, rank: 2) }
        
        // Generate reasoning
        let reasoning = generateOverallReasoning(primaryRecommendation, secondaryRecommendation, category)
        
        // Generate warnings
        let warnings = generateWarnings(recommendations)
        
        // Generate suggestions
        let suggestions = generateSuggestions(recommendations, category, preferences)
        
        return RecommendationResponse(
            primaryRecommendation: primaryCardRecommendation,
            secondaryRecommendation: secondaryCardRecommendation,
            reasoning: reasoning,
            warnings: warnings,
            suggestions: suggestions
        )
    }
    
    private func createCardRecommendation(from cardScore: CardScore, rank: Int) -> CardRecommendation {
        let spendingLimit = cardScore.card.spendingLimits.first { $0.category == cardScore.category }
        
        return CardRecommendation(
            cardId: cardScore.card.id,
            cardName: cardScore.card.name,
            category: cardScore.category,
            multiplier: cardScore.categoryScore,
            pointType: getPointType(cardScore.card, cardScore.category),
            reasoning: cardScore.reasoning,
            currentSpending: spendingLimit?.currentSpending ?? 0.0,
            limit: spendingLimit?.limit ?? 0.0,
            isLimitReached: cardScore.limitScore == 0.0,
            rank: rank
        )
    }
    
    private func getPointType(_ card: CreditCard, _ category: SpendingCategory) -> PointType {
        if let rewardCategory = card.rewardCategories.first(where: { $0.category == category }) {
            return rewardCategory.pointType
        }
        return .membershipRewards // Default
    }
    
    // MARK: - Reasoning Generation
    
    private func generateReasoning(_ card: CreditCard, _ category: SpendingCategory, _ score: Double, _ limitScore: Double) -> String {
        var reasoning = ""
        
        // Base reasoning
        if let rewardCategory = card.rewardCategories.first(where: { $0.category == category }) {
            reasoning += "\(card.name) offers \(rewardCategory.multiplier)x \(rewardCategory.pointType.rawValue) points on \(category.rawValue.lowercased())."
        }
        
        // Limit information
        if let spendingLimit = card.spendingLimits.first(where: { $0.category == category }) {
            let remaining = spendingLimit.remainingAmount
            reasoning += " You have $\(String(format: "%.0f", remaining)) remaining in your limit."
            
            if limitScore == 0.0 {
                reasoning += " ⚠️ Limit reached - consider using another card."
            } else if limitScore == 0.5 {
                reasoning += " ⚠️ Limit almost reached."
            }
        }
        
        return reasoning
    }
    
    private func generateOverallReasoning(_ primary: CardScore, _ secondary: CardScore?, _ category: SpendingCategory) -> String {
        var reasoning = "Based on your \(category.rawValue.lowercased()) purchase, I recommend using your \(primary.card.name). "
        reasoning += primary.reasoning
        
        if let secondary = secondary {
            reasoning += "\n\nAs a backup option, \(secondary.card.name) offers \(String(format: "%.1f", secondary.categoryScore))x points."
        }
        
        return reasoning
    }
    
    private func generateWarnings(_ recommendations: [CardScore]) -> [String] {
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
    
    private func generateSuggestions(_ recommendations: [CardScore], _ category: SpendingCategory, _ preferences: UserPreferences) -> [String] {
        var suggestions: [String] = []
        
        // Check if all cards have low scores
        let lowScoreCards = recommendations.filter { $0.totalScore < 2.0 }
        if lowScoreCards.count == recommendations.count {
            suggestions.append("Consider adding a card that offers better rewards for \(category.rawValue.lowercased()).")
        }
        
        // Suggest based on preferences
        if preferences.preferredPointSystem != .membershipRewards {
            suggestions.append("You might want to prioritize cards that earn \(preferences.preferredPointSystem.rawValue) points.")
        }
        
        return suggestions
    }
    
    // MARK: - Helper Methods
    
    private func determineSpendingCategory(_ parsedQuery: ParsedQuery) -> SpendingCategory {
        // Use parsed category if available
        if let category = parsedQuery.spendingCategory {
            return category
        }
        
        // Try to map merchant to category
        if let merchant = parsedQuery.merchant,
           let category = merchantMappings[merchant] {
            return category
        }
        
        // Default to general purchases
        return .general
    }
    
    // MARK: - Seasonal Bonus Detection
    
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
    
    // MARK: - Multi-Card Optimization
    
    func optimizeMultiCardStrategy(_ cards: [CreditCard], _ amount: Double, _ category: SpendingCategory, _ preferences: UserPreferences) -> [CardRecommendation] {
        var recommendations: [CardRecommendation] = []
        
        // Sort cards by score
        let scoredCards = scoreCards(cards: cards, category: category, merchant: nil, preferences: preferences)
            .sorted { $0.totalScore > $1.totalScore }
        
        // Check if splitting payment across multiple cards is beneficial
        for (index, scoredCard) in scoredCards.enumerated() {
            if index < 2 { // Top 2 cards
                let recommendation = createCardRecommendation(from: scoredCard, rank: index + 1)
                recommendations.append(recommendation)
            }
        }
        
        return recommendations
    }
}

// MARK: - Supporting Types

struct RecommendationRequest {
    let userQuery: String
    let spendingCategory: SpendingCategory?
    let merchant: String?
    let amount: Double?
    let userPreferences: UserPreferences
    let userCards: [CreditCard]
}

struct RecommendationResponse {
    let primaryRecommendation: CardRecommendation?
    let secondaryRecommendation: CardRecommendation?
    let reasoning: String
    let warnings: [String]
    let suggestions: [String]
}

struct CardScore {
    let card: CreditCard
    let category: SpendingCategory
    let baseScore: Double
    let categoryScore: Double
    let preferenceScore: Double
    let limitScore: Double
    let totalScore: Double
    let reasoning: String
}

enum RecommendationError: Error, LocalizedError {
    case invalidQuery(String)
    case noCardsAvailable
    case categoryNotRecognized
    case processingError
    
    var errorDescription: String? {
        switch self {
        case .invalidQuery(let message):
            return "Invalid query: \(message)"
        case .noCardsAvailable:
            return "Please add your credit cards first to get personalized recommendations."
        case .categoryNotRecognized:
            return "I don't recognize that spending category. Please try rephrasing your question."
        case .processingError:
            return "Sorry, I encountered an error processing your request. Please try again."
        }
    }
}

 