import Foundation

class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()
    
    private var events: [AnalyticsEvent] = []
    private let maxEvents = 1000 // Keep last 1000 events in memory
    
    private init() {}
    
    // MARK: - Event Tracking
    
    func trackEvent(_ event: AnalyticsEvent) {
        events.append(event)
        
        // Keep only the last maxEvents
        if events.count > maxEvents {
            events.removeFirst(events.count - maxEvents)
        }
        
        // Log event for debugging
        print("Analytics Event: \(event.name) - \(event.properties)")
    }
    
    func trackScreenView(_ screenName: String, properties: [String: Any] = [:]) {
        let event = AnalyticsEvent(
            name: "screen_view",
            properties: properties.merging([
                "screen_name": screenName,
                "timestamp": Date().timeIntervalSince1970
            ]) { _, new in new }
        )
        trackEvent(event)
    }
    
    func trackRecommendationRequest(query: String, category: SpendingCategory?, merchant: String?) {
        let event = AnalyticsEvent(
            name: "recommendation_request",
            properties: [
                "query": query,
                "category": category?.rawValue ?? "unknown",
                "merchant": merchant ?? "none",
                "timestamp": Date().timeIntervalSince1970
            ]
        )
        trackEvent(event)
    }
    
    func trackRecommendationResponse(primaryCard: String?, secondaryCard: String?, category: SpendingCategory, responseTime: TimeInterval) {
        let event = AnalyticsEvent(
            name: "recommendation_response",
            properties: [
                "primary_card": primaryCard ?? "none",
                "secondary_card": secondaryCard ?? "none",
                "category": category.rawValue,
                "response_time": responseTime,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
        trackEvent(event)
    }
    
    func trackCardAdded(cardType: CardType, hasQuarterlyBonus: Bool) {
        let event = AnalyticsEvent(
            name: "card_added",
            properties: [
                "card_type": cardType.rawValue,
                "has_quarterly_bonus": hasQuarterlyBonus,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
        trackEvent(event)
    }
    
    func trackCardDeleted(cardType: CardType) {
        let event = AnalyticsEvent(
            name: "card_deleted",
            properties: [
                "card_type": cardType.rawValue,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
        trackEvent(event)
    }
    
    func trackSpendingUpdated(cardId: UUID, category: SpendingCategory, amount: Double) {
        let event = AnalyticsEvent(
            name: "spending_updated",
            properties: [
                "card_id": cardId.uuidString,
                "category": category.rawValue,
                "amount": amount,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
        trackEvent(event)
    }
    
    func trackLimitAlert(cardId: UUID, category: SpendingCategory, alertType: LimitAlertType) {
        let event = AnalyticsEvent(
            name: "limit_alert",
            properties: [
                "card_id": cardId.uuidString,
                "category": category.rawValue,
                "alert_type": alertType.rawValue,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
        trackEvent(event)
    }
    
    func trackSettingsChanged(setting: String, oldValue: Any, newValue: Any) {
        let event = AnalyticsEvent(
            name: "settings_changed",
            properties: [
                "setting": setting,
                "old_value": String(describing: oldValue),
                "new_value": String(describing: newValue),
                "timestamp": Date().timeIntervalSince1970
            ]
        )
        trackEvent(event)
    }
    
    func trackError(error: Error, context: String) {
        let event = AnalyticsEvent(
            name: "error",
            properties: [
                "error_message": error.localizedDescription,
                "context": context,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
        trackEvent(event)
    }
    
    func trackPerformance(operation: String, duration: TimeInterval) {
        let event = AnalyticsEvent(
            name: "performance",
            properties: [
                "operation": operation,
                "duration": duration,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
        trackEvent(event)
    }
    
    // MARK: - User Engagement Tracking
    
    func trackSessionStart() {
        let event = AnalyticsEvent(
            name: "session_start",
            properties: [
                "session_id": UUID().uuidString,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
        trackEvent(event)
    }
    
    func trackSessionEnd(duration: TimeInterval, eventsCount: Int) {
        let event = AnalyticsEvent(
            name: "session_end",
            properties: [
                "duration": duration,
                "events_count": eventsCount,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
        trackEvent(event)
    }
    
    func trackFeatureUsage(feature: String) {
        let event = AnalyticsEvent(
            name: "feature_usage",
            properties: [
                "feature": feature,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
        trackEvent(event)
    }
    
    // MARK: - Data Export
    
    func exportAnalyticsData() -> AnalyticsData {
        return AnalyticsData(
            events: events,
            summary: generateSummary(),
            timestamp: Date()
        )
    }
    
    private func generateSummary() -> AnalyticsSummary {
        let totalEvents = events.count
        let uniqueSessions = Set(events.compactMap { $0.properties["session_id"] as? String }).count
        
        let eventCounts = Dictionary(grouping: events, by: { $0.name })
            .mapValues { $0.count }
        
        let averageResponseTime = events
            .filter { $0.name == "recommendation_response" }
            .compactMap { $0.properties["response_time"] as? TimeInterval }
            .reduce(0, +) / max(Double(events.filter { $0.name == "recommendation_response" }.count), 1)
        
        let errorCount = events.filter { $0.name == "error" }.count
        
        return AnalyticsSummary(
            totalEvents: totalEvents,
            uniqueSessions: uniqueSessions,
            eventCounts: eventCounts,
            averageResponseTime: averageResponseTime,
            errorCount: errorCount
        )
    }
    
    // MARK: - Data Cleanup
    
    func clearOldEvents(olderThan days: Int) {
        let cutoffDate = Date().addingTimeInterval(-TimeInterval(days * 24 * 60 * 60))
        events.removeAll { event in
            if let timestamp = event.properties["timestamp"] as? TimeInterval {
                return Date(timeIntervalSince1970: timestamp) < cutoffDate
            }
            return false
        }
    }
    
    func clearAllEvents() {
        events.removeAll()
    }
    
    // MARK: - Performance Monitoring
    
    func startPerformanceTimer(for operation: String) -> PerformanceTimer {
        return PerformanceTimer(operation: operation, analyticsService: self)
    }
}

// MARK: - Supporting Types

struct AnalyticsEvent: Codable {
    let name: String
    let properties: [String: String]
    let timestamp: Date
    
    init(name: String, properties: [String: Any]) {
        self.name = name
        self.properties = properties.mapValues { "\($0)" }
        self.timestamp = Date()
    }
}

struct AnalyticsData: Codable {
    let events: [AnalyticsEvent]
    let summary: AnalyticsSummary
    let timestamp: Date
}

struct AnalyticsSummary: Codable {
    let totalEvents: Int
    let uniqueSessions: Int
    let eventCounts: [String: Int]
    let averageResponseTime: TimeInterval
    let errorCount: Int
}

enum LimitAlertType: String {
    case warning = "warning"
    case reached = "reached"
}

// MARK: - Performance Timer

class PerformanceTimer {
    private let operation: String
    private let analyticsService: AnalyticsService
    private let startTime: Date
    
    init(operation: String, analyticsService: AnalyticsService) {
        self.operation = operation
        self.analyticsService = analyticsService
        self.startTime = Date()
    }
    
    func stop() {
        let duration = Date().timeIntervalSince(startTime)
        analyticsService.trackPerformance(operation: operation, duration: duration)
    }
}

// MARK: - Analytics Extensions

extension AnalyticsService {
    func trackRecommendationAccuracy(correctCard: String, recommendedCard: String, category: SpendingCategory) {
        let isCorrect = correctCard == recommendedCard
        let event = AnalyticsEvent(
            name: "recommendation_accuracy",
            properties: [
                "correct_card": correctCard,
                "recommended_card": recommendedCard,
                "category": category.rawValue,
                "is_correct": isCorrect,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
        trackEvent(event)
    }
    
    func trackUserPreference(preference: String, value: Any) {
        let event = AnalyticsEvent(
            name: "user_preference",
            properties: [
                "preference": preference,
                "value": String(describing: value),
                "timestamp": Date().timeIntervalSince1970
            ]
        )
        trackEvent(event)
    }
}

// MARK: - Debug Analytics

extension AnalyticsService {
    func printAnalyticsSummary() {
        let summary = generateSummary()
        print("=== Analytics Summary ===")
        print("Total Events: \(summary.totalEvents)")
        print("Unique Sessions: \(summary.uniqueSessions)")
        print("Average Response Time: \(String(format: "%.3f", summary.averageResponseTime))s")
        print("Error Count: \(summary.errorCount)")
        print("Event Counts:")
        for (event, count) in summary.eventCounts.sorted(by: { $0.value > $1.value }) {
            print("  \(event): \(count)")
        }
        print("========================")
    }
} 