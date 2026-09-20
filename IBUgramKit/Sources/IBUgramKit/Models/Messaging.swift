import Foundation

public enum ConversationKind: String, Codable, Sendable, Hashable, CaseIterable {
    case direct
    case group
}

public enum ConversationFilter: String, Codable, Sendable, Hashable, CaseIterable {
    case inbox
    case requests
}

/// `sending` is produced by the offline outbox and never appears on the wire from the server.
public enum MessageDelivery: String, Codable, Sendable, Hashable, CaseIterable {
    case sending
    case sent
    case read
}

public struct Message: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    public var conversationId: UUID
    public var sender: User
    public var body: String?
    public var media: [Media]
    public var delivery: MessageDelivery
    public var readBy: [UUID]
    public var createdAt: Date

    public init(
        id: UUID,
        conversationId: UUID,
        sender: User,
        body: String? = nil,
        media: [Media] = [],
        delivery: MessageDelivery = .sent,
        readBy: [UUID] = [],
        createdAt: Date
    ) {
        self.id = id
        self.conversationId = conversationId
        self.sender = sender
        self.body = body
        self.media = media
        self.delivery = delivery
        self.readBy = readBy
        self.createdAt = createdAt
    }
}

public struct Conversation: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    public var kind: ConversationKind
    public var title: String?
    public var avatarUrl: String?
    public var participants: [User]
    public var lastMessage: Message?
    public var unreadCount: Int
    public var isRequest: Bool
    public var updatedAt: Date

    public init(
        id: UUID,
        kind: ConversationKind,
        title: String? = nil,
        avatarUrl: String? = nil,
        participants: [User] = [],
        lastMessage: Message? = nil,
        unreadCount: Int = 0,
        isRequest: Bool = false,
        updatedAt: Date
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.avatarUrl = avatarUrl
        self.participants = participants
        self.lastMessage = lastMessage
        self.unreadCount = unreadCount
        self.isRequest = isRequest
        self.updatedAt = updatedAt
    }
}
