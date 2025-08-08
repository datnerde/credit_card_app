import Foundation
import CoreData

// MARK: - Data Manager
class DataManager: ObservableObject {
    private let coreDataStack: CoreDataStack
    private var fallbackMode = false
    private var fallbackCards: [CreditCard] = []
    private var fallbackMessages: [ChatMessage] = []
    private var fallbackPreferences: UserPreferences = UserPreferences()
    
    init(coreDataStack: CoreDataStack = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
        
        // Test Core Data availability with error handling
        do {
            try testCoreDataAvailability()
        } catch {
            print("⚠️ DataManager: Core Data initialization failed, enabling fallback mode: \(error)")
            fallbackMode = true
        }
    }
    
    private func testCoreDataAvailability() {
        do {
            let context = coreDataStack.context
            let request: NSFetchRequest<CreditCardEntity> = CreditCardEntity.fetchRequest()
            request.fetchLimit = 1
            _ = try context.fetch(request)
        } catch {
            print("⚠️ Core Data not available, switching to fallback mode")
            fallbackMode = true
            loadSampleData()
        }
    }
    
    private func loadSampleData() {
        // Use the same sample data as the regular sample data for consistency
        fallbackCards = [
            CreditCard(
                name: "Amex Gold",
                cardType: .amexGold,
                spendingLimits: [
                    SpendingLimit(category: .groceries, limit: 25000, currentSpending: 800),
                    SpendingLimit(category: .dining, limit: 25000, currentSpending: 1200)
                ]
            ),
            CreditCard(
                name: "Chase Freedom",
                cardType: .chaseFreedom,
                quarterlyBonus: QuarterlyBonus(
                    category: .gas,
                    multiplier: 5.0,
                    pointType: .ultimateRewards,
                    limit: 1500,
                    currentSpending: 1500
                ),
                spendingLimits: [
                    SpendingLimit(category: .gas, limit: 1500, currentSpending: 1500)
                ]
            )
        ]
    }
    
    // Convenience computed properties to match the expected interface
    private var container: NSPersistentContainer {
        return coreDataStack.persistentContainer
    }
    
    // MARK: - Credit Card Operations
    
    func fetchCards() async throws -> [CreditCard] {
        if fallbackMode {
            print("📱 Using fallback mode for cards")
            return fallbackCards
        }
        
        do {
            let context = container.viewContext
            let request: NSFetchRequest<CreditCardEntity> = CreditCardEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \CreditCardEntity.createdAt, ascending: false)]
            
            return try await context.perform {
                let entities = try request.execute()
                return entities.compactMap { $0.toModel() }
            }
        } catch {
            print("DataManager: Failed to fetch cards - \(error)")
            print("📱 Switching to fallback mode")
            fallbackMode = true
            loadSampleData()
            return fallbackCards
        }
    }
    
    func saveCard(_ card: CreditCard) async throws {
        if fallbackMode {
            print("📱 Saving card in fallback mode")
            fallbackCards.append(card)
            return
        }
        
        do {
            let context = container.viewContext
            
            try await context.perform {
                let entity = CreditCardEntity(context: context)
                entity.updateFromModel(card)
                
                try context.save()
            }
        } catch {
            print("DataManager: Failed to save card - \(error)")
            print("📱 Switching to fallback mode for save")
            fallbackMode = true
            fallbackCards.append(card)
        }
    }
    
    func updateCard(_ card: CreditCard) async throws {
        if fallbackMode {
            print("📱 Updating card in fallback mode: \(card.name)")
            if let index = fallbackCards.firstIndex(where: { $0.id == card.id }) {
                fallbackCards[index] = card
            }
            return
        }
        
        do {
            let context = container.viewContext
            let request: NSFetchRequest<CreditCardEntity> = CreditCardEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", card.id as CVarArg)
            
            try await context.perform {
                let entities = try request.execute()
                guard let entity = entities.first else {
                    throw DataManagerError.cardNotFound
                }
                
                entity.updateFromModel(card)
                try context.save()
            }
        } catch {
            print("DataManager: Failed to update card - \(error)")
            print("📱 Switching to fallback mode for update")
            fallbackMode = true
            if let index = fallbackCards.firstIndex(where: { $0.id == card.id }) {
                fallbackCards[index] = card
            }
        }
    }
    
    func deleteCard(_ card: CreditCard) async throws {
        if fallbackMode {
            print("📱 Deleting card in fallback mode: \(card.name)")
            fallbackCards.removeAll { $0.id == card.id }
            return
        }
        
        do {
            let context = container.viewContext
            let request: NSFetchRequest<CreditCardEntity> = CreditCardEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", card.id as CVarArg)
            
            try await context.perform {
                let entities = try request.execute()
                guard let entity = entities.first else {
                    throw DataManagerError.cardNotFound
                }
                
                context.delete(entity)
                try context.save()
            }
        } catch {
            print("DataManager: Failed to delete card - \(error)")
            print("📱 Switching to fallback mode for delete")
            fallbackMode = true
            fallbackCards.removeAll { $0.id == card.id }
        }
    }
    
    // MARK: - User Preferences Operations
    
    func loadUserPreferences() async throws -> UserPreferences {
        let context = container.viewContext
        let request: NSFetchRequest<UserPreferencesEntity> = UserPreferencesEntity.fetchRequest()
        
        return try await context.perform {
            let entities = try request.execute()
            if let entity = entities.first {
                return entity.toModel()
            } else {
                // Return default preferences if none exist
                let defaultPreferences = UserPreferences()
                let entity = UserPreferencesEntity(context: context)
                entity.updateFromModel(defaultPreferences)
                try context.save()
                return defaultPreferences
            }
        }
    }
    
    func saveUserPreferences(_ preferences: UserPreferences) async throws {
        let context = container.viewContext
        let request: NSFetchRequest<UserPreferencesEntity> = UserPreferencesEntity.fetchRequest()
        
        try await context.perform {
            let entities = try request.execute()
            let entity: UserPreferencesEntity
            
            if let existingEntity = entities.first {
                entity = existingEntity
            } else {
                entity = UserPreferencesEntity(context: context)
            }
            
            entity.updateFromModel(preferences)
            try context.save()
        }
    }
    
    // MARK: - Chat Message Operations
    
    func fetchChatMessages() async throws -> [ChatMessage] {
        let context = container.viewContext
        let request: NSFetchRequest<ChatMessageEntity> = ChatMessageEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ChatMessageEntity.timestamp, ascending: true)]
        
        return try await context.perform {
            let entities = try request.execute()
            return entities.compactMap { $0.toModel() }
        }
    }
    
    func saveChatMessage(_ message: ChatMessage) async throws {
        let context = container.viewContext
        
        try await context.perform {
            let entity = ChatMessageEntity(context: context)
            entity.updateFromModel(message)
            
            try context.save()
        }
    }
    
    func clearChatHistory() async throws {
        let context = container.viewContext
        let request: NSFetchRequest<ChatMessageEntity> = ChatMessageEntity.fetchRequest()
        
        try await context.perform {
            let entities = try request.execute()
            entities.forEach { context.delete($0) }
            try context.save()
        }
    }
    
    // MARK: - Spending Limit Operations
    
    func updateSpendingLimit(cardId: UUID, category: SpendingCategory, amount: Double) async throws {
        let context = container.viewContext
        let request: NSFetchRequest<CreditCardEntity> = CreditCardEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", cardId as CVarArg)
        
        try await context.perform {
            let entities = try request.execute()
            guard let entity = entities.first else {
                throw DataManagerError.cardNotFound
            }
            
            // Update the spending limit
            if let card = entity.toModel() {
                var updatedCard = card
                if let index = updatedCard.spendingLimits.firstIndex(where: { $0.category == category }) {
                    updatedCard.spendingLimits[index].currentSpending = amount
                    entity.updateFromModel(updatedCard)
                    try context.save()
                }
            }
        }
    }
    
    // MARK: - Data Cleanup
    
    func removeDuplicateCards() async throws {
        print("🧹 Checking for duplicate cards...")
        if fallbackMode {
            var uniqueCards: [CreditCard] = []
            var seenNames: Set<String> = []
            
            for card in fallbackCards {
                if !seenNames.contains(card.name) {
                    seenNames.insert(card.name)
                    uniqueCards.append(card)
                } else {
                    print("🧹 Removing duplicate fallback card: \(card.name)")
                }
            }
            fallbackCards = uniqueCards
            return
        }
        
        do {
            let context = container.viewContext
            let request: NSFetchRequest<CreditCardEntity> = CreditCardEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \CreditCardEntity.createdAt, ascending: true)]
            
            try await context.perform {
                let entities = try request.execute()
                var seenNames: Set<String> = []
                var duplicatesToDelete: [CreditCardEntity] = []
                
                for entity in entities {
                    let cardName = entity.name ?? ""
                    if !seenNames.contains(cardName) {
                        seenNames.insert(cardName)
                    } else {
                        print("🧹 Found duplicate card to delete: \(cardName)")
                        duplicatesToDelete.append(entity)
                    }
                }
                
                // Delete duplicates
                for duplicate in duplicatesToDelete {
                    context.delete(duplicate)
                    let name = duplicate.name ?? "Unknown"
                    print("🧹 Deleted duplicate card: \(name)")
                }
                
                if !duplicatesToDelete.isEmpty {
                    try context.save()
                    print("🧹 Removed \(duplicatesToDelete.count) duplicate cards")
                } else {
                    print("🧹 No duplicate cards found")
                }
            }
        } catch {
            print("❌ Error removing duplicate cards: \(error)")
            throw error
        }
    }
    
    // MARK: - Sample Data
    
    func loadSampleCardsData() async throws {
        print("🎯 Starting to load sample cards data")
        
        // Check existing cards first to avoid duplicates
        let existingCards = try await fetchCards()
        let existingNames = Set(existingCards.map { $0.name })
        print("🎯 Found existing cards: \(existingNames)")
        
        let sampleCards = [
            CreditCard(
                name: "Amex Gold",
                cardType: .amexGold,
                spendingLimits: [
                    SpendingLimit(category: .groceries, limit: 25000, currentSpending: 800),
                    SpendingLimit(category: .dining, limit: 25000, currentSpending: 1200)
                ]
            ),
            CreditCard(
                name: "Chase Freedom",
                cardType: .chaseFreedom,
                quarterlyBonus: QuarterlyBonus(
                    category: .gas,
                    multiplier: 5.0,
                    pointType: .ultimateRewards,
                    limit: 1500,
                    currentSpending: 1500
                ),
                spendingLimits: [
                    SpendingLimit(category: .gas, limit: 1500, currentSpending: 1500)
                ]
            )
        ]
        
        // Only add cards that don't already exist
        for card in sampleCards {
            if !existingNames.contains(card.name) {
                print("🎯 Adding sample card: \(card.name)")
                try await saveCard(card)
            } else {
                print("🎯 Skipping existing card: \(card.name)")
            }
        }
        
        print("🎯 Sample cards loading completed")
    }
}

// MARK: - Data Errors
enum DataManagerError: LocalizedError {
    case cardNotFound
    case invalidData
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .cardNotFound:
            return "Credit card not found"
        case .invalidData:
            return "Invalid data provided"
        case .saveFailed:
            return "Failed to save data"
        }
    }
} 