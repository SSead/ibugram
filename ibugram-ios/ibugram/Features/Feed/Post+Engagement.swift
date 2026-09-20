import Foundation

extension Post {
    var hasLiked: Bool { viewer?.hasLiked ?? false }
    var hasSaved: Bool { viewer?.hasSaved ?? false }

    func applyingEngagement(
        hasLiked: Bool,
        hasSaved: Bool,
        likeCount: Int,
        commentCount: Int? = nil
    ) -> Post {
        Post(
            id: id,
            author: author,
            media: media,
            caption: caption,
            hashtags: hashtags,
            counts: PostCounts(likes: max(0, likeCount), comments: commentCount ?? counts.comments),
            viewer: PostViewerState(hasLiked: hasLiked, hasSaved: hasSaved),
            commentsEnabled: commentsEnabled,
            createdAt: createdAt,
            editedAt: editedAt
        )
    }
}
