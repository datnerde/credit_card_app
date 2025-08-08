import SwiftUI

struct TypingIndicatorView: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Image(systemName: "brain.head.profile")
                .foregroundColor(.blue)
                .font(.title2)
            
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animationPhase == index ? 1.3 : 0.8)
                        .opacity(animationPhase == index ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: animationPhase
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Spacer()
        }
        .padding(.horizontal)
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            withAnimation {
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

#Preview {
    TypingIndicatorView()
        .padding()
}