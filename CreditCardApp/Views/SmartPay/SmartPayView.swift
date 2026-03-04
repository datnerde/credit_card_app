import SwiftUI
import PassKit

struct SmartPayView: View {
    @StateObject private var viewModel = ViewModelFactory.makeSmartPaymentViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color.blue.opacity(0.05)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        switch viewModel.flowState {
                        case .idle:
                            purchaseInputSection
                            quickCategoriesSection
                        case .analyzing:
                            analyzingSection
                        case .recommendationReady:
                            recommendationSection
                        case .processingPayment:
                            processingPaymentSection
                        case .paymentComplete:
                            paymentCompleteSection
                        case .paymentFailed(let message):
                            paymentFailedSection(message)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Smart Pay")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if viewModel.flowState != .idle {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Start Over") {
                            withAnimation { viewModel.reset() }
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.refreshCards()
        }
    }

    // MARK: - Purchase Input Section

    private var purchaseInputSection: some View {
        VStack(spacing: 16) {
            // Hero section
            VStack(spacing: 8) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)

                Text("What are you buying?")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Describe your purchase and we'll pick the best card")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)

            // Purchase description input
            VStack(alignment: .leading, spacing: 8) {
                Text("Purchase Description")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("e.g. Groceries at Whole Foods, Gas at Shell...",
                          text: $viewModel.purchaseDescription)
                    .textFieldStyle(.roundedBorder)
                    .font(.body)
                    .submitLabel(.done)
                    .onSubmit {
                        if viewModel.canAnalyze {
                            viewModel.analyzePurchase()
                        }
                    }
            }

            // Amount input
            VStack(alignment: .leading, spacing: 8) {
                Text("Amount (optional for recommendation, required for payment)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Text("$")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    TextField("0.00", text: $viewModel.purchaseAmount)
                        .keyboardType(.decimalPad)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }

            // Analyze button
            Button {
                viewModel.analyzePurchase()
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Find Best Card")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.canAnalyze ? Color.blue : Color.gray)
                .cornerRadius(14)
            }
            .disabled(!viewModel.canAnalyze)

            if viewModel.userCards.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Add your credit cards first in the 'My Cards' tab")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }

    // MARK: - Quick Categories

    private var quickCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Categories")
                .font(.headline)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(viewModel.quickCategories) { qc in
                    Button {
                        viewModel.selectQuickCategory(qc.category)
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: qc.emoji)
                                .font(.title2)
                                .foregroundColor(.blue)
                            Text(qc.label)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }

    // MARK: - Analyzing Section

    private var analyzingSection: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 60)

            ProgressView()
                .scaleEffect(1.5)

            Text("Analyzing your purchase...")
                .font(.headline)

            Text("Finding the best card from your wallet")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Recommendation Section

    private var recommendationSection: some View {
        VStack(spacing: 16) {
            // Detected info
            VStack(spacing: 4) {
                HStack {
                    Image(systemName: viewModel.detectedCategory.icon)
                        .foregroundColor(.blue)
                    Text(viewModel.detectedCategory.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if let merchant = viewModel.detectedMerchant {
                        Text("at \(merchant.capitalized)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Primary recommendation card
            if let card = viewModel.recommendedCard {
                recommendedCardView(
                    card: card,
                    isPrimary: true,
                    points: viewModel.estimatedPoints,
                    multiplier: viewModel.multiplierDisplay
                )
            }

            // Secondary recommendation
            if let card = viewModel.secondaryCard {
                recommendedCardView(
                    card: card,
                    isPrimary: false,
                    points: viewModel.estimatedPointsSecondary,
                    multiplier: nil
                )
            }

            // Reasoning
            if !viewModel.recommendationReasoning.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text("Why this card?")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    Text(viewModel.recommendationReasoning)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(4)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }

            // Amount input (if not entered yet)
            if viewModel.parsedAmount == 0 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter amount to pay")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    HStack {
                        Text("$")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $viewModel.purchaseAmount)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }

            // Apple Pay button
            if viewModel.isApplePayAvailable {
                ApplePayButtonView {
                    viewModel.payWithRecommendedCard()
                }
                .frame(height: 50)
                .disabled(!viewModel.canPay)
                .opacity(viewModel.canPay ? 1.0 : 0.5)
            } else {
                // Fallback for simulator / no Apple Pay
                Button {
                    viewModel.payWithRecommendedCard()
                } label: {
                    HStack {
                        Image(systemName: "apple.logo")
                        Text("Pay with Apple Pay")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(14)
                }
                .disabled(!viewModel.canPay)
                .opacity(viewModel.canPay ? 1.0 : 0.5)
            }
        }
    }

    // MARK: - Card Recommendation View

    private func recommendedCardView(
        card: CreditCard,
        isPrimary: Bool,
        points: Double,
        multiplier: String?
    ) -> some View {
        VStack(spacing: 0) {
            if isPrimary {
                // Best card badge
                HStack {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                    Text("BEST CARD")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.green)
                .cornerRadius(8, corners: [.topLeft, .topRight])
            }

            HStack {
                // Card icon
                VStack {
                    Image(systemName: "creditcard.fill")
                        .font(.title)
                        .foregroundColor(isPrimary ? .blue : .gray)
                }
                .frame(width: 50)

                // Card details
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.name)
                        .font(.headline)
                        .fontWeight(isPrimary ? .bold : .medium)
                    Text(card.cardType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Points info
                VStack(alignment: .trailing, spacing: 4) {
                    if let mult = multiplier {
                        Text(mult)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(isPrimary ? .blue : .secondary)
                    }
                    if points > 0 {
                        Text("\(String(format: "%.0f", points)) pts")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: isPrimary ? 0 : 12)
                    .stroke(isPrimary ? Color.blue : Color.gray.opacity(0.3), lineWidth: isPrimary ? 2 : 1)
            )

            // Use this card button for secondary
            if !isPrimary {
                Button {
                    viewModel.payWithSecondaryCard()
                } label: {
                    Text("Use this card instead")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.top, 6)
            }
        }
        .cornerRadius(12)
    }

    // MARK: - Processing Payment

    private var processingPaymentSection: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 60)

            ProgressView()
                .scaleEffect(1.5)

            Text("Processing Payment...")
                .font(.headline)

            Text("Complete the payment in Apple Pay")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Payment Complete

    private var paymentCompleteSection: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 30)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("Payment Successful!")
                .font(.title2)
                .fontWeight(.bold)

            if let result = viewModel.paymentResult {
                VStack(spacing: 12) {
                    PaymentResultRow(label: "Card Used", value: result.cardUsed.name)
                    PaymentResultRow(label: "Amount", value: String(format: "$%.2f", result.amount))
                    PaymentResultRow(label: "Category", value: result.category.displayName)
                    PaymentResultRow(
                        label: "Points Earned",
                        value: "\(result.formattedPointsEarned) \(viewModel.pointTypeDisplay)"
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }

            Button {
                withAnimation { viewModel.reset() }
            } label: {
                Text("New Purchase")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(14)
            }
            .padding(.top, 10)
        }
    }

    // MARK: - Payment Failed

    private func paymentFailedSection(_ message: String) -> some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 30)

            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)

            Text("Payment Failed")
                .font(.title2)
                .fontWeight(.bold)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button {
                    viewModel.goBackToRecommendation()
                } label: {
                    Text("Try Again")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(14)
                }

                Button {
                    withAnimation { viewModel.reset() }
                } label: {
                    Text("Start Over")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(14)
                }
            }
        }
    }
}

// MARK: - Payment Result Row

struct PaymentResultRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Apple Pay Button Wrapper

struct ApplePayButtonView: UIViewRepresentable {
    let action: () -> Void

    func makeUIView(context: Context) -> PKPaymentButton {
        let button = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
        button.addTarget(context.coordinator, action: #selector(Coordinator.tapped), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: PKPaymentButton, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    class Coordinator: NSObject {
        let action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
        @objc func tapped() { action() }
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

#Preview {
    SmartPayView()
        .environmentObject(AppServiceContainer.shared)
}
