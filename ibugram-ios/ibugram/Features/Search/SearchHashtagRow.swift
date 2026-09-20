import SwiftUI
import IBUgramKit

struct SearchHashtagRow: View {
    let hashtag: Hashtag
    var onOpen: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: theme.spacing.sm) {
                Image(systemName: "number")
                    .font(theme.typography.headline)
                    .foregroundStyle(theme.colors.brand)
                    .frame(width: 44, height: 44)
                    .background(theme.colors.brandMuted, in: .circle)
                VStack(alignment: .leading, spacing: theme.spacing.hairline) {
                    Text(hashtag.displayTag)
                        .font(theme.typography.bodyEmphasis)
                        .foregroundStyle(theme.colors.textPrimary)
                    Text("\(hashtag.postCount) posts")
                        .font(theme.typography.footnote)
                        .foregroundStyle(theme.colors.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, theme.spacing.screenMargin)
            .padding(.vertical, theme.spacing.xs)
        }
        .accessibilityLabel("\(hashtag.displayTag), \(hashtag.postCount) posts")
    }
}

#Preview("Hashtag row") {
    SearchHashtagRow(hashtag: SearchFixtures.robotics, onOpen: {})
}
