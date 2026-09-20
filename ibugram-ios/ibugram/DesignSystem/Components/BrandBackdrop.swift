import SwiftUI

/// Shared backdrop for the unauthenticated and onboarding flows.
struct BrandBackdrop: View {
    @Environment(\.theme) private var theme

    var body: some View {
        ZStack {
            theme.colors.background
            LinearGradient(
                colors: [theme.colors.brand.opacity(0.18), .clear],
                startPoint: .top,
                endPoint: .center
            )
            Circle()
                .fill(theme.colors.brand.opacity(0.10))
                .frame(width: 420, height: 420)
                .blur(radius: 60)
                .offset(x: 140, y: -260)
            Circle()
                .fill(theme.colors.accent.opacity(0.10))
                .frame(width: 300, height: 300)
                .blur(radius: 70)
                .offset(x: -150, y: 300)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

#Preview("Backdrop") {
    BrandBackdrop()
}

#Preview("Backdrop · dark") {
    BrandBackdrop()
        .preferredColorScheme(.dark)
}
