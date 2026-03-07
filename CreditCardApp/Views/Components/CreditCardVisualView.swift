import SwiftUI

enum CardVisualSize {
    case compact  // ~160x100, for carousels and lists
    case full     // ~320x200, for detail views
}

struct CreditCardVisualView: View {
    let cardType: CardType
    let cardName: String
    let size: CardVisualSize

    init(cardType: CardType, cardName: String, size: CardVisualSize = .compact) {
        self.cardType = cardType
        self.cardName = cardName
        self.size = size
    }

    private var style: CardVisualStyle { cardType.cardVisual }

    private var gradient: LinearGradient {
        LinearGradient(
            colors: style.gradientColors.map { Color(hex: $0) },
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var textColor: Color { Color(hex: style.textColor) }

    private var cardWidth: CGFloat { size == .full ? 320 : 160 }
    private var cardHeight: CGFloat { size == .full ? 200 : 100 }

    var body: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: size == .full ? 16 : 12)
                .fill(gradient)
                .shadow(color: style.gradientColors.first.map { Color(hex: $0).opacity(0.4) } ?? .black.opacity(0.2),
                        radius: size == .full ? 12 : 6, y: size == .full ? 6 : 3)

            // Subtle shine overlay
            RoundedRectangle(cornerRadius: size == .full ? 16 : 12)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.15), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )

            // Card content
            VStack(alignment: .leading, spacing: 0) {
                // Top row: logo + chip
                HStack {
                    Image(systemName: style.logoSymbol)
                        .font(size == .full ? .title2 : .caption)
                        .foregroundColor(textColor.opacity(0.9))

                    Spacer()

                    // Chip
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.yellow.opacity(0.7))
                        .frame(width: size == .full ? 30 : 18,
                               height: size == .full ? 22 : 14)
                }

                Spacer()

                // Card name
                Text(cardName)
                    .font(size == .full ? .headline : .caption2)
                    .fontWeight(.bold)
                    .foregroundColor(textColor)
                    .lineLimit(1)

                // Card type
                Text(cardType.displayName)
                    .font(size == .full ? .caption : .system(size: 8))
                    .foregroundColor(textColor.opacity(0.7))
                    .lineLimit(1)
            }
            .padding(size == .full ? 20 : 10)
        }
        .frame(width: cardWidth, height: cardHeight)
    }
}

#Preview {
    VStack(spacing: 20) {
        CreditCardVisualView(cardType: .amexGold, cardName: "Amex Gold", size: .full)
        HStack(spacing: 12) {
            CreditCardVisualView(cardType: .chaseSapphireReserve, cardName: "Chase Sapphire Reserve", size: .compact)
            CreditCardVisualView(cardType: .robinhoodGold, cardName: "Robinhood Gold", size: .compact)
        }
    }
    .padding()
}
