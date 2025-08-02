import SwiftUI

struct CardDetailView: View {
    let card: CreditCard
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var editedCard: CreditCard
    
    init(card: CreditCard) {
        self.card = card
        self._editedCard = State(initialValue: card)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Card Header
                    cardHeader
                    
                    // Reward Categories
                    rewardCategoriesSection
                    
                    // Spending Limits
                    spendingLimitsSection
                    
                    // Quarterly Bonus
                    if let quarterlyBonus = card.quarterlyBonus {
                        quarterlyBonusSection(quarterlyBonus)
                    }
                }
                .padding()
            }
            .navigationTitle(card.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Save" : "Edit") {
                        if isEditing {
                            saveChanges()
                        } else {
                            isEditing = true
                        }
                    }
                }
            }
        }
    }
    
    private var cardHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            VStack(spacing: 4) {
                Text(card.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(card.cardType.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if !card.isActive {
                    Text("Inactive")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var rewardCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reward Categories")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(card.rewardCategories) { category in
                    RewardCategoryCard(category: category)
                }
            }
        }
    }
    
    private var spendingLimitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending Limits")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(card.spendingLimits) { limit in
                SpendingLimitCard(limit: limit, isEditing: isEditing) { newAmount in
                    updateSpendingLimit(limit, newAmount: newAmount)
                }
            }
        }
    }
    
    private func quarterlyBonusSection(_ bonus: QuarterlyBonus) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quarterly Bonus")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: bonus.category.icon)
                        .foregroundColor(.blue)
                    
                    Text(bonus.category.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("Q\(bonus.quarter)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                
                HStack {
                    Text("\(bonus.multiplier, specifier: "%.1f")x")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text(bonus.pointType.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("$\(bonus.currentSpending, specifier: "%.0f")/$\(bonus.limit, specifier: "%.0f")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: bonus.currentSpending, total: bonus.limit)
                    .progressViewStyle(LinearProgressViewStyle(tint: bonus.currentSpending >= bonus.limit ? .red : .blue))
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func updateSpendingLimit(_ limit: SpendingLimit, newAmount: Double) {
        // Update the spending limit
        if let index = editedCard.spendingLimits.firstIndex(where: { $0.id == limit.id }) {
            editedCard.spendingLimits[index].currentSpending = newAmount
        }
    }
    
    private func saveChanges() {
        // Save the edited card
        // This would typically call the data manager to update the card
        isEditing = false
    }
}

struct RewardCategoryCard: View {
    let category: RewardCategory
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: category.category.icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(category.category.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
            
            Text("\(category.multiplier, specifier: "%.1f")x")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text(category.pointType.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct SpendingLimitCard: View {
    let limit: SpendingLimit
    let isEditing: Bool
    let onUpdate: (Double) -> Void
    
    @State private var editingAmount: Double
    
    init(limit: SpendingLimit, isEditing: Bool, onUpdate: @escaping (Double) -> Void) {
        self.limit = limit
        self.isEditing = isEditing
        self.onUpdate = onUpdate
        self._editingAmount = State(initialValue: limit.currentSpending)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: limit.category.icon)
                    .foregroundColor(.blue)
                
                Text(limit.category.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if limit.isLimitReached {
                    Text("Limit Reached")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                } else if limit.isWarningThreshold {
                    Text("Warning")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
            
            if isEditing {
                HStack {
                    Text("Current:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Amount", value: $editingAmount, format: .currency(code: "USD"))
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                        .onChange(of: editingAmount) { newValue in
                            onUpdate(newValue)
                        }
                }
            } else {
                HStack {
                    Text("$\(limit.currentSpending, specifier: "%.0f")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("/")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("$\(limit.limit, specifier: "%.0f")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(limit.usagePercentage * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            ProgressView(value: limit.currentSpending, total: limit.limit)
                .progressViewStyle(LinearProgressViewStyle(tint: limit.isWarningThreshold ? .orange : .blue))
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    CardDetailView(card: CreditCard(
        name: "Amex Gold",
        cardType: .amexGold,
        spendingLimits: [
            SpendingLimit(category: .groceries, limit: 25000, currentSpending: 800),
            SpendingLimit(category: .dining, limit: 25000, currentSpending: 1200)
        ]
    ))
} 