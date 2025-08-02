import SwiftUI

struct ContentView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    
    var body: some View {
        TabView {
            ChatView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Chat")
                }
            
            CardListView()
                .tabItem {
                    Image(systemName: "creditcard.fill")
                    Text("My Cards")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .accentColor(.blue)
        .onAppear {
            // Load sample data on first launch
            Task {
                do {
                    let cards = try await serviceContainer.dataManager.fetchCards()
                    if cards.isEmpty {
                        try await serviceContainer.dataManager.loadSampleData()
                    }
                } catch {
                    print("Error loading sample data: \(error)")
                }
            }
        }
    }
}



#Preview {
    ContentView()
        .environmentObject(ServiceContainer.shared)
} 