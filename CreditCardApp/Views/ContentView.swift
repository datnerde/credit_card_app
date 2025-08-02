import SwiftUI

struct ContentView: View {
    @StateObject private var chatViewModel = ViewModelFactory.makeChatViewModel()
    @StateObject private var cardListViewModel = ViewModelFactory.makeCardListViewModel()
    @StateObject private var settingsViewModel = ViewModelFactory.makeSettingsViewModel()
    
    var body: some View {
        TabView {
            ChatView()
                .environmentObject(chatViewModel)
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Chat")
                }
            
            CardListView()
                .environmentObject(cardListViewModel)
                .tabItem {
                    Image(systemName: "creditcard.fill")
                    Text("My Cards")
                }
            
            SettingsView()
                .environmentObject(settingsViewModel)
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .accentColor(.blue)
        .onAppear {
            // Load sample data on first launch
            if cardListViewModel.cards.isEmpty {
                cardListViewModel.loadSampleData()
            }
        }
    }
}

// MARK: - Placeholder Views

struct ChatView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            ChatBubbleView(message: message)
                        }
                        
                        if viewModel.isTyping {
                            TypingIndicatorView()
                        }
                    }
                    .padding()
                }
                
                ChatInputView(
                    text: $viewModel.inputText,
                    onSend: viewModel.sendMessage
                )
            }
            .navigationTitle("Credit Card Assistant")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct CardListView: View {
    @EnvironmentObject var viewModel: CardListViewModel
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.filteredCards) { card in
                    CardRowView(card: card)
                }
                .onDelete(perform: deleteCards)
            }
            .navigationTitle("My Cards")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Card") {
                        viewModel.showingAddCard = true
                    }
                }
            }
        }
    }
    
    private func deleteCards(offsets: IndexSet) {
        for index in offsets {
            let card = viewModel.filteredCards[index]
            viewModel.deleteCard(card)
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var viewModel: SettingsViewModel
    
    var body: some View {
        NavigationView {
            List {
                Section("Preferences") {
                    HStack {
                        Text("Preferred Point System")
                        Spacer()
                        Text(viewModel.userPreferences.preferredPointSystem.displayName)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Alert Threshold")
                        Spacer()
                        Text("\(Int(viewModel.userPreferences.alertThreshold * 100))%")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Language")
                        Spacer()
                        Text(viewModel.userPreferences.language.displayName)
                            .foregroundColor(.secondary)
                    }
                    
                    Toggle("Notifications", isOn: $viewModel.userPreferences.notificationsEnabled)
                    Toggle("Auto Update Spending", isOn: $viewModel.userPreferences.autoUpdateSpending)
                }
                
                Section("Data Management") {
                    Button("Export Data") {
                        viewModel.exportAllData()
                    }
                    
                    Button("Reset All Data") {
                        viewModel.showingResetAlert = true
                    }
                    .foregroundColor(.red)
                }
                
                Section("App Info") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(viewModel.getAppVersion())
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Supporting Views

struct ChatBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.sender == .user {
                Spacer()
                Text(message.content)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            } else {
                Text(message.content)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                Spacer()
            }
        }
    }
}

struct TypingIndicatorView: View {
    var body: some View {
        HStack {
            Text("🤖 is typing...")
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
            Spacer()
        }
    }
}

struct ChatInputView: View {
    @Binding var text: String
    let onSend: () -> Void
    
    var body: some View {
        HStack {
            TextField("Type your question...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Send") {
                onSend()
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
    }
}

struct CardRowView: View {
    let card: CreditCard
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(card.name)
                .font(.headline)
            
            Text(card.cardType.displayName)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if !card.spendingLimits.isEmpty {
                Text("\(card.spendingLimits.count) spending limits")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
} 