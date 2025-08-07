import XCTest
@testable import CreditCardApp

class CompilationTest: XCTestCase {
    
    func testBasicModelCreation() {
        // Test that all basic models can be created without compilation errors
        
        // Test CreditCard creation
        let card = CreditCard(
            name: "Test Card",
            cardType: .amexGold,
            rewardCategories: [
                RewardCategory(category: .groceries, multiplier: 4.0, pointType: .membershipRewards)
            ],
            spendingLimits: [
                SpendingLimit(category: .groceries, limit: 1000, currentSpending: 500)
            ]
        )
        
        XCTAssertEqual(card.name, "Test Card")
        XCTAssertEqual(card.cardType, .amexGold)
        XCTAssertEqual(card.rewardCategories.count, 1)
        XCTAssertEqual(card.spendingLimits.count, 1)
        
        // Test UserPreferences creation
        let preferences = UserPreferences(
            preferredPointSystem: .membershipRewards,
            alertThreshold: 0.85,
            language: .english
        )
        
        XCTAssertEqual(preferences.preferredPointSystem, .membershipRewards)
        XCTAssertEqual(preferences.alertThreshold, 0.85, accuracy: 0.01)
        XCTAssertEqual(preferences.language, .english)
        
        // Test ChatMessage creation
        let message = ChatMessage(
            content: "Test message",
            sender: .user
        )
        
        XCTAssertEqual(message.content, "Test message")
        XCTAssertEqual(message.sender, .user)
        
        // Test CardRecommendation creation
        let recommendation = CardRecommendation(
            cardId: card.id,
            cardName: "Test Card",
            category: .groceries,
            multiplier: 4.0,
            pointType: .membershipRewards,
            reasoning: "Best for groceries"
        )
        
        XCTAssertEqual(recommendation.cardName, "Test Card")
        XCTAssertEqual(recommendation.category, .groceries)
        XCTAssertEqual(recommendation.multiplier, 4.0, accuracy: 0.01)
    }
    
    func testServiceContainerInitialization() {
        // Test that service containers can be initialized without errors
        let serviceContainer = ServiceContainer.shared
        
        XCTAssertNotNil(serviceContainer.dataManager)
        XCTAssertNotNil(serviceContainer.recommendationEngine)
        XCTAssertNotNil(serviceContainer.nlpProcessor)
        XCTAssertNotNil(serviceContainer.notificationService)
        XCTAssertNotNil(serviceContainer.analyticsService)
        
        let appServiceContainer = AppServiceContainer.shared
        
        XCTAssertNotNil(appServiceContainer.dataManager)
        XCTAssertNotNil(appServiceContainer.recommendationEngine)
        XCTAssertNotNil(appServiceContainer.nlpProcessor)
        XCTAssertNotNil(appServiceContainer.notificationService)
        XCTAssertNotNil(appServiceContainer.analyticsService)
    }
    
    func testViewModelFactoryCreation() {
        // Test that ViewModels can be created through factory without compilation errors
        
        let chatViewModel = ViewModelFactory.makeChatViewModel()
        XCTAssertNotNil(chatViewModel)
        
        let cardListViewModel = ViewModelFactory.makeCardListViewModel()
        XCTAssertNotNil(cardListViewModel)
        
        let addCardViewModel = ViewModelFactory.makeAddCardViewModel()
        XCTAssertNotNil(addCardViewModel)
        
        let settingsViewModel = ViewModelFactory.makeSettingsViewModel()
        XCTAssertNotNil(settingsViewModel)
    }
    
    func testEnumCases() {
        // Test that all enum cases are accessible
        
        // Test SpendingCategory
        let categories: [SpendingCategory] = [.groceries, .dining, .travel, .gas, .general]
        XCTAssertEqual(categories.count, 5)
        
        // Test PointType
        let pointTypes: [PointType] = [.membershipRewards, .ultimateRewards, .cashBack]
        XCTAssertEqual(pointTypes.count, 3)
        
        // Test CardType
        let cardTypes: [CardType] = [.amexGold, .amexPlatinum, .chaseFreedom, .chaseSapphireReserve]
        XCTAssertEqual(cardTypes.count, 4)
        
        // Test Language
        let languages: [Language] = [.english, .chinese, .bilingual]
        XCTAssertEqual(languages.count, 3)
        
        // Test MessageSender
        let senders: [MessageSender] = [.user, .assistant]
        XCTAssertEqual(senders.count, 2)
    }
    
    func testExtensions() {
        // Test that extensions compile and work
        
        // Test Double extensions
        let amount = 1234.56
        XCTAssertTrue(amount.asCurrency.contains("$"))
        XCTAssertTrue(amount.isValidAmount)
        
        // Test Calendar extensions
        let quarter = Calendar.currentQuarter
        XCTAssertTrue(quarter >= 1 && quarter <= 4)
        
        // Test String extensions
        let text = "test@example.com"
        XCTAssertTrue(text.isValidEmail)
        XCTAssertTrue(text.isNotEmpty)
    }
    
    func testMockData() {
        // Test that mock data can be created
        let mockCards = MockData.sampleCards
        XCTAssertGreaterThan(mockCards.count, 0)
        
        let previewCard = PreviewData.sampleCard
        XCTAssertEqual(previewCard.name, "Amex Gold")
        
        let previewMessage = PreviewData.sampleMessage
        XCTAssertEqual(previewMessage.sender, .assistant)
    }
}
