import Foundation

extension Comment {
    var hasLiked: Bool { viewer?.hasLiked ?? false }
    var isReply: Bool { parentId != nil }

    func applyingLike(hasLiked: Bool, likeCount: Int) -> Comment {
        Comment(
            id: id,
            postId: postId,
            author: author,
            body: body,
            parentId: parentId,
            replyCount: replyCount,
            likeCount: max(0, likeCount),
            viewer: CommentViewerState(hasLiked: hasLiked),
            createdAt: createdAt
        )
    }
}

struct ThreadedComment: Identifiable, Sendable, Hashable {
    var comment: Comment
    var replies: [Comment]

    var id: UUID { comment.id }
}
