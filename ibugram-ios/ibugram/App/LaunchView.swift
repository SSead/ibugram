import SwiftUI

struct LaunchView: View {
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: theme.spacing.lg) {
            BrandWordmark(height: 40)
            ProgressView()
                .tint(theme.colors.brand)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.background)
        .accessibilityLabel("Loading IBUgram")
    }
}

#Preview("Launch") {
    LaunchView()
}

#Preview("Launch · dark") {
    LaunchView()
        .preferredColorScheme(.dark)
}
