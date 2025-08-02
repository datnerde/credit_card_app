import Foundation

// MARK: - NLP Processor
class NLPProcessor {
    
    // MARK: - Query Parsing
    
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
        
        // Calculate confidence
        let confidence = calculateConfidence(category: category, merchant: merchant, amount: amount, intent: intent)
        
        return ParsedQuery(
            spendingCategory: category,
            merchant: merchant,
            amount: amount,
            intent: intent,
            confidence: confidence
        )
    }
    
    // MARK: - Category Extraction
    
    private func extractSpendingCategory(_ query: String) -> SpendingCategory? {
        let categoryKeywords: [SpendingCategory: [String]] = [
            .groceries: ["grocery", "groceries", "food", "supermarket", "market", "produce", "vegetables", "fruits"],
            .dining: ["dining", "restaurant", "dinner", "lunch", "breakfast", "eat", "food", "meal", "out to eat", "eating out"],
            .travel: ["travel", "flight", "hotel", "vacation", "trip", "airline", "booking", "reservation"],
            .gas: ["gas", "fuel", "gasoline", "petrol", "filling up", "gas station", "fuel station"],
            .online: ["online", "internet", "web", "ecommerce", "online shopping", "web purchase"],
            .drugstores: ["drugstore", "pharmacy", "medicine", "drug", "cvs", "walgreens", "rite aid"],
            .streaming: ["streaming", "netflix", "spotify", "hulu", "disney", "apple tv", "youtube"],
            .transit: ["transit", "transportation", "uber", "lyft", "taxi", "ride", "public transport"],
            .office: ["office", "supply", "staples", "office depot", "work supplies"],
            .phone: ["phone", "mobile", "cell", "telephone", "wireless", "mobile service"],
            .costco: ["costco", "wholesale"],
            .amazon: ["amazon", "amzn"],
            .wholeFoods: ["whole foods", "wholefoods", "organic"],
            .target: ["target", "tar-zhay"],
            .walmart: ["walmart", "wal-mart"],
            .airfare: ["airfare", "airline ticket", "plane ticket", "flight ticket"],
            .hotels: ["hotel", "lodging", "accommodation", "stay"],
            .restaurants: ["restaurant", "dining", "fine dining"],
            .fastFood: ["fast food", "quick service", "drive thru", "drive-through"],
            .coffee: ["coffee", "starbucks", "dunkin", "coffee shop", "cafe"]
        ]
        
        for (category, keywords) in categoryKeywords {
            if keywords.contains(where: { query.contains($0) }) {
                return category
            }
        }
        
        return nil
    }
    
    // MARK: - Merchant Extraction
    
    private func extractMerchant(_ query: String) -> String? {
        let merchants = merchantMappings.keys
        
        for merchant in merchants {
            if query.contains(merchant) {
                return merchant
            }
        }
        
        return nil
    }
    
    // MARK: - Amount Extraction
    
    private func extractAmount(_ query: String) -> Double? {
        // Regular expression to match currency amounts
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
    
    // MARK: - Intent Detection
    
    private func determineIntent(_ query: String) -> QueryIntent {
        let lowercasedQuery = query.lowercased()
        
        // Check for spending update intent
        if lowercasedQuery.contains("spent") || 
           lowercasedQuery.contains("spending") ||
           lowercasedQuery.contains("update") ||
           lowercasedQuery.contains("track") {
            return .spendingUpdate
        }
        
        // Check for limit check intent
        if lowercasedQuery.contains("limit") ||
           lowercasedQuery.contains("remaining") ||
           lowercasedQuery.contains("how much") ||
           lowercasedQuery.contains("progress") {
            return .limitCheck
        }
        
        // Check for general question intent
        if lowercasedQuery.contains("what") ||
           lowercasedQuery.contains("how") ||
           lowercasedQuery.contains("which") ||
           lowercasedQuery.contains("best") ||
           lowercasedQuery.contains("should") {
            return .cardRecommendation
        }
        
        // Default to card recommendation
        return .cardRecommendation
    }
    
    // MARK: - Confidence Calculation
    
    private func calculateConfidence(category: SpendingCategory?, merchant: String?, amount: Double?, intent: QueryIntent) -> Double {
        var confidence: Double = 0.0
        
        // Base confidence for having any category
        if category != nil {
            confidence += 0.4
        }
        
        // Additional confidence for merchant match
        if merchant != nil {
            confidence += 0.3
        }
        
        // Additional confidence for amount
        if amount != nil {
            confidence += 0.2
        }
        
        // Intent confidence
        switch intent {
        case .cardRecommendation:
            confidence += 0.1
        case .spendingUpdate:
            confidence += 0.05
        case .limitCheck:
            confidence += 0.05
        case .generalQuestion:
            confidence += 0.0
        }
        
        return min(confidence, 1.0)
    }
    
    // MARK: - Category Mapping
    
    func mapCategoryToSpendingCategory(_ category: String) -> SpendingCategory? {
        let lowercasedCategory = category.lowercased()
        
        // Direct mapping
        if let directCategory = SpendingCategory(rawValue: category) {
            return directCategory
        }
        
        // Fuzzy matching
        let categoryMappings: [String: SpendingCategory] = [
            "grocery": .groceries,
            "food": .groceries,
            "supermarket": .groceries,
            "market": .groceries,
            "restaurant": .dining,
            "dining out": .dining,
            "eating out": .dining,
            "meal": .dining,
            "airline": .travel,
            "flight": .travel,
            "hotel": .travel,
            "accommodation": .travel,
            "fuel": .gas,
            "gasoline": .gas,
            "petrol": .gas,
            "shopping": .online,
            "ecommerce": .online,
            "pharmacy": .drugstores,
            "medicine": .drugstores,
            "entertainment": .streaming,
            "transport": .transit,
            "transportation": .transit,
            "ride": .transit,
            "supplies": .office,
            "work": .office,
            "mobile": .phone,
            "wireless": .phone,
            "telephone": .phone,
            "wholesale": .costco,
            "organic": .wholeFoods,
            "plane ticket": .airfare,
            "airline ticket": .airfare,
            "lodging": .hotels,
            "stay": .hotels,
            "fine dining": .restaurants,
            "quick service": .fastFood,
            "drive thru": .fastFood,
            "cafe": .coffee,
            "coffee shop": .coffee
        ]
        
        return categoryMappings[lowercasedCategory]
    }
    
    // MARK: - Query Enhancement
    
    func enhanceQuery(_ query: String) -> String {
        var enhancedQuery = query
        
        // Add context for better understanding
        if enhancedQuery.lowercased().contains("buying") || enhancedQuery.lowercased().contains("purchasing") {
            // Query already has good context
            return enhancedQuery
        }
        
        // Add "buying" context if missing
        if !enhancedQuery.lowercased().contains("buy") && 
           !enhancedQuery.lowercased().contains("purchase") &&
           !enhancedQuery.lowercased().contains("spend") {
            enhancedQuery = "buying \(enhancedQuery)"
        }
        
        return enhancedQuery
    }
    
    // MARK: - Query Validation
    
    func validateQuery(_ query: String) -> QueryValidationResult {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if query is empty
        if trimmedQuery.isEmpty {
            return QueryValidationResult(isValid: false, error: "Query cannot be empty")
        }
        
        // Check if query is too short
        if trimmedQuery.count < 3 {
            return QueryValidationResult(isValid: false, error: "Query is too short")
        }
        
        // Check if query is too long
        if trimmedQuery.count > 500 {
            return QueryValidationResult(isValid: false, error: "Query is too long")
        }
        
        // Check for inappropriate content (basic check)
        let inappropriateWords = ["fuck", "shit", "ass", "bitch", "damn"]
        let lowercasedQuery = trimmedQuery.lowercased()
        
        for word in inappropriateWords {
            if lowercasedQuery.contains(word) {
                return QueryValidationResult(isValid: false, error: "Query contains inappropriate content")
            }
        }
        
        return QueryValidationResult(isValid: true, error: nil)
    }
}

// MARK: - Supporting Types

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

struct QueryValidationResult {
    let isValid: Bool
    let error: String?
}

// MARK: - Query Templates

extension NLPProcessor {
    static let commonQueries = [
        "What card should I use for groceries?",
        "Which card is best for dining out?",
        "I'm buying gas, which card?",
        "Shopping at Amazon, what card?",
        "Going to Costco, best card?",
        "Dining at a restaurant tonight",
        "Booking a flight to Europe",
        "Filling up at the gas station",
        "Buying groceries at Whole Foods",
        "Shopping online at Target"
    ]
    
    static let queryExamples = [
        "I want to buy X",
        "What card for X?",
        "Best card for X?",
        "Which card should I use for X?",
        "Shopping at X, what card?",
        "Going to X, best card?"
    ]
} 