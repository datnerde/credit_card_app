import XCTest
import SwiftUI
@testable import CreditCardApp

class Phase1IntegrationTest: XCTestCase {
    
    func testAppLaunchAndBasicNavigation() {
        // Test that the app can launch without crashing
        let serviceContainer = AppServiceContainer.shared
        XCTAssertNotNil(serviceContainer)
        XCTAssertNotNil(serviceContainer.dataManager)
        XCTAssertNotNil(serviceContainer.recommendationEngine)
        XCTAssertNotNil(serviceContainer.nlpProcessor)
    }
    
    func testViewModelCreation() {
        // Test that all ViewModels can be created successfully
        let chatViewModel = ViewModelFactory.makeChatViewModel()
        XCTAssertNotNil(chatViewModel)
        XCTAssertFalse(chatViewModel.isLoading)
        XCTAssertTrue(chatViewModel.messages.isEmpty)
        
        let cardListViewModel = ViewModelFactory.makeCardListViewModel()
        XCTAssertNotNil(cardListViewModel)
        XCTAssertFalse(cardListViewModel.isLoading)
        
        let addCardViewModel = ViewModelFactory.makeAddCardViewModel()
        XCTAssertNotNil(addCardViewModel)
        XCTAssertFalse(addCardViewModel.isFormValid) // Should be invalid initially
        
        let settingsViewModel = ViewModelFactory.makeSettingsViewModel()
        XCTAssertNotNil(settingsViewModel)
        XCTAssertEqual(settingsViewModel.userPreferences.preferredPointSystem, .membershipRewards) // Default
    }
    
    func testDataManagerIntegration() async throws {
        let dataManager = DataManager()
        
        // Test saving and loading a card
        let testCard = CreditCard(
            name: "Integration Test Card",
            cardType: .amexGold,
            rewardCategories: [
                RewardCategory(category: .groceries, multiplier: 4.0, pointType: .membershipRewards),
                RewardCategory(category: .dining, multiplier: 4.0, pointType: .membershipRewards)
            ],
            spendingLimits: [
                SpendingLimit(category: .groceries, limit: 25000, currentSpending: 5000),
                SpendingLimit(category: .dining, limit: 25000, currentSpending: 8000)
            ]
        )
        
        try await dataManager.saveCard(testCard)
        let savedCards = try await dataManager.fetchCards()
        
        XCTAssertTrue(savedCards.contains { $0.name == "Integration Test Card" })
        
        // Test user preferences
        let testPreferences = UserPreferences(
            preferredPointSystem: .ultimateRewards,
            alertThreshold: 0.90,
            language: .english
        )
        
        try await dataManager.saveUserPreferences(testPreferences)
        let loadedPreferences = try await dataManager.loadUserPreferences()
        
        XCTAssertEqual(loadedPreferences.preferredPointSystem, .ultimateRewards)
        XCTAssertEqual(loadedPreferences.alertThreshold, 0.90, accuracy: 0.01)
        
        // Test chat message
        let testMessage = ChatMessage(
            content: "Test integration message",
            sender: .user
        )
        
        try await dataManager.saveChatMessage(testMessage)
        let savedMessages = try await dataManager.fetchChatMessages()
        
        XCTAssertTrue(savedMessages.contains { $0.content == "Test integration message" })
    }
    
    func testRecommendationEngineIntegration() async throws {
        let dataManager = DataManager()
        let recommendationEngine = RecommendationEngine()
        
        // Create test cards
        let amexGold = CreditCard(
            name: "Amex Gold",
            cardType: .amexGold,
            rewardCategories: [
                RewardCategory(category: .groceries, multiplier: 4.0, pointType: .membershipRewards),
                RewardCategory(category: .dining, multiplier: 4.0, pointType: .membershipRewards)
            ],
            spendingLimits: [
                SpendingLimit(category: .groceries, limit: 25000, currentSpending: 5000)
            ]
        )
        
        let csr = CreditCard(
            name: "Chase Sapphire Reserve",
            cardType: .chaseSapphireReserve,
            rewardCategories: [
                RewardCategory(category: .travel, multiplier: 3.0, pointType: .ultimateRewards),
                RewardCategory(category: .dining, multiplier: 3.0, pointType: .ultimateRewards)
            ]
        )
        
        let userCards = [amexGold, csr]
        let userPreferences = UserPreferences()
        
        // Test grocery recommendation
        let groceryResponse = try await recommendationEngine.getRecommendation(
            for: "I'm buying groceries at Whole Foods",
            userCards: userCards,
            userPreferences: userPreferences
        )
        
        XCTAssertNotNil(groceryResponse.primaryRecommendation)
        XCTAssertEqual(groceryResponse.primaryRecommendation?.cardName, "Amex Gold")
        
        // Test travel recommendation
        let travelResponse = try await recommendationEngine.getRecommendation(
            for: "I'm booking a flight to Europe",
            userCards: userCards,
            userPreferences: userPreferences
        )
        
        XCTAssertNotNil(travelResponse.primaryRecommendation)
        XCTAssertEqual(travelResponse.primaryRecommendation?.cardName, "Chase Sapphire Reserve")
    }
    
    func testViewModelDataFlow() async throws {
        let cardListViewModel = ViewModelFactory.makeCardListViewModel()
        
        // Test adding a card through ViewModel
        let testCard = CreditCard(
            name: "ViewModel Test Card",
            cardType: .chaseFreedom
        )
        
        cardListViewModel.addCard(testCard)
        
        // Wait for async operation to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // Check if card was added
        XCTAssertTrue(cardListViewModel.cards.contains { $0.name == "ViewModel Test Card" })
    }
    
    func testAddCardViewModelValidation() {
        let addCardViewModel = ViewModelFactory.makeAddCardViewModel()
        
        // Initially invalid
        XCTAssertFalse(addCardViewModel.isFormValid)
        
        // Add card name
        addCardViewModel.cardName = "Test Card"
        XCTAssertFalse(addCardViewModel.isFormValid) // Still invalid, no categories
        
        // Add category
        addCardViewModel.toggleCategory(.groceries, isSelected: true)
        XCTAssertTrue(addCardViewModel.isFormValid) // Now valid
        
        // Remove card name
        addCardViewModel.cardName = ""
        XCTAssertFalse(addCardViewModel.isFormValid) // Invalid again
    }
    
    func testSettingsViewModelPreferences() async throws {
        let settingsViewModel = ViewModelFactory.makeSettingsViewModel()
        
        // Test updating preferred point system
        settingsViewModel.updatePreferredPointSystem(.ultimateRewards)
        XCTAssertEqual(settingsViewModel.userPreferences.preferredPointSystem, .ultimateRewards)
        
        // Test updating alert threshold
        settingsViewModel.updateAlertThreshold(0.75)
        XCTAssertEqual(settingsViewModel.userPreferences.alertThreshold, 0.75, accuracy: 0.01)
        
        // Test toggling notifications
        let initialNotificationState = settingsViewModel.userPreferences.notificationsEnabled
        settingsViewModel.toggleNotifications()
        XCTAssertNotEqual(settingsViewModel.userPreferences.notificationsEnabled, initialNotificationState)
    }
    
    func testUIViewsCanBeCreated() {
        // Test that all main UI views can be instantiated without crashing
        
        // ContentView
        let contentView = ContentView()
            .environmentObject(AppServiceContainer.shared)
        XCTAssertNotNil(contentView)
        
        // Individual views
        let chatView = ChatView()
        XCTAssertNotNil(chatView)
        
        let cardListView = CardListView()
        XCTAssertNotNil(cardListView)
        
        let addCardView = AddCardView()
        XCTAssertNotNil(addCardView)
        
        let settingsView = SettingsView()
        XCTAssertNotNil(settingsView)
        
        // Component views
        let loadingView = LoadingView()
        XCTAssertNotNil(loadingView)
        
        let emptyStateView = EmptyStateView(
            title: "Test",
            message: "Test message",
            buttonTitle: "Test Button",
            action: {}
        )
        XCTAssertNotNil(emptyStateView)
    }
    
    func testModelExtensions() {
        // Test that model extensions work correctly
        
        // Test spending limit calculations
        let spendingLimit = SpendingLimit(
            category: .groceries,
            limit: 1000,
            currentSpending: 850
        )
        
        XCTAssertEqual(spendingLimit.usagePercentage, 0.85, accuracy: 0.01)
        XCTAssertEqual(spendingLimit.remainingAmount, 150, accuracy: 0.01)
        XCTAssertTrue(spendingLimit.isWarningThreshold)
        XCTAssertFalse(spendingLimit.isLimitReached)
        
        // Test currency formatting
        let amount = 1234.56
        XCTAssertTrue(amount.asCurrency.contains("$"))
        XCTAssertTrue(amount.asCurrency.contains("1,234"))
        
        // Test calendar extensions
        let quarter = Calendar.currentQuarter
        XCTAssertTrue(quarter >= 1 && quarter <= 4)
    }
    
    func testErrorHandling() async {
        let dataManager = DataManager()
        
        // Test deleting non-existent card
        let nonExistentCard = CreditCard(name: "Non-existent", cardType: .custom)
        
        do {
            try await dataManager.deleteCard(nonExistentCard)
            XCTFail("Should have thrown an error")
        } catch DataManagerError.cardNotFound {
            // Expected error
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testPerformanceBaseline() {
        // Performance test for basic operations
        measure {
            // Create 100 cards
            let cards = (0..<100).map { index in
                CreditCard(
                    name: "Performance Test Card \(index)",
                    cardType: .amexGold,
                    rewardCategories: [
                        RewardCategory(category: .groceries, multiplier: 4.0, pointType: .membershipRewards)
                    ]
                )
            }
            
            // Test that creation is fast
            XCTAssertEqual(cards.count, 100)
        }
    }
}
