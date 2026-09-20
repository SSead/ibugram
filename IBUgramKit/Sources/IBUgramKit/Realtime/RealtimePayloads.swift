import Foundation

public struct ConversationScope: Codable, Sendable, Hashable {
    public var conversationId: UUID

    public init(conversationId: UUID) {
        self.conversationId = conversationId
    }
}

public struct MarkReadPayload: Codable, Sendable, Hashable {
    public var conversationId: UUID
    public var upToMessageId: UUID

    public init(conversationId: UUID, upToMessageId: UUID) {
        self.conversationId = conversationId
        self.upToMessageId = upToMessageId
    }
}

public struct MessageCreatedPayload: Codable, Sendable, Hashable {
    public var message: Message

    public init(message: Message) {
        self.message = message
    }
}

public struct MessageReadPayload: Codable, Sendable, Hashable {
    public var conversationId: UUID
    public var userId: UUID
    public var upToMessageId: UUID
    public var readAt: Date

    public init(conversationId: UUID, userId: UUID, upToMessageId: UUID, readAt: Date) {
        self.conversationId = conversationId
        self.userId = userId
        self.upToMessageId = upToMessageId
        self.readAt = readAt
    }
}

public struct TypingPayload: Codable, Sendable, Hashable {
    public var conversationId: UUID
    public var userId: UUID
    public var isTyping: Bool

    public init(conversationId: UUID, userId: UUID, isTyping: Bool) {
        self.conversationId = conversationId
        self.userId = userId
        self.isTyping = isTyping
    }
}

public struct PresenceChangedPayload: Codable, Sendable, Hashable {
    public var userId: UUID
    public var isOnline: Bool
    public var lastSeenAt: Date?

    public init(userId: UUID, isOnline: Bool, lastSeenAt: Date? = nil) {
        self.userId = userId
        self.isOnline = isOnline
        self.lastSeenAt = lastSeenAt
    }
}

public struct NotificationCreatedPayload: Codable, Sendable, Hashable {
    public var notification: Notification

    public init(notification: Notification) {
        self.notification = notification
    }
}

public struct UnreadCountChangedPayload: Codable, Sendable, Hashable {
    public var conversations: Int
    public var notifications: Int

    public init(conversations: Int, notifications: Int) {
        self.conversations = conversations
        self.notifications = notifications
    }
}
