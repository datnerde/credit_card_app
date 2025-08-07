import SwiftUI
import Foundation

// Minimal version of ContentView for testing
struct MinimalContentView: View {
    var body: some View {
        TabView {
            Text("Chat View")
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Chat")
                }
            
            Text("Cards View")
                .tabItem {
                    Image(systemName: "creditcard.fill")
                    Text("My Cards")
                }
            
            Text("Settings View")
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .onAppear {
            print("Minimal ContentView appeared - basic functionality works!")
        }
    }
}

#Preview {
    MinimalContentView()
}