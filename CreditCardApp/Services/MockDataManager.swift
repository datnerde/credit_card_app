import Foundation

class MockDataManager: DataManager {
    private var cards: [CreditCard] = []
    private var userPreferences: UserPreferences = UserPreferences()
    private var chatMessages: [ChatMessage] = []
    
    override func fetchCards() async throws -> [CreditCard] {
        if cards.isEmpty {
            try await loadSampleData()
        }
        return cards
    }
    
    override func saveCard(_ card: CreditCard) async throws {
        if let index = cards.firstIndex(where: { $0.id == card.id }) {
            cards[index] = card
        } else {
            cards.append(card)
        }
    }
    
    override func updateCard(_ card: CreditCard) async throws {
        if let index = cards.firstIndex(where: { $0.id == card.id }) {
            cards[index] = card
        } else {
            throw DataError.cardNotFound
        }
    }
    
    override func deleteCard(_ card: CreditCard) async throws {
        cards.removeAll { $0.id == card.id }
    }
    
    override func loadUserPreferences() async throws -> UserPreferences {
        return userPreferences
    }
    
    override func saveUserPreferences(_ preferences: UserPreferences) async throws {
        self.userPreferences = preferences
    }
    
    override func fetchChatMessages() async throws -> [ChatMessage] {
        return chatMessages
    }
    
    override func saveChatMessage(_ message: ChatMessage) async throws {
        chatMessages.append(message)
    }
    
    override func clearChatHistory() async throws {
        chatMessages.removeAll()
    }
    
    override func loadSampleData() async throws {
        cards = MockData.sampleCards
        chatMessages = MockData.sampleChatMessages
        userPreferences = MockData.sampleUserPreferences
    }
}

enum DataError: Error {
    case cardNotFound
    case saveFailed
    case loadFailed
}