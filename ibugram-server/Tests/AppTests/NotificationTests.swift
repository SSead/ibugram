import Fluent
import Foundation
import IBUgramKit
import Testing
import Vapor
import VaporTesting
@testable import App

extension TestContext {
    var notificationService: NotificationService {
        NotificationService(
            database: app.db,
            realtime: RealtimeBroadcaster(registry: app.realtimeRegistry, logger: app.logger),
            urls: app.dependencies.urls
        )
    }

    func insertPostRecord(authorId: UUID, caption: String = "Library at midnight") async throws -> UUID {
        let record = PostRecord()
        record.id = UUID()
        record.$author.id = authorId
        record.caption = caption
        record.commentsEnabled = true
        record.isArchived = false
        record.likeCount = 0
        record.commentCount = 0
        try await record.create(on: app.db)
        return try record.requireID()
    }

    func notificationList(_ session: AuthSession) async throws -> Paginated<IBUgramKit.Notification> {
        let response = try await app.testing().sendRequest(
            .GET,
            API.Notifications.list.fullPath,
            headers: authorized(session.accessToken)
        )
        #expect(response.status == .ok)
        return try response.content.decode(Paginated<IBUgramKit.Notification>.self)
    }
}

@Suite("Notifications", .serialized)
struct NotificationTests {
    private let author = "amina.hodzic@stu.ibu.edu.ba"

    @Test("Twelve people liking one post become one notification with twelve actors")
    func likesGroupIntoOneRow() async throws {
        try await withMessagingTestServer { context in
            let owner = try await context.signIn(as: author)
            let postId = try await context.insertPostRecord(authorId: owner.user.id)

            var likers: [UUID] = []
            for index in 0..<3 {
                let liker = try await context.signIn(as: "liker\(index)@stu.ibu.edu.ba")
                likers.append(liker.user.id)
                _ = try await context.notificationService.raise(
                    .like,
                    to: owner.user.id,
                    from: liker.user.id,
                    subject: .post(postId)
                )
            }

            #expect(try await NotificationRecord.query(on: context.app.db).count() == 1)
            #expect(try await NotificationActorRecord.query(on: context.app.db).count() == 3)

            let notifications = try await context.notificationList(owner)
            let notification = try #require(notifications.items.first)
            #expect(notification.kind == .like)
            #expect(notification.groupCount == 3)
            #expect(Set(notification.actors.map(\.id)) == Set(likers))
            #expect(notification.post?.id == postId)
            #expect(notification.isRead == false)
        }
    }

    @Test("The same actor acting twice changes nothing")
    func repeatedActorDoesNotInflateTheGroup() async throws {
        try await withMessagingTestServer { context in
            let owner = try await context.signIn(as: author)
            let liker = try await context.signIn(as: "liker@stu.ibu.edu.ba")
            let postId = try await context.insertPostRecord(authorId: owner.user.id)

            for _ in 0..<3 {
                _ = try await context.notificationService.raise(
                    .like,
                    to: owner.user.id,
                    from: liker.user.id,
                    subject: .post(postId)
                )
            }
            let stored = try #require(try await NotificationRecord.query(on: context.app.db).first())
            #expect(stored.groupCount == 1)
            #expect(try await NotificationActorRecord.query(on: context.app.db).count() == 1)
        }
    }

    @Test("A new actor resurfaces a notification that had already been read")
    func groupingResurfacesReadNotifications() async throws {
        try await withMessagingTestServer { context in
            let owner = try await context.signIn(as: author)
            let first = try await context.signIn(as: "first@stu.ibu.edu.ba")
            let second = try await context.signIn(as: "second@stu.ibu.edu.ba")
            let postId = try await context.insertPostRecord(authorId: owner.user.id)

            _ = try await context.notificationService.raise(
                .like,
                to: owner.user.id,
                from: first.user.id,
                subject: .post(postId)
            )
            _ = try await context.notificationService.markRead(ids: nil, for: owner.user.id)
            #expect(try await context.notificationService.unreadCount(for: owner.user.id) == 0)

            _ = try await context.notificationService.raise(
                .like,
                to: owner.user.id,
                from: second.user.id,
                subject: .post(postId)
            )
            #expect(try await context.notificationService.unreadCount(for: owner.user.id) == 1)
            let stored = try #require(try await NotificationRecord.query(on: context.app.db).first())
            #expect(stored.groupCount == 2)
        }
    }

    @Test("Nobody is notified of their own action")
    func selfActionsRaiseNothing() async throws {
        try await withMessagingTestServer { context in
            let owner = try await context.signIn(as: author)
            let postId = try await context.insertPostRecord(authorId: owner.user.id)

            let raised = try await context.notificationService.raise(
                .like,
                to: owner.user.id,
                from: owner.user.id,
                subject: .post(postId)
            )
            #expect(raised == nil)
            #expect(try await NotificationRecord.query(on: context.app.db).count() == 0)
            #expect(try await context.notificationService.unreadCount(for: owner.user.id) == 0)
        }
    }

    @Test("A blocked actor raises no notification")
    func blockedActorsRaiseNothing() async throws {
        try await withMessagingTestServer { context in
            let owner = try await context.signIn(as: author)
            let blocked = try await context.signIn(as: "blocked@stu.ibu.edu.ba")
            try await context.insertBlock(blocker: owner.user.id, blocked: blocked.user.id)
            let postId = try await context.insertPostRecord(authorId: owner.user.id)

            let raised = try await context.notificationService.raise(
                .comment,
                to: owner.user.id,
                from: blocked.user.id,
                subject: .post(postId)
            )
            #expect(raised == nil)
            #expect(try await NotificationRecord.query(on: context.app.db).count() == 0)
        }
    }

    @Test("Separate subjects stay separate notifications")
    func differentSubjectsDoNotGroup() async throws {
        try await withMessagingTestServer { context in
            let owner = try await context.signIn(as: author)
            let liker = try await context.signIn(as: "liker@stu.ibu.edu.ba")
            let firstPost = try await context.insertPostRecord(authorId: owner.user.id, caption: "One")
            let secondPost = try await context.insertPostRecord(authorId: owner.user.id, caption: "Two")

            for postId in [firstPost, secondPost] {
                _ = try await context.notificationService.raise(
                    .like,
                    to: owner.user.id,
                    from: liker.user.id,
                    subject: .post(postId)
                )
            }
            #expect(try await NotificationRecord.query(on: context.app.db).count() == 2)
            #expect(try await context.notificationService.unreadCount(for: owner.user.id) == 2)
        }
    }

    @Test("Follows group by day because they have no subject row of their own")
    func followsGroupByDay() async throws {
        try await withMessagingTestServer { context in
            let owner = try await context.signIn(as: author)
            for index in 0..<2 {
                let follower = try await context.signIn(as: "follower\(index)@stu.ibu.edu.ba")
                _ = try await context.notificationService.raise(
                    .follow,
                    to: owner.user.id,
                    from: follower.user.id
                )
            }
            let stored = try #require(try await NotificationRecord.query(on: context.app.db).first())
            #expect(stored.groupCount == 2)
            #expect(stored.groupKey.hasPrefix("follow:"))
            #expect(try await NotificationRecord.query(on: context.app.db).count() == 1)
        }
    }

    @Test("A system notification has no actor and is never suppressed as a self-action")
    func systemNotificationsAreDelivered() async throws {
        try await withMessagingTestServer { context in
            let host = try await context.signIn(as: author)
            let place = PlaceRecord()
            place.id = UUID()
            place.name = "Aula"
            place.latitude = 43.85
            place.longitude = 18.36
            place.isCampusLocation = true
            try await place.create(on: context.app.db)

            let event = EventRecord()
            event.id = UUID()
            event.title = "Thesis defence"
            event.startsAt = Date().addingTimeInterval(3_600)
            event.$host.id = host.user.id
            event.$place.id = try place.requireID()
            event.goingCount = 0
            event.interestedCount = 0
            try await event.create(on: context.app.db)

            let raised = try await context.notificationService.raise(
                .eventReminder,
                to: host.user.id,
                from: .system,
                subject: .event(try event.requireID())
            )
            #expect(raised != nil)

            let notification = try #require(try await context.notificationList(host).items.first)
            #expect(notification.kind == .eventReminder)
            #expect(notification.actors.isEmpty)
            #expect(notification.groupCount == 1)
            #expect(notification.event?.title == "Thesis defence")
        }
    }

    @Test("Marking read clears the badge, by id or wholesale")
    func markingReadClearsTheBadge() async throws {
        try await withMessagingTestServer { context in
            let owner = try await context.signIn(as: author)
            let actor = try await context.signIn(as: "actor@stu.ibu.edu.ba")
            let firstPost = try await context.insertPostRecord(authorId: owner.user.id, caption: "One")
            let secondPost = try await context.insertPostRecord(authorId: owner.user.id, caption: "Two")
            let first = try #require(
                try await context.notificationService.raise(
                    .like,
                    to: owner.user.id,
                    from: actor.user.id,
                    subject: .post(firstPost)
                )
            )
            _ = try await context.notificationService.raise(
                .comment,
                to: owner.user.id,
                from: actor.user.id,
                subject: .post(secondPost)
            )

            let count = try await context.app.testing().sendRequest(
                .GET,
                API.Notifications.unreadCount.fullPath,
                headers: context.authorized(owner.accessToken)
            )
            #expect(try count.content.decode(UnreadCount.self).count == 2)

            let single = try await context.app.testing().sendRequest(
                .POST,
                API.Notifications.markRead.fullPath,
                headers: context.authorized(owner.accessToken),
                beforeRequest: {
                    try $0.content.encode(MarkNotificationsReadBody(ids: [try first.requireID()]))
                }
            )
            #expect(try single.content.decode(UnreadCount.self).count == 1)

            let everything = try await context.app.testing().sendRequest(
                .POST,
                API.Notifications.markRead.fullPath,
                headers: context.authorized(owner.accessToken),
                beforeRequest: { try $0.content.encode(MarkNotificationsReadBody()) }
            )
            #expect(try everything.content.decode(UnreadCount.self).count == 0)
        }
    }

    @Test("The group key scheme buckets by kind and subject")
    func groupKeysAreStable() {
        let postId = UUID()
        let commentId = UUID()
        let spaceId = UUID()
        let eventId = UUID()

        #expect(
            NotificationService.groupKey(for: .like, subject: .post(postId))
                == "like:post:\(postId.uuidString)"
        )
        #expect(
            NotificationService.groupKey(for: .reply, subject: .comment(commentId, inPost: postId))
                == "reply:comment:\(commentId.uuidString)"
        )
        #expect(
            NotificationService.groupKey(for: .spaceInvite, subject: .space(spaceId))
                == "space_invite:space:\(spaceId.uuidString)"
        )
        #expect(
            NotificationService.groupKey(for: .eventReminder, subject: .event(eventId))
                == "event_reminder:event:\(eventId.uuidString)"
        )
        let afternoon = Date(timeIntervalSince1970: 1_790_000_000)
        #expect(
            NotificationService.groupKey(for: .follow, subject: .none, on: afternoon)
                == "follow:2026-09-21"
        )
        #expect(
            NotificationService.groupKey(for: .follow, subject: .none, on: afternoon)
                != NotificationService.groupKey(
                    for: .follow,
                    subject: .none,
                    on: afternoon.addingTimeInterval(86_400)
                )
        )
    }
}
