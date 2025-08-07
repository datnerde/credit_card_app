// BuildTest.swift - Simple compilation test file
import SwiftUI
import Foundation

// Test that all major types compile
struct BuildTest {
    // Test data models
    func testModels() {
        let card = CreditCard(name: "Test", cardType: .amexGold)
        let message = ChatMessage(content: "Test", sender: .user)
        let preferences = UserPreferences()
        let category = SpendingCategory.groceries
        let pointType = PointType.cashBack
        let language = Language.english
        
        print("Models compile: \(card.id), \(message.id), \(preferences.preferredPointSystem), \(category.displayName), \(pointType.displayName), \(language.displayName)")
    }
    
    // Test services
    func testServices() {
        let dataManager = MockDataManager()
        let engine = RecommendationEngine()
        let nlp = NLPProcessor()
        let notifications = NotificationService()
        let analytics = AnalyticsService()
        let container = ServiceContainer.shared
        
        print("Services compile: \(type(of: dataManager)), \(type(of: engine)), \(type(of: nlp)), \(type(of: notifications)), \(type(of: analytics)), \(type(of: container))")
    }
    
    // Test ViewModels
    func testViewModels() {
        let chatVM = ChatViewModel.mock()
        let cardListVM = CardListViewModel.mock()
        let addCardVM = AddCardViewModel.mock()
        let settingsVM = SettingsViewModel.mock()
        
        print("ViewModels compile: \(type(of: chatVM)), \(type(of: cardListVM)), \(type(of: addCardVM)), \(type(of: settingsVM))")
    }
    
    // Test that everything works together
    func runAllTests() {
        testModels()
        testServices()
        testViewModels()
        print("✅ All build tests passed!")
    }
}

// SwiftUI view for testing UI compilation
struct BuildTestView: View {
    var body: some View {
        VStack {
            Text("Build Test View")
            
            // Test that main app components can be instantiated
            ContentView()
                .environmentObject(ServiceContainer.shared)
                .frame(height: 300)
        }
        .onAppear {
            BuildTest().runAllTests()
        }
    }
}

#Preview {
    BuildTestView()
}