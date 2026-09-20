import SwiftUI
import IBUgramKit

struct ProfileHeaderView: View {
    let user: User
    let isOwnProfile: Bool
    var onFollowers: () -> Void
    var onFollowing: () -> Void
    var onPosts: () -> Void
    var onEditProfile: () -> Void
    var onToggleFollow: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            identity
            stats
            if let bio = user.bio, !bio.isEmpty {
                Text(bio)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            actionRow
        }
        .padding(.horizontal, theme.spacing.screenMargin)
        .padding(.top, theme.spacing.md)
    }

    private var identity: some View {
        HStack(alignment: .center, spacing: theme.spacing.md) {
            AvatarView(
                url: user.avatarURL,
                displayName: user.displayName,
                size: .extraLarge,
                showsVerifiedBadge: false
            )
            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                HStack(spacing: theme.spacing.xxs) {
                    Text(user.displayName)
                        .font(theme.typography.titleSmall)
                        .foregroundStyle(theme.colors.textPrimary)
                    if user.role == .faculty || user.isVerified {
                        VerifiedBadge()
                    }
                }
                .accessibilityElement(children: .combine)

                Text("@\(user.username)")
                    .font(theme.typography.subheadline)
                    .foregroundStyle(theme.colors.textSecondary)

                Text(affiliation)
                    .font(theme.typography.footnote)
                    .foregroundStyle(theme.colors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var affiliation: String {
        var parts = [user.roleTitle]
        if let department = user.department, !department.isEmpty {
            parts.append(department)
        }
        if let year = user.yearOfStudy {
            parts.append("Year \(year)")
        }
        return parts.joined(separator: " · ")
    }

    private var stats: some View {
        HStack(spacing: theme.spacing.xs) {
            statButton(value: user.counts.posts, label: "posts", action: onPosts)
            statButton(value: user.counts.followers, label: "followers", action: onFollowers)
            statButton(value: user.counts.following, label: "following", action: onFollowing)
        }
        .accessibilityElement(children: .contain)
    }

    private func statButton(value: Int, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: theme.spacing.hairline) {
                Text(value, format: .number)
                    .font(theme.typography.headline)
                    .foregroundStyle(theme.colors.textPrimary)
                Text(label)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityLabel("\(value) \(label)")
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var actionRow: some View {
        if isOwnProfile {
            Button("Edit Profile", action: onEditProfile)
                .buttonStyle(.ibuSecondary)
                .accessibilityHint("Edit your display name, bio and photo")
        } else {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                if user.viewer?.isFollowedBy == true {
                    TagChip(title: "Follows you", style: .brand)
                }
                ProfileFollowButton(user: user, onToggle: onToggleFollow)
            }
        }
    }
}

#Preview("Header · own") {
    ProfileHeaderView(
        user: ProfileFixtures.currentUser,
        isOwnProfile: true,
        onFollowers: {},
        onFollowing: {},
        onPosts: {},
        onEditProfile: {},
        onToggleFollow: {}
    )
}

#Preview("Header · faculty") {
    ProfileHeaderView(
        user: ProfileFixtures.unfollowedFaculty,
        isOwnProfile: false,
        onFollowers: {},
        onFollowing: {},
        onPosts: {},
        onEditProfile: {},
        onToggleFollow: {}
    )
}
