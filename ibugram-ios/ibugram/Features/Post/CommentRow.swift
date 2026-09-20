import SwiftUI
import IBUgramKit

struct CommentRow: View {
    let comment: Comment
    var isReply = false
    var canDelete = false
    var onLike: () -> Void = {}
    var onReply: () -> Void = {}
    var onAuthor: () -> Void = {}
    var onDelete: () -> Void = {}

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(alignment: .top, spacing: theme.spacing.xs) {
            Button(action: onAuthor) {
                AvatarView(url: comment.author.avatarURL, displayName: comment.author.displayName, size: .small)
            }
            .accessibilityLabel("Open \(comment.author.displayName)'s profile")

            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                HStack(alignment: .firstTextBaseline, spacing: theme.spacing.xxs) {
                    Text(comment.author.username)
                        .font(theme.typography.bodyEmphasis)
                        .foregroundStyle(theme.colors.textPrimary)
                    Text(RelativeTimestamp.abbreviated(from: comment.createdAt))
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textTertiary)
                }
                Text(comment.body)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                actions
            }

            Spacer(minLength: theme.spacing.xs)

            Button(action: onLike) {
                VStack(spacing: theme.spacing.hairline) {
                    Image(systemName: comment.hasLiked ? "heart.fill" : "heart")
                        .foregroundStyle(comment.hasLiked ? theme.colors.destructive : theme.colors.textTertiary)
                    if comment.likeCount > 0 {
                        Text("\(comment.likeCount)")
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textTertiary)
                    }
                }
            }
            .accessibilityLabel(comment.hasLiked ? "Unlike comment" : "Like comment")
            .accessibilityValue("\(comment.likeCount) likes")
        }
        .padding(.leading, isReply ? theme.spacing.xxl : 0)
        .padding(.vertical, theme.spacing.xxs)
        .contextMenu {
            if canDelete {
                Button("Delete comment", role: .destructive, action: onDelete)
            }
        }
    }

    private var actions: some View {
        HStack(spacing: theme.spacing.md) {
            if !isReply {
                Button("Reply", action: onReply)
                    .font(theme.typography.captionEmphasis)
                    .foregroundStyle(theme.colors.textSecondary)
                    .accessibilityLabel("Reply to \(comment.author.username)")
            }
            if canDelete {
                Button("Delete", role: .destructive, action: onDelete)
                    .font(theme.typography.captionEmphasis)
                    .foregroundStyle(theme.colors.destructive)
                    .accessibilityLabel("Delete comment")
            }
        }
    }
}

#Preview("Comment") {
    VStack {
        CommentRow(comment: PostFixtures.rootComment)
        CommentRow(comment: PostFixtures.reply, isReply: true, canDelete: true)
    }
    .padding()
    .appContainer(.preview())
}
