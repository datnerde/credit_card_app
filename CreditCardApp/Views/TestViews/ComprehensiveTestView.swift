import SwiftUI

struct ComprehensiveTestView: View {
    @State private var currentTest = 0
    
    private let testScreens = [
        "Main App Flow",
        "Chat Interface",
        "Card Management",
        "Settings Panel",
        "Add Card Flow",
        "Onboarding Flow"
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                // Test selector
                Picker("Test Screen", selection: $currentTest) {
                    ForEach(0..<testScreens.count, id: \.self) { index in
                        Text(testScreens[index]).tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Test content
                Group {
                    switch currentTest {
                    case 0:
                        MainAppFlowTest()
                    case 1:
                        ChatInterfaceTest()
                    case 2:
                        CardManagementTest()
                    case 3:
                        SettingsPanelTest()
                    case 4:
                        AddCardFlowTest()
                    case 5:
                        OnboardingFlowTest()
                    default:
                        Text("Invalid test selection")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Spacer()
            }
            .navigationTitle("UI Test Suite")
        }
    }
}

struct MainAppFlowTest: View {
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
        .environmentObject(ServiceContainer.shared)
    }
}

struct ChatInterfaceTest: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Chat Interface Components")
                .font(.title2)
                .fontWeight(.bold)
            
            // AI Status Indicator
            AIStatusIndicator()
            
            // Sample chat bubbles
            VStack(alignment: .leading, spacing: 12) {
                ChatBubbleView(message: ChatMessage(
                    content: "Hello! How can I help you today?",
                    sender: .assistant
                ))
                
                ChatBubbleView(message: ChatMessage(
                    content: "What card should I use for groceries?",
                    sender: .user
                ))
                
                ChatBubbleView(message: PreviewData.sampleMessage)
            }
            .padding()
            
            // Typing indicator
            TypingIndicatorView()
            
            // Smart suggestions
            SmartSuggestionsView { suggestion in
                print("Selected: \(suggestion)")
            }
            
            // Chat input
            ChatInputView(text: .constant("")) {
                print("Send message")
            }
        }
        .padding()
    }
}

struct CardManagementTest: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Card Management Components")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Sample cards
                ForEach(PreviewData.sampleCards) { card in
                    CardRowView(card: card) {
                        print("Card tapped: \(card.name)")
                    }
                }
                
                // Empty state
                EmptyStateView(
                    title: "No Cards",
                    message: "Add your first credit card to get started",
                    buttonTitle: "Add Card"
                ) {
                    print("Add card tapped")
                }
                
                // Loading view
                LoadingView()
            }
            .padding()
        }
    }
}

struct SettingsPanelTest: View {
    @State private var selectedPointType: PointType = .membershipRewards
    @State private var selectedLanguage: Language = .english
    @State private var alertThreshold: Double = 0.85
    @State private var notificationsEnabled: Bool = true
    
    var body: some View {
        Form {
            Section("Point System Preferences") {
                ForEach(PointType.allCases, id: \.self) { pointType in
                    HStack {
                        Circle()
                            .fill(Color(pointType.color))
                            .frame(width: 12, height: 12)
                        
                        Text(pointType.displayName)
                        
                        Spacer()
                        
                        if selectedPointType == pointType {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedPointType = pointType
                    }
                }
            }
            
            Section("Alert Settings") {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Alert Threshold: \(Int(alertThreshold * 100))%")
                    
                    Slider(value: $alertThreshold, in: 0.5...1.0, step: 0.05)
                }
            }
            
            Section("Language") {
                ForEach(Language.allCases, id: \.self) { language in
                    HStack {
                        Text(language.displayName)
                        Spacer()
                        if selectedLanguage == language {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedLanguage = language
                    }
                }
            }
        }
    }
}

struct AddCardFlowTest: View {
    @State private var selectedCategories: Set<SpendingCategory> = []
    @State private var showingAddCard = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Add Card Flow Components")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Button("Show Add Card View") {
                    showingAddCard = true
                }
                .buttonStyle(.borderedProminent)
                
                Text("Reward Category Selection:")
                    .font(.headline)
                
                ForEach(SpendingCategory.allCases.prefix(8), id: \.self) { category in
                    RewardCategoryRow(
                        category: category,
                        isSelected: selectedCategories.contains(category),
                        multiplier: 2.0,
                        pointType: .membershipRewards,
                        onToggle: { isSelected in
                            if isSelected {
                                selectedCategories.insert(category)
                            } else {
                                selectedCategories.remove(category)
                            }
                        },
                        onMultiplierChange: { _ in },
                        onPointTypeChange: { _ in }
                    )
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingAddCard) {
            AddCardView()
        }
    }
}

struct OnboardingFlowTest: View {
    @State private var showingOnboarding = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Onboarding Flow")
                .font(.title2)
                .fontWeight(.bold)
            
            Button("Show Full Onboarding") {
                showingOnboarding = true
            }
            .buttonStyle(.borderedProminent)
            
            Text("Sample Onboarding Page:")
                .font(.headline)
            
            OnboardingPageView(page: OnboardingPage.allPages[1])
                .frame(height: 400)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView()
        }
    }
}

#Preview {
    ComprehensiveTestView()
        .environmentObject(ServiceContainer.shared)
}

// Individual component previews for testing
#Preview("Chat Bubble") {
    ChatBubbleView(message: PreviewData.sampleMessage)
        .padding()
}

#Preview("Card Row") {
    CardRowView(card: PreviewData.sampleCard) {
        print("Card tapped")
    }
    .padding()
}

#Preview("AI Status") {
    AIStatusIndicator()
        .padding()
}

#Preview("Reward Category") {
    RewardCategoryRow(
        category: .groceries,
        isSelected: true,
        multiplier: 4.0,
        pointType: .membershipRewards,
        onToggle: { _ in },
        onMultiplierChange: { _ in },
        onPointTypeChange: { _ in }
    )
    .padding()
}

#Preview("Smart Suggestions") {
    SmartSuggestionsView { suggestion in
        print("Suggestion: \(suggestion)")
    }
    .padding()
}