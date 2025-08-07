import Foundation

struct PreviewData {
    static let mockServiceContainer: ServiceContainer = {
        let container = ServiceContainer.shared
        // Initialize with mock services for previews
        return container
    }()
    
    static let sampleCard = CreditCard(
        name: "Amex Gold",
        cardType: .amexGold,
        rewardCategories: [
            RewardCategory(category: .groceries, multiplier: 4.0, pointType: .membershipRewards),
            RewardCategory(category: .dining, multiplier: 4.0, pointType: .membershipRewards)
        ],
        spendingLimits: [
            SpendingLimit(category: .groceries, limit: 25000, currentSpending: 8000),
            SpendingLimit(category: .dining, limit: 25000, currentSpending: 12000)
        ]
    )
    
    static let sampleCards = [
        sampleCard,
        CreditCard(
            name: "Chase Sapphire Reserve",
            cardType: .chaseSapphireReserve,
            rewardCategories: [
                RewardCategory(category: .travel, multiplier: 3.0, pointType: .ultimateRewards),
                RewardCategory(category: .dining, multiplier: 3.0, pointType: .ultimateRewards)
            ]
        )
    ]
    
    static let sampleMessage = ChatMessage(
        content: "I recommend using your Amex Gold card for groceries.",
        sender: .assistant,
        cardRecommendations: [
            CardRecommendation(
                cardId: sampleCard.id,
                cardName: "Amex Gold",
                category: .groceries,
                multiplier: 4.0,
                pointType: .membershipRewards,
                reasoning: "Best choice for groceries with 4x MR points",
                currentSpending: 8000,
                limit: 25000,
                rank: 1
            )
        ]
    )
    
    static let sampleMessages = [
        ChatMessage(content: "Hello! I'm your credit card assistant.", sender: .assistant),
        ChatMessage(content: "What card should I use for groceries?", sender: .user),
        sampleMessage
    ]
}

// MARK: - Mock ViewModels for Previews

extension ChatViewModel {
    static func mock() -> ChatViewModel {
        let viewModel = ChatViewModel(
            dataManager: MockDataManager(),
            recommendationEngine: RecommendationEngine(),
            nlpProcessor: NLPProcessor(),
            analyticsService: AnalyticsService()
        )
        viewModel.messages = PreviewData.sampleMessages
        return viewModel
    }
}

extension CardListViewModel {
    static func mock() -> CardListViewModel {
        let viewModel = CardListViewModel(
            dataManager: MockDataManager(),
            analyticsService: AnalyticsService()
        )
        viewModel.cards = PreviewData.sampleCards
        return viewModel
    }
}

extension AddCardViewModel {
    static func mock() -> AddCardViewModel {
        return AddCardViewModel(
            dataManager: MockDataManager(),
            analyticsService: AnalyticsService()
        )
    }
}

extension SettingsViewModel {
    static func mock() -> SettingsViewModel {
        let viewModel = SettingsViewModel(
            dataManager: MockDataManager(),
            notificationService: NotificationService(),
            analyticsService: AnalyticsService()
        )
        return viewModel
    }
}