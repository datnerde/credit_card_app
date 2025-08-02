import Foundation
import CoreData

// MARK: - Core Data Entity Extensions

@objc(CreditCardEntity)
public class CreditCardEntity: NSManagedObject {
    
}

extension CreditCardEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CreditCardEntity> {
        return NSFetchRequest<CreditCardEntity>(entityName: "CreditCardEntity")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var cardType: String?
    @NSManaged public var isActive: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var rewardCategories: NSSet?
    @NSManaged public var spendingLimits: NSSet?
    @NSManaged public var quarterlyBonus: QuarterlyBonusEntity?
}

// MARK: Generated accessors for rewardCategories
extension CreditCardEntity {
    @objc(addRewardCategoriesObject:)
    @NSManaged public func addToRewardCategories(_ value: RewardCategoryEntity)

    @objc(removeRewardCategoriesObject:)
    @NSManaged public func removeFromRewardCategories(_ value: RewardCategoryEntity)

    @objc(addRewardCategories:)
    @NSManaged public func addToRewardCategories(_ values: NSSet)

    @objc(removeRewardCategories:)
    @NSManaged public func removeFromRewardCategories(_ values: NSSet)
}

// MARK: Generated accessors for spendingLimits
extension CreditCardEntity {
    @objc(addSpendingLimitsObject:)
    @NSManaged public func addToSpendingLimits(_ value: SpendingLimitEntity)

    @objc(removeSpendingLimitsObject:)
    @NSManaged public func removeFromSpendingLimits(_ value: SpendingLimitEntity)

    @objc(addSpendingLimits:)
    @NSManaged public func addToSpendingLimits(_ values: NSSet)

    @objc(removeSpendingLimits:)
    @NSManaged public func removeFromSpendingLimits(_ values: NSSet)
}

@objc(RewardCategoryEntity)
public class RewardCategoryEntity: NSManagedObject {
    
}

extension RewardCategoryEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RewardCategoryEntity> {
        return NSFetchRequest<RewardCategoryEntity>(entityName: "RewardCategoryEntity")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var category: String?
    @NSManaged public var multiplier: Double
    @NSManaged public var pointType: String?
    @NSManaged public var isActive: Bool
    @NSManaged public var creditCard: CreditCardEntity?
}

@objc(SpendingLimitEntity)
public class SpendingLimitEntity: NSManagedObject {
    
}

extension SpendingLimitEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SpendingLimitEntity> {
        return NSFetchRequest<SpendingLimitEntity>(entityName: "SpendingLimitEntity")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var category: String?
    @NSManaged public var limit: Double
    @NSManaged public var currentSpending: Double
    @NSManaged public var resetDate: Date?
    @NSManaged public var resetType: String?
    @NSManaged public var creditCard: CreditCardEntity?
}

@objc(QuarterlyBonusEntity)
public class QuarterlyBonusEntity: NSManagedObject {
    
}

extension QuarterlyBonusEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<QuarterlyBonusEntity> {
        return NSFetchRequest<QuarterlyBonusEntity>(entityName: "QuarterlyBonusEntity")
    }
    
    @NSManaged public var category: String?
    @NSManaged public var multiplier: Double
    @NSManaged public var pointType: String?
    @NSManaged public var limit: Double
    @NSManaged public var currentSpending: Double
    @NSManaged public var quarter: Int16
    @NSManaged public var year: Int16
    @NSManaged public var creditCard: CreditCardEntity?
}

@objc(UserPreferencesEntity)
public class UserPreferencesEntity: NSManagedObject {
    
}

extension UserPreferencesEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserPreferencesEntity> {
        return NSFetchRequest<UserPreferencesEntity>(entityName: "UserPreferencesEntity")
    }
    
    @NSManaged public var preferredPointSystemString: String?
    @NSManaged public var alertThreshold: Double
    @NSManaged public var languageString: String?
    @NSManaged public var notificationsEnabled: Bool
    @NSManaged public var autoUpdateSpending: Bool
}

@objc(ChatMessageEntity)
public class ChatMessageEntity: NSManagedObject {
    
}

extension ChatMessageEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChatMessageEntity> {
        return NSFetchRequest<ChatMessageEntity>(entityName: "ChatMessageEntity")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var content: String?
    @NSManaged public var sender: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var cardRecommendations: NSSet?
    @NSManaged public var spendingUpdate: SpendingUpdateEntity?
}

// MARK: Generated accessors for cardRecommendations
extension ChatMessageEntity {
    @objc(addCardRecommendationsObject:)
    @NSManaged public func addToCardRecommendations(_ value: CardRecommendationEntity)

    @objc(removeCardRecommendationsObject:)
    @NSManaged public func removeFromCardRecommendations(_ value: CardRecommendationEntity)

    @objc(addCardRecommendations:)
    @NSManaged public func addToCardRecommendations(_ values: NSSet)

    @objc(removeCardRecommendations:)
    @NSManaged public func removeFromCardRecommendations(_ values: NSSet)
}

@objc(CardRecommendationEntity)
public class CardRecommendationEntity: NSManagedObject {
    
}

extension CardRecommendationEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CardRecommendationEntity> {
        return NSFetchRequest<CardRecommendationEntity>(entityName: "CardRecommendationEntity")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var cardId: UUID?
    @NSManaged public var cardName: String?
    @NSManaged public var category: String?
    @NSManaged public var multiplier: Double
    @NSManaged public var pointType: String?
    @NSManaged public var reasoning: String?
    @NSManaged public var currentSpending: Double
    @NSManaged public var limit: Double
    @NSManaged public var isLimitReached: Bool
    @NSManaged public var rank: Int16
    @NSManaged public var chatMessage: ChatMessageEntity?
}

@objc(SpendingUpdateEntity)
public class SpendingUpdateEntity: NSManagedObject {
    
}

extension SpendingUpdateEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SpendingUpdateEntity> {
        return NSFetchRequest<SpendingUpdateEntity>(entityName: "SpendingUpdateEntity")
    }
    
    @NSManaged public var cardId: UUID?
    @NSManaged public var category: String?
    @NSManaged public var amount: Double
    @NSManaged public var previousAmount: Double
    @NSManaged public var chatMessage: ChatMessageEntity?
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
        
        let rewardCategories = (self.rewardCategories?.allObjects as? [RewardCategoryEntity])?.compactMap { $0.toModel() } ?? []
        let spendingLimits = (self.spendingLimits?.allObjects as? [SpendingLimitEntity])?.compactMap { $0.toModel() } ?? []
        let quarterlyBonus = self.quarterlyBonus?.toModel()
        
        var card = CreditCard(
            id: id,
            name: name,
            cardType: cardType,
            rewardCategories: rewardCategories,
            quarterlyBonus: quarterlyBonus,
            spendingLimits: spendingLimits,
            isActive: isActive
        )
        card.createdAt = createdAt ?? Date()
        card.updatedAt = updatedAt ?? Date()
        return card
    }
    
    func updateFromModel(_ card: CreditCard) {
        id = card.id
        name = card.name
        cardType = card.cardType.rawValue
        isActive = card.isActive
        createdAt = card.createdAt
        updatedAt = card.updatedAt
        
        // Clear existing relationships
        self.rewardCategories?.forEach { managedObjectContext?.delete($0 as! NSManagedObject) }
        self.spendingLimits?.forEach { managedObjectContext?.delete($0 as! NSManagedObject) }
        if let existing = self.quarterlyBonus {
            managedObjectContext?.delete(existing as! NSManagedObject)
        }
        
        // Update reward categories
        for category in card.rewardCategories {
            let entity = RewardCategoryEntity(context: self.managedObjectContext!)
            entity.updateFromModel(category)
            self.addToRewardCategories(entity)
        }
        
        // Update spending limits
        for limit in card.spendingLimits {
            let entity = SpendingLimitEntity(context: self.managedObjectContext!)
            entity.updateFromModel(limit)
            self.addToSpendingLimits(entity)
        }
        
        // Update quarterly bonus
        if let quarterlyBonus = card.quarterlyBonus {
            let entity = QuarterlyBonusEntity(context: self.managedObjectContext!)
            entity.updateFromModel(quarterlyBonus)
            self.quarterlyBonus = entity
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
        self.category = category.category.rawValue
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
        self.category = limit.category.rawValue
        self.limit = limit.limit
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
        self.category = bonus.category.rawValue
        multiplier = bonus.multiplier
        pointType = bonus.pointType.rawValue
        self.limit = bonus.limit
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
        
        let cardRecommendations = (self.cardRecommendations?.allObjects as? [CardRecommendationEntity])?.compactMap { $0.toModel() }
        let spendingUpdate = self.spendingUpdate?.toModel()
        
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
            for recommendation in recommendations {
                let entity = CardRecommendationEntity(context: self.managedObjectContext!)
                entity.updateFromModel(recommendation)
                self.addToCardRecommendations(entity)
            }
        }
        
        // Update spending update
        if let spendingUpdate = message.spendingUpdate {
            let entity = SpendingUpdateEntity(context: self.managedObjectContext!)
            entity.updateFromModel(spendingUpdate)
            self.spendingUpdate = entity
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
            cardId: cardId!,
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
        self.category = recommendation.category.rawValue
        multiplier = recommendation.multiplier
        pointType = recommendation.pointType.rawValue
        reasoning = recommendation.reasoning
        currentSpending = recommendation.currentSpending
        self.limit = recommendation.limit
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
            cardId: cardId!,
            category: category,
            amount: amount,
            previousAmount: previousAmount
        )
    }
    
    func updateFromModel(_ update: SpendingUpdate) {
        cardId = update.cardId
        self.category = update.category.rawValue
        amount = update.amount
        previousAmount = update.previousAmount
    }
}