import Foundation

enum ActivityKind: String, Codable, Sendable, Hashable {
    case like
    case comment
    case reply
    case follow
    case mention
    case spaceInvite = "space_invite"
    case eventReminder = "event_reminder"
}

struct CommentViewerState: Codable, Sendable, Hashable {
    let hasLiked: Bool
}

struct Comment: Codable, Sendable, Hashable, Identifiable {
    let id: UUID
    let postId: UUID
    let author: User
    let body: String
    let parentId: UUID?
    let replyCount: Int
    let likeCount: Int
    let viewer: CommentViewerState?
    let createdAt: Date
}

struct Place: Codable, Sendable, Hashable, Identifiable {
    let id: UUID?
    let name: String
    let latitude: Double
    let longitude: Double
    let isCampusLocation: Bool
}

enum RSVPStatus: String, Codable, Sendable {
    case going
    case interested
    case none
}

struct EventCounts: Codable, Sendable, Hashable {
    let going: Int
    let interested: Int
}

struct EventViewerState: Codable, Sendable, Hashable {
    let rsvp: RSVPStatus
}

struct Event: Codable, Sendable, Hashable, Identifiable {
    let id: UUID
    let title: String
    let description: String?
    let startsAt: Date
    let endsAt: Date?
    let place: Place?
    let capacity: Int?
    let host: User
    let space: SpaceSummary?
    let counts: EventCounts
    let viewer: EventViewerState?
    let postId: UUID?
}

struct ActivityNotification: Codable, Sendable, Hashable, Identifiable {
    let id: UUID
    let kind: ActivityKind
    let actors: [User]
    let groupCount: Int
    let post: Post?
    let comment: Comment?
    let space: SpaceSummary?
    let event: Event?
    let isRead: Bool
    let createdAt: Date

    func markingRead() -> ActivityNotification {
        ActivityNotification(
            id: id,
            kind: kind,
            actors: actors,
            groupCount: groupCount,
            post: post,
            comment: comment,
            space: space,
            event: event,
            isRead: true,
            createdAt: createdAt
        )
    }
}

struct UnreadCountResponse: Codable, Sendable, Hashable {
    let count: Int
}
