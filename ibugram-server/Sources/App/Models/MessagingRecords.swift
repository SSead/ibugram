import Fluent
import Foundation
import IBUgramKit

final class ConversationRecord: Model, @unchecked Sendable {
    static let schema = "conversations"

    @ID(key: .id) var id: UUID?
    @Field(key: "kind") var kind: ConversationKind
    @OptionalField(key: "title") var title: String?
    @OptionalParent(key: "avatar_media_id") var avatarMedia: MediaRecord?
    @OptionalParent(key: "created_by_id") var createdBy: UserRecord?
    /// The sorted participant pair for a direct conversation, which makes `POST
    /// /conversations` idempotent for 1:1. Null for groups.
    @OptionalField(key: "direct_key") var directKey: String?
    @OptionalParent(key: "last_message_id") var lastMessage: MessageRecord?
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    @Children(for: \.$conversation) var participants: [ConversationParticipantRecord]

    init() {}

    static func directKey(between first: UUID, and second: UUID) -> String {
        [first.uuidString, second.uuidString].sorted().joined(separator: ":")
    }
}

final class ConversationParticipantRecord: Model, @unchecked Sendable {
    static let schema = "conversation_participants"

    @ID(key: .id) var id: UUID?
    @Parent(key: "conversation_id") var conversation: ConversationRecord
    @Parent(key: "user_id") var user: UserRecord
    @OptionalParent(key: "last_read_message_id") var lastReadMessage: MessageRecord?
    @Field(key: "unread_count") var unreadCount: Int
    @Field(key: "has_accepted") var hasAccepted: Bool
    @OptionalField(key: "muted_at") var mutedAt: Date?
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}
}

final class MessageRecord: Model, @unchecked Sendable {
    static let schema = "messages"

    @ID(key: .id) var id: UUID?
    @Parent(key: "conversation_id") var conversation: ConversationRecord
    @Parent(key: "sender_id") var sender: UserRecord
    @OptionalField(key: "body") var body: String?
    @Field(key: "client_id") var clientId: UUID
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}
}

final class MessageMediaRecord: Model, @unchecked Sendable {
    static let schema = "message_media"

    @ID(key: .id) var id: UUID?
    @Parent(key: "message_id") var message: MessageRecord
    @Parent(key: "media_id") var media: MediaRecord
    @Field(key: "position") var position: Int
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?

    init() {}
}

final class MessageReadRecord: Model, @unchecked Sendable {
    static let schema = "message_reads"

    @ID(key: .id) var id: UUID?
    @Parent(key: "message_id") var message: MessageRecord
    @Parent(key: "user_id") var user: UserRecord
    @Field(key: "read_at") var readAt: Date
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?

    init() {}
}
