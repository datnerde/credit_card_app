import Foundation
import Combine

class AddCardViewModel: BaseViewModelImpl {
    @Published var cardName: String = ""
    @Published var selectedCardType: CardType = .custom
    @Published var selectedCategories: Set<SpendingCategory> = []
    @Published var categoryMultipliers: [SpendingCategory: Double] = [:]
    @Published var categoryPointTypes: [SpendingCategory: PointType] = [:]
    @Published var categoryLimits: [SpendingCategory: Double] = [:]
    @Published var isActive: Bool = true
    
    // Quarterly bonus properties
    @Published var hasQuarterlyBonus: Bool = false
    @Published var quarterlyBonusQuarter: Int = 1
    @Published var quarterlyBonusCategory: SpendingCategory = .groceries
    @Published var quarterlyBonusMultiplier: Double = 5.0
    @Published var quarterlyBonusLimit: Double = 1500.0
    @Published var quarterlyBonusPointType: PointType = .cashBack
    
    // Legacy properties for backward compatibility
    @Published var selectedRewardCategories: Set<SpendingCategory> = []
    @Published var spendingLimits: [SpendingLimit] = []
    @Published var quarterlyBonus: QuarterlyBonus?
    @Published var isEditing: Bool = false
    @Published var editingCard: CreditCard?
    
    // Form validation
    @Published var isFormValid: Bool = false
    @Published var validationErrors: [String] = []
    
    private let dataManager: DataManager
    private var cancellables = Set<AnyCancellable>()
    
    init(dataManager: DataManager, analyticsService: AnalyticsService) {
        self.dataManager = dataManager
        super.init(analyticsService: analyticsService)
        
        setupBindings()
        setupValidation()
    }
    
    // MARK: - New Methods for Enhanced UI
    
    func toggleCategory(_ category: SpendingCategory, isSelected: Bool) {
        if isSelected {
            selectedCategories.insert(category)
            if categoryMultipliers[category] == nil {
                categoryMultipliers[category] = getDefaultMultiplier(for: category)
            }
            if categoryPointTypes[category] == nil {
                categoryPointTypes[category] = getPointTypeForCard()
            }
        } else {
            selectedCategories.remove(category)
            categoryMultipliers.removeValue(forKey: category)
            categoryPointTypes.removeValue(forKey: category)
            categoryLimits.removeValue(forKey: category)
        }
        updateLegacyProperties()
        validateForm()
    }
    
    func updateMultiplier(_ category: SpendingCategory, multiplier: Double) {
        categoryMultipliers[category] = multiplier
        updateLegacyProperties()
        validateForm()
    }
    
    func updatePointType(_ category: SpendingCategory, pointType: PointType) {
        categoryPointTypes[category] = pointType
        updateLegacyProperties()
        validateForm()
    }
    
    private func getDefaultMultiplier(for category: SpendingCategory) -> Double {
        if let defaultReward = selectedCardType.defaultRewards.first(where: { $0.category == category }) {
            return defaultReward.multiplier
        }
        return 1.0
    }
    
    private func updateLegacyProperties() {
        selectedRewardCategories = selectedCategories
        
        // Update spending limits
        spendingLimits = selectedCategories.compactMap { category in
            guard let limit = categoryLimits[category], limit > 0 else { return nil }
            return SpendingLimit(
                category: category,
                limit: limit,
                currentSpending: 0.0,
                resetDate: calculateResetDate(for: .annually),
                resetType: .annually
            )
        }
        
        // Update quarterly bonus
        if hasQuarterlyBonus {
            quarterlyBonus = QuarterlyBonus(
                category: quarterlyBonusCategory,
                multiplier: quarterlyBonusMultiplier,
                pointType: quarterlyBonusPointType,
                limit: quarterlyBonusLimit,
                currentSpending: 0.0,
                quarter: quarterlyBonusQuarter
            )
        } else {
            quarterlyBonus = nil
        }
    }
    
    // MARK: - Public Methods
    
    func setupForEditing(_ card: CreditCard) {
        editingCard = card
        isEditing = true
        
        cardName = card.name
        selectedCardType = card.cardType
        selectedRewardCategories = Set(card.rewardCategories.map { $0.category })
        isActive = card.isActive
        
        // Setup spending limits
        spendingLimits = card.spendingLimits
        
        // Setup quarterly bonus
        quarterlyBonus = card.quarterlyBonus
        
        validateForm()
    }
    
    func saveCard() async {
        guard isFormValid else { return }
        
        do {
            updateLegacyProperties() // Ensure legacy properties are up to date
            let card = createCardFromForm()
            
            if isEditing {
                try await dataManager.updateCard(card)
                
                // Track card update
                let event = AnalyticsEvent(name: "card_updated", properties: [
                    "card_type": card.cardType.rawValue,
                    "card_id": card.id.uuidString,
                    "reward_categories_count": card.rewardCategories.count,
                    "has_quarterly_bonus": card.quarterlyBonus != nil
                ])
                analyticsService?.trackEvent(event)
            } else {
                try await dataManager.saveCard(card)
                
                // Track card addition
                let event = AnalyticsEvent(name: "card_added", properties: [
                    "card_type": card.cardType.rawValue,
                    "has_quarterly_bonus": card.quarterlyBonus != nil,
                    "reward_categories_count": card.rewardCategories.count
                ])
                analyticsService?.trackEvent(event)
            }
            
            await MainActor.run {
                resetForm()
            }
            
        } catch {
            await MainActor.run {
                handleError(error)
            }
        }
    }
    
    func resetForm() {
        cardName = ""
        selectedCardType = .custom
        selectedCategories.removeAll()
        categoryMultipliers.removeAll()
        categoryPointTypes.removeAll()
        categoryLimits.removeAll()
        hasQuarterlyBonus = false
        quarterlyBonusQuarter = 1
        quarterlyBonusCategory = .groceries
        quarterlyBonusMultiplier = 5.0
        quarterlyBonusLimit = 1500.0
        quarterlyBonusPointType = .cashBack
        
        // Legacy properties
        selectedRewardCategories.removeAll()
        spendingLimits.removeAll()
        quarterlyBonus = nil
        isEditing = false
        editingCard = nil
        validationErrors.removeAll()
        validateForm()
    }
    
    func addSpendingLimit(for category: SpendingCategory, limit: Double, resetType: ResetType = .annually) {
        let spendingLimit = SpendingLimit(
            category: category,
            limit: limit,
            currentSpending: 0.0,
            resetDate: calculateResetDate(for: resetType),
            resetType: resetType
        )
        
        // Remove existing limit for this category if it exists
        spendingLimits.removeAll { $0.category == category }
        
        // Add new limit
        spendingLimits.append(spendingLimit)
        validateForm()
    }
    
    func removeSpendingLimit(for category: SpendingCategory) {
        spendingLimits.removeAll { $0.category == category }
        validateForm()
    }
    
    func updateSpendingLimit(for category: SpendingCategory, limit: Double) {
        if let index = spendingLimits.firstIndex(where: { $0.category == category }) {
            spendingLimits[index].limit = limit
        }
        validateForm()
    }
    
    func setQuarterlyBonus(category: SpendingCategory, multiplier: Double, limit: Double) {
        quarterlyBonus = QuarterlyBonus(
            category: category,
            multiplier: multiplier,
            pointType: getPointTypeForCard(),
            limit: limit,
            currentSpending: 0.0
        )
        validateForm()
    }
    
    func removeQuarterlyBonus() {
        quarterlyBonus = nil
        validateForm()
    }
    
    func toggleRewardCategory(_ category: SpendingCategory) {
        if selectedRewardCategories.contains(category) {
            selectedRewardCategories.remove(category)
            // Remove spending limit if it exists
            removeSpendingLimit(for: category)
        } else {
            selectedRewardCategories.insert(category)
            // Add default spending limit
            addDefaultSpendingLimit(for: category)
        }
        validateForm()
    }
    
    // MARK: - Computed Properties
    
    var availableRewardCategories: [SpendingCategory] {
        return SpendingCategory.allCases.filter { category in
            category != .general // General is always available
        }
    }
    
    var selectedCardTypeRewards: [RewardCategory] {
        return selectedCardType.defaultRewards
    }
    
    
    var formTitle: String {
        return isEditing ? "Edit Card" : "Add New Card"
    }
    
    var saveButtonTitle: String {
        return isEditing ? "Update Card" : "Add Card"
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Auto-validate form when inputs change
        Publishers.CombineLatest4($cardName, $selectedCardType, $selectedRewardCategories, $spendingLimits)
            .sink { [weak self] _, _, _, _ in
                self?.validateForm()
            }
            .store(in: &cancellables)
    }
    
    private func setupValidation() {
        validateForm()
    }
    
    private func validateForm() {
        validationErrors.removeAll()
        
        // Validate card name
        if cardName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append("Card name is required")
        }
        
        // Validate reward categories
        if selectedCategories.isEmpty && selectedRewardCategories.isEmpty {
            validationErrors.append("At least one reward category is required")
        }
        
        // Validate spending limits
        for limit in spendingLimits {
            if limit.limit <= 0 {
                validationErrors.append("Spending limit for \(limit.category.rawValue) must be greater than 0")
            }
        }
        
        // Validate quarterly bonus
        if let bonus = quarterlyBonus {
            if bonus.limit <= 0 {
                validationErrors.append("Quarterly bonus limit must be greater than 0")
            }
            if bonus.multiplier <= 0 {
                validationErrors.append("Quarterly bonus multiplier must be greater than 0")
            }
        }
        
        isFormValid = validationErrors.isEmpty && !cardName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (!selectedCategories.isEmpty || !selectedRewardCategories.isEmpty)
    }
    
    private func createCardFromForm() -> CreditCard {
        let rewardCategories = selectedCategories.map { category in
            RewardCategory(
                category: category,
                multiplier: categoryMultipliers[category] ?? 1.0,
                pointType: categoryPointTypes[category] ?? getPointTypeForCard(),
                isActive: true
            )
        }
        
        return CreditCard(
            id: editingCard?.id ?? UUID(),
            name: cardName.trimmingCharacters(in: .whitespacesAndNewlines),
            cardType: selectedCardType,
            rewardCategories: rewardCategories,
            quarterlyBonus: quarterlyBonus,
            spendingLimits: spendingLimits,
            isActive: isActive
        )
    }
    
    private func getMultiplierForCategory(_ category: SpendingCategory) -> Double {
        // Check if there's a default multiplier for this card type
        if let defaultReward = selectedCardType.defaultRewards.first(where: { $0.category == category }) {
            return defaultReward.multiplier
        }
        
        // Check quarterly bonus
        if let bonus = quarterlyBonus, bonus.category == category {
            return bonus.multiplier
        }
        
        // Default multiplier
        return 1.0
    }
    
    private func getPointTypeForCard() -> PointType {
        switch selectedCardType {
        case .amexGold, .amexPlatinum:
            return .membershipRewards
        case .chaseFreedom, .chaseSapphirePreferred, .chaseSapphireReserve:
            return .ultimateRewards
        case .citiDoubleCash:
            return .thankYouPoints
        case .custom:
            return .membershipRewards // Default for custom cards
        }
    }
    
    private func addDefaultSpendingLimit(for category: SpendingCategory) {
        let defaultLimit: Double
        
        switch category {
        case .groceries, .dining:
            defaultLimit = 25000 // $25,000 annual limit
        case .travel:
            defaultLimit = 3000 // $3,000 annual limit
        case .gas:
            defaultLimit = 1500 // $1,500 quarterly limit
        case .online, .drugstores, .streaming:
            defaultLimit = 1000 // $1,000 quarterly limit
        default:
            defaultLimit = 5000 // $5,000 annual limit
        }
        
        let resetType: ResetType = (category == .gas || category == .online || category == .drugstores || category == .streaming) ? .quarterly : .annually
        
        addSpendingLimit(for: category, limit: defaultLimit, resetType: resetType)
    }
    
    private func calculateResetDate(for resetType: ResetType) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch resetType {
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: now) ?? now
        case .quarterly:
            let currentQuarter = calendar.component(.quarter, from: now)
            let nextQuarter = currentQuarter == 4 ? 1 : currentQuarter + 1
            let nextQuarterYear = currentQuarter == 4 ? calendar.component(.year, from: now) + 1 : calendar.component(.year, from: now)
            
            var components = DateComponents()
            components.year = nextQuarterYear
            components.quarter = nextQuarter
            components.day = 1
            
            return calendar.date(from: components) ?? now
        case .annually:
            return calendar.date(byAdding: .year, value: 1, to: now) ?? now
        case .never:
            return now
        }
    }
    
    // MARK: - Helper Methods
    
    func getCardTypeDescription(_ cardType: CardType) -> String {
        switch cardType {
        case .amexGold:
            return "American Express Gold Card - 4x on groceries and dining"
        case .amexPlatinum:
            return "American Express Platinum Card - 5x on travel"
        case .chaseFreedom:
            return "Chase Freedom - 5% rotating categories"
        case .chaseSapphirePreferred:
            return "Chase Sapphire Preferred - 3x on dining, 2x on travel"
        case .chaseSapphireReserve:
            return "Chase Sapphire Reserve - 3x on travel and dining"
        case .citiDoubleCash:
            return "Citi Double Cash - 2% on all purchases"
        case .custom:
            return "Custom card - define your own rewards"
        }
    }
    
    func getCategoryDescription(_ category: SpendingCategory) -> String {
        switch category {
        case .groceries:
            return "Grocery stores and supermarkets"
        case .dining:
            return "Restaurants and dining out"
        case .travel:
            return "Travel expenses including flights and hotels"
        case .gas:
            return "Gas stations and fuel purchases"
        case .online:
            return "Online shopping and e-commerce"
        case .drugstores:
            return "Drugstores and pharmacies"
        case .streaming:
            return "Streaming services and entertainment"
        case .transit:
            return "Public transportation and rideshare"
        case .office:
            return "Office supplies and work expenses"
        case .phone:
            return "Phone services and mobile bills"
        case .general:
            return "General purchases and everything else"
        default:
            return category.rawValue
        }
    }
    
    func getResetTypeDescription(_ resetType: ResetType) -> String {
        switch resetType {
        case .monthly:
            return "Resets monthly"
        case .quarterly:
            return "Resets quarterly"
        case .annually:
            return "Resets annually"
        case .never:
            return "No reset"
        }
    }
}

// MARK: - AddCardViewModel Extensions

extension AddCardViewModel {
    func duplicateCard(_ card: CreditCard) {
        setupForEditing(card)
        cardName = "\(card.name) (Copy)"
        isEditing = false
        editingCard = nil
        validateForm()
    }
    
    func getSuggestedCardTypes() -> [CardType] {
        return [.amexGold, .chaseSapphireReserve, .chaseFreedom, .citiDoubleCash, .custom]
    }
    
    func getPopularCategories() -> [SpendingCategory] {
        return [.groceries, .dining, .travel, .gas, .online]
    }
} 