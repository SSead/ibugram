import SwiftUI
import IBUgramKit

struct SpaceMemberRow: View {
    let member: SpaceMember
    var onOpen: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: theme.spacing.sm) {
                AvatarView(
                    url: member.user.avatarURL,
                    displayName: member.user.displayName,
                    size: .medium,
                    showsVerifiedBadge: member.user.role == .faculty || member.user.isVerified
                )
                VStack(alignment: .leading, spacing: theme.spacing.hairline) {
                    Text(member.user.displayName)
                        .font(theme.typography.bodyEmphasis)
                        .foregroundStyle(theme.colors.textPrimary)
                        .lineLimit(1)
                    Text("@\(member.user.username)")
                        .font(theme.typography.footnote)
                        .foregroundStyle(theme.colors.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
                TagChip(title: roleTitle, style: roleStyle)
            }
            .padding(.horizontal, theme.spacing.screenMargin)
            .padding(.vertical, theme.spacing.xs)
        }
        .accessibilityLabel("\(member.user.displayName), \(roleTitle)")
    }

    private var roleTitle: String {
        switch member.role {
        case .owner: "Owner"
        case .moderator: "Moderator"
        case .member: "Member"
        case .pending: "Pending"
        case .none: "Guest"
        }
    }

    private var roleStyle: TagChip.Style {
        switch member.role {
        case .owner, .moderator: .accent
        case .member: .brand
        case .pending, .none: .neutral
        }
    }
}

#Preview("Member row") {
    VStack {
        ForEach(SpaceFixtures.members) { member in
            SpaceMemberRow(member: member, onOpen: {})
        }
    }
    .appContainer(.preview())
}
