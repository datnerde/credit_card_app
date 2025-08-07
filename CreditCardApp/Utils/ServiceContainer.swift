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
                try await dataManager.loadSampleCardsData()
            } catch {
                print("Failed to load sample data: \(error)")
            }
        }
    }
}