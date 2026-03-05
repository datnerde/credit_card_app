import Foundation

class ServiceContainer: ObservableObject {
    static let shared = ServiceContainer()
    
    // Core services
    let dataManager: DataManager
    let recommendationEngine: RecommendationEngine
    let nlpProcessor: NLPProcessor
    let notificationService: NotificationService
    let analyticsService: AnalyticsService
    
    private init() {
        // Use real Core Data services for production
        self.dataManager = DataManager()
        self.recommendationEngine = RecommendationEngine()
        self.nlpProcessor = NLPProcessor()
        self.notificationService = NotificationService.shared
        self.analyticsService = AnalyticsService.shared
        
        // Load sample data on first launch
        loadSampleDataIfNeeded()
    }
    
    private func loadSampleDataIfNeeded() {
        Task {
            do {
                // First, remove any duplicate cards
                try await dataManager.removeDuplicateCards()
                
                // Then check if we need to load sample data
                let existingCards = try await dataManager.fetchCards()
                if existingCards.isEmpty {
                    print("🚀 Loading sample data - no existing cards found")
                    try await dataManager.loadSampleCardsData()
                } else {
                    print("🚀 Skipping sample data load - found \(existingCards.count) existing cards")
                }
            } catch {
                print("Failed to load sample data: \(error)")
            }
        }
    }
}