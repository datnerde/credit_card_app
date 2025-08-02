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
                    Text("Select reward categories for this card")
                        .foregroundColor(.secondary)
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