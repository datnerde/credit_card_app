import Foundation

// Note: MockDataManager is defined in MockDataManager.swift (subclass of DataManager)

// MARK: - Mock Recommendation Engine
class MockRecommendationEngine {
    func getRecommendation(for query: String, userCards: [CreditCard], userPreferences: UserPreferences) async throws -> RecommendationResponse {
        let recommendations = MockData.sampleCardRecommendations

        return RecommendationResponse(
            primaryRecommendation: recommendations.first,
            secondaryRecommendation: recommendations.count > 1 ? recommendations[1] : nil,
            reasoning: "Based on your query '\(query)', I recommend using your \(recommendations.first?.cardName ?? "best available") card.",
            warnings: [],
            suggestions: ["Consider updating your spending limits for better tracking"],
            confidence: 0.95
        )
    }

    func analyzeSpendingPattern(_ cards: [CreditCard]) -> String {
        return "Your spending pattern looks good!"
    }
}

// MARK: - Mock NLP Processor
class MockNLPProcessor {
    func parseUserQuery(_ query: String) -> ParsedQuery {
        return ParsedQuery(
            spendingCategory: .general,
            merchant: nil,
            amount: nil,
            intent: .cardRecommendation,
            confidence: 0.5
        )
    }

    func extractSpendingCategory(from query: String) -> SpendingCategory {
        let lowercaseQuery = query.lowercased()

        for (merchant, category) in merchantMappings {
            if lowercaseQuery.contains(merchant) {
                return category
            }
        }

        if lowercaseQuery.contains("grocery") || lowercaseQuery.contains("groceries") {
            return .groceries
        } else if lowercaseQuery.contains("dining") || lowercaseQuery.contains("restaurant") {
            return .dining
        } else if lowercaseQuery.contains("travel") || lowercaseQuery.contains("flight") {
            return .travel
        } else if lowercaseQuery.contains("gas") || lowercaseQuery.contains("fuel") {
            return .gas
        }

        return .general
    }
}

// MARK: - Mock Notification Service
class MockNotificationService {
    func scheduleSpendingAlert(for card: CreditCard, category: SpendingCategory, threshold: Double) {
        print("Scheduled alert for \(card.name) - \(category.displayName) at \(threshold * 100)%")
    }

    func cancelAllNotifications() {
        print("Cancelled all notifications")
    }

    func requestNotificationPermission() async -> Bool {
        return true
    }
}

// MARK: - Mock Analytics Service
class MockAnalyticsService {
    func trackEvent(_ eventName: String, properties: [String: Any]? = nil) {
        print("Analytics: \(eventName) - \(properties ?? [:])")
    }

    func trackScreenView(_ screenName: String) {
        print("Screen view: \(screenName)")
    }

    func setUserProperty(_ property: String, value: String) {
        print("User property: \(property) = \(value)")
    }
}
