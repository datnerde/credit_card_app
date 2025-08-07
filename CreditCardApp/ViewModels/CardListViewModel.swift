import Foundation
import Combine

class CardListViewModel: ObservableObject {
    @Published var cards: [CreditCard] = []
    @Published var showingAddCard = false
    @Published var selectedCard: CreditCard?
    @Published var searchText = ""
    @Published var filterCategory: SpendingCategory?
    @Published var sortOption: CardSortOption = .name
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    var hasError: Bool {
        return errorMessage != nil
    }
    
    private let dataManager: DataManager
    private let analyticsService: AnalyticsService
    private var cancellables = Set<AnyCancellable>()
    
    init(dataManager: DataManager, analyticsService: AnalyticsService) {
        self.dataManager = dataManager
        self.analyticsService = analyticsService
        
        // Defer setup to avoid initialization crashes
        DispatchQueue.main.async {
            self.setupBindings()
            self.loadCards()
        }
    }
    
    // MARK: - Public Methods
    
    func loadCards() {
        Task {
            do {
                let fetchedCards = try await dataManager.fetchCards()
                await MainActor.run {
                    self.cards = fetchedCards
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.handleError(error)
                }
            }
        }
    }
    
    func addCard(_ card: CreditCard) {
        Task {
            do {
                try await dataManager.saveCard(card)
                
                await MainActor.run {
                    self.cards.append(card)
                    self.sortCards()
                }
                
                // Track card addition
                trackEvent("card_added", properties: [
                    "card_type": card.cardType.rawValue,
                    "has_quarterly_bonus": card.quarterlyBonus != nil
                ])
                
            } catch {
                await MainActor.run {
                    handleError(error)
                }
            }
        }
    }
    
    func updateCard(_ card: CreditCard) {
        Task {
            do {
                try await dataManager.updateCard(card)
                
                await MainActor.run {
                    if let index = self.cards.firstIndex(where: { $0.id == card.id }) {
                        self.cards[index] = card
                        self.sortCards()
                    }
                }
                
                // Track card update
                trackEvent("card_updated", properties: [
                    "card_type": card.cardType.rawValue,
                    "card_id": card.id.uuidString
                ])
                
            } catch {
                await MainActor.run {
                    handleError(error)
                }
            }
        }
    }
    
    func deleteCard(_ card: CreditCard) {
        Task {
            do {
                try await dataManager.deleteCard(card)
                
                await MainActor.run {
                    self.cards.removeAll { $0.id == card.id }
                }
                
                // Track card deletion
                trackEvent("card_deleted", properties: [
                    "card_type": card.cardType.rawValue
                ])
                
            } catch {
                await MainActor.run {
                    handleError(error)
                }
            }
        }
    }
    
    func updateSpendingLimit(cardId: UUID, category: SpendingCategory, amount: Double) {
        Task {
            do {
                try await dataManager.updateSpendingLimit(cardId: cardId, category: category, amount: amount)
                
                await MainActor.run {
                    if let index = self.cards.firstIndex(where: { $0.id == cardId }) {
                        if let limitIndex = self.cards[index].spendingLimits.firstIndex(where: { $0.category == category }) {
                            self.cards[index].spendingLimits[limitIndex].currentSpending = amount
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
    
    func loadSampleData() {
        Task {
            do {
                try await dataManager.loadSampleCardsData()
                loadCards()
            } catch {
                await MainActor.run {
                    handleError(error)
                }
            }
        }
    }
    
    // MARK: - Filtering and Sorting
    
    func setFilterCategory(_ category: SpendingCategory?) {
        filterCategory = category
        applyFilters()
    }
    
    func setSortOption(_ option: CardSortOption) {
        sortOption = option
        sortCards()
    }
    
    func clearFilters() {
        searchText = ""
        filterCategory = nil
        applyFilters()
    }
    
    // MARK: - Computed Properties
    
    var filteredCards: [CreditCard] {
        var filtered = cards
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { card in
                card.name.localizedCaseInsensitiveContains(searchText) ||
                card.cardType.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply category filter
        if let category = filterCategory {
            filtered = filtered.filter { card in
                card.rewardCategories.contains { $0.category == category }
            }
        }
        
        return filtered
    }
    
    var totalCards: Int {
        return cards.count
    }
    
    var activeCards: Int {
        return cards.filter { $0.isActive }.count
    }
    
    var cardsWithLimits: Int {
        return cards.filter { !$0.spendingLimits.isEmpty }.count
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Auto-sort when cards change
        $cards
            .sink { [weak self] cards in
                guard let self = self, !cards.isEmpty else { return }
                self.sortCards()
            }
            .store(in: &cancellables)
        
        // Apply filters when search text changes
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }
    
    private func sortCards() {
        guard !cards.isEmpty else { return }
        
        cards.sort { first, second in
            switch sortOption {
            case .name:
                return first.name < second.name
            case .cardType:
                return first.cardType.rawValue < second.cardType.rawValue
            case .recentlyAdded:
                return first.createdAt > second.createdAt
            case .recentlyUpdated:
                return first.updatedAt > second.updatedAt
            case .activeFirst:
                if first.isActive != second.isActive {
                    return first.isActive
                }
                return first.name < second.name
            }
        }
    }
    
    private func applyFilters() {
        // This is handled by the computed property filteredCards
        // The UI will automatically update when the filtered results change
    }
    
    // MARK: - Card Analysis
    
    func getCardStats() -> CardStats {
        let totalCards = cards.count
        let activeCards = cards.filter { $0.isActive }.count
        let cardsWithLimits = cards.filter { !$0.spendingLimits.isEmpty }.count
        
        let totalSpending = cards.flatMap { $0.spendingLimits }.reduce(0) { $0 + $1.currentSpending }
        let totalLimits = cards.flatMap { $0.spendingLimits }.reduce(0) { $0 + $1.limit }
        
        let averageUsage = totalLimits > 0 ? totalSpending / totalLimits : 0
        
        return CardStats(
            totalCards: totalCards,
            activeCards: activeCards,
            cardsWithLimits: cardsWithLimits,
            totalSpending: totalSpending,
            totalLimits: totalLimits,
            averageUsage: averageUsage
        )
    }
    
    func getCardsByCategory(_ category: SpendingCategory) -> [CreditCard] {
        return cards.filter { card in
            card.rewardCategories.contains { $0.category == category }
        }
    }
    
    func getCardsWithLimitReached() -> [CreditCard] {
        return cards.filter { card in
            card.spendingLimits.contains { $0.isLimitReached }
        }
    }
    
    func getCardsWithWarningThreshold() -> [CreditCard] {
        return cards.filter { card in
            card.spendingLimits.contains { $0.isWarningThreshold }
        }
    }
    
    // MARK: - Export and Backup
    
    func exportCardsData() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(cards)
            return String(data: data, encoding: .utf8) ?? "Export failed"
        } catch {
            return "Export failed: \(error.localizedDescription)"
        }
    }
    
    func importCardsData(_ jsonString: String) {
        let decoder = JSONDecoder()
        
        do {
            let data = jsonString.data(using: .utf8) ?? Data()
            let importedCards = try decoder.decode([CreditCard].self, from: data)
            
            Task {
                for card in importedCards {
                    try await dataManager.saveCard(card)
                }
                loadCards()
            }
            
        } catch {
            handleError(error)
        }
    }
}

// MARK: - Supporting Types

enum CardSortOption: String, CaseIterable {
    case name = "Name"
    case cardType = "Card Type"
    case recentlyAdded = "Recently Added"
    case recentlyUpdated = "Recently Updated"
    case activeFirst = "Active First"
    
    var displayName: String {
        return rawValue
    }
}

struct CardStats {
    let totalCards: Int
    let activeCards: Int
    let cardsWithLimits: Int
    let totalSpending: Double
    let totalLimits: Double
    let averageUsage: Double
    
    var usagePercentage: Double {
        return averageUsage * 100
    }
    
    var formattedTotalSpending: String {
        return totalSpending.asCurrency
    }
    
    var formattedTotalLimits: String {
        return totalLimits.asCurrency
    }
    
    var formattedUsagePercentage: String {
        return usagePercentage.asPercentage
    }
}

// MARK: - CardListViewModel Extensions

extension CardListViewModel {
    func getCardById(_ id: UUID) -> CreditCard? {
        return cards.first { $0.id == id }
    }
    
    func toggleCardActive(_ card: CreditCard) {
        var updatedCard = card
        updatedCard.isActive.toggle()
        updateCard(updatedCard)
    }
    
    func duplicateCard(_ card: CreditCard) {
        var newCard = card
        newCard.id = UUID()
        newCard.name = "\(card.name) (Copy)"
        newCard.createdAt = Date()
        newCard.updatedAt = Date()
        
        // Reset spending limits
        for i in 0..<newCard.spendingLimits.count {
            newCard.spendingLimits[i].currentSpending = 0
        }
        
        addCard(newCard)
    }
    
    func getCardsByPointType(_ pointType: PointType) -> [CreditCard] {
        return cards.filter { card in
            card.rewardCategories.contains { $0.pointType == pointType }
        }
    }
    
    // MARK: - Error Handling
    
    func handleError(_ error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    func clearError() {
        DispatchQueue.main.async {
            self.errorMessage = nil
        }
    }
    
    // MARK: - Loading State Management
    
    func setLoading(_ loading: Bool) {
        DispatchQueue.main.async {
            self.isLoading = loading
        }
    }
    
    // MARK: - Analytics
    
    func trackEvent(_ eventName: String, properties: [String: Any] = [:]) {
        let event = AnalyticsEvent(name: eventName, properties: properties)
        analyticsService.trackEvent(event)
    }
    
    func trackScreenView(_ screenName: String) {
        analyticsService.trackScreenView(screenName)
    }
} 