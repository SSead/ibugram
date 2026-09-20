import SwiftUI

struct PostActionBar: View {
    let post: Post
    let shareText: String
    var onLike: () -> Void = {}
    var onComment: () -> Void = {}
    var onSave: () -> Void = {}

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: theme.spacing.md) {
            Button(action: onLike) {
                Image(systemName: post.hasLiked ? "heart.fill" : "heart")
                    .foregroundStyle(post.hasLiked ? theme.colors.destructive : theme.colors.textPrimary)
                    .symbolEffect(.bounce, value: post.hasLiked)
            }
            .accessibilityLabel(post.hasLiked ? "Unlike" : "Like")
            .accessibilityValue("\(post.counts.likes) likes")

            Button(action: onComment) {
                Image(systemName: "bubble.right")
                    .foregroundStyle(theme.colors.textPrimary)
            }
            .accessibilityLabel("Comment")
            .accessibilityValue("\(post.counts.comments) comments")

            ShareLink(item: shareText) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(theme.colors.textPrimary)
            }
            .accessibilityLabel("Share")

            Spacer(minLength: theme.spacing.xs)

            Button(action: onSave) {
                Image(systemName: post.hasSaved ? "bookmark.fill" : "bookmark")
                    .foregroundStyle(post.hasSaved ? theme.colors.brand : theme.colors.textPrimary)
            }
            .accessibilityLabel(post.hasSaved ? "Unsave" : "Save")
        }
        .font(theme.typography.titleSmall)
        .padding(.horizontal, theme.spacing.screenMargin)
        .padding(.top, theme.spacing.xs)
    }
}
