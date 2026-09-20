import SwiftUI

struct OfflineBanner: View {
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: theme.spacing.xs) {
            Image(systemName: "wifi.slash")
                .font(theme.typography.captionEmphasis)
            Text("Showing last saved feed")
                .font(theme.typography.captionEmphasis)
        }
        .foregroundStyle(theme.colors.textPrimary)
        .padding(.horizontal, theme.spacing.screenMargin)
        .padding(.vertical, theme.spacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.colors.warning.opacity(0.18))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Showing last saved feed. You are offline.")
    }
}

#Preview("Offline banner") {
    OfflineBanner()
}

#Preview("Offline banner · dark") {
    OfflineBanner()
        .preferredColorScheme(.dark)
}
