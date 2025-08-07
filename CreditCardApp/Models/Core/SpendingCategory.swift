import Foundation

// MARK: - Spending Categories
enum SpendingCategory: String, Codable, CaseIterable {
    // Basic categories
    case groceries = "Groceries"
    case dining = "Dining"
    case travel = "Travel"
    case gas = "Gas"
    case online = "Online Shopping"
    case drugstores = "Drugstores"
    case streaming = "Streaming"
    case transit = "Transit"
    case office = "Office Supply"
    case phone = "Phone Services"
    case general = "General Purchases"
    
    // Merchant-specific categories
    case costco = "Costco"
    case amazon = "Amazon"
    case wholeFoods = "Whole Foods"
    case target = "Target"
    case walmart = "Walmart"
    
    // Subcategories
    case airfare = "Airfare"
    case hotels = "Hotels"
    case restaurants = "Restaurants"
    case fastFood = "Fast Food"
    case coffee = "Coffee Shops"
    
    var displayName: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .groceries: return "cart.fill"
        case .dining: return "fork.knife"
        case .travel: return "airplane"
        case .gas: return "fuelpump.fill"
        case .online: return "globe"
        case .drugstores: return "cross.fill"
        case .streaming: return "play.tv.fill"
        case .transit: return "bus.fill"
        case .office: return "briefcase.fill"
        case .phone: return "phone.fill"
        case .general: return "creditcard.fill"
        case .costco: return "building.2.fill"
        case .amazon: return "cart.badge.plus"
        case .wholeFoods: return "leaf.fill"
        case .target: return "target"
        case .walmart: return "building.fill"
        case .airfare: return "airplane.departure"
        case .hotels: return "bed.double.fill"
        case .restaurants: return "house.fill"
        case .fastFood: return "takeoutbag.and.cup.and.straw.fill"
        case .coffee: return "cup.and.saucer.fill"
        }
    }
}

// MARK: - Point Types
enum PointType: String, Codable, CaseIterable {
    case membershipRewards = "MR"
    case ultimateRewards = "UR"
    case thankYouPoints = "TYP"
    case cashBack = "Cash Back"
    case capitalOneMiles = "Capital One Miles"
    case discoverCashback = "Discover Cash Back"
    
    var displayName: String {
        switch self {
        case .membershipRewards: return "Membership Rewards (MR)"
        case .ultimateRewards: return "Ultimate Rewards (UR)"
        case .thankYouPoints: return "ThankYou Points (TYP)"
        case .cashBack: return "Cash Back"
        case .capitalOneMiles: return "Capital One Miles"
        case .discoverCashback: return "Discover Cash Back"
        }
    }
    
    var color: String {
        switch self {
        case .membershipRewards: return "gold"
        case .ultimateRewards: return "blue"
        case .thankYouPoints: return "purple"
        case .cashBack: return "green"
        case .capitalOneMiles: return "orange"
        case .discoverCashback: return "red"
        }
    }
}

// MARK: - Reset Types
enum ResetType: String, Codable, CaseIterable {
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case annually = "Annually"
    case never = "Never"
    
    var displayName: String {
        return rawValue
    }
}

// MARK: - Card Types
enum CardType: String, Codable, CaseIterable {
    case amexGold = "Amex Gold"
    case amexPlatinum = "Amex Platinum"
    case chaseFreedom = "Chase Freedom"
    case chaseSapphirePreferred = "Chase Sapphire Preferred"
    case chaseSapphireReserve = "Chase Sapphire Reserve"
    case citiDoubleCash = "Citi Double Cash"
    case custom = "Custom"
    
    var displayName: String {
        return rawValue
    }
    
    var defaultRewards: [RewardCategory] {
        switch self {
        case .amexGold:
            return [
                RewardCategory(category: .groceries, multiplier: 4.0, pointType: .membershipRewards),
                RewardCategory(category: .dining, multiplier: 4.0, pointType: .membershipRewards),
                RewardCategory(category: .travel, multiplier: 3.0, pointType: .membershipRewards),
                RewardCategory(category: .general, multiplier: 1.0, pointType: .membershipRewards)
            ]
        case .amexPlatinum:
            return [
                RewardCategory(category: .travel, multiplier: 5.0, pointType: .membershipRewards),
                RewardCategory(category: .dining, multiplier: 1.0, pointType: .membershipRewards),
                RewardCategory(category: .general, multiplier: 1.0, pointType: .membershipRewards)
            ]
        case .chaseFreedom:
            return [
                RewardCategory(category: .general, multiplier: 1.0, pointType: .ultimateRewards)
            ]
        case .chaseSapphirePreferred:
            return [
                RewardCategory(category: .travel, multiplier: 2.0, pointType: .ultimateRewards),
                RewardCategory(category: .dining, multiplier: 3.0, pointType: .ultimateRewards),
                RewardCategory(category: .general, multiplier: 1.0, pointType: .ultimateRewards)
            ]
        case .chaseSapphireReserve:
            return [
                RewardCategory(category: .travel, multiplier: 3.0, pointType: .ultimateRewards),
                RewardCategory(category: .dining, multiplier: 3.0, pointType: .ultimateRewards),
                RewardCategory(category: .general, multiplier: 1.0, pointType: .ultimateRewards)
            ]
        case .citiDoubleCash:
            return [
                RewardCategory(category: .general, multiplier: 2.0, pointType: .thankYouPoints)
            ]
        case .custom:
            return []
        }
    }
}

// MARK: - Language
enum Language: String, Codable, CaseIterable {
    case english = "English"
    case chinese = "Chinese"
    case bilingual = "Bilingual"
    
    var displayName: String {
        return rawValue
    }
} 
