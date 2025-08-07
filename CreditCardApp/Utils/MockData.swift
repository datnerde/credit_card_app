import Foundation

struct MockData {
    static let sampleCards: [CreditCard] = [
        CreditCard(
            name: "Amex Gold",
            cardType: .amexGold,
            rewardCategories: [
                RewardCategory(category: .groceries, multiplier: 4.0, pointType: .membershipRewards),
                RewardCategory(category: .dining, multiplier: 4.0, pointType: .membershipRewards),
                RewardCategory(category: .general, multiplier: 1.0, pointType: .membershipRewards)
            ],
            spendingLimits: [
                SpendingLimit(category: .groceries, limit: 25000, currentSpending: 8000),
                SpendingLimit(category: .dining, limit: 25000, currentSpending: 12000)
            ]
        ),
        CreditCard(
            name: "Chase Sapphire Reserve",
            cardType: .chaseSapphireReserve,
            rewardCategories: [
                RewardCategory(category: .travel, multiplier: 3.0, pointType: .ultimateRewards),
                RewardCategory(category: .dining, multiplier: 3.0, pointType: .ultimateRewards),
                RewardCategory(category: .general, multiplier: 1.0, pointType: .ultimateRewards)
            ],
            spendingLimits: [
                SpendingLimit(category: .travel, limit: 50000, currentSpending: 15000),
                SpendingLimit(category: .dining, limit: 30000, currentSpending: 25000)
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
                currentSpending: 1400,
                quarter: 1
            ),
            spendingLimits: [
                SpendingLimit(category: .gas, limit: 1500, currentSpending: 1400, resetType: .quarterly)
            ]
        ),
        CreditCard(
            name: "Citi Double Cash",
            cardType: .citiDoubleCash,
            rewardCategories: [
                RewardCategory(category: .general, multiplier: 2.0, pointType: .thankYouPoints)
            ]
        )
    ]
    
    static let sampleUserPreferences = UserPreferences(
        preferredPointSystem: .membershipRewards,
        alertThreshold: 0.85,
        language: .english,
        notificationsEnabled: true,
        autoUpdateSpending: false
    )
    
    static let sampleChatMessages: [ChatMessage] = [
        ChatMessage(
            content: "Welcome! I'm your credit card assistant. Ask me which card to use for your purchases.",
            sender: .assistant
        ),
        ChatMessage(
            content: "I'm buying groceries at Whole Foods",
            sender: .user
        ),
        ChatMessage(
            content: "I recommend using your Amex Gold card for groceries.",
            sender: .assistant,
            cardRecommendations: [
                CardRecommendation(
                    cardId: sampleCards[0].id,
                    cardName: "Amex Gold",
                    category: .groceries,
                    multiplier: 4.0,
                    pointType: .membershipRewards,
                    reasoning: "Amex Gold offers 4x MR points on groceries, and you have $17,000 remaining in your annual limit.",
                    currentSpending: 8000,
                    limit: 25000,
                    isLimitReached: false,
                    rank: 1
                )
            ]
        )
    ]
    
    static let sampleCardRecommendations: [CardRecommendation] = [
        CardRecommendation(
            cardId: sampleCards[0].id,
            cardName: "Amex Gold",
            category: .groceries,
            multiplier: 4.0,
            pointType: .membershipRewards,
            reasoning: "Best choice for groceries with 4x MR points",
            currentSpending: 800,
            limit: 1000,
            isLimitReached: false,
            rank: 1
        ),
        CardRecommendation(
            cardId: sampleCards[1].id,
            cardName: "Chase Sapphire Reserve",
            category: .dining,
            multiplier: 3.0,
            pointType: .ultimateRewards,
            reasoning: "Great for dining with 3x UR points",
            currentSpending: 250,
            limit: 300,
            isLimitReached: false,
            rank: 2
        )
    ]
    
    static func createTestCard(name: String = "Test Card", cardType: CardType = .custom) -> CreditCard {
        return CreditCard(
            name: name,
            cardType: cardType,
            rewardCategories: [
                RewardCategory(category: .general, multiplier: 1.0, pointType: .cashback)
            ],
            spendingLimits: [
                SpendingLimit(category: .general, limit: 5000, currentSpending: 1000)
            ]
        )
    }
    
    static func createTestMessage(content: String, sender: MessageSender) -> ChatMessage {
        return ChatMessage(content: content, sender: sender)
    }
}