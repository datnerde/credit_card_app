import Foundation
import Combine

class SettingsViewModel: BaseViewModelImpl {
    @Published var userPreferences: UserPreferences = UserPreferences()
    @Published var showingResetAlert = false
    @Published var showingExportSheet = false
    @Published var exportData: String = ""
    
    private let dataManager: DataManager
    private var cancellables = Set<AnyCancellable>()
    
    init(dataManager: DataManager, notificationService: NotificationService, analyticsService: AnalyticsService) {
        self.dataManager = dataManager
        super.init(analyticsService: analyticsService)
        
        setupBindings()
        loadUserPreferences()
    }
    
    // MARK: - Public Methods
    
    func loadUserPreferences() {
        Task {
            do {
                let preferences = try await dataManager.loadUserPreferences()
                await MainActor.run {
                    self.userPreferences = preferences
                }
            } catch {
                await MainActor.run {
                    handleError(error)
                }
            }
        }
    }
    
    func saveUserPreferences() {
        Task {
            do {
                try await dataManager.saveUserPreferences(userPreferences)
                
                // Track settings change
                trackEvent("settings_saved", properties: [
                    "preferred_point_system": userPreferences.preferredPointSystem.rawValue,
                    "alert_threshold": userPreferences.alertThreshold,
                    "language": userPreferences.language.rawValue,
                    "notifications_enabled": userPreferences.notificationsEnabled,
                    "auto_update_spending": userPreferences.autoUpdateSpending
                ])
                
            } catch {
                await MainActor.run {
                    handleError(error)
                }
            }
        }
    }
    
    func updatePreferredPointSystem(_ pointSystem: PointType) {
        let oldValue = userPreferences.preferredPointSystem
        userPreferences.preferredPointSystem = pointSystem
        saveUserPreferences()
        
        // Track preference change
        trackEvent("preference_changed", properties: [
            "setting": "preferred_point_system",
            "old_value": oldValue.rawValue,
            "new_value": pointSystem.rawValue
        ])
    }
    
    func updateAlertThreshold(_ threshold: Double) {
        let oldValue = userPreferences.alertThreshold
        userPreferences.alertThreshold = threshold
        saveUserPreferences()
        
        // Track preference change
        trackEvent("preference_changed", properties: [
            "setting": "alert_threshold",
            "old_value": oldValue,
            "new_value": threshold
        ])
    }
    
    func updateLanguage(_ language: Language) {
        let oldValue = userPreferences.language
        userPreferences.language = language
        saveUserPreferences()
        
        // Track preference change
        trackEvent("preference_changed", properties: [
            "setting": "language",
            "old_value": oldValue.rawValue,
            "new_value": language.rawValue
        ])
    }
    
    func toggleNotifications() {
        let oldValue = userPreferences.notificationsEnabled
        userPreferences.notificationsEnabled.toggle()
        saveUserPreferences()
        
        // Track preference change
        trackEvent("preference_changed", properties: [
            "setting": "notifications_enabled",
            "old_value": oldValue,
            "new_value": userPreferences.notificationsEnabled
        ])
        
        // Request notification permission if enabled
        if userPreferences.notificationsEnabled {
            print("Requesting notification permission")
        }
    }
    
    func toggleAutoUpdateSpending() {
        let oldValue = userPreferences.autoUpdateSpending
        userPreferences.autoUpdateSpending.toggle()
        saveUserPreferences()
        
        // Track preference change
        trackEvent("preference_changed", properties: [
            "setting": "auto_update_spending",
            "old_value": oldValue,
            "new_value": userPreferences.autoUpdateSpending
        ])
    }
    
    func resetAllData() {
        Task {
            do {
                // Clear all data
                try await dataManager.clearChatHistory()
                
                // Reset preferences to defaults
                userPreferences = UserPreferences()
                try await dataManager.saveUserPreferences(userPreferences)
                
                await MainActor.run {
                    self.showingResetAlert = false
                }
                
                // Track data reset
                trackEvent("data_reset", properties: [:])
                
            } catch {
                await MainActor.run {
                    handleError(error)
                }
            }
        }
    }
    
    func exportAllData() {
        Task {
            do {
                let cards = try await dataManager.fetchCards()
                let messages = try await dataManager.fetchChatMessages()
                let preferences = try await dataManager.loadUserPreferences()
                
                let exportData = ExportData(
                    cards: cards,
                    messages: messages,
                    preferences: preferences,
                    exportDate: Date()
                )
                
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let data = try encoder.encode(exportData)
                
                await MainActor.run {
                    self.exportData = String(data: data, encoding: .utf8) ?? "Export failed"
                    self.showingExportSheet = true
                }
                
                // Track data export
                trackEvent("data_exported", properties: [
                    "cards_count": cards.count,
                    "messages_count": messages.count
                ])
                
            } catch {
                await MainActor.run {
                    handleError(error)
                }
            }
        }
    }
    
    func importData(_ jsonString: String) {
        let decoder = JSONDecoder()
        
        do {
            let data = jsonString.data(using: .utf8) ?? Data()
            let importedData = try decoder.decode(ExportData.self, from: data)
            
            Task {
                do {
                    // Import cards
                    for card in importedData.cards {
                        try await dataManager.saveCard(card)
                    }
                    
                    // Import messages
                    for message in importedData.messages {
                        try await dataManager.saveChatMessage(message)
                    }
                    
                    // Import preferences
                    try await dataManager.saveUserPreferences(importedData.preferences)
                    
                    // Update local preferences
                    await MainActor.run {
                        self.userPreferences = importedData.preferences
                    }
                    
                    // Track data import
                    trackEvent("data_imported", properties: [
                        "cards_count": importedData.cards.count,
                        "messages_count": importedData.messages.count
                    ])
                    
                } catch {
                    await MainActor.run {
                        handleError(error)
                    }
                }
            }
            
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - App Information
    
    func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    func getBuildNumber() -> String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    func getAppName() -> String {
        return Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Credit Card App"
    }
    
    // MARK: - Analytics
    
    func clearAnalyticsData() {
        trackEvent("analytics_cleared", properties: [:])
    }
    
    func exportAnalyticsData() -> String {
        return "Analytics data export not implemented in mock version"
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Auto-save preferences when they change
        $userPreferences
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] preferences in
                self?.saveUserPreferences()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Validation
    
    func validateAlertThreshold(_ threshold: Double) -> Bool {
        return threshold >= 0.5 && threshold <= 1.0
    }
    
    func getAlertThresholdRange() -> ClosedRange<Double> {
        return 0.5...1.0
    }
    
    func getAlertThresholdStep() -> Double {
        return 0.05
    }
    
    // MARK: - Localization
    
    func getSupportedLanguages() -> [Language] {
        return Language.allCases
    }
    
    func getLanguageDisplayName(_ language: Language) -> String {
        switch language {
        case .english:
            return "English"
        case .chinese:
            return "中文"
        case .bilingual:
            return "Bilingual / 双语"
        }
    }
    
    // MARK: - Point System Information
    
    func getPointSystemDescription(_ pointSystem: PointType) -> String {
        switch pointSystem {
        case .membershipRewards:
            return "American Express Membership Rewards points"
        case .ultimateRewards:
            return "Chase Ultimate Rewards points"
        case .thankYouPoints:
            return "Citi ThankYou Points"
        case .cashBack:
            return "Cash back rewards"
        case .capitalOneMiles:
            return "Capital One miles"
        case .discoverCashback:
            return "Discover cash back"
        }
    }
    
    func getPointSystemValue(_ pointSystem: PointType) -> String {
        switch pointSystem {
        case .membershipRewards:
            return "1.5-2.0 cents per point"
        case .ultimateRewards:
            return "1.5-2.0 cents per point"
        case .thankYouPoints:
            return "1.0-1.6 cents per point"
        case .cashBack:
            return "1.0 cent per dollar"
        case .capitalOneMiles:
            return "1.0-1.4 cents per mile"
        case .discoverCashback:
            return "1.0 cent per dollar"
        }
    }
}

// MARK: - Supporting Types

struct ExportData: Codable {
    let cards: [CreditCard]
    let messages: [ChatMessage]
    let preferences: UserPreferences
    let exportDate: Date
    let version: String
    
    init(cards: [CreditCard], messages: [ChatMessage], preferences: UserPreferences, exportDate: Date) {
        self.cards = cards
        self.messages = messages
        self.preferences = preferences
        self.exportDate = exportDate
        self.version = "1.0"
    }
}

// MARK: - SettingsViewModel Extensions

extension SettingsViewModel {
    func getDefaultPreferences() -> UserPreferences {
        return UserPreferences()
    }
    
    func resetToDefaults() {
        userPreferences = getDefaultPreferences()
        saveUserPreferences()
        
        trackEvent("preferences_reset_to_defaults", properties: [:])
    }
    
    func getStorageUsage() -> StorageUsage {
        // This would typically calculate actual storage usage
        // For now, return placeholder data
        return StorageUsage(
            totalSize: "2.5 MB",
            cardsSize: "1.2 MB",
            messagesSize: "0.8 MB",
            preferencesSize: "0.1 MB",
            analyticsSize: "0.4 MB"
        )
    }
}

struct StorageUsage {
    let totalSize: String
    let cardsSize: String
    let messagesSize: String
    let preferencesSize: String
    let analyticsSize: String
} 