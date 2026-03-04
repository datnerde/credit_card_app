import Foundation
import PassKit

// MARK: - Wallet Card Mapping
/// Maps an in-app CreditCard to its corresponding card in the user's Apple Pay wallet
struct WalletCardMapping: Codable, Identifiable {
    let id: UUID
    var creditCardId: UUID          // Our app's card ID
    var walletCardSuffix: String    // Last 4 digits of the card in Apple Wallet
    var paymentNetworkRaw: String   // PKPaymentNetwork raw value
    var isPrimary: Bool             // Whether this is the primary mapping for the card
    var createdAt: Date

    init(id: UUID = UUID(),
         creditCardId: UUID,
         walletCardSuffix: String,
         paymentNetworkRaw: String,
         isPrimary: Bool = true) {
        self.id = id
        self.creditCardId = creditCardId
        self.walletCardSuffix = walletCardSuffix
        self.paymentNetworkRaw = paymentNetworkRaw
        self.isPrimary = isPrimary
        self.createdAt = Date()
    }
}

// MARK: - Payment Result
struct SmartPaymentResult {
    let success: Bool
    let cardUsed: CreditCard
    let category: SpendingCategory
    let amount: Double
    let pointsEarned: Double
    let errorMessage: String?

    var formattedPointsEarned: String {
        return String(format: "%.0f", pointsEarned)
    }
}

// MARK: - Wallet Integration Service
class WalletIntegrationService: NSObject, ObservableObject {
    static let shared = WalletIntegrationService()

    @Published var isApplePayAvailable: Bool = false
    @Published var walletCards: [PKPass] = []
    @Published var cardMappings: [WalletCardMapping] = []

    private let passLibrary = PKPassLibrary()
    private let supportedNetworks: [PKPaymentNetwork] = [
        .amex, .visa, .masterCard, .discover
    ]

    // Merchant ID for Apple Pay (configure in Apple Developer Portal)
    private let merchantIdentifier = "merchant.com.creditcardapp.smartpay"

    private var paymentCompletion: ((SmartPaymentResult) -> Void)?
    private var currentPaymentCard: CreditCard?
    private var currentPaymentCategory: SpendingCategory?
    private var currentPaymentAmount: Double = 0

    override init() {
        super.init()
        checkApplePayAvailability()
        loadCardMappings()
    }

    // MARK: - Apple Pay Availability

    func checkApplePayAvailability() {
        isApplePayAvailable = PKPaymentAuthorizationController.canMakePayments()
    }

    func canMakePaymentsWithCards() -> Bool {
        return PKPaymentAuthorizationController.canMakePayments(
            usingNetworks: supportedNetworks
        )
    }

    // MARK: - Card Mapping (App Card <-> Apple Wallet Card)

    /// Links an in-app credit card to its Apple Wallet counterpart
    func mapCardToWallet(creditCard: CreditCard, walletCardSuffix: String, network: String) {
        // Remove existing mapping for this credit card
        cardMappings.removeAll { $0.creditCardId == creditCard.id }

        let mapping = WalletCardMapping(
            creditCardId: creditCard.id,
            walletCardSuffix: walletCardSuffix,
            paymentNetworkRaw: network,
            isPrimary: true
        )

        cardMappings.append(mapping)
        saveCardMappings()
    }

    /// Gets the wallet mapping for a specific credit card
    func getWalletMapping(for creditCard: CreditCard) -> WalletCardMapping? {
        return cardMappings.first { $0.creditCardId == creditCard.id && $0.isPrimary }
    }

    /// Checks if a credit card has been linked to Apple Wallet
    func isCardLinkedToWallet(_ creditCard: CreditCard) -> Bool {
        return cardMappings.contains { $0.creditCardId == creditCard.id }
    }

    // MARK: - Smart Payment Flow

    /// The main entry point: triggers Apple Pay with the recommended card pre-selected
    func initiateSmartPayment(
        card: CreditCard,
        category: SpendingCategory,
        amount: Double,
        merchantName: String,
        completion: @escaping (SmartPaymentResult) -> Void
    ) {
        guard isApplePayAvailable else {
            completion(SmartPaymentResult(
                success: false,
                cardUsed: card,
                category: category,
                amount: amount,
                pointsEarned: 0,
                errorMessage: "Apple Pay is not available on this device. Please set up Apple Pay in your Wallet settings."
            ))
            return
        }

        self.paymentCompletion = completion
        self.currentPaymentCard = card
        self.currentPaymentCategory = category
        self.currentPaymentAmount = amount

        // Build the payment request
        let request = buildPaymentRequest(
            amount: amount,
            merchantName: merchantName,
            category: category
        )

        // Present the Apple Pay payment sheet
        let controller = PKPaymentAuthorizationController(paymentRequest: request)
        controller.delegate = self
        controller.present { [weak self] presented in
            if !presented {
                self?.paymentCompletion?(SmartPaymentResult(
                    success: false,
                    cardUsed: card,
                    category: category,
                    amount: amount,
                    pointsEarned: 0,
                    errorMessage: "Unable to present Apple Pay. Please check your wallet setup."
                ))
            }
        }
    }

    // MARK: - Payment Request Builder

    private func buildPaymentRequest(
        amount: Double,
        merchantName: String,
        category: SpendingCategory
    ) -> PKPaymentRequest {
        let request = PKPaymentRequest()
        request.merchantIdentifier = merchantIdentifier
        request.supportedNetworks = supportedNetworks
        request.merchantCapabilities = .threeDSecure
        request.countryCode = "US"
        request.currencyCode = "USD"

        // Build payment summary items
        let purchaseItem = PKPaymentSummaryItem(
            label: "\(category.displayName) - \(merchantName)",
            amount: NSDecimalNumber(value: amount)
        )
        let total = PKPaymentSummaryItem(
            label: merchantName,
            amount: NSDecimalNumber(value: amount)
        )
        request.paymentSummaryItems = [purchaseItem, total]

        return request
    }

    // MARK: - Points Calculation

    func calculatePointsEarned(card: CreditCard, category: SpendingCategory, amount: Double) -> Double {
        // Find the multiplier for this category
        let multiplier: Double
        if let rewardCategory = card.rewardCategories.first(where: { $0.category == category && $0.isActive }) {
            multiplier = rewardCategory.multiplier
        } else if let quarterlyBonus = card.quarterlyBonus, quarterlyBonus.category == category {
            multiplier = quarterlyBonus.multiplier
        } else {
            multiplier = 1.0
        }

        return amount * multiplier
    }

    // MARK: - Persistence

    private func saveCardMappings() {
        if let data = try? JSONEncoder().encode(cardMappings) {
            UserDefaults.standard.set(data, forKey: "wallet_card_mappings")
        }
    }

    private func loadCardMappings() {
        if let data = UserDefaults.standard.data(forKey: "wallet_card_mappings"),
           let mappings = try? JSONDecoder().decode([WalletCardMapping].self, from: data) {
            cardMappings = mappings
        }
    }

    // MARK: - Network Mapping Helper

    func paymentNetworkForCardType(_ cardType: CardType) -> PKPaymentNetwork {
        switch cardType {
        case .amexGold, .amexPlatinum:
            return .amex
        case .chaseFreedom, .chaseSapphirePreferred, .chaseSapphireReserve:
            return .visa
        case .citiDoubleCash:
            return .masterCard
        case .custom:
            return .visa
        }
    }
}

// MARK: - PKPaymentAuthorizationControllerDelegate

extension WalletIntegrationService: PKPaymentAuthorizationControllerDelegate {

    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss {
            // If we haven't sent a result yet, user cancelled
            if let card = self.currentPaymentCard,
               let category = self.currentPaymentCategory {
                self.paymentCompletion?(SmartPaymentResult(
                    success: false,
                    cardUsed: card,
                    category: category,
                    amount: self.currentPaymentAmount,
                    pointsEarned: 0,
                    errorMessage: nil // User cancelled, not an error
                ))
            }
            self.cleanupPaymentState()
        }
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        // In production: send payment.token to your payment processor
        // For MVP: simulate successful payment

        guard let card = currentPaymentCard,
              let category = currentPaymentCategory else {
            completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
            return
        }

        let pointsEarned = calculatePointsEarned(
            card: card,
            category: category,
            amount: currentPaymentAmount
        )

        // Notify success
        paymentCompletion?(SmartPaymentResult(
            success: true,
            cardUsed: card,
            category: category,
            amount: currentPaymentAmount,
            pointsEarned: pointsEarned,
            errorMessage: nil
        ))

        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
        cleanupPaymentState()
    }

    private func cleanupPaymentState() {
        currentPaymentCard = nil
        currentPaymentCategory = nil
        currentPaymentAmount = 0
        paymentCompletion = nil
    }
}
