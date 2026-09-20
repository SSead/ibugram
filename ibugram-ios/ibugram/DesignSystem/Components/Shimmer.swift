import SwiftUI

extension View {
    func shimmering(isActive: Bool = true) -> some View {
        modifier(ShimmerModifier(isActive: isActive))
    }
}

private struct ShimmerModifier: ViewModifier {
    let isActive: Bool

    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay { if isActive && !reduceMotion { highlight } }
            .mask(content)
            .onAppear {
                guard isActive, !reduceMotion else { return }
                withAnimation(theme.motion.shimmer) { phase = 2 }
            }
    }

    private var highlight: some View {
        GeometryReader { proxy in
            LinearGradient(
                colors: [.clear, theme.colors.skeletonHighlight, .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: proxy.size.width * 0.6)
            .offset(x: phase * proxy.size.width)
            .blendMode(.plusLighter)
        }
        .allowsHitTesting(false)
    }
}
