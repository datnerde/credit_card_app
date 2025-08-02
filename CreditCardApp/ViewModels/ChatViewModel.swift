import Foundation
import Combine

class ChatViewModel: BaseViewModelImpl {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isTyping: Bool = false
    @Published var userCards: [CreditCard] = []
    @Published var userPreferences: UserPreferences = UserPreferences()
    
    private let recommendationEngine: RecommendationEngine
    private let dataManager: DataManager
    private let nlpProcessor: NLPProcessor
    private var cancellables = Set<AnyCancellable>()
    
    init(recommendationEngine: RecommendationEngine, 
         dataManager: DataManager, 
         nlpProcessor: NLPProcessor) {
        self.recommendationEngine = recommendationEngine
        self.dataManager = dataManager
        self.nlpProcessor = nlpProcessor
        super.init()
        
        setupBindings()
        loadInitialData()
        loadInitialMessage()
    }
    
    // MARK: - Public Methods
    
    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(
            content: inputText,
            sender: .user,
            timestamp: Date()
        )
        
        messages.append(userMessage)
        let query = inputText
        inputText = ""
        
        processUserQuery(query)
    }
    
    func clearChat() {
        Task {
            do {
                try await dataManager.clearChatHistory()
                await MainActor.run {
                    messages.removeAll()
                    loadInitialMessage()
                }
            } catch {
                await MainActor.run {
                    handleError(error)
                }
            }
        }
    }
    
    func updateSpending(cardId: UUID, category: SpendingCategory, amount: Double) {
        Task {
            do {
                try await dataManager.updateSpendingLimit(cardId: cardId, category: category, amount: amount)
                
                // Update local cards
                await MainActor.run {
                    if let index = userCards.firstIndex(where: { $0.id == cardId }) {
                        if let limitIndex = userCards[index].spendingLimits.firstIndex(where: { $0.category == category }) {
                            userCards[index].spendingLimits[limitIndex].currentSpending = amount
                        }
                    }
                }
                
                // Track spending update
                trackEvent("spending_updated", properties: [
                    "card_id": cardId.uuidString,
                    "category": category.rawValue,
                    "amount": amount
                ])
                
            } catch {
                await MainActor.run {
                    handleError(error)
                }
            }
        }
    }
    
    func clearChatHistory() {
        Task {
            do {
                try await dataManager.clearChatHistory()
                await MainActor.run {
                    self.messages.removeAll()
                }
            } catch {
                await MainActor.run {
                    handleError(error)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Auto-save messages when they change
        $messages
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] messages in
                self?.saveMessages(messages)
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialData() {
        Task {
            await loadUserCards()
            await loadUserPreferences()
        }
    }
    
    private func loadUserCards() async {
        do {
            let cards = try await dataManager.fetchCards()
            await MainActor.run {
                self.userCards = cards
            }
        } catch {
            await MainActor.run {
                handleError(error)
            }
        }
    }
    
    private func loadUserPreferences() async {
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
    
    private func loadInitialMessage() {
        let welcomeMessage = ChatMessage(
            content: "Welcome! Ask me which card to use for your next purchase. For example:\n• \"What card should I use for groceries?\"\n• \"I'm buying gas, which card?\"\n• \"Shopping at Amazon, best card?\"",
            sender: .assistant,
            timestamp: Date()
        )
        
        messages.append(welcomeMessage)
    }
    
    private func processUserQuery(_ query: String) {
        isTyping = true
        
        // Track recommendation request
        let parsedQuery = nlpProcessor.parseUserQuery(query)
        trackEvent("recommendation_request", properties: [
            "query": query,
            "category": parsedQuery.spendingCategory?.rawValue ?? "unknown",
            "merchant": parsedQuery.merchant ?? "none"
        ])
        
        Task {
            let startTime = Date()
            
            do {
                let response = try await recommendationEngine.getRecommendation(
                    for: query,
                    userCards: userCards,
                    userPreferences: userPreferences
                )
                
                let responseTime = Date().timeIntervalSince(startTime)
                
                await MainActor.run {
                    self.isTyping = false
                    self.handleRecommendationResponse(response, query: query, responseTime: responseTime)
                }
                
            } catch {
                await MainActor.run {
                    self.isTyping = false
                    self.handleError(error)
                }
            }
        }
    }
    
    private func handleRecommendationResponse(_ response: RecommendationResponse, query: String, responseTime: TimeInterval) {
        var content = response.reasoning
        
        // Add warnings if any
        if !response.warnings.isEmpty {
            content += "\n\n⚠️ Warnings:\n" + response.warnings.joined(separator: "\n")
        }
        
        // Add suggestions if any
        if !response.suggestions.isEmpty {
            content += "\n\n💡 Suggestions:\n" + response.suggestions.joined(separator: "\n")
        }
        
        let assistantMessage = ChatMessage(
            content: content,
            sender: .assistant,
            timestamp: Date(),
            cardRecommendations: [response.primaryRecommendation, response.secondaryRecommendation].compactMap { $0 }
        )
        
        messages.append(assistantMessage)
        
        // Track recommendation response
        trackEvent("recommendation_response", properties: [
            "primary_card": response.primaryRecommendation?.cardName ?? "none",
            "secondary_card": response.secondaryRecommendation?.cardName ?? "none",
            "category": response.primaryRecommendation?.category.rawValue ?? "unknown",
            "response_time": responseTime
        ])
        
        // Check for limit alerts
        checkLimitAlerts()
    }
    
    private func saveMessages(_ messages: [ChatMessage]) {
        Task {
            for message in messages {
                do {
                    try await dataManager.saveChatMessage(message)
                } catch {
                    print("Failed to save message: \(error)")
                }
            }
        }
    }
    
    private func checkLimitAlerts() {
        NotificationService.shared.checkAndSendLimitAlerts(for: userCards, preferences: userPreferences)
    }
    
    // MARK: - Message Loading
    
    func loadChatHistory() {
        Task {
            do {
                let history = try await dataManager.fetchChatMessages()
                await MainActor.run {
                    self.messages = history
                    if self.messages.isEmpty {
                        self.loadInitialMessage()
                    }
                }
            } catch {
                await MainActor.run {
                    handleError(error)
                }
            }
        }
    }
    
    // MARK: - Quick Actions
    
    func sendQuickMessage(_ message: String) {
        inputText = message
        sendMessage()
    }
    
    func getQuickMessages() -> [String] {
        return [
            "What card should I use for groceries?",
            "I'm buying gas, which card?",
            "Shopping at Amazon, best card?",
            "Dining out tonight, which card?",
            "Booking a flight, what card?"
        ]
    }
    
    // MARK: - Analytics
    
    override func trackEvent(_ eventName: String, properties: [String: Any] = [:]) {
        super.trackEvent(eventName, properties: properties)
        
        // Add session context
        var enhancedProperties = properties
        enhancedProperties["session_id"] = UUID().uuidString
        enhancedProperties["cards_count"] = userCards.count
        enhancedProperties["preferred_point_system"] = userPreferences.preferredPointSystem.rawValue
        
        AnalyticsService.shared.trackEvent(AnalyticsEvent(name: eventName, properties: enhancedProperties))
    }
    
    // MARK: - Performance Monitoring
    
    func measureRecommendationPerformance(_ query: String) async -> RecommendationResponse? {
        do {
            return try await measureAsyncPerformance("recommendation_processing") {
                try await self.recommendationEngine.getRecommendation(
                    for: query,
                    userCards: self.userCards,
                    userPreferences: self.userPreferences
                )
            }
        } catch {
            return nil
        }
    }
}

// MARK: - ChatViewModel Extensions

extension ChatViewModel {
    func getMessageCount() -> Int {
        return messages.count
    }
    
    func getLastMessage() -> ChatMessage? {
        return messages.last
    }
    
    func hasUserCards() -> Bool {
        return !userCards.isEmpty
    }
    
    func getCardById(_ id: UUID) -> CreditCard? {
        return userCards.first { $0.id == id }
    }
    
    func refreshData() {
        Task {
            await loadUserCards()
            await loadUserPreferences()
        }
    }
} 