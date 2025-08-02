import Foundation
import CoreData

// MARK: - Credit Card Model
struct CreditCard: Codable, Identifiable {
    let id: UUID
    var name: String
    var cardType: CardType
    var rewardCategories: [RewardCategory]
    var quarterlyBonus: QuarterlyBonus?
    var spendingLimits: [SpendingLimit]
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), 
         name: String, 
         cardType: CardType, 
         rewardCategories: [RewardCategory] = [], 
         quarterlyBonus: QuarterlyBonus? = nil, 
         spendingLimits: [SpendingLimit] = [], 
         isActive: Bool = true) {
        self.id = id
        self.name = name
        self.cardType = cardType
        self.rewardCategories = rewardCategories.isEmpty ? cardType.defaultRewards : rewardCategories
        self.quarterlyBonus = quarterlyBonus
        self.spendingLimits = spendingLimits
        self.isActive = isActive
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Reward Category
struct RewardCategory: Codable, Identifiable {
    let id: UUID
    var category: SpendingCategory
    var multiplier: Double
    var pointType: PointType
    var isActive: Bool
    
    init(id: UUID = UUID(), 
         category: SpendingCategory, 
         multiplier: Double, 
         pointType: PointType, 
         isActive: Bool = true) {
        self.id = id
        self.category = category
        self.multiplier = multiplier
        self.pointType = pointType
        self.isActive = isActive
    }
}

// MARK: - Quarterly Bonus
struct QuarterlyBonus: Codable {
    var category: SpendingCategory
    var multiplier: Double
    var pointType: PointType
    var limit: Double
    var currentSpending: Double
    var quarter: Int // 1-4
    var year: Int
    
    init(category: SpendingCategory, 
         multiplier: Double, 
         pointType: PointType, 
         limit: Double, 
         currentSpending: Double = 0.0, 
         quarter: Int = Calendar.current.component(.quarter, from: Date()), 
         year: Int = Calendar.current.component(.year, from: Date())) {
        self.category = category
        self.multiplier = multiplier
        self.pointType = pointType
        self.limit = limit
        self.currentSpending = currentSpending
        self.quarter = quarter
        self.year = year
    }
}

// MARK: - Spending Limit
struct SpendingLimit: Codable, Identifiable {
    let id: UUID
    var category: SpendingCategory
    var limit: Double
    var currentSpending: Double
    var resetDate: Date
    var resetType: ResetType
    
    init(id: UUID = UUID(), 
         category: SpendingCategory, 
         limit: Double, 
         currentSpending: Double = 0.0, 
         resetDate: Date = Date(), 
         resetType: ResetType = .annually) {
        self.id = id
        self.category = category
        self.limit = limit
        self.currentSpending = currentSpending
        self.resetDate = resetDate
        self.resetType = resetType
    }
    
    var usagePercentage: Double {
        guard limit > 0 else { return 0.0 }
        return currentSpending / limit
    }
    
    var remainingAmount: Double {
        return max(0, limit - currentSpending)
    }
    
    var isLimitReached: Bool {
        return currentSpending >= limit
    }
    
    var isWarningThreshold: Bool {
        return usagePercentage >= 0.85
    }
}

// MARK: - User Preferences
struct UserPreferences: Codable {
    var preferredPointSystem: PointType
    var alertThreshold: Double // Percentage (0.85 = 85%)
    var language: Language
    var notificationsEnabled: Bool
    var autoUpdateSpending: Bool
    
    init(preferredPointSystem: PointType = .membershipRewards,
         alertThreshold: Double = 0.85,
         language: Language = .english,
         notificationsEnabled: Bool = true,
         autoUpdateSpending: Bool = false) {
        self.preferredPointSystem = preferredPointSystem
        self.alertThreshold = alertThreshold
        self.language = language
        self.notificationsEnabled = notificationsEnabled
        self.autoUpdateSpending = autoUpdateSpending
    }
}

// MARK: - Chat Message
struct ChatMessage: Codable, Identifiable {
    let id: UUID
    var content: String
    var sender: MessageSender
    var timestamp: Date
    var cardRecommendations: [CardRecommendation]?
    var spendingUpdate: SpendingUpdate?
    
    init(id: UUID = UUID(),
         content: String,
         sender: MessageSender,
         timestamp: Date = Date(),
         cardRecommendations: [CardRecommendation]? = nil,
         spendingUpdate: SpendingUpdate? = nil) {
        self.id = id
        self.content = content
        self.sender = sender
        self.timestamp = timestamp
        self.cardRecommendations = cardRecommendations
        self.spendingUpdate = spendingUpdate
    }
}

enum MessageSender: String, Codable {
    case user = "User"
    case assistant = "Assistant"
}

// MARK: - Card Recommendation
struct CardRecommendation: Codable, Identifiable {
    let id: UUID
    var cardId: UUID
    var cardName: String
    var category: SpendingCategory
    var multiplier: Double
    var pointType: PointType
    var reasoning: String
    var currentSpending: Double
    var limit: Double
    var isLimitReached: Bool
    var rank: Int // 1 for primary, 2 for secondary
    
    init(id: UUID = UUID(),
         cardId: UUID,
         cardName: String,
         category: SpendingCategory,
         multiplier: Double,
         pointType: PointType,
         reasoning: String,
         currentSpending: Double = 0.0,
         limit: Double = 0.0,
         isLimitReached: Bool = false,
         rank: Int = 1) {
        self.id = id
        self.cardId = cardId
        self.cardName = cardName
        self.category = category
        self.multiplier = multiplier
        self.pointType = pointType
        self.reasoning = reasoning
        self.currentSpending = currentSpending
        self.limit = limit
        self.isLimitReached = isLimitReached
        self.rank = rank
    }
}

// MARK: - Spending Update
struct SpendingUpdate: Codable {
    var cardId: UUID
    var category: SpendingCategory
    var amount: Double
    var previousAmount: Double
    
    init(cardId: UUID, category: SpendingCategory, amount: Double, previousAmount: Double) {
        self.cardId = cardId
        self.category = category
        self.amount = amount
        self.previousAmount = previousAmount
    }
}

// MARK: - Merchant
struct Merchant: Codable, Identifiable {
    let id: UUID
    var name: String
    var category: SpendingCategory
    var aliases: [String] // Alternative names
    var isActive: Bool
    
    init(id: UUID = UUID(), name: String, category: SpendingCategory, aliases: [String] = [], isActive: Bool = true) {
        self.id = id
        self.name = name
        self.category = category
        self.aliases = aliases
        self.isActive = isActive
    }
}

// MARK: - Pre-defined Merchant Mappings
let merchantMappings: [String: SpendingCategory] = [
    "costco": .costco,
    "whole foods": .wholeFoods,
    "wholefoods": .wholeFoods,
    "amazon": .amazon,
    "target": .target,
    "walmart": .walmart,
    "starbucks": .coffee,
    "mcdonalds": .fastFood,
    "mcdonald's": .fastFood,
    "uber": .transit,
    "lyft": .transit,
    "netflix": .streaming,
    "spotify": .streaming,
    "cvs": .drugstores,
    "walgreens": .drugstores,
    "shell": .gas,
    "exxon": .gas,
    "chevron": .gas,
    "bp": .gas,
    "mobil": .gas
] 