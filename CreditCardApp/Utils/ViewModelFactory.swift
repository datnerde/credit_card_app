import Foundation

class ViewModelFactory {
    private static let serviceContainer = AppServiceContainer.shared
    
    static func makeChatViewModel() -> ChatViewModel {
        return ChatViewModel(
            dataManager: serviceContainer.dataManager,
            recommendationEngine: serviceContainer.recommendationEngine,
            nlpProcessor: serviceContainer.nlpProcessor,
            analyticsService: serviceContainer.analyticsService
        )
    }
    
    static func makeCardListViewModel() -> CardListViewModel {
        return CardListViewModel(
            dataManager: serviceContainer.dataManager,
            analyticsService: serviceContainer.analyticsService
        )
    }
    
    static func makeAddCardViewModel() -> AddCardViewModel {
        return AddCardViewModel(
            dataManager: serviceContainer.dataManager,
            analyticsService: serviceContainer.analyticsService
        )
    }
    
    static func makeSettingsViewModel() -> SettingsViewModel {
        return SettingsViewModel(
            dataManager: serviceContainer.dataManager,
            notificationService: serviceContainer.notificationService,
            analyticsService: serviceContainer.analyticsService
        )
    }
}