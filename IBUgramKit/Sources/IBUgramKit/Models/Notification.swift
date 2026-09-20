import Foundation

public enum NotificationKind: String, Codable, Sendable, Hashable, CaseIterable {
    case like
    case comment
    case reply
    case follow
    case mention
    case spaceInvite = "space_invite"
    case eventReminder = "event_reminder"
}

public struct Notification: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    public var kind: NotificationKind
    public var actors: [User]
    public var groupCount: Int
    public var post: Post?
    public var comment: Comment?
    public var space: SpaceSummary?
    public var event: Event?
    public var isRead: Bool
    public var createdAt: Date

    public init(
        id: UUID,
        kind: NotificationKind,
        actors: [User] = [],
        groupCount: Int = 1,
        post: Post? = nil,
        comment: Comment? = nil,
        space: SpaceSummary? = nil,
        event: Event? = nil,
        isRead: Bool = false,
        createdAt: Date
    ) {
        self.id = id
        self.kind = kind
        self.actors = actors
        self.groupCount = groupCount
        self.post = post
        self.comment = comment
        self.space = space
        self.event = event
        self.isRead = isRead
        self.createdAt = createdAt
    }
}

public struct UnreadCount: Codable, Sendable, Hashable {
    public var count: Int

    public init(count: Int) {
        self.count = count
    }
}
