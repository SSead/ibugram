import Fluent
import Foundation
import IBUgramKit
import Vapor

/// The subject rows for a page of notifications, loaded once per page rather than once per
/// row. Feature teams own the full `Post`, `Comment`, `Space` and `Event` projections; a
/// notification only needs enough of each to render its cell, so hashtags, mentions and
/// viewer state are deliberately left empty here.
struct NotificationSubjects: Sendable {
    private let posts: [UUID: PostRecord]
    private let comments: [UUID: CommentRecord]
    private let spaces: [UUID: SpaceRecord]
    private let events: [UUID: EventRecord]

    static func load(
        for notifications: [NotificationRecord],
        on database: any Database
    ) async throws -> NotificationSubjects {
        let postIds = notifications.compactMap { $0.$post.id }
        let commentIds = notifications.compactMap { $0.$comment.id }
        let spaceIds = notifications.compactMap { $0.$space.id }
        let eventIds = notifications.compactMap { $0.$event.id }

        let posts = postIds.isEmpty ? [] : try await PostRecord.query(on: database)
            .filter(\.$id ~~ postIds)
            .with(\.$author)
            .with(\.$attachedMedia) { $0.with(\.$media) }
            .all()
        let comments = commentIds.isEmpty ? [] : try await CommentRecord.query(on: database)
            .filter(\.$id ~~ commentIds)
            .with(\.$author)
            .all()
        let spaces = spaceIds.isEmpty ? [] : try await SpaceRecord.query(on: database)
            .filter(\.$id ~~ spaceIds)
            .all()
        let events = eventIds.isEmpty ? [] : try await EventRecord.query(on: database)
            .filter(\.$id ~~ eventIds)
            .with(\.$host)
            .with(\.$place)
            .with(\.$space)
            .all()

        return NotificationSubjects(
            posts: try indexed(posts),
            comments: try indexed(comments),
            spaces: try indexed(spaces),
            events: try indexed(events)
        )
    }

    func post(_ id: UUID?, urls: MediaURLBuilder) throws -> Post? {
        guard let id, let record = posts[id] else { return nil }
        return Post(
            id: try record.requireID(),
            author: try record.author.asDTO(urls: urls),
            media: try record.attachedMedia
                .sorted { $0.position < $1.position }
                .map { try $0.media.asDTO(urls: urls) },
            caption: record.caption,
            counts: PostCounts(likes: record.likeCount, comments: record.commentCount),
            commentsEnabled: record.commentsEnabled,
            createdAt: record.createdAt ?? Date(),
            editedAt: record.editedAt
        )
    }

    func comment(_ id: UUID?, urls: MediaURLBuilder) throws -> Comment? {
        guard let id, let record = comments[id] else { return nil }
        return Comment(
            id: try record.requireID(),
            postId: record.$post.id,
            author: try record.author.asDTO(urls: urls),
            body: record.body,
            parentId: record.$parent.id,
            replyCount: record.replyCount,
            likeCount: record.likeCount,
            createdAt: record.createdAt ?? Date()
        )
    }

    func space(_ id: UUID?, urls: MediaURLBuilder) throws -> SpaceSummary? {
        guard let id, let record = spaces[id] else { return nil }
        return try summary(of: record, urls: urls)
    }

    func event(_ id: UUID?, urls: MediaURLBuilder) throws -> Event? {
        guard let id, let record = events[id] else { return nil }
        return Event(
            id: try record.requireID(),
            title: record.title,
            description: record.description,
            startsAt: record.startsAt,
            endsAt: record.endsAt,
            place: try record.place.map(place(of:)),
            capacity: record.capacity,
            host: try record.host.asDTO(urls: urls),
            space: try record.space.map { try summary(of: $0, urls: urls) },
            counts: EventCounts(going: record.goingCount, interested: record.interestedCount)
        )
    }

    private func summary(of record: SpaceRecord, urls: MediaURLBuilder) throws -> SpaceSummary {
        SpaceSummary(
            id: try record.requireID(),
            slug: record.slug,
            name: record.name,
            avatarUrl: record.$avatarMedia.id.map(urls.url(forMedia:)),
            isOfficial: record.isOfficial,
            memberCount: record.memberCount
        )
    }

    private func place(of record: PlaceRecord) throws -> Place {
        Place(
            id: try record.requireID(),
            name: record.name,
            latitude: record.latitude,
            longitude: record.longitude,
            isCampusLocation: record.isCampusLocation
        )
    }

    private static func indexed<Record: Model>(_ records: [Record]) throws -> [UUID: Record]
        where Record.IDValue == UUID
    {
        try records.reduce(into: [:]) { result, record in
            result[try record.requireID()] = record
        }
    }
}

extension NotificationRecord {
    func asDTO(subjects: NotificationSubjects, urls: MediaURLBuilder) throws -> IBUgramKit.Notification {
        IBUgramKit.Notification(
            id: try requireID(),
            kind: kind,
            actors: try actors
                .sorted { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) }
                .map { try $0.user.asDTO(urls: urls) },
            groupCount: groupCount,
            post: try subjects.post($post.id, urls: urls),
            comment: try subjects.comment($comment.id, urls: urls),
            space: try subjects.space($space.id, urls: urls),
            event: try subjects.event($event.id, urls: urls),
            isRead: isRead,
            createdAt: createdAt ?? Date()
        )
    }
}

extension IBUgramKit.Notification: @retroactive AsyncRequestDecodable {}
extension IBUgramKit.Notification: @retroactive AsyncResponseEncodable {}
extension IBUgramKit.Notification: @retroactive Content {}

extension UnreadCount: @retroactive AsyncRequestDecodable {}
extension UnreadCount: @retroactive AsyncResponseEncodable {}
extension UnreadCount: @retroactive Content {}

extension MarkNotificationsReadBody: @retroactive AsyncRequestDecodable {}
extension MarkNotificationsReadBody: @retroactive AsyncResponseEncodable {}
extension MarkNotificationsReadBody: @retroactive Content {}
