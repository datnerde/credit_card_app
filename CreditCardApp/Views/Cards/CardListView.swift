import SwiftUI
import Foundation

struct CardListView: View {
    @EnvironmentObject var serviceContainer: AppServiceContainer
    @State private var viewModel: CardListViewModel?
    @State private var showingAddCard = false
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            Group {
                if let viewModel = viewModel {
                    if viewModel.isLoading {
                        LoadingView()
                    } else if viewModel.cards.isEmpty {
                        EmptyStateView(
                            title: "No Cards Added",
                            message: "Add your credit cards to get personalized recommendations",
                            buttonTitle: "Add Card",
                            action: { showingAddCard = true }
                        )
                    } else {
                        cardList(viewModel: viewModel)
                    }
                } else {
                    LoadingView()
                }
            }
            .navigationTitle("My Cards")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Card") {
                        showingAddCard = true
                    }
                }
            }
            .onAppear {
                if viewModel == nil {
                    // Safely initialize the ViewModel using the service container
                    viewModel = CardListViewModel(
                        dataManager: serviceContainer.dataManager,
                        analyticsService: serviceContainer.analyticsService
                    )
                }
            }
            .sheet(isPresented: $showingAddCard) {
                AddCardView()
            }
            .sheet(item: Binding(
                get: { viewModel?.selectedCard },
                set: { viewModel?.selectedCard = $0 }
            )) { (card: CreditCard) in
                CardDetailView(card: card)
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel?.errorMessage != nil },
            set: { _ in }
        )) {
            Button("OK") {
                viewModel?.clearError()
            }
        } message: {
            Text(viewModel?.errorMessage ?? "")
        }
    }
    
    private func cardList(viewModel: CardListViewModel) -> some View {
        List {
            ForEach(viewModel.cards) { card in
                CardRowView(card: card) {
                    // Navigation handled by NavigationLink in CardRowView
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("Delete", role: .destructive) {
                        viewModel.deleteCard(card)
                    }
                }
            }
        }
        .refreshable {
            viewModel.loadCards()
        }
    }
}

struct CardRowView: View {
    let card: CreditCard
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Card header
                HStack {
                    Image(systemName: "creditcard.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(card.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
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
                
                // Reward categories
                if !card.rewardCategories.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rewards:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 4) {
                            ForEach(card.rewardCategories.prefix(4)) { category in
                                HStack(spacing: 4) {
                                    Image(systemName: category.category.icon)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    
                                    Text("\(category.multiplier, specifier: "%.1f")x")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                    
                                    Text(category.pointType.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                // Spending limits
                if !card.spendingLimits.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Spending Progress:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(card.spendingLimits.prefix(3)) { limit in
                            HStack {
                                Text(limit.category.displayName)
                                    .font(.caption)
                                    .frame(width: 80, alignment: .leading)
                                
                                ProgressView(value: limit.currentSpending, total: limit.limit)
                                    .progressViewStyle(LinearProgressViewStyle(tint: limit.isWarningThreshold ? .orange : .blue))
                                
                                Text("$\(limit.currentSpending, specifier: "%.0f")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 50, alignment: .trailing)
                            }
                            
                            if limit.isLimitReached {
                                Text("⚠️ Limit reached")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            } else if limit.isWarningThreshold {
                                Text("⚠️ Almost at limit")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                
                // Quarterly bonus
                if let quarterlyBonus = card.quarterlyBonus {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Q\(quarterlyBonus.quarter) Bonus:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text(quarterlyBonus.category.displayName)
                                .font(.caption)
                                .fontWeight(.semibold)
                            
                            Text("\(quarterlyBonus.multiplier, specifier: "%.1f")x")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            Text(quarterlyBonus.pointType.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("$\(quarterlyBonus.currentSpending, specifier: "%.0f")/$\(quarterlyBonus.limit, specifier: "%.0f")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        ProgressView(value: quarterlyBonus.currentSpending, total: quarterlyBonus.limit)
                            .progressViewStyle(LinearProgressViewStyle(tint: quarterlyBonus.currentSpending >= quarterlyBonus.limit ? .red : .blue))
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}


#Preview {
    CardListView()
} 