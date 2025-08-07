import SwiftUI
import Foundation

struct ChatBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.sender == .user {
                Spacer()
                userBubble
            } else {
                assistantBubble
                Spacer()
            }
        }
    }
    
    private var userBubble: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text(message.content)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .trailing)
            
            if let recommendations = message.cardRecommendations, !recommendations.isEmpty {
                VStack(alignment: .trailing, spacing: 8) {
                    ForEach(recommendations) { recommendation in
                        CardRecommendationView(recommendation: recommendation)
                    }
                }
            }
        }
    }
    
    private var assistantBubble: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .leading)
                    
                    if let recommendations = message.cardRecommendations, !recommendations.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(recommendations) { recommendation in
                                CardRecommendationView(recommendation: recommendation)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct CardRecommendationView: View {
    let recommendation: CardRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.blue)
                
                Text(recommendation.cardName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if recommendation.rank == 1 {
                    Text("1st Choice")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                } else {
                    Text("2nd Choice")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
            
            HStack {
                Text("\(recommendation.multiplier, specifier: "%.1f")x")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text(recommendation.pointType.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if recommendation.isLimitReached {
                    Text("Limit Reached")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                } else if recommendation.limit > 0 {
                    ProgressView(value: recommendation.currentSpending, total: recommendation.limit)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(width: 60)
                }
            }
            
            if recommendation.limit > 0 {
                HStack {
                    Text("$\(recommendation.currentSpending, specifier: "%.0f") / $\(recommendation.limit, specifier: "%.0f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if recommendation.isLimitReached {
                        Text("⚠️ Limit reached")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else if recommendation.currentSpending / recommendation.limit >= 0.85 {
                        Text("⚠️ Almost at limit")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Text(recommendation.reasoning)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct TypingIndicatorView: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "brain.head.profile")
                .foregroundColor(.blue)
                .font(.title2)
            
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                        .scaleEffect(1.0 + animationOffset)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: animationOffset
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .onAppear {
            animationOffset = 0.3
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ChatBubbleView(message: ChatMessage(
            content: "I'm buying groceries at Whole Foods",
            sender: .user
        ))
        
        ChatBubbleView(message: ChatMessage(
            content: "I recommend using your Amex Gold card for groceries at Whole Foods.",
            sender: .assistant,
            cardRecommendations: [
                CardRecommendation(
                    cardId: UUID(),
                    cardName: "Amex Gold",
                    category: .groceries,
                    multiplier: 4.0,
                    pointType: .membershipRewards,
                    reasoning: "Amex Gold offers 4x MR points on groceries, and you have $200 remaining in your limit.",
                    currentSpending: 800,
                    limit: 1000,
                    isLimitReached: false,
                    rank: 1
                )
            ]
        ))
        
        TypingIndicatorView()
    }
    .padding()
} 