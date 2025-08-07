import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @Environment(\.dismiss) private var dismiss
    
    private let pages = OnboardingPage.allPages
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 20)
                
                // Content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                
                // Navigation buttons
                HStack(spacing: 16) {
                    if currentPage > 0 {
                        Button("Back") {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                        .foregroundColor(.blue)
                    } else {
                        Spacer()
                    }
                    
                    Spacer()
                    
                    Button(currentPage == pages.count - 1 ? "Get Started" : "Next") {
                        if currentPage == pages.count - 1 {
                            completeOnboarding()
                        } else {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .foregroundColor(.gray)
                }
            }
        }
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
        dismiss()
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon/Image
            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            if let features = page.features {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(features, id: \.self) { feature in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                            
                            Text(feature)
                                .font(.subheadline)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 32)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let icon: String
    let features: [String]?
    
    static let allPages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to Credit Card AI",
            description: "Your personal assistant for maximizing credit card rewards with Apple Intelligence.",
            icon: "brain.head.profile",
            features: nil
        ),
        OnboardingPage(
            title: "Smart Recommendations",
            description: "Ask which card to use and get instant, personalized recommendations.",
            icon: "creditcard.and.123",
            features: [
                "Natural language queries",
                "Real-time spending analysis",
                "Contextual card suggestions",
                "Limit tracking and alerts"
            ]
        ),
        OnboardingPage(
            title: "Apple Intelligence",
            description: "Powered by on-device AI for privacy and speed.",
            icon: "cpu",
            features: [
                "100% private processing",
                "Lightning-fast responses",
                "Context-aware conversations",
                "No data leaves your device"
            ]
        ),
        OnboardingPage(
            title: "Let's Get Started",
            description: "Add your credit cards to begin getting personalized recommendations.",
            icon: "plus.circle.fill",
            features: nil
        )
    ]
}

#Preview {
    OnboardingView()
}