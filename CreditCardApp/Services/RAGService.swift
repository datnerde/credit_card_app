import Foundation

class RAGService: ObservableObject {
    static let shared = RAGService()
    
    private let appleIntelligenceService: AppleIntelligenceService
    private var cardContextCache: [String: String] = [:]
    private var embeddingCache: [String: [Double]] = [:]
    
    private init() {
        self.appleIntelligenceService = AppleIntelligenceService.shared
        print("🔍 RAG Service initialized")
    }
    
    // MARK: - Context Generation
    
    func generateContext(for userCards: [CreditCard], userPreferences: UserPreferences, query: String) async throws -> String {
        // Generate relevant context based on user's cards and query
        let cardContexts = await generateCardContexts(cards: userCards)
        let preferencesContext = generatePreferencesContext(preferences: userPreferences)
        let spendingContext = generateSpendingContext(cards: userCards)
        
        // Find most relevant contexts using embeddings
        let allContexts = cardContexts + [preferencesContext, spendingContext]
        let relevantContexts = try await appleIntelligenceService.findSimilarContext(
            query: query,
            contexts: allContexts
        )
        
        return buildFinalContext(relevantContexts: relevantContexts, userPreferences: userPreferences)
    }
    
    // MARK: - Card Context Generation
    
    private func generateCardContexts(cards: [CreditCard]) async -> [String] {
        var contexts: [String] = []
        
        for card in cards {
            let context = await generateSingleCardContext(card: card)
            contexts.append(context)
            
            // Cache the context for future use
            cardContextCache[card.id.uuidString] = context
        }
        
        return contexts
    }
    
    private func generateSingleCardContext(card: CreditCard) async -> String {
        // Check cache first
        if let cached = cardContextCache[card.id.uuidString] {
            return cached
        }
        
        var context = """
        Card: \(card.name) (\(card.cardType.displayName))
        Status: \(card.isActive ? "Active" : "Inactive")
        
        """
        
        // Reward categories
        if !card.rewardCategories.isEmpty {
            context += "Rewards:\n"
            for reward in card.rewardCategories {
                context += "- \(reward.category.displayName): \(reward.multiplier)x \(reward.pointType.displayName)\n"
            }
            context += "\n"
        }
        
        // Quarterly bonus
        if let bonus = card.quarterlyBonus {
            let progress = bonus.limit > 0 ? (bonus.currentSpending / bonus.limit * 100) : 0
            context += """
            Q\(bonus.quarter) \(bonus.year) Bonus:
            - Category: \(bonus.category.displayName)
            - Multiplier: \(bonus.multiplier)x \(bonus.pointType.displayName)
            - Progress: $\(Int(bonus.currentSpending))/$\(Int(bonus.limit)) (\(Int(progress))%)
            
            """
        }
        
        // Spending limits
        if !card.spendingLimits.isEmpty {
            context += "Spending Limits:\n"
            for limit in card.spendingLimits {
                let progress = limit.usagePercentage * 100
                let status = limit.isLimitReached ? "LIMIT REACHED" : 
                            limit.isWarningThreshold ? "NEAR LIMIT" : "OK"
                
                context += "- \(limit.category.displayName): $\(Int(limit.currentSpending))/$\(Int(limit.limit)) (\(Int(progress))%) - \(status)\n"
            }
            context += "\n"
        }
        
        return context
    }
    
    // MARK: - Preferences Context
    
    private func generatePreferencesContext(preferences: UserPreferences) -> String {
        return """
        User Preferences:
        - Preferred Point System: \(preferences.preferredPointSystem.displayName)
        - Alert Threshold: \(Int(preferences.alertThreshold * 100))%
        - Language: \(preferences.language.displayName)
        - Notifications: \(preferences.notificationsEnabled ? "Enabled" : "Disabled")
        - Auto Update Spending: \(preferences.autoUpdateSpending ? "Enabled" : "Disabled")
        
        """
    }
    
    // MARK: - Spending Context
    
    private func generateSpendingContext(cards: [CreditCard]) -> String {
        var context = "Spending Analysis:\n"
        
        var totalLimits: [SpendingCategory: (current: Double, limit: Double)] = [:]
        
        for card in cards.filter({ $0.isActive }) {
            for spendingLimit in card.spendingLimits {
                if let existing = totalLimits[spendingLimit.category] {
                    totalLimits[spendingLimit.category] = (
                        current: existing.current + spendingLimit.currentSpending,
                        limit: existing.limit + spendingLimit.limit
                    )
                } else {
                    totalLimits[spendingLimit.category] = (
                        current: spendingLimit.currentSpending,
                        limit: spendingLimit.limit
                    )
                }
            }
        }
        
        for (category, totals) in totalLimits {
            let percentage = totals.limit > 0 ? (totals.current / totals.limit * 100) : 0
            context += "- \(category.displayName): \(Int(percentage))% utilized\n"
        }
        
        return context
    }
    
    // MARK: - Context Building
    
    private func buildFinalContext(relevantContexts: [String], userPreferences: UserPreferences) -> String {
        let separator = "\n" + String(repeating: "-", count: 40) + "\n"
        let finalContext = relevantContexts.joined(separator: separator)
        
        let systemPrompt = """
        SYSTEM CONTEXT:
        You are an expert credit card recommendation assistant with access to the user's complete card portfolio and preferences. Use this information to provide personalized, accurate advice.
        
        KEY PRINCIPLES:
        1. Always recommend the card that maximizes rewards for the specific purchase
        2. Warn users when approaching or at spending limits
        3. Consider the user's preferred point system: \(userPreferences.preferredPointSystem.displayName)
        4. Be specific about multipliers, limits, and potential earnings
        5. If limits are reached, suggest alternative cards
        6. Factor in quarterly bonuses when applicable
        
        USER DATA:
        \(separator)
        \(finalContext)
        \(separator)
        
        """
        
        return systemPrompt
    }
    
    // MARK: - Query Enhancement
    
    func enhanceQuery(originalQuery: String, cards: [CreditCard]) async throws -> String {
        // Extract entities and context from the query
        let extractedEntities = extractEntities(from: originalQuery)
        var enhancedQuery = originalQuery
        
        // Add context about relevant cards
        if let category = extractedEntities.category {
            let relevantCards = cards.filter { card in
                card.rewardCategories.contains { $0.category == category } ||
                card.quarterlyBonus?.category == category
            }
            
            if !relevantCards.isEmpty {
                enhancedQuery += "\n\nRelevant cards for \(category.displayName): \(relevantCards.map { $0.name }.joined(separator: ", "))"
            }
        }
        
        // Add merchant context
        if let merchant = extractedEntities.merchant {
            enhancedQuery += "\n\nMerchant: \(merchant)"
            if let category = merchantMappings[merchant.lowercased()] {
                enhancedQuery += " (Category: \(category.displayName))"
            }
        }
        
        return enhancedQuery
    }
    
    // MARK: - Entity Extraction
    
    private func extractEntities(from query: String) -> (category: SpendingCategory?, merchant: String?, amount: Double?) {
        let lowercasedQuery = query.lowercased()
        
        // Extract spending category
        let category = SpendingCategory.allCases.first { cat in
            lowercasedQuery.contains(cat.rawValue.lowercased())
        }
        
        // Extract merchant
        let merchant = merchantMappings.keys.first { merchantName in
            lowercasedQuery.contains(merchantName)
        }
        
        // Extract amount
        let amount = extractAmount(from: query)
        
        return (category: category, merchant: merchant, amount: amount)
    }
    
    private func extractAmount(from query: String) -> Double? {
        let pattern = #"\$?(\d+(?:\.\d{2})?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }
        
        let range = NSRange(location: 0, length: query.utf16.count)
        let matches = regex.matches(in: query, options: [], range: range)
        
        if let match = matches.first,
           let range = Range(match.range(at: 1), in: query) {
            let amountString = String(query[range])
            return Double(amountString)
        }
        
        return nil
    }
    
    // MARK: - Cache Management
    
    func clearCache() {
        cardContextCache.removeAll()
        embeddingCache.removeAll()
        print("🧹 RAG Service cache cleared")
    }
    
    func updateCardContext(for card: CreditCard) async {
        let context = await generateSingleCardContext(card: card)
        cardContextCache[card.id.uuidString] = context
        print("🔄 Updated context cache for card: \(card.name)")
    }
    
    // MARK: - Analytics
    
    func getContextStats() -> RAGStats {
        return RAGStats(
            cachedCards: cardContextCache.count,
            cachedEmbeddings: embeddingCache.count,
            cacheSize: cardContextCache.values.reduce(0) { $0 + $1.count }
        )
    }
}

// MARK: - Supporting Types

struct RAGStats {
    let cachedCards: Int
    let cachedEmbeddings: Int
    let cacheSize: Int
}

struct EntityExtractionResult {
    let category: SpendingCategory?
    let merchant: String?
    let amount: Double?
    let confidence: Double
}