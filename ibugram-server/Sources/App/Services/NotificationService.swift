import Fluent
import Foundation
import IBUgramKit
import Vapor

/// Who caused the notification. `system` covers notices nobody performed — an event
/// reminder — and is the one origin that is never treated as a self-action.
enum NotificationOrigin: Sendable, Hashable {
    case actor(UUID)
    case system
}

/// The row the notification is about. It fills the subject foreign keys and, more
/// importantly, decides which bucket the notification groups into.
enum NotificationSubject: Sendable, Hashable {
    case none
    case post(UUID)
    case comment(UUID, inPost: UUID?)
    case space(UUID)
    case event(UUID)
}

/// Raising a notification is an upsert, not an insert. `notifications` is unique on
/// `(recipient_id, group_key)`, so the twelfth person to like a post adds an actor row and
/// bumps `group_count` instead of creating a twelfth notification.
struct NotificationService: Sendable {
    let database: any Database
    let realtime: RealtimeBroadcaster
    let urls: MediaURLBuilder

    @discardableResult
    func raise(
        _ kind: NotificationKind,
        to recipientId: UUID,
        from origin: NotificationOrigin,
        subject: NotificationSubject = .none
    ) async throws -> NotificationRecord? {
        if case .actor(let actorId) = origin {
            guard actorId != recipientId else { return nil }
            guard try await !isBlockEitherWay(between: actorId, and: recipientId) else { return nil }
        }

        let outcome = try await upsert(
            kind: kind,
            recipientId: recipientId,
            groupKey: Self.groupKey(for: kind, subject: subject),
            subject: subject,
            origin: origin
        )
        guard outcome.didChange else { return outcome.record }
        await deliver(outcome.record, to: recipientId)
        return outcome.record
    }

    @discardableResult
    func raise(
        _ kind: NotificationKind,
        to recipientId: UUID,
        from actorId: UUID,
        subject: NotificationSubject = .none
    ) async throws -> NotificationRecord? {
        try await raise(kind, to: recipientId, from: .actor(actorId), subject: subject)
    }

    /// `like:post:<id>` folds every liker of one post together, while a notification with no
    /// subject row of its own is bucketed by UTC day so that "3 people followed you" is
    /// today's news rather than a single row that grows for the lifetime of the account.
    static func groupKey(
        for kind: NotificationKind,
        subject: NotificationSubject,
        on date: Date = Date()
    ) -> String {
        switch subject {
        case .none:
            "\(kind.rawValue):\(dayBucket(of: date))"
        case .post(let id):
            "\(kind.rawValue):post:\(id.uuidString)"
        case .comment(let id, _):
            "\(kind.rawValue):comment:\(id.uuidString)"
        case .space(let id):
            "\(kind.rawValue):space:\(id.uuidString)"
        case .event(let id):
            "\(kind.rawValue):event:\(id.uuidString)"
        }
    }

    func list(for recipient: UUID, page: PageRequest) async throws -> Paginated<IBUgramKit.Notification> {
        let query = NotificationRecord.query(on: database)
            .filter(\.$recipient.$id == recipient)
            .with(\.$actors) { $0.with(\.$user) }
            .sort(\.$createdAt, .descending)
            .sort(\.$id, .descending)
        if let cursor = page.cursor.flatMap(MessagingCursor.init(encoded:)) {
            query.group(.or) { group in
                group.filter(\.$createdAt < cursor.timestamp)
                group.group(.and) { tie in
                    tie.filter(\.$createdAt == cursor.timestamp)
                    tie.filter(\.$id < cursor.id)
                }
            }
        }

        let rows = try await query.limit(page.limit + 1).all()
        let visible = Array(rows.prefix(page.limit))
        let subjects = try await NotificationSubjects.load(for: visible, on: database)
        let items = try visible.map { try $0.asDTO(subjects: subjects, urls: urls) }

        var nextCursor: String?
        if rows.count > page.limit, let last = visible.last, let createdAt = last.createdAt {
            nextCursor = MessagingCursor(timestamp: createdAt, id: try last.requireID()).encoded
        }
        return Paginated(items: items, nextCursor: nextCursor)
    }

    func unreadCount(for recipient: UUID) async throws -> Int {
        try await UnreadTotals.notificationUnreadCount(for: recipient, on: database)
    }

    func markRead(ids: [UUID]?, for recipient: UUID) async throws -> Int {
        let query = NotificationRecord.query(on: database)
            .filter(\.$recipient.$id == recipient)
            .filter(\.$isRead == false)
        if let ids, !ids.isEmpty {
            query.filter(\.$id ~~ ids)
        }
        try await query.set(\.$isRead, to: true).update()
        await realtime.sendUnreadCounts(to: [recipient], on: database)
        return try await unreadCount(for: recipient)
    }

    private func upsert(
        kind: NotificationKind,
        recipientId: UUID,
        groupKey: String,
        subject: NotificationSubject,
        origin: NotificationOrigin
    ) async throws -> (record: NotificationRecord, didChange: Bool) {
        if let existing = try await find(groupKey: groupKey, for: recipientId) {
            return (existing, try await fold(origin, into: existing))
        }

        let record = NotificationRecord()
        record.id = UUID()
        record.$recipient.id = recipientId
        record.kind = kind
        record.groupKey = groupKey
        record.groupCount = 1
        record.isRead = false
        Self.apply(subject, to: record)

        do {
            try await record.create(on: database)
        } catch let error as any DatabaseError where error.isConstraintFailure {
            guard let existing = try await find(groupKey: groupKey, for: recipientId) else {
                throw APIError.conflict("That notification could not be recorded.")
            }
            return (existing, try await fold(origin, into: existing))
        }
        _ = try await fold(origin, into: record)
        return (record, true)
    }

    /// Adds the actor to an existing group and resurfaces the row. A repeat action by an actor
    /// who is already in the group changes nothing, so it neither re-marks the row unread nor
    /// re-sends a frame.
    private func fold(_ origin: NotificationOrigin, into record: NotificationRecord) async throws -> Bool {
        var didChange = false
        if case .actor(let actorId) = origin {
            didChange = try await addActor(actorId, to: record)
        }
        let actorCount = try await actorCount(of: record)
        let groupCount = max(actorCount, 1)
        if record.groupCount != groupCount {
            record.groupCount = groupCount
            didChange = true
        }
        if didChange {
            record.isRead = false
            try await record.save(on: database)
        }
        return didChange
    }

    private func addActor(_ actorId: UUID, to record: NotificationRecord) async throws -> Bool {
        let notificationId = try record.requireID()
        let actor = NotificationActorRecord()
        actor.$notification.id = notificationId
        actor.$user.id = actorId
        do {
            try await actor.create(on: database)
            return true
        } catch let error as any DatabaseError where error.isConstraintFailure {
            return false
        }
    }

    private func actorCount(of record: NotificationRecord) async throws -> Int {
        try await NotificationActorRecord.query(on: database)
            .filter(\.$notification.$id == record.requireID())
            .count()
    }

    private func find(groupKey: String, for recipientId: UUID) async throws -> NotificationRecord? {
        try await NotificationRecord.query(on: database)
            .filter(\.$recipient.$id == recipientId)
            .filter(\.$groupKey == groupKey)
            .first()
    }

    private func deliver(_ record: NotificationRecord, to recipientId: UUID) async {
        do {
            let query = NotificationRecord.query(on: database)
                .filter(\.$id == (try record.requireID()))
                .with(\.$actors) { $0.with(\.$user) }
            guard let reloaded = try await query.first() else { return }
            let subjects = try await NotificationSubjects.load(for: [reloaded], on: database)
            let payload = NotificationCreatedPayload(
                notification: try reloaded.asDTO(subjects: subjects, urls: urls)
            )
            await realtime.send(.notificationCreated(payload), to: [recipientId])
            await realtime.sendUnreadCounts(to: [recipientId], on: database)
        } catch {
            realtime.logger.debug(
                "Could not deliver a notification over the socket",
                metadata: ["reason": .string("\(error)")]
            )
        }
    }

    private func isBlockEitherWay(between first: UUID, and second: UUID) async throws -> Bool {
        try await BlockRecord.query(on: database)
            .group(.or) { group in
                group.group(.and) { outgoing in
                    outgoing.filter(\.$blocker.$id == first)
                    outgoing.filter(\.$blocked.$id == second)
                }
                group.group(.and) { incoming in
                    incoming.filter(\.$blocker.$id == second)
                    incoming.filter(\.$blocked.$id == first)
                }
            }
            .count() > 0
    }

    private static func apply(_ subject: NotificationSubject, to record: NotificationRecord) {
        switch subject {
        case .none:
            break
        case .post(let id):
            record.$post.id = id
        case .comment(let id, let postId):
            record.$comment.id = id
            record.$post.id = postId
        case .space(let id):
            record.$space.id = id
        case .event(let id):
            record.$event.id = id
        }
    }

    private static func dayBucket(of date: Date) -> String {
        let components = Calendar(identifier: .gregorian).dateComponents(in: .gmt, from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }
}

extension Request {
    /// How every other feature raises a notification:
    /// `try await request.notifications.raise(.like, to: authorId, from: viewer.id, subject: .post(postId))`
    var notifications: NotificationService {
        NotificationService(database: db, realtime: realtime, urls: dependencies.urls)
    }

    var conversations: ConversationService {
        ConversationService(database: db, realtime: realtime, urls: dependencies.urls)
    }

    var messages: MessageService {
        MessageService(database: db, realtime: realtime, urls: dependencies.urls)
    }
}
