import SwiftUI

struct ActivityRow: View {
    let item: ActivityNotification
    var isRead: Bool
    var displayedActor: User?
    var onOpen: () -> Void
    var onFollow: (() -> Void)?

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: onOpen) {
            HStack(alignment: .center, spacing: theme.spacing.sm) {
                avatarStack
                VStack(alignment: .leading, spacing: theme.spacing.hairline) {
                    Text(ActivityCopy.sentence(for: item))
                        .font(isRead ? theme.typography.body : theme.typography.bodyEmphasis)
                        .foregroundStyle(theme.colors.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(RelativeTimestamp.abbreviated(from: item.createdAt))
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                trailing
            }
            .padding(.horizontal, theme.spacing.screenMargin)
            .padding(.vertical, theme.spacing.sm)
            .background(isRead ? theme.colors.background : theme.colors.brandMuted.opacity(0.45))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySentence)
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilitySentence: String {
        let time = RelativeTimestamp.accessible(from: item.createdAt)
        let unread = isRead ? "" : " Unread."
        return "\(ActivityCopy.sentence(for: item)). \(time).\(unread)"
    }

    private var avatarStack: some View {
        let actors = Array(item.actors.prefix(2))
        return ZStack {
            if actors.isEmpty {
                Image(systemName: symbolName)
                    .font(theme.typography.headline)
                    .foregroundStyle(theme.colors.brand)
                    .frame(width: 44, height: 44)
                    .background(theme.colors.brandMuted, in: .circle)
            } else if actors.count == 1 {
                AvatarView(url: actors[0].avatarUrl, displayName: actors[0].displayName, size: .medium)
            } else {
                AvatarView(url: actors[0].avatarUrl, displayName: actors[0].displayName, size: .small)
                    .offset(x: -theme.spacing.xs, y: -theme.spacing.xxs)
                AvatarView(url: actors[1].avatarUrl, displayName: actors[1].displayName, size: .small)
                    .offset(x: theme.spacing.xs, y: theme.spacing.xxs)
            }
        }
        .frame(width: 44, height: 44)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var trailing: some View {
        if item.kind == .follow, let actor = displayedActor ?? item.actors.first, let onFollow {
            ProfileFollowButton(user: actor, isCompact: true, onToggle: onFollow)
        } else if let cover = item.post?.cover {
            RemoteImage(
                url: cover.thumbnailUrl,
                blurhash: cover.blurhash,
                altText: cover.altText,
                contentMode: .fill
            )
            .frame(width: 44, height: 44)
            .clipShape(.rect(cornerRadius: theme.radii.xs))
            .accessibilityHidden(true)
        }
    }

    private var symbolName: String {
        switch item.kind {
        case .like: "heart.fill"
        case .comment, .reply: "bubble.left.fill"
        case .follow: "person.fill.badge.plus"
        case .mention: "at"
        case .spaceInvite: "person.3.fill"
        case .eventReminder: "calendar"
        }
    }
}

#Preview("Activity rows") {
    VStack(spacing: 0) {
        ActivityRow(item: ActivityFixtures.likeToday, isRead: false, onOpen: {})
        ActivityRow(item: ActivityFixtures.followThisWeek, isRead: true, onOpen: {}, onFollow: {})
        ActivityRow(item: ActivityFixtures.eventReminderEarlier, isRead: false, onOpen: {})
    }
    .appContainer(.preview())
}
