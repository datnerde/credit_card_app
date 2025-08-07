import SwiftUI

struct AddCardView: View {
    @StateObject private var viewModel = ViewModelFactory.makeAddCardViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Card Information") {
                    TextField("Card Name", text: $viewModel.cardName)
                    
                    Picker("Card Type", selection: $viewModel.selectedCardType) {
                        ForEach(CardType.allCases, id: \.self) { cardType in
                            Text(cardType.displayName).tag(cardType)
                        }
                    }
                    
                    Toggle("Active", isOn: $viewModel.isActive)
                }
                
                Section("Reward Categories") {
                    Text("Select reward categories and multipliers")
                        .foregroundColor(.secondary)
                    
                    ForEach(SpendingCategory.allCases, id: \.self) { category in
                        RewardCategoryRow(
                            category: category,
                            isSelected: viewModel.selectedCategories.contains(category),
                            multiplier: viewModel.categoryMultipliers[category] ?? 1.0,
                            pointType: viewModel.categoryPointTypes[category] ?? .cashBack,
                            onToggle: { isSelected in
                                viewModel.toggleCategory(category, isSelected: isSelected)
                            },
                            onMultiplierChange: { multiplier in
                                viewModel.updateMultiplier(category, multiplier: multiplier)
                            },
                            onPointTypeChange: { pointType in
                                viewModel.updatePointType(category, pointType: pointType)
                            }
                        )
                    }
                }
                
                if !viewModel.selectedCategories.isEmpty {
                    Section("Spending Limits") {
                        Text("Set quarterly/annual spending limits for bonus categories")
                            .foregroundColor(.secondary)
                        
                        ForEach(viewModel.selectedCategories.sorted(by: { $0.displayName < $1.displayName }), id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(.blue)
                                    .frame(width: 20)
                                
                                Text(category.displayName)
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                TextField("Limit", value: Binding(
                                    get: { viewModel.categoryLimits[category] ?? 0 },
                                    set: { viewModel.categoryLimits[category] = $0 }
                                ), format: .currency(code: "USD"))
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                                .frame(width: 120)
                            }
                        }
                    }
                }
                
                Section("Quarterly Bonus (Optional)") {
                    Toggle("Has Quarterly Bonus", isOn: $viewModel.hasQuarterlyBonus)
                    
                    if viewModel.hasQuarterlyBonus {
                        Picker("Quarter", selection: $viewModel.quarterlyBonusQuarter) {
                            ForEach(1...4, id: \.self) { quarter in
                                Text("Q\(quarter)").tag(quarter)
                            }
                        }
                        
                        Picker("Bonus Category", selection: $viewModel.quarterlyBonusCategory) {
                            ForEach(SpendingCategory.allCases, id: \.self) { category in
                                Text(category.displayName).tag(category)
                            }
                        }
                        
                        HStack {
                            Text("Multiplier:")
                            Spacer()
                            TextField("Multiplier", value: $viewModel.quarterlyBonusMultiplier, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                                .frame(width: 80)
                            Text("x")
                        }
                        
                        HStack {
                            Text("Limit:")
                            Spacer()
                            TextField("Limit", value: $viewModel.quarterlyBonusLimit, format: .currency(code: "USD"))
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                                .frame(width: 120)
                        }
                        
                        Picker("Point Type", selection: $viewModel.quarterlyBonusPointType) {
                            ForEach(PointType.allCases, id: \.self) { pointType in
                                Text(pointType.displayName).tag(pointType)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Credit Card")
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
                            if viewModel.errorMessage == nil {
                                dismiss()
                            } else {
                                showingError = true
                            }
                        }
                    }
                    .disabled(viewModel.cardName.isEmpty)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
        }
    }
}

#Preview {
    AddCardView()
}