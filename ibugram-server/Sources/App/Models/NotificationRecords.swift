import Fluent
import Foundation
import IBUgramKit

final class NotificationRecord: Model, @unchecked Sendable {
    static let schema = "notifications"

    @ID(key: .id) var id: UUID?
    @Parent(key: "recipient_id") var recipient: UserRecord
    @Field(key: "kind") var kind: NotificationKind
    /// Identifies the bucket that "X and 4 others liked your post" collapses into.
    @Field(key: "group_key") var groupKey: String
    @Field(key: "group_count") var groupCount: Int
    @OptionalParent(key: "post_id") var post: PostRecord?
    @OptionalParent(key: "comment_id") var comment: CommentRecord?
    @OptionalParent(key: "space_id") var space: SpaceRecord?
    @OptionalParent(key: "event_id") var event: EventRecord?
    @Field(key: "is_read") var isRead: Bool
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    @Children(for: \.$notification) var actors: [NotificationActorRecord]

    init() {}
}

final class NotificationActorRecord: Model, @unchecked Sendable {
    static let schema = "notification_actors"

    @ID(key: .id) var id: UUID?
    @Parent(key: "notification_id") var notification: NotificationRecord
    @Parent(key: "user_id") var user: UserRecord
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?

    init() {}
}

enum ReportStatus: String, Codable, Sendable, CaseIterable {
    case open
    case reviewing
    case actioned
    case dismissed
}

final class ReportRecord: Model, @unchecked Sendable {
    static let schema = "reports"

    @ID(key: .id) var id: UUID?
    @Parent(key: "reporter_id") var reporter: UserRecord
    @Field(key: "subject") var subject: ReportSubject
    @OptionalParent(key: "post_id") var post: PostRecord?
    @OptionalParent(key: "comment_id") var comment: CommentRecord?
    @OptionalParent(key: "subject_user_id") var subjectUser: UserRecord?
    @Field(key: "reason") var reason: ReportReason
    @OptionalField(key: "detail") var detail: String?
    @Field(key: "status") var status: ReportStatus
    @OptionalParent(key: "handled_by_id") var handledBy: UserRecord?
    @OptionalField(key: "handled_at") var handledAt: Date?
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}
}
