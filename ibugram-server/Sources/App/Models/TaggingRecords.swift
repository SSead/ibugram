import Fluent
import Foundation

final class HashtagRecord: Model, @unchecked Sendable {
    static let schema = "hashtags"

    @ID(key: .id) var id: UUID?
    @Field(key: "tag") var tag: String
    @Field(key: "post_count") var postCount: Int
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?

    init() {}

    init(tag: String) {
        self.tag = tag
        self.postCount = 0
    }
}

final class PostHashtagRecord: Model, @unchecked Sendable {
    static let schema = "post_hashtags"

    @ID(key: .id) var id: UUID?
    @Parent(key: "post_id") var post: PostRecord
    @Parent(key: "hashtag_id") var hashtag: HashtagRecord
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?

    init() {}
}

/// A mention belongs to exactly one of a post or a comment; the database enforces it.
final class MentionRecord: Model, @unchecked Sendable {
    static let schema = "mentions"

    @ID(key: .id) var id: UUID?
    @OptionalParent(key: "post_id") var post: PostRecord?
    @OptionalParent(key: "comment_id") var comment: CommentRecord?
    @Parent(key: "user_id") var user: UserRecord
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?

    init() {}
}
