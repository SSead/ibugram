import SwiftUI

struct ProfileFollowButton: View {
    let user: User
    var isCompact = false
    var onToggle: () -> Void

    @Environment(\.theme) private var theme

    private var isFollowing: Bool { user.viewer?.isFollowing ?? false }
    private var isBlocked: Bool { user.viewer?.isBlocked ?? false }

    var body: some View {
        if isCompact {
            compactButton
        } else {
            prominentButton
        }
    }

    @ViewBuilder
    private var prominentButton: some View {
        if isBlocked {
            Button(title, action: onToggle)
                .buttonStyle(.ibuDestructive)
                .accessibilityHint(hint)
        } else if isFollowing {
            Button(title, action: onToggle)
                .buttonStyle(.ibuSecondary)
                .accessibilityHint(hint)
        } else {
            Button(title, action: onToggle)
                .buttonStyle(.ibuPrimary)
                .accessibilityHint(hint)
        }
    }

    private var compactButton: some View {
        Button(action: onToggle) {
            Text(title)
                .font(theme.typography.captionEmphasis)
                .padding(.horizontal, theme.spacing.sm)
                .padding(.vertical, theme.spacing.xxs)
                .foregroundStyle(compactForeground)
                .background(compactBackground, in: .rect(cornerRadius: theme.radii.sm))
        }
        .accessibilityLabel(title)
        .accessibilityHint(hint)
    }

    private var title: String {
        if isBlocked { return "Unblock" }
        return isFollowing ? "Following" : "Follow"
    }

    private var hint: String {
        if isBlocked { return "Unblock this account" }
        return isFollowing ? "Unfollow this account" : "Follow this account"
    }

    private var compactForeground: Color {
        if isBlocked { return theme.colors.destructive }
        return isFollowing ? theme.colors.brand : theme.colors.textOnBrand
    }

    private var compactBackground: Color {
        if isBlocked { return theme.colors.destructive.opacity(0.12) }
        return isFollowing ? theme.colors.brandMuted : theme.colors.brand
    }
}

#Preview("Follow button") {
    VStack(spacing: 16) {
        ProfileFollowButton(user: ProfileFixtures.unfollowedFaculty, onToggle: {})
        ProfileFollowButton(user: ProfileFixtures.followedStudent, onToggle: {})
        ProfileFollowButton(user: ProfileFixtures.followedStudent, isCompact: true, onToggle: {})
    }
    .padding()
}
