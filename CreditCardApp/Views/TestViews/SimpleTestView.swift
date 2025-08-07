import SwiftUI
import Foundation

// Simplified test view to verify basic compilation
struct SimpleTestView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Simple Test View")
                    .font(.title)
                
                // Test basic data model creation
                Text("Testing Data Models...")
                
                Button("Test Models") {
                    testDataModels()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Test Services") {
                    testServices()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Test ViewModels") {
                    testViewModels()
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Build Test")
        }
    }
    
    private func testDataModels() {
        let card = CreditCard(name: "Test Card", cardType: .amexGold)
        let message = ChatMessage(content: "Hello", sender: .user)
        let preferences = UserPreferences()
        
        print("✅ Data models work: \(card.name), \(message.content), \(preferences.preferredPointSystem)")
    }
    
    private func testServices() {
        let container = ServiceContainer.shared
        print("✅ Services work: \(type(of: container.dataManager))")
    }
    
    private func testViewModels() {
        // Test that ViewModelFactory works
        let chatVM = ViewModelFactory.makeChatViewModel()
        let cardListVM = ViewModelFactory.makeCardListViewModel()
        let addCardVM = ViewModelFactory.makeAddCardViewModel()
        let settingsVM = ViewModelFactory.makeSettingsViewModel()
        
        print("✅ ViewModels work: \(type(of: chatVM)), \(type(of: cardListVM)), \(type(of: addCardVM)), \(type(of: settingsVM))")
    }
}

#Preview {
    SimpleTestView()
}