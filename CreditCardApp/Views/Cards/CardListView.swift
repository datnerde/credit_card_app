import SwiftUI
import Foundation

struct CardListView: View {
    @EnvironmentObject var serviceContainer: AppServiceContainer
    @StateObject private var viewModel = CardListViewModel(
        dataManager: DataManager(),
        analyticsService: AnalyticsService.shared
    )
    @State private var showingAddCard = false
    @State private var selectedIndex: Int = 0

    private let accentTeal = Color(hex: "00D09C")

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    LoadingView()
                } else if viewModel.cards.isEmpty {
                    EmptyStateView(
                        title: "No Cards Yet",
                        message: "Add your credit cards to start maximizing rewards",
                        buttonTitle: "Add Card",
                        action: { showingAddCard = true }
                    )
                } else {
                    cardContent
                }
            }
            .navigationTitle("Wallet")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddCard = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(accentTeal)
                            .font(.title3)
                    }
                }
            }
            .onAppear {
                viewModel.updateDataManager(serviceContainer.dataManager)
                Task { await viewModel.loadCards() }
            }
            .sheet(isPresented: $showingAddCard) {
                AddCardView(onCardAdded: {
                    Task { @MainActor in
                        await viewModel.loadCards()
                    }
                })
                .environmentObject(serviceContainer)
            }
            .onChange(of: showingAddCard) { isPresented in
                if !isPresented {
                    Task { await viewModel.loadCards() }
                }
            }
            .sheet(item: Binding(
                get: { viewModel.selectedCard },
                set: { viewModel.selectedCard = $0 }
            )) { (card: CreditCard) in
                CardDetailView(card: card)
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in }
        )) {
            Button("OK") { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Card Content

    private var cardContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Card carousel
                cardCarousel

                // Selected card details
                if selectedIndex < viewModel.cards.count {
                    selectedCardDetails(viewModel.cards[selectedIndex])
                }
            }
            .padding(.top, 8)
        }
        .refreshable {
            await viewModel.loadCards()
        }
    }

    // MARK: - Carousel

    private var cardCarousel: some View {
        VStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(Array(viewModel.cards.enumerated()), id: \.element.id) { index, card in
                        CreditCardVisualView(
                            cardType: card.cardType,
                            cardName: card.name,
                            size: .full
                        )
                        .scaleEffect(selectedIndex == index ? 1.0 : 0.9)
                        .opacity(selectedIndex == index ? 1.0 : 0.6)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                selectedIndex = index
                            }
                        }
                        .contextMenu {
                            Button {
                                viewModel.selectedCard = card
                            } label: {
                                Label("View Details", systemImage: "eye")
                            }
                            Button(role: .destructive) {
                                Task { @MainActor in
                                    await viewModel.deleteCard(card)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }

                    // Add card placeholder
                    addCardPlaceholder
                }
                .padding(.horizontal, 20)
            }

            // Page dots
            if viewModel.cards.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<viewModel.cards.count, id: \.self) { index in
                        Circle()
                            .fill(selectedIndex == index ? accentTeal : Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
    }

    // MARK: - Add Card Placeholder

    private var addCardPlaceholder: some View {
        Button {
            showingAddCard = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                    .foregroundColor(Color.gray.opacity(0.3))
                    .frame(width: 320, height: 200)

                VStack(spacing: 8) {
                    Image(systemName: "plus.circle")
                        .font(.largeTitle)
                        .foregroundColor(.gray.opacity(0.5))
                    Text("Add Card")
                        .font(.subheadline)
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Selected Card Details

    private func selectedCardDetails(_ card: CreditCard) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Card name
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.name)
                        .font(.title3)
                        .fontWeight(.bold)
                    Text(card.cardType.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if !card.isActive {
                    Text("Inactive")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }

            // Rewards
            if !card.rewardCategories.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rewards")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(card.rewardCategories.prefix(6)) { category in
                            HStack(spacing: 6) {
                                Image(systemName: category.category.icon)
                                    .font(.caption)
                                    .foregroundColor(accentTeal)
                                    .frame(width: 16)
                                Text("\(category.multiplier, specifier: "%.0f")x")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                Text(category.category.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                Spacer()
                            }
                        }
                    }
                }
            }

            // Spending limits
            if !card.spendingLimits.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Spending")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    ForEach(card.spendingLimits.prefix(3)) { limit in
                        VStack(spacing: 4) {
                            HStack {
                                Text(limit.category.displayName)
                                    .font(.caption)
                                Spacer()
                                Text("$\(limit.currentSpending, specifier: "%.0f") / $\(limit.limit, specifier: "%.0f")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            ProgressView(
                                value: max(0, limit.currentSpending),
                                total: max(1, limit.limit)
                            )
                            .progressViewStyle(LinearProgressViewStyle(
                                tint: limit.isLimitReached ? .red : limit.isWarningThreshold ? .orange : accentTeal
                            ))
                        }
                    }
                }
            }

            // Quarterly bonus
            if let bonus = card.quarterlyBonus {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Q\(bonus.quarter) Bonus")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    HStack {
                        Text(bonus.category.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("\(bonus.multiplier, specifier: "%.0f")x")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(accentTeal)
                        Spacer()
                        Text("$\(bonus.currentSpending, specifier: "%.0f")/$\(bonus.limit, specifier: "%.0f")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    ProgressView(
                        value: max(0, bonus.currentSpending),
                        total: max(1, bonus.limit)
                    )
                    .progressViewStyle(LinearProgressViewStyle(
                        tint: bonus.currentSpending >= bonus.limit ? .red : accentTeal
                    ))
                }
            }
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
}

#Preview {
    CardListView()
        .environmentObject(AppServiceContainer.shared)
}
