import XCTest
import SwiftUI
@testable import CreditCardApp

/// Build verification test to ensure all components compile successfully
class BuildVerificationTest: XCTestCase {
    
    func testAllImportsCompile() {
        // This test ensures all imports work correctly
        XCTAssertTrue(true, "All imports compiled successfully")
    }
    
    func testAllModelsCompile() {
        // Test that all models can be instantiated
        
        // Core models
        let card = CreditCard(name: "Test", cardType: .amexGold)
        XCTAssertEqual(card.name, "Test")
        
        let category = RewardCategory(category: .groceries, multiplier: 4.0, pointType: .membershipRewards)
        XCTAssertEqual(category.category, .groceries)
        
        let limit = SpendingLimit(category: .groceries, limit: 1000)
        XCTAssertEqual(limit.limit, 1000)
        
        let preferences = UserPreferences()
        XCTAssertEqual(preferences.preferredPointSystem, .membershipRewards)
        
        let message = ChatMessage(content: "Test", sender: .user)
        XCTAssertEqual(message.content, "Test")
        
        let recommendation = CardRecommendation(
            cardId: UUID(),
            cardName: "Test",
            category: .groceries,
            multiplier: 4.0,
            pointType: .membershipRewards,
            reasoning: "Test"
        )
        XCTAssertEqual(recommendation.cardName, "Test")
        
        let update = SpendingUpdate(cardId: UUID(), category: .groceries, amount: 100, previousAmount: 50)
        XCTAssertEqual(update.amount, 100)
    }
    
    func testAllServicesCompile() {
        // Test that all services can be instantiated
        let dataManager = DataManager()
        XCTAssertNotNil(dataManager)
        
        let recommendationEngine = RecommendationEngine()
        XCTAssertNotNil(recommendationEngine)
        
        let nlpProcessor = NLPProcessor()
        XCTAssertNotNil(nlpProcessor)
        
        let notificationService = NotificationService.shared
        XCTAssertNotNil(notificationService)
        
        let analyticsService = AnalyticsService.shared
        XCTAssertNotNil(analyticsService)
    }
    
    func testAllViewModelsCompile() {
        // Test that all ViewModels can be created
        let chatVM = ViewModelFactory.makeChatViewModel()
        XCTAssertNotNil(chatVM)
        
        let cardListVM = ViewModelFactory.makeCardListViewModel()
        XCTAssertNotNil(cardListVM)
        
        let addCardVM = ViewModelFactory.makeAddCardViewModel()
        XCTAssertNotNil(addCardVM)
        
        let settingsVM = ViewModelFactory.makeSettingsViewModel()
        XCTAssertNotNil(settingsVM)
    }
    
    func testAllViewsCompile() {
        // Test that all views can be instantiated
        let contentView = ContentView()
            .environmentObject(AppServiceContainer.shared)
        XCTAssertNotNil(contentView)
        
        let chatView = ChatView()
        XCTAssertNotNil(chatView)
        
        let cardListView = CardListView()
        XCTAssertNotNil(cardListView)
        
        let addCardView = AddCardView()
        XCTAssertNotNil(addCardView)
        
        let cardDetailView = CardDetailView(card: PreviewData.sampleCard)
        XCTAssertNotNil(cardDetailView)
        
        let settingsView = SettingsView()
        XCTAssertNotNil(settingsView)
        
        let onboardingView = OnboardingView()
        XCTAssertNotNil(onboardingView)
        
        let loadingView = LoadingView()
        XCTAssertNotNil(loadingView)
        
        let emptyStateView = EmptyStateView(title: "Test", message: "Test")
        XCTAssertNotNil(emptyStateView)
    }
    
    func testAllEnumsCompile() {
        // Test that all enums work correctly
        let spendingCategories = SpendingCategory.allCases
        XCTAssertGreaterThan(spendingCategories.count, 0)
        
        let pointTypes = PointType.allCases
        XCTAssertGreaterThan(pointTypes.count, 0)
        
        let cardTypes = CardType.allCases
        XCTAssertGreaterThan(cardTypes.count, 0)
        
        let languages = Language.allCases
        XCTAssertGreaterThan(languages.count, 0)
        
        let resetTypes = ResetType.allCases
        XCTAssertGreaterThan(resetTypes.count, 0)
        
        let messageSenders = [MessageSender.user, MessageSender.assistant]
        XCTAssertEqual(messageSenders.count, 2)
    }
    
    func testAllExtensionsCompile() {
        // Test that all extensions work
        let amount = 1234.56
        XCTAssertNotNil(amount.asCurrency)
        
        let text = "test@example.com"
        XCTAssertTrue(text.isValidEmail)
        
        let quarter = Calendar.currentQuarter
        XCTAssertTrue(quarter >= 1 && quarter <= 4)
    }
    
    func testMockDataCompiles() {
        // Test that mock data works
        let mockCards = MockData.sampleCards
        XCTAssertGreaterThan(mockCards.count, 0)
        
        let previewCard = PreviewData.sampleCard
        XCTAssertEqual(previewCard.name, "Amex Gold")
        
        let previewMessage = PreviewData.sampleMessage
        XCTAssertEqual(previewMessage.sender, .assistant)
    }
    
    func testServiceContainersCompile() {
        // Test that service containers work
        let serviceContainer = ServiceContainer.shared
        XCTAssertNotNil(serviceContainer.dataManager)
        XCTAssertNotNil(serviceContainer.recommendationEngine)
        
        let appServiceContainer = AppServiceContainer.shared
        XCTAssertNotNil(appServiceContainer.dataManager)
        XCTAssertNotNil(appServiceContainer.recommendationEngine)
    }
    
    func testCoreDataStackCompiles() {
        // Test that Core Data stack initializes
        let coreDataStack = CoreDataStack.shared
        XCTAssertNotNil(coreDataStack.persistentContainer)
        XCTAssertNotNil(coreDataStack.context)
    }
}
