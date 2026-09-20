import Foundation
import IBUgramKit

struct ThreadedComment: Identifiable, Sendable, Hashable {
    var comment: Comment
    var replies: [Comment]

    var id: UUID { comment.id }
}
