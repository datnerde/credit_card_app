import Foundation

class LLMRecommendationEngine {
    private let appleIntelligenceService: AppleIntelligenceService
    private let ragService: RAGService
    private let contextBuilder: ContextBuilder
    private var recommendationCache: [String: String] = [:]
    private var cacheMaxSize: Int = 100
    
    init(
        appleIntelligenceService: AppleIntelligenceService = AppleIntelligenceService.shared,
        ragService: RAGService = RAGService.shared,
        contextBuilder: ContextBuilder = ContextBuilder.shared
    ) {
        self.appleIntelligenceService = appleIntelligenceService
        self.ragService = ragService
        self.contextBuilder = contextBuilder
        print("🤖 LLMRecommendationEngine initialized")
    }
    
    // MARK: - Main Recommendation Flow (LLM-Powered)
    
    func getRecommendation(
        for query: String, 
        userCards: [CreditCard], 
        userPreferences: UserPreferences,
        recentMessages: [ChatMessage] = []
    ) async throws -> String {
        
        // Validate inputs
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw RecommendationError.invalidQuery("Query cannot be empty")
        }
        
        guard !userCards.isEmpty else {
            return "I'd love to help with credit card recommendations! Please add your credit cards first so I can provide personalized advice based on your portfolio."
        }
        
        // Check cache first
        let cacheKey = createCacheKey(query: query, cards: userCards)
        if let cachedResponse = getCachedRecommendation(for: cacheKey) {
            print("💾 Returning cached recommendation")
            return cachedResponse
        }
        
        do {
            // Build context using RAG
            print("🔍 Building context for query: \(query.prefix(50))...")
            let context = await contextBuilder.buildContext(
                query: query,
                cards: userCards,
                preferences: userPreferences,
                recentMessages: recentMessages
            )
            
            // Generate response using Apple Intelligence
            print("🧠 Generating LLM response")
            let llmResponse = try await appleIntelligenceService.generateResponse(
                for: query,
                context: context.fullContext
            )
            
            // Post-process the response
            let finalResponse = postProcessResponse(llmResponse, userCards: userCards)
            
            // Cache the result
            cacheRecommendation(finalResponse, for: cacheKey)
            
            print("✅ LLM recommendation generated successfully")
            return finalResponse
            
        } catch {
            print("❌ LLM generation failed: \(error), falling back to rule-based")
            // Fallback to rule-based recommendation
            return try await generateFallbackRecommendation(query: query, userCards: userCards, userPreferences: userPreferences)
        }
    }
    
    // MARK: - Chat Message Processing
    
    func generateChatResponse(
        for message: String,
        userCards: [CreditCard],
        userPreferences: UserPreferences,
        conversationHistory: [ChatMessage] = []
    ) async throws -> ChatMessage {
        
        let response = try await getRecommendation(
            for: message,
            userCards: userCards,
            userPreferences: userPreferences,
            recentMessages: conversationHistory
        )
        
        // Extract any recommendations from the response
        let recommendations = extractRecommendations(from: response, userCards: userCards)
        
        return ChatMessage(
            content: response,
            sender: .assistant,
            cardRecommendations: recommendations.isEmpty ? nil : recommendations
        )
    }
    
    // MARK: - Response Post-Processing
    
    private func postProcessResponse(_ response: String, userCards: [CreditCard]) -> String {
        var processedResponse = response
        
        // Replace placeholders with actual data
        processedResponse = replacePlaceholders(in: processedResponse, userCards: userCards)
        
        // Add emojis and formatting
        processedResponse = addFormatting(to: processedResponse)
        
        // Ensure response is within reasonable length
        if processedResponse.count > 1000 {
            processedResponse = String(processedResponse.prefix(950)) + "..."
        }
        
        return processedResponse
    }
    
    private func replacePlaceholders(in response: String, userCards: [CreditCard]) -> String {
        var processed = response
        
        // Replace {recommendation} with actual card name
        if processed.contains("{recommendation}") {
            let topCard = userCards.first { $0.isActive }?.name ?? "your best card"
            processed = processed.replacingOccurrences(of: "{recommendation}", with: topCard)
        }
        
        // Replace {points} with calculated points
        if processed.contains("{points}") {
            processed = processed.replacingOccurrences(of: "{points}", with: "bonus")
        }
        
        return processed
    }
    
    private func addFormatting(to response: String) -> String {
        var formatted = response
        
        // Add emphasis to card names
        let cardPattern = #"(Chase|Amex|Citi|Capital One|Discover)\s+[A-Za-z\s]+"#
        if let regex = try? NSRegularExpression(pattern: cardPattern) {
            let range = NSRange(location: 0, length: formatted.utf16.count)
            formatted = regex.stringByReplacingMatches(
                in: formatted,
                options: [],
                range: range,
                withTemplate: "**$1**"
            )
        }
        
        return formatted
    }
    
    // MARK: - Fallback Logic
    
    private func generateFallbackRecommendation(
        query: String,
        userCards: [CreditCard],
        userPreferences: UserPreferences
    ) async throws -> String {
        
        print("🔄 Using fallback recommendation logic")
        
        let activeCards = userCards.filter { $0.isActive }
        guard let bestCard = activeCards.first else {
            return "You don't have any active credit cards. Please add and activate a card to get recommendations."
        }
        
        // Simple category matching
        let category = extractCategoryFromQuery(query)
        let relevantCard = findBestCardForCategory(category, in: activeCards)
        
        let cardToRecommend = relevantCard ?? bestCard
        
        var response = "Based on your query, I recommend using your **\(cardToRecommend.name)**."
        
        // Add category-specific info if found
        if let category = category,
           let rewardCategory = cardToRecommend.rewardCategories.first(where: { $0.category == category }) {
            response += " It offers \(rewardCategory.multiplier)x \(rewardCategory.pointType.rawValue) points for \(category.displayName.lowercased())."
        }
        
        // Add limit warning if applicable
        if let category = category,
           let spendingLimit = cardToRecommend.spendingLimits.first(where: { $0.category == category }),
           spendingLimit.isWarningThreshold {
            response += " ⚠️ Note: You're approaching your spending limit for this category."
        }
        
        return response
    }
    
    // MARK: - Helper Functions
    
    private func createCacheKey(query: String, cards: [CreditCard]) -> String {
        let cardsHash = cards.map { $0.id.uuidString }.joined().hash
        let queryHash = query.lowercased().hash
        return "\(queryHash)_\(cardsHash)"
    }
    
    private func extractCategoryFromQuery(_ query: String) -> SpendingCategory? {
        let lowercasedQuery = query.lowercased()
        
        return SpendingCategory.allCases.first { category in
            lowercasedQuery.contains(category.rawValue.lowercased()) ||
            lowercasedQuery.contains(category.displayName.lowercased())
        }
    }
    
    private func findBestCardForCategory(_ category: SpendingCategory?, in cards: [CreditCard]) -> CreditCard? {
        guard let category = category else { return nil }
        
        return cards.max { card1, card2 in
            let score1 = getCardScore(card1, for: category)
            let score2 = getCardScore(card2, for: category)
            return score1 < score2
        }
    }
    
    private func getCardScore(_ card: CreditCard, for category: SpendingCategory) -> Double {
        var score: Double = 1.0
        
        // Regular rewards
        if let rewardCategory = card.rewardCategories.first(where: { $0.category == category }) {
            score = rewardCategory.multiplier
        }
        
        // Quarterly bonus
        if card.quarterlyBonus?.category == category {
            score = max(score, card.quarterlyBonus?.multiplier ?? 1.0)
        }
        
        // Penalty for reached limits
        if let spendingLimit = card.spendingLimits.first(where: { $0.category == category }),
           spendingLimit.isLimitReached {
            score = 0.1
        }
        
        return score
    }
    
    private func extractRecommendations(from response: String, userCards: [CreditCard]) -> [CardRecommendation] {
        // Extract card recommendations from the LLM response
        var recommendations: [CardRecommendation] = []
        
        for card in userCards {
            if response.lowercased().contains(card.name.lowercased()) {
                let recommendation = CardRecommendation(
                    cardId: card.id,
                    cardName: card.name,
                    category: .general, // Default category
                    multiplier: 1.0,    // Default multiplier
                    pointType: card.rewardCategories.first?.pointType ?? .membershipRewards,
                    reasoning: "Recommended based on your query",
                    rank: recommendations.count + 1
                )
                recommendations.append(recommendation)
            }
        }
        
        return Array(recommendations.prefix(2)) // Limit to 2 recommendations
    }
    
    // MARK: - Caching
    
    private func getCachedRecommendation(for key: String) -> String? {
        return recommendationCache[key]
    }
    
    private func cacheRecommendation(_ response: String, for key: String) {
        recommendationCache[key] = response
        
        // Simple LRU - remove oldest entries if cache gets too large
        if recommendationCache.count > cacheMaxSize {
            let keys = Array(recommendationCache.keys)
            let keysToRemove = keys.dropLast(cacheMaxSize)
            keysToRemove.forEach { recommendationCache.removeValue(forKey: $0) }
        }
    }
    
    // MARK: - Cache Management
    
    func clearCache() {
        recommendationCache.removeAll()
        ragService.clearCache()
        print("🧹 LLM recommendation cache cleared")
    }
    
    func getCacheStats() -> (cached: Int, maxSize: Int) {
        return (cached: recommendationCache.count, maxSize: cacheMaxSize)
    }
}

// MARK: - Error Types (reusing existing ones)

extension RecommendationError {
    static func llmProcessingError(_ message: String) -> RecommendationError {
        return .processingError
    }
}