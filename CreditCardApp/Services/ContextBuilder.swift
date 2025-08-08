import Foundation

class ContextBuilder {
    static let shared = ContextBuilder()
    
    private init() {}
    
    // MARK: - Main Context Building
    
    func buildContext(
        query: String,
        cards: [CreditCard],
        preferences: UserPreferences,
        recentMessages: [ChatMessage] = []
    ) async -> LLMContext {
        
        let queryAnalysis = analyzeQuery(query)
        let cardContext = buildCardContext(cards: cards, queryAnalysis: queryAnalysis)
        let preferencesContext = buildPreferencesContext(preferences: preferences)
        let conversationContext = buildConversationContext(messages: recentMessages)
        let systemContext = buildSystemContext(queryAnalysis: queryAnalysis)
        
        return LLMContext(
            systemPrompt: systemContext,
            cardData: cardContext,
            userPreferences: preferencesContext,
            conversationHistory: conversationContext,
            queryAnalysis: queryAnalysis
        )
    }
    
    // MARK: - Query Analysis
    
    private func analyzeQuery(_ query: String) -> QueryAnalysis {
        let lowercasedQuery = query.lowercased()
        
        // Determine intent
        let intent = determineIntent(query: lowercasedQuery)
        
        // Extract entities
        let category = extractSpendingCategory(query: lowercasedQuery)
        let merchant = extractMerchant(query: lowercasedQuery)
        let amount = extractAmount(query: query)
        
        // Determine urgency
        let urgency = determineUrgency(query: lowercasedQuery)
        
        // Extract keywords
        let keywords = extractKeywords(query: lowercasedQuery)
        
        return QueryAnalysis(
            originalQuery: query,
            intent: intent,
            category: category,
            merchant: merchant,
            amount: amount,
            urgency: urgency,
            keywords: keywords
        )
    }
    
    private func determineIntent(query: String) -> QueryIntent {
        let intentPatterns: [QueryIntent: [String]] = [
            .cardRecommendation: ["which card", "best card", "recommend", "should i use", "what card"],
            .spendingUpdate: ["spent", "spending", "update", "bought", "purchased"],
            .limitInquiry: ["limit", "remaining", "how much left", "progress", "usage"],
            .rewardInquiry: ["points", "rewards", "cashback", "miles", "how many points"],
            .generalQuestion: ["what", "how", "why", "when", "tell me about"]
        ]
        
        for (intent, patterns) in intentPatterns {
            if patterns.contains(where: { query.contains($0) }) {
                return intent
            }
        }
        
        return .cardRecommendation // default
    }
    
    private func extractSpendingCategory(query: String) -> SpendingCategory? {
        let categoryKeywords: [SpendingCategory: [String]] = [
            .groceries: ["grocery", "groceries", "food shopping", "supermarket", "whole foods", "trader joe"],
            .dining: ["restaurant", "dining", "dinner", "lunch", "eating out", "food delivery"],
            .travel: ["travel", "flight", "hotel", "vacation", "trip", "airline", "airfare"],
            .gas: ["gas", "fuel", "shell", "exxon", "chevron", "bp", "mobil"],
            .online: ["online", "amazon", "shopping online", "e-commerce"],
            .streaming: ["netflix", "spotify", "hulu", "disney+", "apple tv", "streaming"],
            .transit: ["uber", "lyft", "taxi", "public transport", "metro", "bus"],
            .coffee: ["starbucks", "coffee", "cafe", "dunkin"],
            .drugstores: ["cvs", "walgreens", "pharmacy", "drugstore"]
        ]
        
        for (category, keywords) in categoryKeywords {
            if keywords.contains(where: { query.contains($0) }) {
                return category
            }
        }
        
        return nil
    }
    
    private func extractMerchant(query: String) -> String? {
        let merchants = Array(merchantMappings.keys)
        return merchants.first { query.contains($0) }
    }
    
    private func extractAmount(query: String) -> Double? {
        let patterns = [
            #"\$(\d+(?:\.\d{2})?)"#,  // $123.45
            #"(\d+) dollars"#,          // 123 dollars
            #"(\d+(?:\.\d{2})?) bucks"# // 123.45 bucks
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(location: 0, length: query.utf16.count)
                if let match = regex.firstMatch(in: query, options: [], range: range),
                   let amountRange = Range(match.range(at: 1), in: query) {
                    return Double(String(query[amountRange]))
                }
            }
        }
        
        return nil
    }
    
    private func determineUrgency(query: String) -> QueryUrgency {
        let urgentWords = ["urgent", "quick", "asap", "now", "immediately", "emergency"]
        let casualWords = ["maybe", "thinking about", "considering", "sometime"]
        
        if urgentWords.contains(where: { query.contains($0) }) {
            return .high
        } else if casualWords.contains(where: { query.contains($0) }) {
            return .low
        }
        
        return .medium
    }
    
    private func extractKeywords(query: String) -> [String] {
        let words = query.components(separatedBy: .whitespacesAndNewlines)
        let stopWords = Set(["the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by", "is", "am", "are", "was", "were", "be", "been", "being", "have", "has", "had", "do", "does", "did", "will", "would", "could", "should", "may", "might", "must", "can", "i", "you", "he", "she", "it", "we", "they", "me", "him", "her", "us", "them", "my", "your", "his", "her", "its", "our", "their"])
        
        return words
            .map { $0.lowercased().trimmingCharacters(in: .punctuationCharacters) }
            .filter { !stopWords.contains($0) && $0.count > 2 }
    }
    
    // MARK: - Context Building
    
    private func buildCardContext(cards: [CreditCard], queryAnalysis: QueryAnalysis) -> String {
        var context = "USER'S CREDIT CARD PORTFOLIO:\n\n"
        
        let activeCards = cards.filter { $0.isActive }
        let inactiveCards = cards.filter { !$0.isActive }
        
        // Prioritize cards based on query relevance
        let relevantCards = prioritizeCardsByRelevance(cards: activeCards, analysis: queryAnalysis)
        
        for (index, card) in relevantCards.enumerated() {
            context += "Card \(index + 1): \(card.name) (\(card.cardType.displayName))\n"
            
            // Reward structure
            if !card.rewardCategories.isEmpty {
                context += "Rewards:\n"
                for reward in card.rewardCategories.sorted(by: { $0.multiplier > $1.multiplier }) {
                    let highlight = (reward.category == queryAnalysis.category) ? " ⭐" : ""
                    context += "  • \(reward.category.displayName): \(formatMultiplier(reward.multiplier))x \(reward.pointType.rawValue)\(highlight)\n"
                }
            }
            
            // Quarterly bonus
            if let bonus = card.quarterlyBonus {
                let isRelevant = bonus.category == queryAnalysis.category
                let highlight = isRelevant ? " 🎯" : ""
                let progress = bonus.limit > 0 ? Int((bonus.currentSpending / bonus.limit) * 100) : 0
                
                context += "Q\(bonus.quarter) Bonus: \(bonus.category.displayName) \(formatMultiplier(bonus.multiplier))x (\(progress)% used)\(highlight)\n"
            }
            
            // Spending limits with status
            if !card.spendingLimits.isEmpty {
                context += "Limits:\n"
                for limit in card.spendingLimits {
                    let percentage = Int(limit.usagePercentage * 100)
                    let status = getStatusEmoji(for: limit)
                    let highlight = (limit.category == queryAnalysis.category) ? " ⭐" : ""
                    
                    context += "  • \(limit.category.displayName): $\(Int(limit.currentSpending))/$\(Int(limit.limit)) (\(percentage)%) \(status)\(highlight)\n"
                }
            }
            
            context += "\n"
        }
        
        // Mention inactive cards briefly
        if !inactiveCards.isEmpty {
            context += "Inactive Cards: \(inactiveCards.map { $0.name }.joined(separator: ", "))\n\n"
        }
        
        return context
    }
    
    private func buildPreferencesContext(preferences: UserPreferences) -> String {
        return """
        USER PREFERENCES:
        • Preferred Points: \(preferences.preferredPointSystem.displayName)
        • Alert Threshold: \(Int(preferences.alertThreshold * 100))%
        • Language: \(preferences.language.displayName)
        • Notifications: \(preferences.notificationsEnabled ? "On" : "Off")
        
        """
    }
    
    private func buildConversationContext(messages: [ChatMessage]) -> String {
        guard !messages.isEmpty else { return "" }
        
        let recentMessages = messages.suffix(5) // Last 5 messages for context
        var context = "RECENT CONVERSATION:\n"
        
        for message in recentMessages {
            let sender = message.sender == .user ? "User" : "Assistant"
            let content = message.content.prefix(100) // Truncate long messages
            context += "\(sender): \(content)\n"
        }
        
        return context + "\n"
    }
    
    private func buildSystemContext(queryAnalysis: QueryAnalysis) -> String {
        let currentDate = DateFormatter.mediumStyle.string(from: Date())
        let currentQuarter = Calendar.currentQuarter
        
        var systemContext = """
        You are an expert credit card recommendation assistant. Today is \(currentDate), Q\(currentQuarter).
        
        ANALYSIS OF USER'S QUERY:
        • Intent: \(queryAnalysis.intent.description)
        • Category: \(queryAnalysis.category?.displayName ?? "Not specified")
        • Merchant: \(queryAnalysis.merchant ?? "Not specified")
        • Amount: \(queryAnalysis.amount != nil ? "$\(Int(queryAnalysis.amount!))" : "Not specified")
        • Urgency: \(queryAnalysis.urgency.description)
        
        INSTRUCTIONS:
        1. Provide specific, actionable recommendations based on the user's portfolio
        2. Always mention exact multipliers and point types
        3. Warn about spending limits (🚨 if >85%, ⚠️ if >70%)
        4. Highlight quarterly bonuses when relevant
        5. Consider the user's preferred point system
        6. Be conversational but precise
        7. If asking for clarification, provide smart suggestions
        
        """
        
        // Add specific guidance based on intent
        switch queryAnalysis.intent {
        case .cardRecommendation:
            systemContext += "8. Recommend the optimal card with clear reasoning\n"
            systemContext += "9. Mention backup options if primary card has issues\n"
        case .spendingUpdate:
            systemContext += "8. Acknowledge the spending and update context\n"
            systemContext += "9. Provide insights on progress toward limits/bonuses\n"
        case .limitInquiry:
            systemContext += "8. Show current usage and remaining amounts\n"
            systemContext += "9. Provide timeline context (monthly/quarterly/annual)\n"
        case .rewardInquiry:
            systemContext += "8. Calculate potential earnings for the scenario\n"
            systemContext += "9. Compare options across different cards\n"
        case .generalQuestion:
            systemContext += "8. Provide educational information relevant to their portfolio\n"
            systemContext += "9. Suggest related optimizations\n"
        }
        
        return systemContext + "\n"
    }
    
    // MARK: - Helper Functions
    
    private func prioritizeCardsByRelevance(cards: [CreditCard], analysis: QueryAnalysis) -> [CreditCard] {
        return cards.sorted { card1, card2 in
            let score1 = calculateRelevanceScore(card: card1, analysis: analysis)
            let score2 = calculateRelevanceScore(card: card2, analysis: analysis)
            return score1 > score2
        }
    }
    
    private func calculateRelevanceScore(card: CreditCard, analysis: QueryAnalysis) -> Double {
        var score: Double = 0
        
        // Base score for active cards
        score += card.isActive ? 1.0 : 0.1
        
        // Category match bonus
        if let queryCategory = analysis.category {
            // Check regular rewards
            if let rewardCategory = card.rewardCategories.first(where: { $0.category == queryCategory }) {
                score += Double(rewardCategory.multiplier) * 2
            }
            
            // Check quarterly bonus
            if card.quarterlyBonus?.category == queryCategory {
                score += Double(card.quarterlyBonus?.multiplier ?? 0) * 3
            }
            
            // Penalty for reached limits
            if let spendingLimit = card.spendingLimits.first(where: { $0.category == queryCategory }) {
                if spendingLimit.isLimitReached {
                    score -= 10
                } else if spendingLimit.isWarningThreshold {
                    score -= 3
                }
            }
        }
        
        // Merchant bonus
        if let merchant = analysis.merchant,
           let category = merchantMappings[merchant.lowercased()],
           card.rewardCategories.contains(where: { $0.category == category }) {
            score += 1
        }
        
        return score
    }
    
    private func formatMultiplier(_ multiplier: Double) -> String {
        return multiplier.truncatingRemainder(dividingBy: 1) == 0 ? 
               String(format: "%.0f", multiplier) : 
               String(format: "%.1f", multiplier)
    }
    
    private func getStatusEmoji(for limit: SpendingLimit) -> String {
        if limit.isLimitReached {
            return "🚨"
        } else if limit.isWarningThreshold {
            return "⚠️"
        } else if limit.usagePercentage > 0.5 {
            return "📈"
        } else {
            return "✅"
        }
    }
}

// MARK: - Supporting Types

struct LLMContext {
    let systemPrompt: String
    let cardData: String
    let userPreferences: String
    let conversationHistory: String
    let queryAnalysis: QueryAnalysis
    
    var fullContext: String {
        return [systemPrompt, cardData, userPreferences, conversationHistory]
            .filter { !$0.isEmpty }
            .joined(separator: "\n" + String(repeating: "-", count: 50) + "\n")
    }
}

struct QueryAnalysis {
    let originalQuery: String
    let intent: QueryIntent
    let category: SpendingCategory?
    let merchant: String?
    let amount: Double?
    let urgency: QueryUrgency
    let keywords: [String]
}

enum QueryIntent: CaseIterable {
    case cardRecommendation
    case spendingUpdate
    case limitInquiry
    case rewardInquiry
    case generalQuestion
    
    var description: String {
        switch self {
        case .cardRecommendation: return "Seeking card recommendation"
        case .spendingUpdate: return "Updating spending information"
        case .limitInquiry: return "Checking spending limits/progress"
        case .rewardInquiry: return "Asking about rewards/points"
        case .generalQuestion: return "General information request"
        }
    }
}

enum QueryUrgency {
    case low, medium, high
    
    var description: String {
        switch self {
        case .low: return "Low (casual inquiry)"
        case .medium: return "Medium (standard request)"
        case .high: return "High (urgent/immediate)"
        }
    }
}

extension DateFormatter {
    static let mediumStyle: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}