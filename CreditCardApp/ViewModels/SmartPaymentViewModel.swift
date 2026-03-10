import Foundation
import Combine
import PassKit

// MARK: - Payment Flow State
enum PaymentFlowState: Equatable {
    case idle                           // Waiting for user input
    case analyzing                      // NLP parsing the purchase description
    case recommendationReady            // Best card found, showing to user
    case processingPayment              // Apple Pay sheet presented
    case paymentComplete                // Payment succeeded
    case paymentFailed(String)          // Payment failed with reason

    static func == (lhs: PaymentFlowState, rhs: PaymentFlowState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.analyzing, .analyzing),
             (.recommendationReady, .recommendationReady),
             (.processingPayment, .processingPayment),
             (.paymentComplete, .paymentComplete):
            return true
        case (.paymentFailed(let a), .paymentFailed(let b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - Quick Purchase Category
struct QuickPurchaseCategory: Identifiable {
    let id = UUID()
    let category: SpendingCategory
    let emoji: String
    let label: String
}

// MARK: - Smart Payment ViewModel
class SmartPaymentViewModel: BaseViewModelImpl {
    // MARK: - Published Properties
    @Published var purchaseDescription: String = ""
    @Published var purchaseAmount: String = ""
    @Published var flowState: PaymentFlowState = .idle
    @Published var recommendedCard: CreditCard?
    @Published var secondaryCard: CreditCard?
    @Published var detectedCategory: SpendingCategory = .general
    @Published var detectedMerchant: String?
    @Published var recommendationReasoning: String = ""
    @Published var estimatedPoints: Double = 0
    @Published var estimatedPointsSecondary: Double = 0
    @Published var paymentResult: SmartPaymentResult?
    @Published var userCards: [CreditCard] = []
    @Published var userPreferences: UserPreferences = UserPreferences()
    @Published var showCardLinkingSheet: Bool = false
    @Published var useApplePay: Bool = false

    // MARK: - Services
    private let recommendationEngine: RecommendationEngine
    private let dataManager: DataManager
    private let nlpProcessor: NLPProcessor
    private let walletService: WalletIntegrationService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Quick Categories
    let quickCategories: [QuickPurchaseCategory] = [
        QuickPurchaseCategory(category: .groceries, emoji: "cart.fill", label: "Groceries"),
        QuickPurchaseCategory(category: .dining, emoji: "fork.knife", label: "Dining"),
        QuickPurchaseCategory(category: .gas, emoji: "fuelpump.fill", label: "Gas"),
        QuickPurchaseCategory(category: .travel, emoji: "airplane", label: "Travel"),
        QuickPurchaseCategory(category: .online, emoji: "globe", label: "Online"),
        QuickPurchaseCategory(category: .streaming, emoji: "play.tv.fill", label: "Streaming"),
    ]

    // MARK: - Init
    init(dataManager: DataManager,
         recommendationEngine: RecommendationEngine,
         nlpProcessor: NLPProcessor,
         walletService: WalletIntegrationService = .shared,
         analyticsService: AnalyticsService) {
        self.dataManager = dataManager
        self.recommendationEngine = recommendationEngine
        self.nlpProcessor = nlpProcessor
        self.walletService = walletService
        super.init(analyticsService: analyticsService)

        loadData()
    }

    // MARK: - Data Loading

    private func loadData() {
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
            await MainActor.run { handleError(error) }
        }
    }

    private func loadUserPreferences() async {
        do {
            let prefs = try await dataManager.loadUserPreferences()
            await MainActor.run {
                self.userPreferences = prefs
                self.useApplePay = prefs.useApplePay
            }
        } catch {
            await MainActor.run { handleError(error) }
        }
    }

    func refreshCards() {
        Task { await loadUserCards() }
    }

    // MARK: - Smart Analysis Flow

    /// Main entry: user describes what they want to buy, we find the best card
    func analyzePurchase() {
        let description = purchaseDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !description.isEmpty else { return }
        guard !userCards.isEmpty else {
            handleError(RecommendationError.noCardsAvailable)
            return
        }

        flowState = .analyzing
        trackEvent("smart_pay_analyze", properties: ["query": description])

        Task {
            do {
                // 1. Parse the purchase description with NLP
                let parsed = nlpProcessor.parseUserQuery(description)

                // 2. Get recommendation from engine
                let response = try await recommendationEngine.getRecommendation(
                    for: description,
                    userCards: userCards,
                    userPreferences: userPreferences
                )

                // 3. Find the actual card objects
                let primaryCard = response.primaryRecommendation.flatMap { rec in
                    userCards.first { $0.id == rec.cardId }
                }
                let secondCard = response.secondaryRecommendation.flatMap { rec in
                    userCards.first { $0.id == rec.cardId }
                }

                // 4. Determine category and amount
                let category = parsed.spendingCategory ?? .general
                let amount = parsed.amount ?? Double(purchaseAmount) ?? 0

                // 5. Calculate estimated points
                let points = primaryCard.map {
                    walletService.calculatePointsEarned(card: $0, category: category, amount: amount)
                } ?? 0
                let pointsSecondary = secondCard.map {
                    walletService.calculatePointsEarned(card: $0, category: category, amount: amount)
                } ?? 0

                await MainActor.run {
                    self.recommendedCard = primaryCard
                    self.secondaryCard = secondCard
                    self.detectedCategory = category
                    self.detectedMerchant = parsed.merchant
                    self.recommendationReasoning = response.reasoning
                    self.estimatedPoints = points
                    self.estimatedPointsSecondary = pointsSecondary
                    self.flowState = .recommendationReady
                }

                trackEvent("smart_pay_recommendation", properties: [
                    "recommended_card": primaryCard?.name ?? "none",
                    "category": category.rawValue,
                    "amount": amount
                ])

            } catch {
                await MainActor.run {
                    self.flowState = .paymentFailed(error.localizedDescription)
                    handleError(error)
                }
            }
        }
    }

    /// Quick category selection: user taps a category icon for fast analysis
    func selectQuickCategory(_ category: SpendingCategory) {
        purchaseDescription = "I'm buying \(category.displayName.lowercased())"
        detectedCategory = category
        analyzePurchase()
    }

    /// Category-first flow: user picks a category, gets instant recommendation
    func selectCategory(_ category: SpendingCategory) {
        guard !userCards.isEmpty else {
            handleError(RecommendationError.noCardsAvailable)
            return
        }

        detectedCategory = category
        flowState = .analyzing

        trackEvent("category_selected", properties: ["category": category.rawValue])

        // Brief delay for smooth animation, then show result
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }

            let response = self.recommendationEngine.getInstantRecommendation(
                category: category,
                userCards: self.userCards,
                userPreferences: self.userPreferences
            )

            let primaryCard = response.primaryRecommendation.flatMap { rec in
                self.userCards.first { $0.id == rec.cardId }
            }
            let secondCard = response.secondaryRecommendation.flatMap { rec in
                self.userCards.first { $0.id == rec.cardId }
            }

            let amount = Double(self.purchaseAmount) ?? 0
            let points = primaryCard.map {
                self.walletService.calculatePointsEarned(card: $0, category: category, amount: amount)
            } ?? 0
            let pointsSecondary = secondCard.map {
                self.walletService.calculatePointsEarned(card: $0, category: category, amount: amount)
            } ?? 0

            self.recommendedCard = primaryCard
            self.secondaryCard = secondCard
            self.recommendationReasoning = response.reasoning
            self.estimatedPoints = points
            self.estimatedPointsSecondary = pointsSecondary
            self.flowState = .recommendationReady
        }
    }

    /// Dismiss recommendation (for "Got it!" flow when Apple Pay is off)
    func dismissRecommendation() {
        reset()
    }

    // MARK: - Payment Execution

    /// Triggers Apple Pay with the recommended card
    func payWithRecommendedCard() {
        guard let card = recommendedCard else { return }
        payWithCard(card)
    }

    /// Triggers Apple Pay with the secondary card (user override)
    func payWithSecondaryCard() {
        guard let card = secondaryCard else { return }
        payWithCard(card)
    }

    /// Triggers Apple Pay with a specific card
    func payWithCard(_ card: CreditCard) {
        let amount = Double(purchaseAmount) ?? 0
        guard amount > 0 else {
            flowState = .paymentFailed("Please enter a valid purchase amount.")
            return
        }

        flowState = .processingPayment
        let merchantName = detectedMerchant ?? detectedCategory.displayName

        trackEvent("smart_pay_initiated", properties: [
            "card": card.name,
            "category": detectedCategory.rawValue,
            "amount": amount
        ])

        walletService.initiateSmartPayment(
            card: card,
            category: detectedCategory,
            amount: amount,
            merchantName: merchantName
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handlePaymentResult(result)
            }
        }
    }

    private func handlePaymentResult(_ result: SmartPaymentResult) {
        paymentResult = result

        if result.success {
            flowState = .paymentComplete

            // Update spending in our tracker
            updateSpendingAfterPayment(result)

            trackEvent("smart_pay_success", properties: [
                "card": result.cardUsed.name,
                "category": result.category.rawValue,
                "amount": result.amount,
                "points_earned": result.pointsEarned
            ])
        } else if let errorMessage = result.errorMessage {
            flowState = .paymentFailed(errorMessage)
            trackEvent("smart_pay_failed", properties: [
                "card": result.cardUsed.name,
                "error": errorMessage
            ])
        } else {
            // User cancelled
            flowState = .recommendationReady
            trackEvent("smart_pay_cancelled", properties: [
                "card": result.cardUsed.name
            ])
        }
    }

    private func updateSpendingAfterPayment(_ result: SmartPaymentResult) {
        Task {
            do {
                try await dataManager.updateSpendingLimit(
                    cardId: result.cardUsed.id,
                    category: result.category,
                    amount: result.amount
                )
                await loadUserCards() // Refresh to show updated limits
            } catch {
                print("Failed to update spending after payment: \(error)")
            }
        }
    }

    // MARK: - Card Linking

    func isRecommendedCardLinked() -> Bool {
        guard let card = recommendedCard else { return false }
        return walletService.isCardLinkedToWallet(card)
    }

    func linkCardToWallet(card: CreditCard, lastFourDigits: String) {
        let network = walletService.paymentNetworkForCardType(card.cardType).rawValue
        walletService.mapCardToWallet(
            creditCard: card,
            walletCardSuffix: lastFourDigits,
            network: network
        )
    }

    // MARK: - State Management

    func reset() {
        purchaseDescription = ""
        purchaseAmount = ""
        flowState = .idle
        recommendedCard = nil
        secondaryCard = nil
        detectedCategory = .general
        detectedMerchant = nil
        recommendationReasoning = ""
        estimatedPoints = 0
        estimatedPointsSecondary = 0
        paymentResult = nil
    }

    func goBackToRecommendation() {
        flowState = .recommendationReady
    }

    // MARK: - Computed Properties

    var isApplePayAvailable: Bool {
        walletService.isApplePayAvailable
    }

    var parsedAmount: Double {
        Double(purchaseAmount) ?? 0
    }

    var canAnalyze: Bool {
        !purchaseDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !userCards.isEmpty
    }

    var canPay: Bool {
        recommendedCard != nil && parsedAmount > 0 && useApplePay
    }

    var pointTypeDisplay: String {
        guard let card = recommendedCard,
              let reward = card.rewardCategories.first(where: { $0.category == detectedCategory }) else {
            return "points"
        }
        return reward.pointType.displayName
    }

    var multiplierDisplay: String {
        guard let card = recommendedCard,
              let reward = card.rewardCategories.first(where: { $0.category == detectedCategory }) else {
            return "1x"
        }
        return "\(String(format: "%.0f", reward.multiplier))x"
    }
}
