import SwiftUI
import Foundation

// Use the main service container instead of duplicating
typealias AppServiceContainer = ServiceContainer

@main
struct CreditCardAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AppServiceContainer.shared)
        }
    }
} 