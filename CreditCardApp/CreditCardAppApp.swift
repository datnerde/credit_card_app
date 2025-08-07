import SwiftUI
import Foundation

// Simple service container for the app
class AppServiceContainer: ObservableObject {
    static let shared = AppServiceContainer()
    
    let dataManager: DataManager
    let recommendationEngine: RecommendationEngine
    let nlpProcessor: NLPProcessor
    let notificationService: NotificationService
    let analyticsService: AnalyticsService
    
    private init() {
        self.dataManager = DataManager()
        self.recommendationEngine = RecommendationEngine()
        self.nlpProcessor = NLPProcessor()
        self.notificationService = NotificationService.shared
        self.analyticsService = AnalyticsService.shared
    }
}

@main
struct CreditCardAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AppServiceContainer.shared)
        }
    }
} 