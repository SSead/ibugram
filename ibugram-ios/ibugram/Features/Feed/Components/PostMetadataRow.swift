import SwiftUI

struct PostMetadataRow: View {
    let post: Post
    var onLikeCount: () -> Void = {}
    var onComment: () -> Void = {}

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: theme.spacing.md) {
            Button(action: onLikeCount) {
                Text(likeLabel)
                    .font(theme.typography.bodyEmphasis)
                    .foregroundStyle(theme.colors.textPrimary)
            }
            .accessibilityLabel(likeLabel)

            Button(action: onComment) {
                Text(commentLabel)
                    .font(theme.typography.subheadline)
                    .foregroundStyle(theme.colors.textSecondary)
            }
            .accessibilityLabel(commentLabel)
        }
        .padding(.horizontal, theme.spacing.screenMargin)
        .padding(.bottom, theme.spacing.sm)
    }

    private var likeLabel: String {
        post.counts.likes == 1 ? "1 like" : "\(post.counts.likes) likes"
    }

    private var commentLabel: String {
        post.counts.comments == 1 ? "1 comment" : "\(post.counts.comments) comments"
    }
}
