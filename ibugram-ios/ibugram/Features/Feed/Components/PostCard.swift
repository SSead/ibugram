import SwiftUI

struct PostCard: View {
    let post: Post
    var actions: PostCardActions = PostCardActions()

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PostAuthorRow(
                post: post,
                onAuthor: actions.onAuthor,
                onDelete: actions.onDelete
            )
            PostMediaCarousel(media: post.media, onDoubleTap: actions.onDoubleTapLike)
            PostActionBar(
                post: post,
                shareText: shareText,
                onLike: actions.onLike,
                onComment: actions.onComment,
                onSave: actions.onSave
            )
            PostMetadataRow(
                post: post,
                onLikeCount: actions.onLikeCount,
                onComment: actions.onComment
            )
            if post.caption != nil {
                PostCaptionView(
                    post: post,
                    onHashtag: actions.onHashtag,
                    onMention: actions.onMention,
                    onAuthor: actions.onAuthor
                )
            }
        }
        .padding(.bottom, theme.spacing.sm)
        .background(theme.colors.background)
        .accessibilityElement(children: .contain)
    }

    private var shareText: String {
        let caption = post.caption.map { "\($0)\n\n" } ?? ""
        return "\(caption)\(post.author.displayName) on IBUgram"
    }
}

#Preview("Post card · single image") {
    ScrollView {
        PostCard(post: FeedFixtures.singleImage)
    }
    .appContainer(.preview())
}

#Preview("Post card · carousel") {
    ScrollView {
        PostCard(post: FeedFixtures.carousel)
    }
    .appContainer(.preview())
}

#Preview("Post card · long caption") {
    ScrollView {
        PostCard(post: FeedFixtures.longCaption)
    }
    .appContainer(.preview())
}

#Preview("Post card · faculty author") {
    ScrollView {
        PostCard(post: FeedFixtures.facultyAuthor)
    }
    .appContainer(.preview())
}

#Preview("Post card · liked") {
    ScrollView {
        PostCard(post: FeedFixtures.liked)
    }
    .appContainer(.preview())
}

#Preview("Post card · dark") {
    ScrollView {
        PostCard(post: FeedFixtures.carousel)
    }
    .appContainer(.preview())
    .preferredColorScheme(.dark)
}
