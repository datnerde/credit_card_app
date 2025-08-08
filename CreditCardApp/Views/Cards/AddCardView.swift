import SwiftUI

struct AddCardView: View {
    @EnvironmentObject var serviceContainer: AppServiceContainer
    @StateObject private var viewModel: AddCardViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    @State private var selectedCard: CardOption?
    @State private var showingDropdown = false
    @State private var filteredCards: [CardOption] = []
    
    let onCardAdded: (() -> Void)?
    
    init(onCardAdded: (() -> Void)? = nil) {
        self.onCardAdded = onCardAdded
        // Initialize with a placeholder - will be updated in onAppear
        self._viewModel = StateObject(wrappedValue: AddCardViewModel(
            dataManager: DataManager(),
            analyticsService: AnalyticsService.shared
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                
                Spacer()
                
                // Card Icon
                Image(systemName: "creditcard.and.123")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                VStack(spacing: 20) {
                    Text("Add Your Credit Card")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Just enter the card name and we'll automatically configure the rewards for you!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(spacing: 16) {
                    // Card Name Input with Dropdown
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Search for your credit card")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ZStack(alignment: .trailing) {
                            TextField("e.g., Amex, Chase Sapphire, Citi", text: $searchText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.body)
                                .onChange(of: searchText) { newValue in
                                    updateSearchResults(query: newValue)
                                    if !newValue.isEmpty {
                                        showingDropdown = true
                                    } else {
                                        showingDropdown = false
                                        selectedCard = nil
                                    }
                                }
                                .onTapGesture {
                                    if !searchText.isEmpty {
                                        showingDropdown = true
                                        updateSearchResults(query: searchText)
                                    }
                                }
                            
                            if showingDropdown {
                                Button {
                                    showingDropdown = false
                                } label: {
                                    Image(systemName: "chevron.up")
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 12)
                                }
                            } else {
                                Button {
                                    showingDropdown = true
                                    updateSearchResults(query: searchText)
                                } label: {
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 12)
                                }
                            }
                        }
                        
                        // Dropdown List
                        if showingDropdown && !filteredCards.isEmpty {
                            ScrollView {
                                LazyVStack(spacing: 0) {
                                    ForEach(filteredCards.prefix(8), id: \.id) { card in
                                        CardOptionRow(card: card) {
                                            selectCard(card)
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: 250)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                        }
                    }
                    
                    // Selected Card Preview
                    if let card = selectedCard {
                        selectedCardPreviewView(card: card)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                        // Save Button
                        Button("Add Card") {
                            saveCard()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(selectedCard == nil ? Color.gray : Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .disabled(selectedCard == nil || viewModel.isLoading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                    }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { _ in viewModel.clearError() }
            )) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .navigationTitle("Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // Update the viewModel to use the shared data manager
            viewModel.updateDataManager(serviceContainer.dataManager)
            // Initialize with all available cards
            updateSearchResults(query: "")
        }
    }
    
    // MARK: - Card Search and Selection Logic
    
    private func updateSearchResults(query: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            filteredCards = CardDatabase.search(query: query)
        }
    }
    
    private func selectCard(_ card: CardOption) {
        print("🔍 Selecting card: \(card.name)")
        withAnimation {
            selectedCard = card
            searchText = card.name
            showingDropdown = false
        }
    }
    
    
    private func saveCard() {
        guard let selectedCard = selectedCard else { 
            print("❌ No selected card to save")
            return 
        }
        
        print("💾 Starting to save card: \(selectedCard.name)")
        
        // Configure the view model with the selected card
        viewModel.cardName = selectedCard.name
        viewModel.selectedCardType = selectedCard.cardType
        
        print("💾 Set card name: '\(viewModel.cardName)' and type: \(viewModel.selectedCardType)")
        
        // Auto-configure based on card type
        print("💾 Loading defaults for card type...")
        viewModel.loadDefaultsForCardType()
        print("💾 Defaults loaded. Form valid: \(viewModel.isFormValid)")
        
        // For Chase Freedom, set up quarterly bonus
        if selectedCard.cardType == .chaseFreedom {
            viewModel.hasQuarterlyBonus = true
            viewModel.quarterlyBonusQuarter = Calendar.currentQuarter
            viewModel.quarterlyBonusCategory = .gas
            viewModel.quarterlyBonusMultiplier = 5.0
            viewModel.quarterlyBonusLimit = 1500.0
        }
        
        Task {
            print("💾 Calling viewModel.saveCard()")
            await viewModel.saveCard()
            print("💾 SaveCard completed. HasError: \(viewModel.hasError)")
            if !viewModel.hasError {
                print("💾 No error, calling onCardAdded callback")
                onCardAdded?()
                // Small delay to ensure the callback completes before dismissing
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                print("💾 Dismissing sheet")
                dismiss()
            } else {
                print("❌ Error saving card: \(viewModel.errorMessage ?? "Unknown error")")
            }
        }
    }
    
    // MARK: - Card Preview
    
    @ViewBuilder
    private func selectedCardPreviewView(card: CardOption) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Card Selected!")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(card.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Show default rewards preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Rewards Preview:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(card.cardType.defaultRewards.prefix(4), id: \.id) { reward in
                        HStack(spacing: 4) {
                            Image(systemName: reward.category.icon)
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Text("\(reward.multiplier, specifier: "%.0f")x")
                                .font(.caption)
                                .fontWeight(.semibold)
                            
                            Text(reward.category.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Card Option Model

struct CardOption: Identifiable, Hashable {
    let name: String
    let cardType: CardType
    let issuer: String
    let category: String
    
    var id: String {
        return "\(name)-\(issuer)-\(category)".replacingOccurrences(of: " ", with: "_")
    }
    
    var displayName: String {
        return name
    }
    
    var subtitle: String {
        return "\(issuer) • \(category)"
    }
}

// MARK: - Card Database

struct CardDatabase {
    static let allCards: [CardOption] = [
        // American Express Cards
        CardOption(name: "American Express Gold Card", cardType: .amexGold, issuer: "American Express", category: "Travel & Dining"),
        CardOption(name: "American Express Platinum Card", cardType: .amexPlatinum, issuer: "American Express", category: "Premium Travel"),
        CardOption(name: "Amex Gold", cardType: .amexGold, issuer: "American Express", category: "Travel & Dining"),
        CardOption(name: "Amex Platinum", cardType: .amexPlatinum, issuer: "American Express", category: "Premium Travel"),
        CardOption(name: "Amex Hilton Honors", cardType: .amexGold, issuer: "American Express", category: "Hotel"),
        CardOption(name: "Amex Hilton Aspire", cardType: .amexGold, issuer: "American Express", category: "Premium Hotel"),
        
        // Chase Cards
        CardOption(name: "Chase Sapphire Preferred", cardType: .chaseSapphirePreferred, issuer: "Chase", category: "Travel & Dining"),
        CardOption(name: "Chase Sapphire Reserve", cardType: .chaseSapphireReserve, issuer: "Chase", category: "Premium Travel"),
        CardOption(name: "Chase Freedom Flex", cardType: .chaseFreedom, issuer: "Chase", category: "Rotating Categories"),
        CardOption(name: "Chase Freedom Unlimited", cardType: .chaseFreedom, issuer: "Chase", category: "Flat Rate"),
        CardOption(name: "Chase Freedom", cardType: .chaseFreedom, issuer: "Chase", category: "Rotating Categories"),
        CardOption(name: "Chase Ink Business Preferred", cardType: .chaseSapphirePreferred, issuer: "Chase", category: "Business"),
        
        // Citi Cards
        CardOption(name: "Citi Double Cash Card", cardType: .citiDoubleCash, issuer: "Citi", category: "Cash Back"),
        CardOption(name: "Citi Premier Card", cardType: .citiDoubleCash, issuer: "Citi", category: "Travel & Dining"),
        CardOption(name: "Citi Custom Cash", cardType: .citiDoubleCash, issuer: "Citi", category: "Category Cash Back"),
        
        // Capital One Cards
        CardOption(name: "Capital One Venture", cardType: .custom, issuer: "Capital One", category: "Travel"),
        CardOption(name: "Capital One Venture X", cardType: .custom, issuer: "Capital One", category: "Premium Travel"),
        CardOption(name: "Capital One SavorOne", cardType: .custom, issuer: "Capital One", category: "Dining & Entertainment"),
        
        // Discover Cards
        CardOption(name: "Discover it Cash Back", cardType: .custom, issuer: "Discover", category: "Rotating Categories"),
        CardOption(name: "Discover it Miles", cardType: .custom, issuer: "Discover", category: "Travel"),
        
        // Bank of America Cards
        CardOption(name: "Bank of America Premium Rewards", cardType: .custom, issuer: "Bank of America", category: "Travel & Dining"),
        CardOption(name: "Bank of America Cash Rewards", cardType: .custom, issuer: "Bank of America", category: "Cash Back"),
        
        // Wells Fargo Cards
        CardOption(name: "Wells Fargo Bilt Mastercard", cardType: .custom, issuer: "Wells Fargo", category: "Rent & Travel"),
        CardOption(name: "Wells Fargo Active Cash", cardType: .custom, issuer: "Wells Fargo", category: "Cash Back"),
        
        // Other Popular Cards
        CardOption(name: "Apple Card", cardType: .custom, issuer: "Goldman Sachs", category: "Cash Back"),
        CardOption(name: "Amazon Prime Rewards Visa", cardType: .custom, issuer: "Chase", category: "Amazon & Online"),
        CardOption(name: "Target RedCard", cardType: .custom, issuer: "TD Bank", category: "Store Card"),
        CardOption(name: "Costco Anywhere Visa", cardType: .custom, issuer: "Citi", category: "Warehouse"),
        
        // Custom option
        CardOption(name: "Custom Card", cardType: .custom, issuer: "Other", category: "Custom")
    ]
    
    static func search(query: String) -> [CardOption] {
        if query.isEmpty {
            return allCards.prefix(10).map { $0 } // Show top 10 when empty
        }
        
        let lowercaseQuery = query.lowercased()
        return allCards.filter { card in
            card.name.lowercased().contains(lowercaseQuery) ||
            card.issuer.lowercased().contains(lowercaseQuery) ||
            card.category.lowercased().contains(lowercaseQuery)
        }
    }
}

// MARK: - Card Type Detector

struct CardTypeDetector {
    static func detectCardType(from cardName: String) -> CardType? {
        let matchingCard = CardDatabase.search(query: cardName).first
        return matchingCard?.cardType ?? (cardName.isEmpty ? nil : .custom)
    }
}


// MARK: - Card Option Row Component

struct CardOptionRow: View {
    let card: CardOption
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Card icon
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(issuerColor)
                    .frame(width: 40, height: 28)
                
                Image(systemName: "creditcard.fill")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            
            // Card info
            VStack(alignment: .leading, spacing: 2) {
                Text(card.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Text(card.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Arrow
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.caption2)
                .foregroundColor(.gray)
                .rotationEffect(.degrees(90))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .background(Color(UIColor.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(UIColor.separator)),
            alignment: .bottom
        )
    }
    
    private var issuerColor: Color {
        switch card.issuer.lowercased() {
        case "american express":
            return .blue
        case "chase":
            return .blue
        case "citi":
            return .red
        case "capital one":
            return .orange
        case "discover":
            return .orange
        case "bank of america":
            return .red
        case "wells fargo":
            return .yellow
        case "goldman sachs":
            return .black
        default:
            return .gray
        }
    }
}

#Preview {
    AddCardView()
        .environmentObject(AppServiceContainer.shared)
}