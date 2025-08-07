import XCTest
import CoreData
@testable import CreditCardApp

class DataManagerTests: XCTestCase {
    var dataManager: DataManager!
    var testContext: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        
        // Create in-memory Core Data stack for testing
        let container = NSPersistentContainer(name: "CreditCardApp")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data error: \(error)")
            }
        }
        
        testContext = container.viewContext
        let testCoreDataStack = TestCoreDataStack(container: container)
        dataManager = DataManager(coreDataStack: testCoreDataStack)
    }
    
    override func tearDown() {
        dataManager = nil
        testContext = nil
        super.tearDown()
    }
    
    // MARK: - Credit Card Tests
    
    func testSaveAndFetchCards() async throws {
        // Given
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
        
        // When
        try await dataManager.saveCard(card)
        let fetchedCards = try await dataManager.fetchCards()
        
        // Then
        XCTAssertEqual(fetchedCards.count, 1)
        XCTAssertEqual(fetchedCards.first?.name, "Test Card")
        XCTAssertEqual(fetchedCards.first?.cardType, .amexGold)
        XCTAssertEqual(fetchedCards.first?.rewardCategories.count, 1)
        XCTAssertEqual(fetchedCards.first?.spendingLimits.count, 1)
    }
    
    func testUpdateCard() async throws {
        // Given
        let originalCard = CreditCard(
            name: "Original Card",
            cardType: .amexGold
        )
        
        try await dataManager.saveCard(originalCard)
        
        // When
        var updatedCard = originalCard
        updatedCard.name = "Updated Card"
        updatedCard.cardType = .chaseSapphireReserve
        
        try await dataManager.updateCard(updatedCard)
        let fetchedCards = try await dataManager.fetchCards()
        
        // Then
        XCTAssertEqual(fetchedCards.count, 1)
        XCTAssertEqual(fetchedCards.first?.name, "Updated Card")
        XCTAssertEqual(fetchedCards.first?.cardType, .chaseSapphireReserve)
        XCTAssertEqual(fetchedCards.first?.id, originalCard.id)
    }
    
    func testDeleteCard() async throws {
        // Given
        let card = CreditCard(name: "Test Card", cardType: .amexGold)
        try await dataManager.saveCard(card)
        
        let initialCards = try await dataManager.fetchCards()
        XCTAssertEqual(initialCards.count, 1)
        
        // When
        try await dataManager.deleteCard(card)
        let remainingCards = try await dataManager.fetchCards()
        
        // Then
        XCTAssertEqual(remainingCards.count, 0)
    }
    
    func testDeleteNonExistentCard() async {
        // Given
        let card = CreditCard(name: "Non-existent Card", cardType: .amexGold)
        
        // When/Then
        do {
            try await dataManager.deleteCard(card)
            XCTFail("Expected DataManagerError.cardNotFound")
        } catch DataManagerError.cardNotFound {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - User Preferences Tests
    
    func testSaveAndLoadUserPreferences() async throws {
        // Given
        let preferences = UserPreferences(
            preferredPointSystem: .ultimateRewards,
            alertThreshold: 0.90,
            language: .chinese,
            notificationsEnabled: false,
            autoUpdateSpending: true
        )
        
        // When
        try await dataManager.saveUserPreferences(preferences)
        let loadedPreferences = try await dataManager.loadUserPreferences()
        
        // Then
        XCTAssertEqual(loadedPreferences.preferredPointSystem, .ultimateRewards)
        XCTAssertEqual(loadedPreferences.alertThreshold, 0.90, accuracy: 0.01)
        XCTAssertEqual(loadedPreferences.language, .chinese)
        XCTAssertEqual(loadedPreferences.notificationsEnabled, false)
        XCTAssertEqual(loadedPreferences.autoUpdateSpending, true)
    }
    
    func testLoadDefaultUserPreferences() async throws {
        // When - Load preferences when none exist
        let preferences = try await dataManager.loadUserPreferences()
        
        // Then - Should return default values
        XCTAssertEqual(preferences.preferredPointSystem, .membershipRewards)
        XCTAssertEqual(preferences.alertThreshold, 0.85, accuracy: 0.01)
        XCTAssertEqual(preferences.language, .english)
        XCTAssertEqual(preferences.notificationsEnabled, true)
        XCTAssertEqual(preferences.autoUpdateSpending, false)
    }
    
    // MARK: - Chat Message Tests
    
    func testSaveAndFetchChatMessages() async throws {
        // Given
        let message = ChatMessage(
            content: "Test message",
            sender: .user,
            cardRecommendations: [
                CardRecommendation(
                    cardId: UUID(),
                    cardName: "Test Card",
                    category: .groceries,
                    multiplier: 4.0,
                    pointType: .membershipRewards,
                    reasoning: "Test reasoning"
                )
            ]
        )
        
        // When
        try await dataManager.saveChatMessage(message)
        let fetchedMessages = try await dataManager.fetchChatMessages()
        
        // Then
        XCTAssertEqual(fetchedMessages.count, 1)
        XCTAssertEqual(fetchedMessages.first?.content, "Test message")
        XCTAssertEqual(fetchedMessages.first?.sender, .user)
        XCTAssertEqual(fetchedMessages.first?.cardRecommendations?.count, 1)
    }
    
    func testClearChatHistory() async throws {
        // Given
        let message1 = ChatMessage(content: "Message 1", sender: .user)
        let message2 = ChatMessage(content: "Message 2", sender: .assistant)
        
        try await dataManager.saveChatMessage(message1)
        try await dataManager.saveChatMessage(message2)
        
        let initialMessages = try await dataManager.fetchChatMessages()
        XCTAssertEqual(initialMessages.count, 2)
        
        // When
        try await dataManager.clearChatHistory()
        let remainingMessages = try await dataManager.fetchChatMessages()
        
        // Then
        XCTAssertEqual(remainingMessages.count, 0)
    }
    
    // MARK: - Spending Limit Tests
    
    func testUpdateSpendingLimit() async throws {
        // Given
        let card = CreditCard(
            name: "Test Card",
            cardType: .amexGold,
            spendingLimits: [
                SpendingLimit(category: .groceries, limit: 1000, currentSpending: 500)
            ]
        )
        
        try await dataManager.saveCard(card)
        
        // When
        try await dataManager.updateSpendingLimit(
            cardId: card.id,
            category: .groceries,
            amount: 750
        )
        
        let updatedCards = try await dataManager.fetchCards()
        
        // Then
        XCTAssertEqual(updatedCards.count, 1)
        let groceryLimit = updatedCards.first?.spendingLimits.first { $0.category == .groceries }
        XCTAssertEqual(groceryLimit?.currentSpending, 750, accuracy: 0.01)
    }
    
    func testUpdateSpendingLimitForNonExistentCard() async {
        // Given
        let nonExistentCardId = UUID()
        
        // When/Then
        do {
            try await dataManager.updateSpendingLimit(
                cardId: nonExistentCardId,
                category: .groceries,
                amount: 100
            )
            XCTFail("Expected DataManagerError.cardNotFound")
        } catch DataManagerError.cardNotFound {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Sample Data Tests
    
    func testLoadSampleData() async throws {
        // When
        try await dataManager.loadSampleData()
        let cards = try await dataManager.fetchCards()
        
        // Then
        XCTAssertEqual(cards.count, 3)
        
        let cardNames = cards.map { $0.name }
        XCTAssertTrue(cardNames.contains("Amex Gold"))
        XCTAssertTrue(cardNames.contains("Chase Freedom"))
        XCTAssertTrue(cardNames.contains("Chase Sapphire Reserve"))
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceFetchCards() throws {
        // Load sample data first
        let expectation = expectation(description: "Load sample data")
        Task {
            try await dataManager.loadSampleData()
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)
        
        // Measure performance
        measure {
            let fetchExpectation = expectation(description: "Fetch cards")
            Task {
                _ = try await dataManager.fetchCards()
                fetchExpectation.fulfill()
            }
            wait(for: [fetchExpectation], timeout: 1.0)
        }
    }
}

// MARK: - Test Helper Classes

class TestCoreDataStack: CoreDataStack {
    private let testContainer: NSPersistentContainer
    
    init(container: NSPersistentContainer) {
        self.testContainer = container
        super.init()
    }
    
    override var persistentContainer: NSPersistentContainer {
        return testContainer
    }
}
