import Foundation
import Combine

@MainActor
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
    
    private var dataManager: DataManager
    private let analyticsService: AnalyticsService
    private var cancellables = Set<AnyCancellable>()
    
    init(dataManager: DataManager, analyticsService: AnalyticsService) {
        self.dataManager = dataManager
        self.analyticsService = analyticsService
        
        setupBindings()
        // Don't load cards in init - let the view control when to load
    }
    
    // MARK: - Configuration Methods
    
    func updateDataManager(_ newDataManager: DataManager) {
        self.dataManager = newDataManager
    }
    
    // MARK: - Public Methods
    
    func loadCards() async {
        print("🔄 CardListViewModel.loadCards() called")
        isLoading = true
        do {
            let fetchedCards = try await dataManager.fetchCards()
            print("🔄 Fetched \(fetchedCards.count) cards from DataManager")
            cards = fetchedCards
            sortCards()
            isLoading = false
            print("🔄 CardListViewModel now has \(cards.count) cards")
        } catch {
            print("❌ Error loading cards: \(error)")
            handleError(error)
        }
    }
    
    func addCard(_ card: CreditCard) async {
        do {
            try await dataManager.saveCard(card)
            
            cards.append(card)
            sortCards()
            
            // Track card addition
            trackEvent("card_added", properties: [
                "card_type": card.cardType.rawValue,
                "has_quarterly_bonus": card.quarterlyBonus != nil
            ])
            
        } catch {
            handleError(error)
        }
    }
    
    func updateCard(_ card: CreditCard) async {
        do {
            try await dataManager.updateCard(card)
            
            if let index = cards.firstIndex(where: { $0.id == card.id }) {
                cards[index] = card
                sortCards()
            }
            
            // Track card update
            trackEvent("card_updated", properties: [
                "card_type": card.cardType.rawValue,
                "card_id": card.id.uuidString
            ])
            
        } catch {
            handleError(error)
        }
    }
    
    func deleteCard(_ card: CreditCard) async {
        print("🗑️ Attempting to delete card: \(card.name) (ID: \(card.id))")
        
        do {
            // First, delete from the data manager
            try await dataManager.deleteCard(card)
            print("🗑️ Successfully deleted card from DataManager")
            
            // Then refresh the entire card list to ensure UI consistency
            await loadCards()
            
            // Track card deletion
            trackEvent("card_deleted", properties: [
                "card_type": card.cardType.rawValue
            ])
            
            print("✅ Card deletion completed successfully")
            
        } catch {
            print("❌ Error deleting card: \(error)")
            handleError(error)
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
    
    func loadSampleData() async {
        do {
            try await dataManager.loadSampleCardsData()
            await loadCards()
        } catch {
            handleError(error)
        }
    }
    
    func removeDuplicateCards() async {
        do {
            try await dataManager.removeDuplicateCards()
            await loadCards()
        } catch {
            handleError(error)
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
    
    func importCardsData(_ jsonString: String) async {
        let decoder = JSONDecoder()
        
        do {
            let data = jsonString.data(using: .utf8) ?? Data()
            let importedCards = try decoder.decode([CreditCard].self, from: data)
            
            for card in importedCards {
                try await dataManager.saveCard(card)
            }
            await loadCards()
            
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
    
    func toggleCardActive(_ card: CreditCard) async {
        var updatedCard = card
        updatedCard.isActive.toggle()
        await updateCard(updatedCard)
    }
    
    func duplicateCard(_ card: CreditCard) async {
        var newCard = card
        newCard.id = UUID()
        newCard.name = "\(card.name) (Copy)"
        newCard.createdAt = Date()
        newCard.updatedAt = Date()
        
        // Reset spending limits
        for i in 0..<newCard.spendingLimits.count {
            newCard.spendingLimits[i].currentSpending = 0
        }
        
        await addCard(newCard)
    }
    
    func getCardsByPointType(_ pointType: PointType) -> [CreditCard] {
        return cards.filter { card in
            card.rewardCategories.contains { $0.pointType == pointType }
        }
    }
    
    // MARK: - Error Handling
    
    func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        isLoading = false
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Loading State Management
    
    func setLoading(_ loading: Bool) {
        isLoading = loading
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