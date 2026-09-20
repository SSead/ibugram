import SwiftUI
import IBUgramKit

struct SpaceRow: View {
    let space: Space
    var onOpen: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: theme.spacing.sm) {
                AvatarView(url: space.avatarResourceURL, displayName: space.name, size: .medium)
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
                    Text(subtitle)
                        .font(theme.typography.footnote)
                        .foregroundStyle(theme.colors.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.horizontal, theme.spacing.screenMargin)
            .padding(.vertical, theme.spacing.xs)
        }
        .accessibilityLabel(accessibilityLabel)
    }

    private var subtitle: String {
        "\(space.kind.title) · \(space.memberCount) members · \(space.visibility.title)"
    }

    private var accessibilityLabel: String {
        var parts = [space.name, space.kind.title, "\(space.memberCount) members", space.visibility.title]
        if space.isOfficial { parts.insert("Official", at: 1) }
        return parts.joined(separator: ", ")
    }
}

#Preview("Space row") {
    VStack {
        SpaceRow(space: SpaceFixtures.robotics, onOpen: {})
        SpaceRow(space: SpaceFixtures.engineering, onOpen: {})
        SpaceRow(space: SpaceFixtures.facultyCircle, onOpen: {})
    }
    .appContainer(.preview())
}
