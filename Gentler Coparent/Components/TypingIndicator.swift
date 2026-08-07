import SwiftUI

// MARK: - Lightweight typing dots (TimelineView — no Timer / DispatchQueue thrash)
struct TypingIndicator: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.12, paused: false)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { index in
                    let phase = (sin(t * 4.2 + Double(index) * 0.55) + 1) / 2
                    Circle()
                        .fill(GCPTheme.primary.opacity(0.35 + phase * 0.55))
                        .frame(width: 7, height: 7)
                        .scaleEffect(0.65 + phase * 0.45)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 18,
                bottomLeadingRadius: 6,
                bottomTrailingRadius: 18,
                topTrailingRadius: 18,
                style: .continuous
            )
            .fill(GCPTheme.typingFill)
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 18,
                bottomLeadingRadius: 6,
                bottomTrailingRadius: 18,
                topTrailingRadius: 18,
                style: .continuous
            )
            .strokeBorder(GCPTheme.assistantBubbleStroke, lineWidth: 1)
        )
        .accessibilityLabel("Gentler Coparent is typing")
    }
}