import SwiftUI

struct AddCardView: View {
    @StateObject private var viewModel = ViewModelFactory.makeAddCardViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // Card Information Section
                Section("Card Information") {
                    TextField("Card Name", text: $viewModel.cardName)
                    
                    Picker("Card Type", selection: $viewModel.selectedCardType) {
                        ForEach(CardType.allCases, id: \.self) { cardType in
                            Text(cardType.displayName).tag(cardType)
                        }
                    }
                    .onChange(of: viewModel.selectedCardType) { newValue in
                        viewModel.updateCardType(newValue)
                    }
                    
                    Toggle("Active", isOn: $viewModel.isActive)
                }
                
                // Reward Categories Section
                Section("Reward Categories") {
                    ForEach(SpendingCategory.allCases, id: \.self) { category in
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(category.displayName)
                                    .font(.body)
                                
                                if let defaultReward = viewModel.selectedCardType.defaultRewards.first(where: { $0.category == category }) {
                                    Text("\(defaultReward.multiplier, specifier: "%.1f")x \(defaultReward.pointType.rawValue)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { viewModel.selectedRewardCategories.contains(category) },
                                set: { _ in viewModel.toggleRewardCategory(category) }
                            ))
                        }
                    }
                }
                
                // Spending Limits Section
                if !viewModel.spendingLimits.isEmpty {
                    Section("Spending Limits") {
                        ForEach(viewModel.spendingLimits) { limit in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: limit.category.icon)
                                        .foregroundColor(.blue)
                                    
                                    Text(limit.category.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                }
                                
                                HStack {
                                    Text("Limit:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("Amount", value: $viewModel.spendingLimits[viewModel.spendingLimits.firstIndex(where: { $0.id == limit.id })!].limit, format: .currency(code: "USD"))
                                        .textFieldStyle(.roundedBorder)
                                        .keyboardType(.decimalPad)
                                }
                                
                                HStack {
                                    Text("Current:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("Amount", value: $viewModel.spendingLimits[viewModel.spendingLimits.firstIndex(where: { $0.id == limit.id })!].currentSpending, format: .currency(code: "USD"))
                                        .textFieldStyle(.roundedBorder)
                                        .keyboardType(.decimalPad)
                                }
                            }
                        }
                    }
                }
                
                // Quarterly Bonus Section
                Section("Quarterly Bonus (Optional)") {
                    if let quarterlyBonus = viewModel.quarterlyBonus {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Category:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                Button("Remove") {
                                    viewModel.clearQuarterlyBonus()
                                }
                                .foregroundColor(.red)
                            }
                            
                            Text(quarterlyBonus.category.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text("Multiplier:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("\(quarterlyBonus.multiplier, specifier: "%.1f")x")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Limit:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("$\(quarterlyBonus.limit, specifier: "%.0f")")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                    } else {
                        Button("Add Quarterly Bonus") {
                            // Show quarterly bonus picker
                            showQuarterlyBonusPicker()
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.saveCard()
                        dismiss()
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func showQuarterlyBonusPicker() {
        // This would typically show a picker or modal for selecting quarterly bonus
        // For now, we'll set a default quarterly bonus
        viewModel.setQuarterlyBonus(
            category: .gas,
            multiplier: 5.0,
            limit: 1500.0
        )
    }
}

#Preview {
    AddCardView()
} 