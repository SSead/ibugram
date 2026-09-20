import SwiftUI
import IBUgramKit

struct ConversationRow: View {
    let conversation: Conversation
    let title: String
    let currentUserID: UUID
    var isOnline: Bool
    var onOpen: () -> Void
    var onAccept: (() -> Void)?

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: theme.spacing.sm) {
            Button(action: onOpen) {
                HStack(spacing: theme.spacing.sm) {
                    avatar
                    VStack(alignment: .leading, spacing: theme.spacing.hairline) {
                        titleRow
                        previewRow
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilityText)

            if let onAccept {
                Button("Accept", action: onAccept)
                    .buttonStyle(.ibuSecondary)
                    .accessibilityLabel("Accept message request from \(title)")
            }
        }
        .padding(.horizontal, theme.spacing.screenMargin)
        .padding(.vertical, theme.spacing.xs)
    }

    private var titleRow: some View {
        HStack {
            Text(title)
                .font(theme.typography.bodyEmphasis)
                .foregroundStyle(theme.colors.textPrimary)
                .lineLimit(1)
            Spacer(minLength: theme.spacing.xs)
            if let last = conversation.lastMessage {
                Text(RelativeTimestamp.abbreviated(from: last.createdAt))
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textTertiary)
            }
        }
    }

    private var previewRow: some View {
        HStack(alignment: .center, spacing: theme.spacing.xs) {
            Text(ConversationPresentation.preview(for: conversation))
                .font(conversation.unreadCount > 0 ? theme.typography.bodyEmphasis : theme.typography.subheadline)
                .foregroundStyle(conversation.unreadCount > 0 ? theme.colors.textPrimary : theme.colors.textSecondary)
                .lineLimit(2)
            Spacer(minLength: theme.spacing.xs)
            if conversation.unreadCount > 0 {
                unreadBadge
            }
        }
    }

    private var avatar: some View {
        AvatarView(
            url: peer?.avatarURL ?? RemoteURL.parse(conversation.avatarUrl),
            displayName: title,
            size: .medium,
            showsVerifiedBadge: peer?.role == .faculty || peer?.isVerified == true
        )
        .overlay(alignment: .bottomTrailing) {
            if isOnline {
                Circle()
                    .fill(theme.colors.success)
                    .frame(width: theme.spacing.xs, height: theme.spacing.xs)
                    .overlay {
                        Circle().strokeBorder(theme.colors.background, lineWidth: theme.spacing.hairline / 2)
                    }
                    .accessibilityHidden(true)
            }
        }
    }

    private var unreadBadge: some View {
        Text(conversation.unreadCount > 99 ? "99+" : "\(conversation.unreadCount)")
            .font(theme.typography.captionEmphasis)
            .foregroundStyle(theme.colors.textOnBrand)
            .padding(.horizontal, theme.spacing.xs)
            .padding(.vertical, theme.spacing.hairline)
            .background(theme.colors.brand, in: .capsule)
            .accessibilityLabel("\(conversation.unreadCount) unread")
    }

    private var peer: User? {
        ConversationPresentation.peer(in: conversation, currentUserID: currentUserID)
    }

    private var accessibilityText: String {
        var parts = [title, ConversationPresentation.preview(for: conversation)]
        if conversation.unreadCount > 0 {
            parts.append("\(conversation.unreadCount) unread")
        }
        if isOnline { parts.append("online") }
        return parts.joined(separator: ", ")
    }
}

#Preview("Conversation row") {
    VStack {
        ConversationRow(
            conversation: MessageFixtures.inboxConversation,
            title: "Leila Marković",
            currentUserID: MessageFixtures.viewer.id,
            isOnline: true,
            onOpen: {}
        )
        ConversationRow(
            conversation: MessageFixtures.requestConversation,
            title: "Prof. Dr. Damir Kovač",
            currentUserID: MessageFixtures.viewer.id,
            isOnline: false,
            onOpen: {},
            onAccept: {}
        )
    }
    .appContainer(.preview())
}
