import SwiftUI
import PassKit

struct SmartPayView: View {
    @StateObject private var viewModel = ViewModelFactory.makeSmartPaymentViewModel()

    private let accentTeal = Color(hex: "00D09C")

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        switch viewModel.flowState {
                        case .idle:
                            idleSection
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
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Pay")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if viewModel.flowState != .idle {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            withAnimation(.spring(response: 0.35)) {
                                viewModel.reset()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundColor(accentTeal)
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.refreshCards()
        }
    }

    // MARK: - Idle: Category Picker

    private var idleSection: some View {
        VStack(spacing: 24) {
            // Hero
            VStack(spacing: 6) {
                Text("What are you spending on?")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Tap a category to find your best card")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 12)

            // Category grid
            CategoryPickerView { category in
                withAnimation(.spring(response: 0.35)) {
                    viewModel.selectCategory(category)
                }
            }

            // No cards warning
            if viewModel.userCards.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Add your cards in the Wallet tab first")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Analyzing

    private var analyzingSection: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 60)
            ProgressView()
                .scaleEffect(1.5)
                .tint(accentTeal)
            Text("Finding your best card...")
                .font(.headline)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Recommendation Result

    private var recommendationSection: some View {
        VStack(spacing: 20) {
            // Category badge
            HStack(spacing: 6) {
                Image(systemName: viewModel.detectedCategory.icon)
                    .foregroundColor(accentTeal)
                Text(viewModel.detectedCategory.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(accentTeal.opacity(0.1))
            .clipShape(Capsule())

            // Primary card
            if let card = viewModel.recommendedCard {
                VStack(spacing: 12) {
                    Text("USE THIS CARD")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(accentTeal)
                        .tracking(1.2)

                    CreditCardVisualView(
                        cardType: card.cardType,
                        cardName: card.name,
                        size: .full
                    )

                    // Multiplier badge
                    HStack(spacing: 8) {
                        Text(viewModel.multiplierDisplay)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(accentTeal)

                        Text(viewModel.pointTypeDisplay)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        if viewModel.estimatedPoints > 0 {
                            Spacer()
                            Text("\(String(format: "%.0f", viewModel.estimatedPoints)) pts")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(accentTeal)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
            }

            // Reasoning
            if !viewModel.recommendationReasoning.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text(viewModel.recommendationReasoning)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }

            // Secondary card
            if let secondaryCard = viewModel.secondaryCard {
                VStack(spacing: 8) {
                    Text("RUNNER UP")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .tracking(1)

                    HStack(spacing: 12) {
                        CreditCardVisualView(
                            cardType: secondaryCard.cardType,
                            cardName: secondaryCard.name,
                            size: .compact
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(secondaryCard.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(secondaryCard.cardType.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if !viewModel.useApplePay {
                            Button("Use this") {
                                viewModel.recommendedCard = secondaryCard
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(accentTeal)
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }

            // Action buttons
            if viewModel.useApplePay {
                // Apple Pay flow: show amount input + pay button
                VStack(spacing: 12) {
                    HStack {
                        Text("$")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        TextField("Amount", text: $viewModel.purchaseAmount)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    if viewModel.isApplePayAvailable {
                        ApplePayButtonView {
                            viewModel.payWithRecommendedCard()
                        }
                        .frame(height: 50)
                        .disabled(!viewModel.canPay)
                        .opacity(viewModel.canPay ? 1.0 : 0.5)
                    } else {
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
            } else {
                // "Got it!" flow: just confirm and go back
                Button {
                    viewModel.dismissRecommendation()
                } label: {
                    Text("Got it!")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "0A0A1A"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [accentTeal, Color(hex: "00E6AC")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                }
            }
        }
    }

    // MARK: - Processing Payment

    private var processingPaymentSection: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 60)
            ProgressView()
                .scaleEffect(1.5)
                .tint(accentTeal)
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
                .foregroundColor(accentTeal)

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
                Text("Done")
                    .font(.headline)
                    .foregroundColor(Color(hex: "0A0A1A"))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(accentTeal)
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
                        .foregroundColor(accentTeal)
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
                        .foregroundColor(Color(hex: "0A0A1A"))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(accentTeal)
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
