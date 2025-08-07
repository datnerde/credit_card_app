import SwiftUI

struct AddCardView: View {
    @StateObject private var viewModel: AddCardViewModel
    @Environment(\.dismiss) private var dismiss
    
    init() {
        // Create a safe ViewModel instance
        self._viewModel = StateObject(wrappedValue: AddCardViewModel(
            dataManager: AppServiceContainer.shared.dataManager,
            analyticsService: AppServiceContainer.shared.analyticsService
        ))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Card Information")) {
                    TextField("Card Name", text: $viewModel.cardName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Picker("Card Type", selection: $viewModel.selectedCardType) {
                        ForEach(CardType.allCases, id: \.self) { cardType in
                            Text(cardType.displayName).tag(cardType)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("Reward Categories")) {
                    ForEach(SpendingCategory.allCases.prefix(10), id: \.self) { category in
                        CategoryRowView(
                            category: category,
                            isSelected: viewModel.selectedCategories.contains(category),
                            multiplier: viewModel.categoryMultipliers[category] ?? 1.0,
                            pointType: viewModel.categoryPointTypes[category] ?? .membershipRewards,
                            limit: viewModel.categoryLimits[category] ?? 0.0
                        ) { isSelected in
                            viewModel.toggleCategory(category, isSelected: isSelected)
                        }
                    }
                }
                
                if viewModel.selectedCardType == .chaseFreedom {
                    Section(header: Text("Quarterly Bonus")) {
                        Toggle("Has Quarterly Bonus", isOn: $viewModel.hasQuarterlyBonus)
                        
                        if viewModel.hasQuarterlyBonus {
                            Picker("Quarter", selection: $viewModel.quarterlyBonusQuarter) {
                                ForEach(1...4, id: \.self) { quarter in
                                    Text("Q\(quarter)").tag(quarter)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            
                            Picker("Category", selection: $viewModel.quarterlyBonusCategory) {
                                ForEach([SpendingCategory.gas, .groceries, .dining, .online], id: \.self) { category in
                                    Text(category.displayName).tag(category)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            
                            HStack {
                                Text("Multiplier:")
                                Spacer()
                                TextField("5.0", value: $viewModel.quarterlyBonusMultiplier, format: .number)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 80)
                                Text("x")
                            }
                            
                            HStack {
                                Text("Limit:")
                                Spacer()
                                TextField("1500", value: $viewModel.quarterlyBonusLimit, format: .currency(code: "USD"))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 100)
                            }
                        }
                    }
                }
                
                Section(header: Text("Settings")) {
                    Toggle("Active Card", isOn: $viewModel.isActive)
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Card" : "Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await viewModel.saveCard()
                            if !viewModel.hasError {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
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
        .onAppear {
            if let editingCard = viewModel.editingCard {
                viewModel.loadCard(editingCard)
            } else {
                viewModel.loadDefaultsForCardType()
            }
        }
    }
}

struct CategoryRowView: View {
    let category: SpendingCategory
    let isSelected: Bool
    let multiplier: Double
    let pointType: PointType
    let limit: Double
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            Button(action: { onToggle(!isSelected) }) {
                HStack {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .gray)
                    
                    Image(systemName: category.icon)
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.displayName)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        if isSelected {
                            Text("\(multiplier, specifier: "%.1f")x \(pointType.rawValue)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if isSelected && limit > 0 {
                        Text(limit.asCurrency)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

#Preview {
    AddCardView()
}