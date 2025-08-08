import SwiftUI

struct SmartSuggestionsView: View {
    let onSuggestionTapped: (String) -> Void
    
    private let suggestions = [
        "What card should I use for groceries?",
        "I'm buying gas, which card?",
        "Shopping at Amazon, best card?",
        "Dining out tonight, which card?",
        "Booking a flight, what card?",
        "Coffee shop purchase"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Try asking:")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        SuggestionChip(
                            text: suggestion,
                            onTap: { onSuggestionTapped(suggestion) }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color.gray.opacity(0.05))
    }
}

struct SuggestionChip: View {
    let text: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.subheadline)
                .foregroundColor(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SmartSuggestionsView { suggestion in
        print("Tapped: \(suggestion)")
    }
}