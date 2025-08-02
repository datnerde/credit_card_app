import Foundation
import CoreData

// MARK: - Data Manager
class DataManager: ObservableObject {
    private let persistenceController: PersistenceController
    
    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
    }
    
    // MARK: - Credit Card Operations
    
    func fetchCards() async throws -> [CreditCard] {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<CreditCardEntity> = CreditCardEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CreditCardEntity.createdAt, ascending: false)]
        
        return try await context.perform {
            let entities = try request.execute()
            return entities.compactMap { $0.toModel() }
        }
    }
    
    func saveCard(_ card: CreditCard) async throws {
        let context = persistenceController.container.viewContext
        
        try await context.perform {
            let entity = CreditCardEntity(context: context)
            entity.updateFromModel(card)
            
            try context.save()
        }
    }
    
    func updateCard(_ card: CreditCard) async throws {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<CreditCardEntity> = CreditCardEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", card.id as CVarArg)
        
        try await context.perform {
            let entities = try request.execute()
            guard let entity = entities.first else {
                throw DataError.cardNotFound
            }
            
            entity.updateFromModel(card)
            try context.save()
        }
    }
    
    func deleteCard(_ card: CreditCard) async throws {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<CreditCardEntity> = CreditCardEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", card.id as CVarArg)
        
        try await context.perform {
            let entities = try request.execute()
            guard let entity = entities.first else {
                throw DataError.cardNotFound
            }
            
            context.delete(entity)
            try context.save()
        }
    }
    
    // MARK: - User Preferences Operations
    
    func fetchUserPreferences() async throws -> UserPreferences {
        let context = persistenceController.container.viewContext
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
        let context = persistenceController.container.viewContext
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
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<ChatMessageEntity> = ChatMessageEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ChatMessageEntity.timestamp, ascending: true)]
        
        return try await context.perform {
            let entities = try request.execute()
            return entities.compactMap { $0.toModel() }
        }
    }
    
    func saveChatMessage(_ message: ChatMessage) async throws {
        let context = persistenceController.container.viewContext
        
        try await context.perform {
            let entity = ChatMessageEntity(context: context)
            entity.updateFromModel(message)
            
            try context.save()
        }
    }
    
    func clearChatHistory() async throws {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<ChatMessageEntity> = ChatMessageEntity.fetchRequest()
        
        try await context.perform {
            let entities = try request.execute()
            entities.forEach { context.delete($0) }
            try context.save()
        }
    }
    
    // MARK: - Spending Limit Operations
    
    func updateSpendingLimit(cardId: UUID, category: SpendingCategory, amount: Double) async throws {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<CreditCardEntity> = CreditCardEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", cardId as CVarArg)
        
        try await context.perform {
            let entities = try request.execute()
            guard let entity = entities.first else {
                throw DataError.cardNotFound
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
enum DataError: LocalizedError {
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

// MARK: - Core Data Entity Extensions

extension CreditCardEntity {
    func toModel() -> CreditCard? {
        guard let id = id,
              let name = name,
              let cardTypeString = cardType,
              let cardType = CardType(rawValue: cardTypeString) else {
            return nil
        }
        
        let rewardCategories = (rewardCategoriesArray as? [RewardCategoryEntity])?.compactMap { $0.toModel() } ?? []
        let spendingLimits = (spendingLimitsArray as? [SpendingLimitEntity])?.compactMap { $0.toModel() } ?? []
        let quarterlyBonus = quarterlyBonusEntity?.toModel()
        
        return CreditCard(
            id: id,
            name: name,
            cardType: cardType,
            rewardCategories: rewardCategories,
            quarterlyBonus: quarterlyBonus,
            spendingLimits: spendingLimits,
            isActive: isActive,
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date()
        )
    }
    
    func updateFromModel(_ card: CreditCard) {
        id = card.id
        name = card.name
        cardType = card.cardType.rawValue
        isActive = card.isActive
        createdAt = card.createdAt
        updatedAt = card.updatedAt
        
        // Update reward categories
        rewardCategoriesArray = card.rewardCategories.map { category in
            let entity = RewardCategoryEntity(context: self.managedObjectContext!)
            entity.updateFromModel(category)
            return entity
        }
        
        // Update spending limits
        spendingLimitsArray = card.spendingLimits.map { limit in
            let entity = SpendingLimitEntity(context: self.managedObjectContext!)
            entity.updateFromModel(limit)
            return entity
        }
        
        // Update quarterly bonus
        if let quarterlyBonus = card.quarterlyBonus {
            let entity = QuarterlyBonusEntity(context: self.managedObjectContext!)
            entity.updateFromModel(quarterlyBonus)
            quarterlyBonusEntity = entity
        }
    }
}

extension RewardCategoryEntity {
    func toModel() -> RewardCategory? {
        guard let id = id,
              let categoryString = category,
              let category = SpendingCategory(rawValue: categoryString),
              let pointTypeString = pointType,
              let pointType = PointType(rawValue: pointTypeString) else {
            return nil
        }
        
        return RewardCategory(
            id: id,
            category: category,
            multiplier: multiplier,
            pointType: pointType,
            isActive: isActive
        )
    }
    
    func updateFromModel(_ category: RewardCategory) {
        id = category.id
        category = category.category.rawValue
        multiplier = category.multiplier
        pointType = category.pointType.rawValue
        isActive = category.isActive
    }
}

extension SpendingLimitEntity {
    func toModel() -> SpendingLimit? {
        guard let id = id,
              let categoryString = category,
              let category = SpendingCategory(rawValue: categoryString),
              let resetTypeString = resetType,
              let resetType = ResetType(rawValue: resetTypeString) else {
            return nil
        }
        
        return SpendingLimit(
            id: id,
            category: category,
            limit: limit,
            currentSpending: currentSpending,
            resetDate: resetDate ?? Date(),
            resetType: resetType
        )
    }
    
    func updateFromModel(_ limit: SpendingLimit) {
        id = limit.id
        category = limit.category.rawValue
        limit = limit.limit
        currentSpending = limit.currentSpending
        resetDate = limit.resetDate
        resetType = limit.resetType.rawValue
    }
}

extension QuarterlyBonusEntity {
    func toModel() -> QuarterlyBonus? {
        guard let categoryString = category,
              let category = SpendingCategory(rawValue: categoryString),
              let pointTypeString = pointType,
              let pointType = PointType(rawValue: pointTypeString) else {
            return nil
        }
        
        return QuarterlyBonus(
            category: category,
            multiplier: multiplier,
            pointType: pointType,
            limit: limit,
            currentSpending: currentSpending,
            quarter: Int(quarter),
            year: Int(year)
        )
    }
    
    func updateFromModel(_ bonus: QuarterlyBonus) {
        category = bonus.category.rawValue
        multiplier = bonus.multiplier
        pointType = bonus.pointType.rawValue
        limit = bonus.limit
        currentSpending = bonus.currentSpending
        quarter = Int16(bonus.quarter)
        year = Int16(bonus.year)
    }
}

extension UserPreferencesEntity {
    func toModel() -> UserPreferences {
        let preferredPointSystem = PointType(rawValue: preferredPointSystemString ?? "MR") ?? .membershipRewards
        let language = Language(rawValue: languageString ?? "English") ?? .english
        
        return UserPreferences(
            preferredPointSystem: preferredPointSystem,
            alertThreshold: alertThreshold,
            language: language,
            notificationsEnabled: notificationsEnabled,
            autoUpdateSpending: autoUpdateSpending
        )
    }
    
    func updateFromModel(_ preferences: UserPreferences) {
        preferredPointSystemString = preferences.preferredPointSystem.rawValue
        alertThreshold = preferences.alertThreshold
        languageString = preferences.language.rawValue
        notificationsEnabled = preferences.notificationsEnabled
        autoUpdateSpending = preferences.autoUpdateSpending
    }
}

extension ChatMessageEntity {
    func toModel() -> ChatMessage? {
        guard let id = id,
              let content = content,
              let senderString = sender,
              let sender = MessageSender(rawValue: senderString) else {
            return nil
        }
        
        let cardRecommendations = (cardRecommendationsArray as? [CardRecommendationEntity])?.compactMap { $0.toModel() }
        let spendingUpdate = spendingUpdateEntity?.toModel()
        
        return ChatMessage(
            id: id,
            content: content,
            sender: sender,
            timestamp: timestamp ?? Date(),
            cardRecommendations: cardRecommendations,
            spendingUpdate: spendingUpdate
        )
    }
    
    func updateFromModel(_ message: ChatMessage) {
        id = message.id
        content = message.content
        sender = message.sender.rawValue
        timestamp = message.timestamp
        
        // Update card recommendations
        if let recommendations = message.cardRecommendations {
            cardRecommendationsArray = recommendations.map { recommendation in
                let entity = CardRecommendationEntity(context: self.managedObjectContext!)
                entity.updateFromModel(recommendation)
                return entity
            }
        }
        
        // Update spending update
        if let spendingUpdate = message.spendingUpdate {
            let entity = SpendingUpdateEntity(context: self.managedObjectContext!)
            entity.updateFromModel(spendingUpdate)
            spendingUpdateEntity = entity
        }
    }
}

extension CardRecommendationEntity {
    func toModel() -> CardRecommendation? {
        guard let id = id,
              let cardName = cardName,
              let categoryString = category,
              let category = SpendingCategory(rawValue: categoryString),
              let pointTypeString = pointType,
              let pointType = PointType(rawValue: pointTypeString),
              let reasoning = reasoning else {
            return nil
        }
        
        return CardRecommendation(
            id: id,
            cardId: cardId,
            cardName: cardName,
            category: category,
            multiplier: multiplier,
            pointType: pointType,
            reasoning: reasoning,
            currentSpending: currentSpending,
            limit: limit,
            isLimitReached: isLimitReached,
            rank: Int(rank)
        )
    }
    
    func updateFromModel(_ recommendation: CardRecommendation) {
        id = recommendation.id
        cardId = recommendation.cardId
        cardName = recommendation.cardName
        category = recommendation.category.rawValue
        multiplier = recommendation.multiplier
        pointType = recommendation.pointType.rawValue
        reasoning = recommendation.reasoning
        currentSpending = recommendation.currentSpending
        limit = recommendation.limit
        isLimitReached = recommendation.isLimitReached
        rank = Int16(recommendation.rank)
    }
}

extension SpendingUpdateEntity {
    func toModel() -> SpendingUpdate? {
        guard let categoryString = category,
              let category = SpendingCategory(rawValue: categoryString) else {
            return nil
        }
        
        return SpendingUpdate(
            cardId: cardId,
            category: category,
            amount: amount,
            previousAmount: previousAmount
        )
    }
    
    func updateFromModel(_ update: SpendingUpdate) {
        cardId = update.cardId
        category = update.category.rawValue
        amount = update.amount
        previousAmount = update.previousAmount
    }
} 