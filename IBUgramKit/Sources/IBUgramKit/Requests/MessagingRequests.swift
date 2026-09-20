import Foundation

public struct CreateConversationBody: Codable, Sendable, Hashable {
    public var participantIds: [UUID]
    public var title: String?

    public init(participantIds: [UUID], title: String? = nil) {
        self.participantIds = participantIds
        self.title = title
    }
}

/// `clientId` makes retries from the offline outbox idempotent.
public struct CreateMessageBody: Codable, Sendable, Hashable {
    public var body: String?
    public var mediaIds: [UUID]?
    public var clientId: UUID

    public init(body: String? = nil, mediaIds: [UUID]? = nil, clientId: UUID = UUID()) {
        self.body = body
        self.mediaIds = mediaIds
        self.clientId = clientId
    }
}

public struct MarkConversationReadBody: Codable, Sendable, Hashable {
    public var upToMessageId: UUID

    public init(upToMessageId: UUID) {
        self.upToMessageId = upToMessageId
    }
}

/// An empty `ids` marks every unread notification as read.
public struct MarkNotificationsReadBody: Codable, Sendable, Hashable {
    public var ids: [UUID]?

    public init(ids: [UUID]? = nil) {
        self.ids = ids
    }
}
