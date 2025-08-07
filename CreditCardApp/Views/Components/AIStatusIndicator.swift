import SwiftUI

struct AIStatusIndicator: View {
    @StateObject private var deviceCompatibility = DeviceCompatibilityManager.shared
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: deviceCompatibility.isAppleIntelligenceAvailable ? "brain.head.profile" : "cpu")
                .font(.caption)
                .foregroundColor(deviceCompatibility.statusColor)
            
            Text(deviceCompatibility.statusDescription)
                .font(.caption)
                .foregroundColor(deviceCompatibility.statusColor)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(deviceCompatibility.statusColor.opacity(0.1))
        .clipShape(Capsule())
    }
}

struct SmartSuggestionsView: View {
    let onSuggestionTap: (String) -> Void
    
    private let suggestions = [
        "Groceries at Costco",
        "Dining out tonight",
        "Booking a flight",
        "Gas station fill-up",
        "Online shopping",
        "Hotel stay"
    ]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(action: {
                        onSuggestionTap("What card should I use for \(suggestion.lowercased())?")
                    }) {
                        Text(suggestion)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .foregroundColor(.primary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    VStack {
        AIStatusIndicator()
        SmartSuggestionsView { suggestion in
            print("Tapped: \(suggestion)")
        }
    }
}