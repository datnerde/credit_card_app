import SwiftUI

// This file tests that all components compile correctly
struct TestCompilationView: View {
    var body: some View {
        TabView {
            // Test ChatView compilation
            TestChatView()
                .tabItem {
                    Image(systemName: "message")
                    Text("Chat Test")
                }
            
            // Test CardListView compilation
            TestCardListView()
                .tabItem {
                    Image(systemName: "creditcard")
                    Text("Cards Test")
                }
            
            // Test SettingsView compilation
            TestSettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings Test")
                }
            
            // Test other components
            TestComponentsView()
                .tabItem {
                    Image(systemName: "wrench")
                    Text("Components Test")
                }
        }
    }
}

struct TestChatView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("ChatView Test")
                
                // Test ChatBubbleView
                ChatBubbleView(message: PreviewData.sampleMessage)
                
                // Test ChatInputView
                ChatInputView(text: .constant("Test message")) {
                    print("Send tapped")
                }
                
                // Test TypingIndicatorView
                TypingIndicatorView()
                
                // Test AIStatusIndicator
                AIStatusIndicator()
                
                // Test SmartSuggestionsView
                SmartSuggestionsView { suggestion in
                    print("Suggestion: \(suggestion)")
                }
            }
            .navigationTitle("Chat Test")
        }
    }
}

struct TestCardListView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack {
                    Text("CardListView Test")
                    
                    ForEach(PreviewData.sampleCards) { card in
                        CardRowView(card: card) {
                            print("Card tapped: \(card.name)")
                        }
                        .padding(.horizontal)
                    }
                    
                    // Test EmptyStateView
                    EmptyStateView(
                        title: "Test Empty State",
                        message: "This is a test empty state",
                        buttonTitle: "Test Action"
                    ) {
                        print("Empty state action")
                    }
                    
                    // Test LoadingView
                    LoadingView()
                }
            }
            .navigationTitle("Cards Test")
        }
    }
}

struct TestSettingsView: View {
    var body: some View {
        NavigationView {
            Form {
                Section("Settings Test") {
                    Text("Testing SettingsView compilation")
                    
                    // Test point system selection
                    ForEach(PointType.allCases, id: \.self) { pointType in
                        HStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 12, height: 12)
                            Text(pointType.displayName)
                            Spacer()
                        }
                    }
                    
                    // Test language selection
                    ForEach(Language.allCases, id: \.self) { language in
                        Text(language.displayName)
                    }
                }
                
                Section("Export Test") {
                    ExportDataView(data: "Test export data")
                }
            }
            .navigationTitle("Settings Test")
        }
    }
}

struct TestComponentsView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    Text("Component Tests")
                        .font(.title)
                    
                    // Test OnboardingView
                    Text("Onboarding Components")
                        .font(.headline)
                    
                    OnboardingPageView(page: OnboardingPage.allPages.first!)
                        .frame(height: 300)
                    
                    // Test RewardCategoryRow
                    Text("Reward Category Row")
                        .font(.headline)
                    
                    RewardCategoryRow(
                        category: .groceries,
                        isSelected: true,
                        multiplier: 4.0,
                        pointType: .membershipRewards,
                        onToggle: { _ in },
                        onMultiplierChange: { _ in },
                        onPointTypeChange: { _ in }
                    )
                    
                    // Test AddCardView components
                    Text("Add Card Components")
                        .font(.headline)
                    
                    VStack {
                        ForEach(SpendingCategory.allCases.prefix(5), id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(.blue)
                                Text(category.displayName)
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Components Test")
        }
    }
}

// Test ViewModels
struct TestViewModelView: View {
    @StateObject private var chatViewModel = ChatViewModel.mock()
    @StateObject private var cardListViewModel = CardListViewModel.mock()
    @StateObject private var addCardViewModel = AddCardViewModel.mock()
    @StateObject private var settingsViewModel = SettingsViewModel.mock()
    
    var body: some View {
        VStack {
            Text("ViewModel Tests")
                .font(.title)
            
            Text("Chat Messages: \(chatViewModel.messages.count)")
            Text("Cards: \(cardListViewModel.cards.count)")
            Text("Card Name: \(addCardViewModel.cardName)")
            Text("Preferred Points: \(settingsViewModel.userPreferences.preferredPointSystem.displayName)")
            
            Button("Test Chat Send") {
                chatViewModel.inputText = "Test message"
                chatViewModel.sendMessage()
            }
            
            Button("Test Card Load") {
                cardListViewModel.loadCards()
            }
            
            Button("Test Add Card") {
                addCardViewModel.cardName = "Test Card"
                addCardViewModel.selectedCategories.insert(.groceries)
                Task {
                    await addCardViewModel.saveCard()
                }
            }
            
            Button("Test Settings Save") {
                settingsViewModel.updatePreferredPointSystem(.ultimateRewards)
            }
        }
        .padding()
    }
}

#Preview("Main Test") {
    TestCompilationView()
        .environmentObject(ServiceContainer.shared)
}

#Preview("ViewModels Test") {
    TestViewModelView()
}