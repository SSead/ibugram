import SwiftUI

struct TypingIndicatorView: View {
    let label: String

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: theme.spacing.xs) {
            Image(systemName: "ellipsis.bubble")
                .foregroundStyle(theme.colors.brand)
            Text(label)
                .font(theme.typography.footnote)
                .foregroundStyle(theme.colors.textSecondary)
            Spacer()
        }
        .padding(.horizontal, theme.spacing.screenMargin)
        .padding(.vertical, theme.spacing.xxs)
        .accessibilityLabel(label)
    }
}

#Preview("Typing") {
    TypingIndicatorView(label: "Leila Marković is typing…")
}
