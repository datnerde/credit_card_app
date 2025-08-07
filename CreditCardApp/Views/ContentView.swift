import SwiftUI
import Foundation

// Simple onboarding view to avoid scope issues
struct SimpleOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "creditcard.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Welcome to Credit Card AI")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Get personalized credit card recommendations with AI-powered insights.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button("Get Started") {
                dismiss()
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
        .padding()
    }
}

struct ContentView: View {
    @EnvironmentObject var serviceContainer: AppServiceContainer
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showingOnboarding = false
    
    var body: some View {
        TabView {
            ChatView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Chat")
                }
            
            CardListView()
                .environmentObject(serviceContainer)
                .tabItem {
                    Image(systemName: "creditcard.fill")
                    Text("My Cards")
                }
            
            SettingsView()
                .environmentObject(serviceContainer)
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .accentColor(.blue)
        .onAppear {
            // Show onboarding if not completed
            if !hasCompletedOnboarding {
                showingOnboarding = true
            }
            
            print("App appeared - service container available: \(type(of: serviceContainer))")
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            SimpleOnboardingView()
        }
    }
}



#Preview {
    ContentView()
        .environmentObject(AppServiceContainer.shared)
} 