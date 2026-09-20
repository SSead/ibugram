import SwiftUI
import IBUgramKit

struct FollowListRow: View {
    let user: User
    var showsFollowButton = true
    var onOpen: () -> Void
    var onToggleFollow: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: theme.spacing.sm) {
            Button(action: onOpen) {
                HStack(spacing: theme.spacing.sm) {
                    AvatarView(
                        url: user.avatarURL,
                        displayName: user.displayName,
                        size: .medium,
                        showsVerifiedBadge: user.role == .faculty || user.isVerified
                    )
                    VStack(alignment: .leading, spacing: theme.spacing.hairline) {
                        Text(user.displayName)
                            .font(theme.typography.bodyEmphasis)
                            .foregroundStyle(theme.colors.textPrimary)
                            .lineLimit(1)
                        Text("@\(user.username)")
                            .font(theme.typography.footnote)
                            .foregroundStyle(theme.colors.textSecondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(user.displayName), \(user.username)")

            if showsFollowButton {
                ProfileFollowButton(user: user, isCompact: true, onToggle: onToggleFollow)
            }
        }
        .padding(.horizontal, theme.spacing.screenMargin)
        .padding(.vertical, theme.spacing.xs)
    }
}

#Preview("Follow row") {
    VStack {
        FollowListRow(user: ProfileFixtures.followedStudent, onOpen: {}, onToggleFollow: {})
        FollowListRow(user: ProfileFixtures.unfollowedFaculty, onOpen: {}, onToggleFollow: {})
    }
}
