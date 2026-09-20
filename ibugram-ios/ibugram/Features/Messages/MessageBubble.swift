import SwiftUI
import IBUgramKit

struct MessageBubble: View {
    let message: Message
    var isFromCurrentUser: Bool

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(alignment: .bottom, spacing: theme.spacing.xs) {
            if isFromCurrentUser { Spacer(minLength: theme.spacing.xxl) }
            if !isFromCurrentUser {
                AvatarView(
                    url: message.sender.avatarURL,
                    displayName: message.sender.displayName,
                    size: .small,
                    showsVerifiedBadge: false
                )
            }
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: theme.spacing.hairline) {
                bubble
                meta
            }
            if !isFromCurrentUser { Spacer(minLength: theme.spacing.xxl) }
        }
        .padding(.horizontal, theme.spacing.screenMargin)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder
    private var bubble: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            ForEach(message.media) { media in
                RemoteImage(
                    url: media.resourceURL,
                    blurhash: media.blurhash,
                    altText: media.altText,
                    contentMode: .fill
                )
                .frame(maxHeight: 240)
                .clipShape(.rect(cornerRadius: theme.radii.md))
                .accessibilityLabel(media.altText ?? "Photo")
            }
            if let body = message.body, !body.isEmpty {
                Text(body)
                    .font(theme.typography.body)
                    .foregroundStyle(isFromCurrentUser ? theme.colors.textOnBrand : theme.colors.textPrimary)
            }
        }
        .padding(.horizontal, theme.spacing.sm)
        .padding(.vertical, theme.spacing.xs)
        .background(isFromCurrentUser ? theme.colors.brand : theme.colors.surfaceSunken, in: .rect(cornerRadius: theme.radii.lg))
    }

    private var meta: some View {
        HStack(spacing: theme.spacing.xxs) {
            Text(RelativeTimestamp.abbreviated(from: message.createdAt))
            if isFromCurrentUser {
                Text(deliveryLabel)
            }
        }
        .font(theme.typography.caption)
        .foregroundStyle(theme.colors.textTertiary)
    }

    private var deliveryLabel: String {
        switch message.delivery {
        case .sending: "Sending"
        case .sent: "Sent"
        case .read: "Read"
        }
    }

    private var accessibilityText: String {
        var parts = [message.sender.displayName]
        if let body = message.body { parts.append(body) }
        if !message.media.isEmpty { parts.append("Photo") }
        if isFromCurrentUser { parts.append(deliveryLabel) }
        return parts.joined(separator: ", ")
    }
}

#Preview("Bubbles") {
    VStack(alignment: .leading, spacing: 12) {
        MessageBubble(message: MessageFixtures.inboxEarlier, isFromCurrentUser: true)
        MessageBubble(message: MessageFixtures.inboxLastMessage, isFromCurrentUser: false)
        MessageBubble(message: MessageFixtures.inboxPhoto, isFromCurrentUser: false)
    }
    .appContainer(.preview())
}

#Preview("Bubbles · dark") {
    VStack(alignment: .leading, spacing: 12) {
        MessageBubble(message: MessageFixtures.inboxEarlier, isFromCurrentUser: true)
        MessageBubble(message: MessageFixtures.inboxLastMessage, isFromCurrentUser: false)
    }
    .preferredColorScheme(.dark)
    .appContainer(.preview())
}
