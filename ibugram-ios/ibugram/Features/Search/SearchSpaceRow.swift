import SwiftUI

struct SearchSpaceRow: View {
    let space: SpaceSummary
    var onOpen: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: theme.spacing.sm) {
                AvatarView(url: space.avatarUrl, displayName: space.name, size: .medium)
                VStack(alignment: .leading, spacing: theme.spacing.hairline) {
                    HStack(spacing: theme.spacing.xxs) {
                        Text(space.name)
                            .font(theme.typography.bodyEmphasis)
                            .foregroundStyle(theme.colors.textPrimary)
                            .lineLimit(1)
                        if space.isOfficial {
                            TagChip(title: "Official", icon: "checkmark.seal.fill", style: .accent)
                        }
                    }
                    Text("\(space.memberCount) members")
                        .font(theme.typography.footnote)
                        .foregroundStyle(theme.colors.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, theme.spacing.screenMargin)
            .padding(.vertical, theme.spacing.xs)
        }
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        var parts = [space.name, "\(space.memberCount) members"]
        if space.isOfficial { parts.insert("Official", at: 1) }
        return parts.joined(separator: ", ")
    }
}

#Preview("Space row") {
    SearchSpaceRow(space: SearchFixtures.roboticsSpace, onOpen: {})
}
