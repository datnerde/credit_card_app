import SwiftUI

/// View for linking app credit cards to their Apple Wallet counterparts.
/// Users enter the last 4 digits of each card so we can identify which
/// Apple Pay card corresponds to which in-app card.
struct CardLinkingView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var walletService = WalletIntegrationService.shared

    let cards: [CreditCard]
    @State private var lastFourDigits: [UUID: String] = [:]

    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Link your cards to Apple Pay by entering the last 4 digits of each card as it appears in your Apple Wallet.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Section("Your Cards") {
                    ForEach(cards) { card in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(card.name)
                                    .font(.headline)
                                Text(card.cardType.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if walletService.isCardLinkedToWallet(card) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }

                            TextField("Last 4", text: binding(for: card.id))
                                .keyboardType(.numberPad)
                                .frame(width: 70)
                                .textFieldStyle(.roundedBorder)
                                .multilineTextAlignment(.center)
                        }
                    }
                }

                Section {
                    Button("Save Linking") {
                        saveLinks()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Link to Apple Pay")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func binding(for cardId: UUID) -> Binding<String> {
        Binding(
            get: {
                lastFourDigits[cardId] ??
                walletService.getWalletMapping(
                    for: cards.first { $0.id == cardId }!
                )?.walletCardSuffix ?? ""
            },
            set: { lastFourDigits[cardId] = $0 }
        )
    }

    private func saveLinks() {
        for card in cards {
            if let digits = lastFourDigits[card.id], digits.count == 4 {
                let network = walletService.paymentNetworkForCardType(card.cardType).rawValue
                walletService.mapCardToWallet(
                    creditCard: card,
                    walletCardSuffix: digits,
                    network: network
                )
            }
        }
    }
}

#Preview {
    CardLinkingView(cards: [
        CreditCard(name: "Amex Gold", cardType: .amexGold),
        CreditCard(name: "Chase Sapphire Reserve", cardType: .chaseSapphireReserve)
    ])
}
