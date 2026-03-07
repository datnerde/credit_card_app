import SwiftUI
import Foundation

// MARK: - Onboarding

struct SimpleOnboardingView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                colors: [Color(hex: "0A0A1A"), Color(hex: "1A1A2E")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Animated card stack
                ZStack {
                    CreditCardVisualView(cardType: .chaseSapphireReserve, cardName: "Chase Sapphire", size: .compact)
                        .rotationEffect(.degrees(-8))
                        .offset(x: -20, y: 10)
                        .opacity(0.7)
                    CreditCardVisualView(cardType: .amexGold, cardName: "Amex Gold", size: .compact)
                        .rotationEffect(.degrees(5))
                        .offset(x: 20, y: -10)
                }

                VStack(spacing: 12) {
                    Text("Swipe Smart")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)

                    Text("Pick a category. See your best card.\nMaximize every purchase.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "0A0A1A"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "00D09C"), Color(hex: "00E6AC")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Main App

struct ContentView: View {
    @EnvironmentObject var serviceContainer: AppServiceContainer
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showingOnboarding = false

    private let accentTeal = Color(hex: "00D09C")

    var body: some View {
        TabView {
            SmartPayView()
                .tabItem {
                    Image(systemName: "bolt.fill")
                    Text("Pay")
                }

            CardListView()
                .environmentObject(serviceContainer)
                .tabItem {
                    Image(systemName: "wallet.pass.fill")
                    Text("Wallet")
                }

            SettingsView()
                .environmentObject(serviceContainer)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
        }
        .accentColor(accentTeal)
        .onAppear {
            if !hasCompletedOnboarding {
                showingOnboarding = true
            }
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
