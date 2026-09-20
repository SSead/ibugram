import Foundation
import IBUgramKit

extension CommentRecord {
    func asDTO(author: IBUgramKit.User, viewer: CommentViewerState?) throws -> Comment {
        Comment(
            id: try requireID(),
            postId: $post.id,
            author: author,
            body: body,
            parentId: $parent.id,
            replyCount: replyCount,
            likeCount: likeCount,
            viewer: viewer,
            createdAt: createdAt ?? Date()
        )
    }
}
