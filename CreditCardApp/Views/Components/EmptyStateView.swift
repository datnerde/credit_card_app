import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    let buttonTitle: String?
    let action: (() -> Void)?
    
    init(title: String, message: String, buttonTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wallet.pass")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "00D09C").opacity(0.5))

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if let buttonTitle = buttonTitle, let action = action {
                Button(action: action) {
                    Text(buttonTitle)
                        .font(.headline)
                        .foregroundColor(Color(hex: "0A0A1A"))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(hex: "00D09C"))
                        .cornerRadius(12)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    EmptyStateView(
        title: "No Cards Added",
        message: "Add your credit cards to get personalized recommendations",
        buttonTitle: "Add Card",
        action: { print("Add card tapped") }
    )
}