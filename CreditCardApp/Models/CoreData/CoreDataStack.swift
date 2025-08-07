import Foundation
import CoreData

class CoreDataStack {
    static let shared = CoreDataStack()
    
    lazy var persistentContainer: NSPersistentContainer = {
        // Create the Core Data model programmatically to avoid bundle issues
        let managedObjectModel = self.createManagedObjectModel()
        let container = NSPersistentContainer(name: "CreditCardApp", managedObjectModel: managedObjectModel)
        
        // Configure for better performance
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("⚠️ Core Data Stack: Failed to load persistent stores: \(error)")
                print("📱 Store Description: \(storeDescription)")
                
                // In development, don't crash - let the DataManager handle fallback
                #if DEBUG
                print("🔄 Core Data failed to load - DataManager will use fallback mode")
                #else
                fatalError("Core Data error: \(error), \(error.userInfo)")
                #endif
            } else {
                print("✅ Core Data Stack: Persistent stores loaded successfully")
            }
        }
        
        return container
    }()
    
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    var backgroundContext: NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Core Data save error: \(error)")
            }
        }
    }
    
    func saveBackgroundContext(_ context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Background Core Data save error: \(error)")
            }
        }
    }
    
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            persistentContainer.performBackgroundTask { context in
                do {
                    let result = try block(context)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Programmatic Core Data Model Creation
    
    private func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        // Create CreditCardEntity
        let creditCardEntity = NSEntityDescription()
        creditCardEntity.name = "CreditCardEntity"
        creditCardEntity.managedObjectClassName = "CreditCardEntity"
        
        // CreditCardEntity attributes
        let cardId = NSAttributeDescription()
        cardId.name = "id"
        cardId.attributeType = .UUIDAttributeType
        cardId.isOptional = true
        
        let cardName = NSAttributeDescription()
        cardName.name = "name"
        cardName.attributeType = .stringAttributeType
        cardName.isOptional = true
        
        let cardType = NSAttributeDescription()
        cardType.name = "cardType"
        cardType.attributeType = .stringAttributeType
        cardType.isOptional = true
        
        let isActive = NSAttributeDescription()
        isActive.name = "isActive"
        isActive.attributeType = .booleanAttributeType
        isActive.isOptional = false
        
        let createdAt = NSAttributeDescription()
        createdAt.name = "createdAt"
        createdAt.attributeType = .dateAttributeType
        createdAt.isOptional = true
        
        let updatedAt = NSAttributeDescription()
        updatedAt.name = "updatedAt"
        updatedAt.attributeType = .dateAttributeType
        updatedAt.isOptional = true
        
        creditCardEntity.properties = [cardId, cardName, cardType, isActive, createdAt, updatedAt]
        
        // Create ChatMessageEntity
        let chatMessageEntity = NSEntityDescription()
        chatMessageEntity.name = "ChatMessageEntity"
        chatMessageEntity.managedObjectClassName = "ChatMessageEntity"
        
        let messageId = NSAttributeDescription()
        messageId.name = "id"
        messageId.attributeType = .UUIDAttributeType
        messageId.isOptional = true
        
        let messageContent = NSAttributeDescription()
        messageContent.name = "content"
        messageContent.attributeType = .stringAttributeType
        messageContent.isOptional = true
        
        let messageSender = NSAttributeDescription()
        messageSender.name = "sender"
        messageSender.attributeType = .stringAttributeType
        messageSender.isOptional = true
        
        let messageTimestamp = NSAttributeDescription()
        messageTimestamp.name = "timestamp"
        messageTimestamp.attributeType = .dateAttributeType
        messageTimestamp.isOptional = true
        
        chatMessageEntity.properties = [messageId, messageContent, messageSender, messageTimestamp]
        
        // Create UserPreferencesEntity
        let userPreferencesEntity = NSEntityDescription()
        userPreferencesEntity.name = "UserPreferencesEntity"
        userPreferencesEntity.managedObjectClassName = "UserPreferencesEntity"
        
        let preferredPointSystemString = NSAttributeDescription()
        preferredPointSystemString.name = "preferredPointSystemString"
        preferredPointSystemString.attributeType = .stringAttributeType
        preferredPointSystemString.isOptional = true
        
        let alertThreshold = NSAttributeDescription()
        alertThreshold.name = "alertThreshold"
        alertThreshold.attributeType = .doubleAttributeType
        alertThreshold.isOptional = false
        
        let languageString = NSAttributeDescription()
        languageString.name = "languageString"
        languageString.attributeType = .stringAttributeType
        languageString.isOptional = true
        
        let notificationsEnabled = NSAttributeDescription()
        notificationsEnabled.name = "notificationsEnabled"
        notificationsEnabled.attributeType = .booleanAttributeType
        notificationsEnabled.isOptional = false
        
        let autoUpdateSpending = NSAttributeDescription()
        autoUpdateSpending.name = "autoUpdateSpending"
        autoUpdateSpending.attributeType = .booleanAttributeType
        autoUpdateSpending.isOptional = false
        
        userPreferencesEntity.properties = [preferredPointSystemString, alertThreshold, languageString, notificationsEnabled, autoUpdateSpending]
        
        // Create RewardCategoryEntity
        let rewardCategoryEntity = NSEntityDescription()
        rewardCategoryEntity.name = "RewardCategoryEntity"
        rewardCategoryEntity.managedObjectClassName = "RewardCategoryEntity"
        
        let rewardId = NSAttributeDescription()
        rewardId.name = "id"
        rewardId.attributeType = .UUIDAttributeType
        rewardId.isOptional = true
        
        let rewardCategory = NSAttributeDescription()
        rewardCategory.name = "category"
        rewardCategory.attributeType = .stringAttributeType
        rewardCategory.isOptional = true
        
        let rewardMultiplier = NSAttributeDescription()
        rewardMultiplier.name = "multiplier"
        rewardMultiplier.attributeType = .doubleAttributeType
        rewardMultiplier.isOptional = false
        
        let rewardPointType = NSAttributeDescription()
        rewardPointType.name = "pointType"
        rewardPointType.attributeType = .stringAttributeType
        rewardPointType.isOptional = true
        
        let rewardIsActive = NSAttributeDescription()
        rewardIsActive.name = "isActive"
        rewardIsActive.attributeType = .booleanAttributeType
        rewardIsActive.isOptional = false
        
        rewardCategoryEntity.properties = [rewardId, rewardCategory, rewardMultiplier, rewardPointType, rewardIsActive]
        
        // Create SpendingLimitEntity
        let spendingLimitEntity = NSEntityDescription()
        spendingLimitEntity.name = "SpendingLimitEntity"
        spendingLimitEntity.managedObjectClassName = "SpendingLimitEntity"
        
        let limitId = NSAttributeDescription()
        limitId.name = "id"
        limitId.attributeType = .UUIDAttributeType
        limitId.isOptional = true
        
        let limitCategory = NSAttributeDescription()
        limitCategory.name = "category"
        limitCategory.attributeType = .stringAttributeType
        limitCategory.isOptional = true
        
        let limitAmount = NSAttributeDescription()
        limitAmount.name = "limit"
        limitAmount.attributeType = .doubleAttributeType
        limitAmount.isOptional = false
        
        let currentSpending = NSAttributeDescription()
        currentSpending.name = "currentSpending"
        currentSpending.attributeType = .doubleAttributeType
        currentSpending.isOptional = false
        
        let resetDate = NSAttributeDescription()
        resetDate.name = "resetDate"
        resetDate.attributeType = .dateAttributeType
        resetDate.isOptional = true
        
        let resetType = NSAttributeDescription()
        resetType.name = "resetType"
        resetType.attributeType = .stringAttributeType
        resetType.isOptional = true
        
        spendingLimitEntity.properties = [limitId, limitCategory, limitAmount, currentSpending, resetDate, resetType]
        
        // Create QuarterlyBonusEntity
        let quarterlyBonusEntity = NSEntityDescription()
        quarterlyBonusEntity.name = "QuarterlyBonusEntity"
        quarterlyBonusEntity.managedObjectClassName = "QuarterlyBonusEntity"
        
        let bonusCategory = NSAttributeDescription()
        bonusCategory.name = "category"
        bonusCategory.attributeType = .stringAttributeType
        bonusCategory.isOptional = true
        
        let bonusMultiplier = NSAttributeDescription()
        bonusMultiplier.name = "multiplier"
        bonusMultiplier.attributeType = .doubleAttributeType
        bonusMultiplier.isOptional = false
        
        let bonusPointType = NSAttributeDescription()
        bonusPointType.name = "pointType"
        bonusPointType.attributeType = .stringAttributeType
        bonusPointType.isOptional = true
        
        let bonusLimit = NSAttributeDescription()
        bonusLimit.name = "limit"
        bonusLimit.attributeType = .doubleAttributeType
        bonusLimit.isOptional = false
        
        let bonusCurrentSpending = NSAttributeDescription()
        bonusCurrentSpending.name = "currentSpending"
        bonusCurrentSpending.attributeType = .doubleAttributeType
        bonusCurrentSpending.isOptional = false
        
        let bonusQuarter = NSAttributeDescription()
        bonusQuarter.name = "quarter"
        bonusQuarter.attributeType = .integer16AttributeType
        bonusQuarter.isOptional = false
        
        let bonusYear = NSAttributeDescription()
        bonusYear.name = "year"
        bonusYear.attributeType = .integer16AttributeType
        bonusYear.isOptional = false
        
        quarterlyBonusEntity.properties = [bonusCategory, bonusMultiplier, bonusPointType, bonusLimit, bonusCurrentSpending, bonusQuarter, bonusYear]
        
        // Create CardRecommendationEntity
        let cardRecommendationEntity = NSEntityDescription()
        cardRecommendationEntity.name = "CardRecommendationEntity"
        cardRecommendationEntity.managedObjectClassName = "CardRecommendationEntity"
        
        let recId = NSAttributeDescription()
        recId.name = "id"
        recId.attributeType = .UUIDAttributeType
        recId.isOptional = true
        
        let recCardId = NSAttributeDescription()
        recCardId.name = "cardId"
        recCardId.attributeType = .UUIDAttributeType
        recCardId.isOptional = true
        
        let recCardName = NSAttributeDescription()
        recCardName.name = "cardName"
        recCardName.attributeType = .stringAttributeType
        recCardName.isOptional = true
        
        let recCategory = NSAttributeDescription()
        recCategory.name = "category"
        recCategory.attributeType = .stringAttributeType
        recCategory.isOptional = true
        
        let recMultiplier = NSAttributeDescription()
        recMultiplier.name = "multiplier"
        recMultiplier.attributeType = .doubleAttributeType
        recMultiplier.isOptional = false
        
        let recPointType = NSAttributeDescription()
        recPointType.name = "pointType"
        recPointType.attributeType = .stringAttributeType
        recPointType.isOptional = true
        
        let recReasoning = NSAttributeDescription()
        recReasoning.name = "reasoning"
        recReasoning.attributeType = .stringAttributeType
        recReasoning.isOptional = true
        
        let recCurrentSpending = NSAttributeDescription()
        recCurrentSpending.name = "currentSpending"
        recCurrentSpending.attributeType = .doubleAttributeType
        recCurrentSpending.isOptional = false
        
        let recLimit = NSAttributeDescription()
        recLimit.name = "limit"
        recLimit.attributeType = .doubleAttributeType
        recLimit.isOptional = false
        
        let recIsLimitReached = NSAttributeDescription()
        recIsLimitReached.name = "isLimitReached"
        recIsLimitReached.attributeType = .booleanAttributeType
        recIsLimitReached.isOptional = false
        
        let recRank = NSAttributeDescription()
        recRank.name = "rank"
        recRank.attributeType = .integer16AttributeType
        recRank.isOptional = false
        
        cardRecommendationEntity.properties = [recId, recCardId, recCardName, recCategory, recMultiplier, recPointType, recReasoning, recCurrentSpending, recLimit, recIsLimitReached, recRank]
        
        // Create SpendingUpdateEntity
        let spendingUpdateEntity = NSEntityDescription()
        spendingUpdateEntity.name = "SpendingUpdateEntity"
        spendingUpdateEntity.managedObjectClassName = "SpendingUpdateEntity"
        
        let updateId = NSAttributeDescription()
        updateId.name = "id"
        updateId.attributeType = .UUIDAttributeType
        updateId.isOptional = true
        
        let updateCategory = NSAttributeDescription()
        updateCategory.name = "category"
        updateCategory.attributeType = .stringAttributeType
        updateCategory.isOptional = true
        
        let updateAmount = NSAttributeDescription()
        updateAmount.name = "amount"
        updateAmount.attributeType = .doubleAttributeType
        updateAmount.isOptional = false
        
        let updateDate = NSAttributeDescription()
        updateDate.name = "date"
        updateDate.attributeType = .dateAttributeType
        updateDate.isOptional = true
        
        let updateDescription = NSAttributeDescription()
        updateDescription.name = "updateDescription"
        updateDescription.attributeType = .stringAttributeType
        updateDescription.isOptional = true
        
        spendingUpdateEntity.properties = [updateId, updateCategory, updateAmount, updateDate, updateDescription]
        
        // Create relationships
        
        // CreditCardEntity -> RewardCategoryEntity (one-to-many)
        let rewardCategoriesRelationship = NSRelationshipDescription()
        rewardCategoriesRelationship.name = "rewardCategories"
        rewardCategoriesRelationship.destinationEntity = rewardCategoryEntity
        rewardCategoriesRelationship.minCount = 0
        rewardCategoriesRelationship.maxCount = 0 // 0 means unlimited (to-many)
        rewardCategoriesRelationship.deleteRule = .cascadeDeleteRule
        
        // RewardCategoryEntity -> CreditCardEntity (many-to-one, inverse)
        let creditCardRelationship = NSRelationshipDescription()
        creditCardRelationship.name = "creditCard"
        creditCardRelationship.destinationEntity = creditCardEntity
        creditCardRelationship.minCount = 0
        creditCardRelationship.maxCount = 1
        creditCardRelationship.deleteRule = .nullifyDeleteRule
        
        // Set inverse relationships
        rewardCategoriesRelationship.inverseRelationship = creditCardRelationship
        creditCardRelationship.inverseRelationship = rewardCategoriesRelationship
        
        // CreditCardEntity -> SpendingLimitEntity (one-to-many)
        let spendingLimitsRelationship = NSRelationshipDescription()
        spendingLimitsRelationship.name = "spendingLimits"
        spendingLimitsRelationship.destinationEntity = spendingLimitEntity
        spendingLimitsRelationship.minCount = 0
        spendingLimitsRelationship.maxCount = 0 // 0 means unlimited (to-many)
        spendingLimitsRelationship.deleteRule = .cascadeDeleteRule
        
        // SpendingLimitEntity -> CreditCardEntity (many-to-one, inverse)
        let creditCardSpendingRelationship = NSRelationshipDescription()
        creditCardSpendingRelationship.name = "creditCard"
        creditCardSpendingRelationship.destinationEntity = creditCardEntity
        creditCardSpendingRelationship.minCount = 0
        creditCardSpendingRelationship.maxCount = 1
        creditCardSpendingRelationship.deleteRule = .nullifyDeleteRule
        
        // Set inverse relationships
        spendingLimitsRelationship.inverseRelationship = creditCardSpendingRelationship
        creditCardSpendingRelationship.inverseRelationship = spendingLimitsRelationship
        
        // CreditCardEntity -> QuarterlyBonusEntity (one-to-one)
        let quarterlyBonusRelationship = NSRelationshipDescription()
        quarterlyBonusRelationship.name = "quarterlyBonus"
        quarterlyBonusRelationship.destinationEntity = quarterlyBonusEntity
        quarterlyBonusRelationship.minCount = 0
        quarterlyBonusRelationship.maxCount = 1
        quarterlyBonusRelationship.deleteRule = .cascadeDeleteRule
        
        // QuarterlyBonusEntity -> CreditCardEntity (one-to-one, inverse)
        let creditCardBonusRelationship = NSRelationshipDescription()
        creditCardBonusRelationship.name = "creditCard"
        creditCardBonusRelationship.destinationEntity = creditCardEntity
        creditCardBonusRelationship.minCount = 0
        creditCardBonusRelationship.maxCount = 1
        creditCardBonusRelationship.deleteRule = .nullifyDeleteRule
        
        // Set inverse relationships
        quarterlyBonusRelationship.inverseRelationship = creditCardBonusRelationship
        creditCardBonusRelationship.inverseRelationship = quarterlyBonusRelationship
        
        // ChatMessageEntity -> CardRecommendationEntity (one-to-many)
        let cardRecommendationsRelationship = NSRelationshipDescription()
        cardRecommendationsRelationship.name = "cardRecommendations"
        cardRecommendationsRelationship.destinationEntity = cardRecommendationEntity
        cardRecommendationsRelationship.minCount = 0
        cardRecommendationsRelationship.maxCount = 0 // 0 means unlimited (to-many)
        cardRecommendationsRelationship.deleteRule = .cascadeDeleteRule
        
        // CardRecommendationEntity -> ChatMessageEntity (many-to-one)
        let chatMessageRecommendationRelationship = NSRelationshipDescription()
        chatMessageRecommendationRelationship.name = "chatMessage"
        chatMessageRecommendationRelationship.destinationEntity = chatMessageEntity
        chatMessageRecommendationRelationship.minCount = 0
        chatMessageRecommendationRelationship.maxCount = 1
        chatMessageRecommendationRelationship.deleteRule = .nullifyDeleteRule
        
        // ChatMessageEntity -> SpendingUpdateEntity (one-to-one)
        let spendingUpdateRelationship = NSRelationshipDescription()
        spendingUpdateRelationship.name = "spendingUpdate"
        spendingUpdateRelationship.destinationEntity = spendingUpdateEntity
        spendingUpdateRelationship.minCount = 0
        spendingUpdateRelationship.maxCount = 1
        spendingUpdateRelationship.deleteRule = .cascadeDeleteRule
        
        // SpendingUpdateEntity -> ChatMessageEntity (one-to-one)
        let chatMessageUpdateRelationship = NSRelationshipDescription()
        chatMessageUpdateRelationship.name = "chatMessage"
        chatMessageUpdateRelationship.destinationEntity = chatMessageEntity
        chatMessageUpdateRelationship.minCount = 0
        chatMessageUpdateRelationship.maxCount = 1
        chatMessageUpdateRelationship.deleteRule = .nullifyDeleteRule
        
        // Set inverse relationships for ChatMessage entities
        cardRecommendationsRelationship.inverseRelationship = chatMessageRecommendationRelationship
        chatMessageRecommendationRelationship.inverseRelationship = cardRecommendationsRelationship
        
        spendingUpdateRelationship.inverseRelationship = chatMessageUpdateRelationship
        chatMessageUpdateRelationship.inverseRelationship = spendingUpdateRelationship
        
        // Add relationships to entities
        creditCardEntity.properties.append(contentsOf: [rewardCategoriesRelationship, spendingLimitsRelationship, quarterlyBonusRelationship])
        rewardCategoryEntity.properties.append(creditCardRelationship)
        spendingLimitEntity.properties.append(creditCardSpendingRelationship)
        quarterlyBonusEntity.properties.append(creditCardBonusRelationship)
        chatMessageEntity.properties.append(contentsOf: [cardRecommendationsRelationship, spendingUpdateRelationship])
        cardRecommendationEntity.properties.append(chatMessageRecommendationRelationship)
        spendingUpdateEntity.properties.append(chatMessageUpdateRelationship)
        
        // Add entities to model
        model.entities = [creditCardEntity, chatMessageEntity, userPreferencesEntity, rewardCategoryEntity, spendingLimitEntity, quarterlyBonusEntity, cardRecommendationEntity, spendingUpdateEntity]
        
        print("✅ Core Data Stack: Created programmatic model with \(model.entities.count) entities")
        
        return model
    }
} 