import SwiftUI
import Foundation

struct ChatView: View {
    @StateObject private var viewModel = ViewModelFactory.makeChatViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                ChatBubbleView(message: message)
                                    .id(message.id)
                            }
                            
                            if viewModel.isTyping {
                                TypingIndicatorView()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                        }
                    }
                }
                
                // Chat input
                ChatInputView(
                    text: $viewModel.inputText,
                    onSend: viewModel.sendMessage
                )
            }
            .navigationTitle("Credit Card Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    AIStatusIndicator()
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        viewModel.clearChatHistory()
                    }
                    .foregroundColor(.red)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if viewModel.messages.isEmpty {
                    SmartSuggestionsView { suggestion in
                        viewModel.inputText = suggestion
                        viewModel.sendMessage()
                    }
                    .padding(Edge.Set.bottom, 8)
                }
            }
        }
        .onAppear {
            viewModel.loadChatHistory()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

#Preview {
    ChatView()
        .environmentObject(AppServiceContainer.shared)
} 