import Foundation
import CoreData

// MARK: - Data Manager
class DataManager: ObservableObject {
    private let persistenceController: PersistenceController
    
    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
    }
    
    // Convenience computed properties to match the expected interface
    private var container: NSPersistentContainer {
        return persistenceController.container
    }
    
    // MARK: - Credit Card Operations
    
    func fetchCards() async throws -> [CreditCard] {
        let context = container.viewContext
        let request: NSFetchRequest<CreditCardEntity> = CreditCardEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CreditCardEntity.createdAt, ascending: false)]
        
        return try await context.perform {
            let entities = try request.execute()
            return entities.compactMap { $0.toModel() }
        }
    }
    
    func saveCard(_ card: CreditCard) async throws {
        let context = container.viewContext
        
        try await context.perform {
            let entity = CreditCardEntity(context: context)
            entity.updateFromModel(card)
            
            try context.save()
        }
    }
    
    func updateCard(_ card: CreditCard) async throws {
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
    }
    
    func deleteCard(_ card: CreditCard) async throws {
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
    
    // MARK: - Sample Data
    
    func loadSampleData() async throws {
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
            ),
            CreditCard(
                name: "Chase Sapphire Reserve",
                cardType: .chaseSapphireReserve,
                spendingLimits: [
                    SpendingLimit(category: .travel, limit: 3000, currentSpending: 2000)
                ]
            )
        ]
        
        for card in sampleCards {
            try await saveCard(card)
        }
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