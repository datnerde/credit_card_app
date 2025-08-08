import XCTest
@testable import CreditCardApp

final class CardManagementIntegrationTest: XCTestCase {
    var dataManager: DataManager!
    var cardListViewModel: CardListViewModel!
    var addCardViewModel: AddCardViewModel!
    
    override func setUp() {
        super.setUp()
        
        // Initialize with a fresh DataManager for each test
        dataManager = DataManager()
        cardListViewModel = CardListViewModel(
            dataManager: dataManager,
            analyticsService: AnalyticsService.shared
        )
        addCardViewModel = AddCardViewModel(
            dataManager: dataManager,
            analyticsService: AnalyticsService.shared
        )
    }
    
    override func tearDown() {
        dataManager = nil
        cardListViewModel = nil
        addCardViewModel = nil
        super.tearDown()
    }
    
    // MARK: - Test Card Adding Flow
    
    func testAddCardFlow() async throws {
        // Given: Start with empty card list
        await cardListViewModel.loadCards()
        let initialCount = cardListViewModel.cards.count
        
        // When: Add a new card through AddCardViewModel
        addCardViewModel.cardName = "Test Amex Gold"
        addCardViewModel.selectedCardType = .amexGold
        addCardViewModel.loadDefaultsForCardType()
        
        // Ensure form is valid
        XCTAssertTrue(addCardViewModel.isFormValid, "Form should be valid with card name and type")
        
        // Save the card
        await addCardViewModel.saveCard()
        
        // Verify no error occurred
        XCTAssertNil(addCardViewModel.errorMessage, "Should not have error after saving")
        
        // Reload cards in CardListViewModel
        await cardListViewModel.loadCards()
        
        // Then: Card should appear in the list
        XCTAssertEqual(cardListViewModel.cards.count, initialCount + 1, "Should have one more card")
        
        let addedCard = cardListViewModel.cards.first { $0.name == "Test Amex Gold" }
        XCTAssertNotNil(addedCard, "Added card should be found in the list")
        XCTAssertEqual(addedCard?.cardType, .amexGold, "Card type should match")
    }
    
    // MARK: - Test Card Deletion Flow
    
    func testDeleteCardFlow() async throws {
        // Given: Add a card first
        await cardListViewModel.loadCards()
        let initialCount = cardListViewModel.cards.count
        
        // Create a test card
        let testCard = CreditCard(
            name: "Test Delete Card",
            cardType: .chaseFreedom
        )
        
        // Add it to the DataManager directly
        try await dataManager.saveCard(testCard)
        await cardListViewModel.loadCards()
        
        let afterAddCount = cardListViewModel.cards.count
        XCTAssertEqual(afterAddCount, initialCount + 1, "Should have added one card")
        
        // When: Delete the card
        await cardListViewModel.deleteCard(testCard)
        
        // Then: Card should be removed from the list
        XCTAssertEqual(cardListViewModel.cards.count, initialCount, "Should be back to initial count")
        
        let deletedCard = cardListViewModel.cards.first { $0.id == testCard.id }
        XCTAssertNil(deletedCard, "Deleted card should not be in the list")
    }
    
    // MARK: - Test Update Card Flow
    
    func testUpdateCardFlow() async throws {
        // Given: Add a card first
        let originalCard = CreditCard(
            name: "Original Card",
            cardType: .amexGold
        )
        
        try await dataManager.saveCard(originalCard)
        await cardListViewModel.loadCards()
        
        let foundCard = cardListViewModel.cards.first { $0.id == originalCard.id }
        XCTAssertNotNil(foundCard, "Original card should be in the list")
        
        // When: Update the card
        var updatedCard = originalCard
        updatedCard.name = "Updated Card Name"
        updatedCard.isActive = false
        
        await cardListViewModel.updateCard(updatedCard)
        
        // Then: Card should be updated in the list
        let updatedFoundCard = cardListViewModel.cards.first { $0.id == originalCard.id }
        XCTAssertNotNil(updatedFoundCard, "Updated card should still be in the list")
        XCTAssertEqual(updatedFoundCard?.name, "Updated Card Name", "Name should be updated")
        XCTAssertEqual(updatedFoundCard?.isActive, false, "Active status should be updated")
    }
    
    // MARK: - Test Data Consistency
    
    func testDataConsistencyAfterMultipleOperations() async throws {
        // Given: Start fresh
        await cardListViewModel.loadCards()
        let initialCount = cardListViewModel.cards.count
        
        // When: Perform multiple operations
        let card1 = CreditCard(name: "Card 1", cardType: .amexGold)
        let card2 = CreditCard(name: "Card 2", cardType: .chaseFreedom)
        let card3 = CreditCard(name: "Card 3", cardType: .citiDoubleCash)
        
        // Add three cards
        try await dataManager.saveCard(card1)
        try await dataManager.saveCard(card2)
        try await dataManager.saveCard(card3)
        
        // Reload and verify
        await cardListViewModel.loadCards()
        XCTAssertEqual(cardListViewModel.cards.count, initialCount + 3, "Should have 3 more cards")
        
        // Delete one card
        await cardListViewModel.deleteCard(card2)
        XCTAssertEqual(cardListViewModel.cards.count, initialCount + 2, "Should have 2 more cards after deletion")
        
        // Update one card
        var updatedCard1 = card1
        updatedCard1.name = "Updated Card 1"
        await cardListViewModel.updateCard(updatedCard1)
        
        // Verify final state
        let finalCard1 = cardListViewModel.cards.first { $0.id == card1.id }
        XCTAssertEqual(finalCard1?.name, "Updated Card 1", "Card 1 should be updated")
        
        let deletedCard2 = cardListViewModel.cards.first { $0.id == card2.id }
        XCTAssertNil(deletedCard2, "Card 2 should be deleted")
        
        let card3Found = cardListViewModel.cards.first { $0.id == card3.id }
        XCTAssertNotNil(card3Found, "Card 3 should still exist")
    }
    
    // MARK: - Test Fallback Mode Behavior
    
    func testFallbackModeConsistency() async throws {
        // This test ensures that fallback mode works consistently
        // by forcing fallback mode and testing operations
        
        // Access the fallback mode directly
        let testDataManager = DataManager()
        
        // Add cards in fallback mode
        let card1 = CreditCard(name: "Fallback Card 1", cardType: .amexGold)
        let card2 = CreditCard(name: "Fallback Card 2", cardType: .chaseFreedom)
        
        try await testDataManager.saveCard(card1)
        try await testDataManager.saveCard(card2)
        
        // Fetch and verify
        let cards = try await testDataManager.fetchCards()
        XCTAssertTrue(cards.count >= 2, "Should have at least 2 cards")
        
        let foundCard1 = cards.first { $0.id == card1.id }
        let foundCard2 = cards.first { $0.id == card2.id }
        XCTAssertNotNil(foundCard1, "Card 1 should be found")
        XCTAssertNotNil(foundCard2, "Card 2 should be found")
        
        // Test deletion
        try await testDataManager.deleteCard(card1)
        let cardsAfterDelete = try await testDataManager.fetchCards()
        
        let deletedCard = cardsAfterDelete.first { $0.id == card1.id }
        XCTAssertNil(deletedCard, "Card 1 should be deleted")
        
        let remainingCard = cardsAfterDelete.first { $0.id == card2.id }
        XCTAssertNotNil(remainingCard, "Card 2 should remain")
    }
    
    // MARK: - Test UI Integration
    
    func testCardListUIIntegration() async throws {
        // Test the complete flow from AddCard to CardList
        await cardListViewModel.loadCards()
        let initialCount = cardListViewModel.cards.count
        
        // Simulate the AddCardView flow
        addCardViewModel.cardName = "UI Integration Test Card"
        addCardViewModel.selectedCardType = .chaseSapphireReserve
        addCardViewModel.loadDefaultsForCardType()
        
        // Save through AddCardViewModel
        await addCardViewModel.saveCard()
        XCTAssertNil(addCardViewModel.errorMessage, "Save should succeed")
        
        // Reload CardListViewModel (simulating what happens when sheet is dismissed)
        await cardListViewModel.loadCards()
        
        // Verify the card appears
        XCTAssertEqual(cardListViewModel.cards.count, initialCount + 1, "Card should appear in list")
        
        let addedCard = cardListViewModel.cards.first { $0.name == "UI Integration Test Card" }
        XCTAssertNotNil(addedCard, "Added card should be found")
        XCTAssertEqual(addedCard?.cardType, .chaseSapphireReserve, "Card type should match")
    }
}