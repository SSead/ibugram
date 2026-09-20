import Fluent
import Foundation

final class PostRecord: Model, @unchecked Sendable {
    static let schema = "posts"

    @ID(key: .id) var id: UUID?
    @Parent(key: "author_id") var author: UserRecord
    @OptionalParent(key: "space_id") var space: SpaceRecord?
    @OptionalParent(key: "event_id") var event: EventRecord?
    @OptionalParent(key: "place_id") var place: PlaceRecord?
    @OptionalField(key: "caption") var caption: String?
    @Field(key: "comments_enabled") var commentsEnabled: Bool
    @Field(key: "is_archived") var isArchived: Bool
    @Field(key: "like_count") var likeCount: Int
    @Field(key: "comment_count") var commentCount: Int
    @OptionalField(key: "edited_at") var editedAt: Date?
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    @Children(for: \.$post) var attachedMedia: [PostMediaRecord]
    @Children(for: \.$post) var comments: [CommentRecord]

    init() {}
}

final class PostMediaRecord: Model, @unchecked Sendable {
    static let schema = "post_media"

    @ID(key: .id) var id: UUID?
    @Parent(key: "post_id") var post: PostRecord
    @Parent(key: "media_id") var media: MediaRecord
    @Field(key: "position") var position: Int
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?

    init() {}
}

final class PostLikeRecord: Model, @unchecked Sendable {
    static let schema = "post_likes"

    @ID(key: .id) var id: UUID?
    @Parent(key: "post_id") var post: PostRecord
    @Parent(key: "user_id") var user: UserRecord
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?

    init() {}
}

final class SaveRecord: Model, @unchecked Sendable {
    static let schema = "saves"

    @ID(key: .id) var id: UUID?
    @Parent(key: "user_id") var user: UserRecord
    @Parent(key: "post_id") var post: PostRecord
    @OptionalField(key: "collection_name") var collectionName: String?
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?

    init() {}
}

final class CommentRecord: Model, @unchecked Sendable {
    static let schema = "comments"

    @ID(key: .id) var id: UUID?
    @Parent(key: "post_id") var post: PostRecord
    @Parent(key: "author_id") var author: UserRecord
    @OptionalParent(key: "parent_id") var parent: CommentRecord?
    @Field(key: "body") var body: String
    @Field(key: "like_count") var likeCount: Int
    @Field(key: "reply_count") var replyCount: Int
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}
}

final class CommentLikeRecord: Model, @unchecked Sendable {
    static let schema = "comment_likes"

    @ID(key: .id) var id: UUID?
    @Parent(key: "comment_id") var comment: CommentRecord
    @Parent(key: "user_id") var user: UserRecord
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?

    init() {}
}
