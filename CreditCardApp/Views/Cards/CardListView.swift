import SwiftUI
import Foundation

struct CardListView: View {
    @EnvironmentObject var serviceContainer: AppServiceContainer
    @StateObject private var viewModel = CardListViewModel(
        dataManager: DataManager(), // Temporary placeholder
        analyticsService: AnalyticsService.shared
    )
    @State private var showingAddCard = false
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            Group {
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
                print("🚀 CardListView onAppear called")
                // Update the ViewModel with the proper DataManager from service container
                viewModel.updateDataManager(serviceContainer.dataManager)
                
                print("🚀 Loading cards on app startup")
                Task {
                    await viewModel.loadCards()
                    print("🚀 Initial card load completed. Card count: \(viewModel.cards.count)")
                }
            }
            .sheet(isPresented: $showingAddCard) {
                AddCardView(onCardAdded: {
                    print("🔄 Card added callback triggered, refreshing card list")
                    Task { @MainActor in
                        await viewModel.loadCards()
                        print("🔄 Card list refreshed after card added. New count: \(viewModel.cards.count)")
                    }
                })
                .environmentObject(serviceContainer)
            }
            .onChange(of: showingAddCard) { isPresented in
                // Also refresh when sheet is dismissed (backup mechanism)
                if !isPresented {
                    print("🔄 AddCard sheet dismissed, refreshing card list. Current count: \(viewModel.cards.count)")
                    Task {
                        await viewModel.loadCards()
                        print("🔄 Card list refreshed after sheet dismiss. New count: \(viewModel.cards.count)")
                    }
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
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
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
                        Task { @MainActor in
                            print("🗑️ UI: Starting card deletion for \(card.name)")
                            await viewModel.deleteCard(card)
                            print("🗑️ UI: Card deletion task completed")
                        }
                    }
                }
            }
            .onDelete { indexSet in
                // Handle delete via Edit mode as well
                Task { @MainActor in
                    for index in indexSet {
                        if index < viewModel.cards.count {
                            let card = viewModel.cards[index]
                            print("🗑️ UI: Deleting card via onDelete: \(card.name)")
                            await viewModel.deleteCard(card)
                        }
                    }
                }
            }
        }
        .refreshable {
            await viewModel.loadCards()
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
                                
                                ProgressView(
                                    value: max(0, limit.currentSpending), 
                                    total: max(1, limit.limit)
                                )
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
                        
                        ProgressView(
                            value: max(0, quarterlyBonus.currentSpending), 
                            total: max(1, quarterlyBonus.limit)
                        )
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