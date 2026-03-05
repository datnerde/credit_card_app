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
    case entertainment = "Entertainment"
    case rent = "Rent"

    // Merchant-specific categories
    case costco = "Costco"
    case amazon = "Amazon"
    case wholeFoods = "Whole Foods"
    case target = "Target"
    case walmart = "Walmart"
    case paypal = "PayPal/Venmo"

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
        case .entertainment: return "theatermasks.fill"
        case .rent: return "house.fill"
        case .costco: return "building.2.fill"
        case .amazon: return "cart.badge.plus"
        case .wholeFoods: return "leaf.fill"
        case .target: return "target"
        case .walmart: return "building.fill"
        case .paypal: return "dollarsign.circle.fill"
        case .airfare: return "airplane.departure"
        case .hotels: return "bed.double.fill"
        case .restaurants: return "fork.knife.circle.fill"
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
    case biltRewards = "Bilt Rewards"
    case ventureXMiles = "Venture X Miles"

    var displayName: String {
        switch self {
        case .membershipRewards: return "Membership Rewards (MR)"
        case .ultimateRewards: return "Ultimate Rewards (UR)"
        case .thankYouPoints: return "ThankYou Points (TYP)"
        case .cashBack: return "Cash Back"
        case .capitalOneMiles: return "Capital One Miles"
        case .discoverCashback: return "Discover Cash Back"
        case .biltRewards: return "Bilt Rewards"
        case .ventureXMiles: return "Venture X Miles"
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
        case .biltRewards: return "teal"
        case .ventureXMiles: return "orange"
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
    // Amex
    case amexGold = "Amex Gold"
    case amexPlatinum = "Amex Platinum"
    case amexBlueCashPreferred = "Amex Blue Cash Preferred"

    // Chase
    case chaseFreedom = "Chase Freedom"
    case chaseFreedomFlex = "Chase Freedom Flex"
    case chaseFreedomUnlimited = "Chase Freedom Unlimited"
    case chaseSapphirePreferred = "Chase Sapphire Preferred"
    case chaseSapphireReserve = "Chase Sapphire Reserve"

    // Citi
    case citiDoubleCash = "Citi Double Cash"

    // Capital One
    case capitalOneSavorOne = "Capital One SavorOne"
    case capitalOneVentureX = "Capital One Venture X"

    // Discover
    case discoverIt = "Discover It"

    // Fintech / Outlier cards
    case robinhoodGold = "Robinhood Gold Card"
    case paypalCashback = "PayPal Cashback Mastercard"
    case biltMastercard = "Bilt Mastercard"
    case wellsFargoActiveCash = "Wells Fargo Active Cash"

    // Custom
    case custom = "Custom"

    var displayName: String {
        return rawValue
    }

    var defaultRewards: [RewardCategory] {
        switch self {

        // ── Amex Gold ──
        // 4x US restaurants, 4x US supermarkets (up to $25k/yr), 3x flights booked directly, 1x everything
        case .amexGold:
            return [
                RewardCategory(category: .groceries, multiplier: 4.0, pointType: .membershipRewards),
                RewardCategory(category: .dining, multiplier: 4.0, pointType: .membershipRewards),
                RewardCategory(category: .restaurants, multiplier: 4.0, pointType: .membershipRewards),
                RewardCategory(category: .airfare, multiplier: 3.0, pointType: .membershipRewards),
                RewardCategory(category: .travel, multiplier: 3.0, pointType: .membershipRewards),
                RewardCategory(category: .general, multiplier: 1.0, pointType: .membershipRewards)
            ]

        // ── Amex Platinum ──
        // 5x flights booked directly or via Amex Travel, 5x prepaid hotels via Amex Travel, 1x everything
        case .amexPlatinum:
            return [
                RewardCategory(category: .airfare, multiplier: 5.0, pointType: .membershipRewards),
                RewardCategory(category: .hotels, multiplier: 5.0, pointType: .membershipRewards),
                RewardCategory(category: .travel, multiplier: 5.0, pointType: .membershipRewards),
                RewardCategory(category: .general, multiplier: 1.0, pointType: .membershipRewards)
            ]

        // ── Amex Blue Cash Preferred ──
        // 6% US supermarkets (up to $6k/yr), 6% select US streaming, 3% US gas, 3% transit, 1% everything
        case .amexBlueCashPreferred:
            return [
                RewardCategory(category: .groceries, multiplier: 6.0, pointType: .cashBack),
                RewardCategory(category: .streaming, multiplier: 6.0, pointType: .cashBack),
                RewardCategory(category: .gas, multiplier: 3.0, pointType: .cashBack),
                RewardCategory(category: .transit, multiplier: 3.0, pointType: .cashBack),
                RewardCategory(category: .general, multiplier: 1.0, pointType: .cashBack)
            ]

        // ── Chase Freedom (legacy, 1.5% flat) ──
        case .chaseFreedom:
            return [
                RewardCategory(category: .general, multiplier: 1.5, pointType: .ultimateRewards)
            ]

        // ── Chase Freedom Flex ──
        // 5% quarterly rotating (set via QuarterlyBonus), 5% travel via Chase portal, 3% dining, 3% drugstores, 1% everything
        case .chaseFreedomFlex:
            return [
                RewardCategory(category: .dining, multiplier: 3.0, pointType: .ultimateRewards),
                RewardCategory(category: .restaurants, multiplier: 3.0, pointType: .ultimateRewards),
                RewardCategory(category: .drugstores, multiplier: 3.0, pointType: .ultimateRewards),
                RewardCategory(category: .general, multiplier: 1.0, pointType: .ultimateRewards)
            ]

        // ── Chase Freedom Unlimited ──
        // 5% travel via Chase portal, 3% dining, 3% drugstores, 1.5% everything
        case .chaseFreedomUnlimited:
            return [
                RewardCategory(category: .dining, multiplier: 3.0, pointType: .ultimateRewards),
                RewardCategory(category: .restaurants, multiplier: 3.0, pointType: .ultimateRewards),
                RewardCategory(category: .drugstores, multiplier: 3.0, pointType: .ultimateRewards),
                RewardCategory(category: .general, multiplier: 1.5, pointType: .ultimateRewards)
            ]

        // ── Chase Sapphire Preferred ──
        // 5x travel via Chase portal, 3x dining, 3x streaming, 2x other travel, 1x everything
        case .chaseSapphirePreferred:
            return [
                RewardCategory(category: .dining, multiplier: 3.0, pointType: .ultimateRewards),
                RewardCategory(category: .restaurants, multiplier: 3.0, pointType: .ultimateRewards),
                RewardCategory(category: .streaming, multiplier: 3.0, pointType: .ultimateRewards),
                RewardCategory(category: .online, multiplier: 3.0, pointType: .ultimateRewards),
                RewardCategory(category: .travel, multiplier: 2.0, pointType: .ultimateRewards),
                RewardCategory(category: .general, multiplier: 1.0, pointType: .ultimateRewards)
            ]

        // ── Chase Sapphire Reserve ──
        // 10x hotels/car via Chase portal, 5x flights via portal, 3x dining, 3x travel, 1x everything
        case .chaseSapphireReserve:
            return [
                RewardCategory(category: .hotels, multiplier: 10.0, pointType: .ultimateRewards),
                RewardCategory(category: .airfare, multiplier: 5.0, pointType: .ultimateRewards),
                RewardCategory(category: .dining, multiplier: 3.0, pointType: .ultimateRewards),
                RewardCategory(category: .restaurants, multiplier: 3.0, pointType: .ultimateRewards),
                RewardCategory(category: .travel, multiplier: 3.0, pointType: .ultimateRewards),
                RewardCategory(category: .general, multiplier: 1.0, pointType: .ultimateRewards)
            ]

        // ── Citi Double Cash ──
        // 2% on everything (1% when you buy + 1% when you pay)
        case .citiDoubleCash:
            return [
                RewardCategory(category: .general, multiplier: 2.0, pointType: .thankYouPoints)
            ]

        // ── Capital One SavorOne ──
        // 3% dining, 3% entertainment, 3% groceries, 3% streaming, 5% hotels/car via Capital One Travel, 1% everything
        case .capitalOneSavorOne:
            return [
                RewardCategory(category: .dining, multiplier: 3.0, pointType: .cashBack),
                RewardCategory(category: .restaurants, multiplier: 3.0, pointType: .cashBack),
                RewardCategory(category: .entertainment, multiplier: 3.0, pointType: .cashBack),
                RewardCategory(category: .groceries, multiplier: 3.0, pointType: .cashBack),
                RewardCategory(category: .streaming, multiplier: 3.0, pointType: .cashBack),
                RewardCategory(category: .hotels, multiplier: 5.0, pointType: .cashBack),
                RewardCategory(category: .general, multiplier: 1.0, pointType: .cashBack)
            ]

        // ── Capital One Venture X ──
        // 10x hotels/car via Capital One Travel, 5x flights via portal, 2x everything
        case .capitalOneVentureX:
            return [
                RewardCategory(category: .hotels, multiplier: 10.0, pointType: .ventureXMiles),
                RewardCategory(category: .airfare, multiplier: 5.0, pointType: .ventureXMiles),
                RewardCategory(category: .travel, multiplier: 5.0, pointType: .ventureXMiles),
                RewardCategory(category: .general, multiplier: 2.0, pointType: .ventureXMiles)
            ]

        // ── Discover It ──
        // 5% quarterly rotating categories (set via QuarterlyBonus), 1% everything else
        case .discoverIt:
            return [
                RewardCategory(category: .general, multiplier: 1.0, pointType: .discoverCashback)
            ]

        // ── Robinhood Gold Card ──
        // 3% cashback on everything (with Robinhood Gold subscription $5/mo)
        case .robinhoodGold:
            return [
                RewardCategory(category: .general, multiplier: 3.0, pointType: .cashBack),
                RewardCategory(category: .dining, multiplier: 3.0, pointType: .cashBack),
                RewardCategory(category: .groceries, multiplier: 3.0, pointType: .cashBack),
                RewardCategory(category: .travel, multiplier: 3.0, pointType: .cashBack),
                RewardCategory(category: .gas, multiplier: 3.0, pointType: .cashBack),
                RewardCategory(category: .online, multiplier: 3.0, pointType: .cashBack)
            ]

        // ── PayPal Cashback Mastercard ──
        // 3% cashback on PayPal purchases, 2% everywhere else
        case .paypalCashback:
            return [
                RewardCategory(category: .paypal, multiplier: 3.0, pointType: .cashBack),
                RewardCategory(category: .online, multiplier: 3.0, pointType: .cashBack),
                RewardCategory(category: .general, multiplier: 2.0, pointType: .cashBack)
            ]

        // ── Bilt Mastercard ──
        // 3x dining, 2x travel, 1x rent (no fee!), 1x everything else
        case .biltMastercard:
            return [
                RewardCategory(category: .dining, multiplier: 3.0, pointType: .biltRewards),
                RewardCategory(category: .restaurants, multiplier: 3.0, pointType: .biltRewards),
                RewardCategory(category: .travel, multiplier: 2.0, pointType: .biltRewards),
                RewardCategory(category: .airfare, multiplier: 2.0, pointType: .biltRewards),
                RewardCategory(category: .hotels, multiplier: 2.0, pointType: .biltRewards),
                RewardCategory(category: .rent, multiplier: 1.0, pointType: .biltRewards),
                RewardCategory(category: .general, multiplier: 1.0, pointType: .biltRewards)
            ]

        // ── Wells Fargo Active Cash ──
        // 2% cashback on everything
        case .wellsFargoActiveCash:
            return [
                RewardCategory(category: .general, multiplier: 2.0, pointType: .cashBack)
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
