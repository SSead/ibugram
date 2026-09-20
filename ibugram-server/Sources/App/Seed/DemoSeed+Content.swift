import Fluent
import Foundation
import IBUgramKit
import Vapor

extension DemoSeed {
    func insertPosts(
        users: [String: UserRecord],
        places: [String: PlaceRecord],
        spaces: [String: SpaceRecord],
        events: [String: EventRecord]
    ) async throws -> [String: PostRecord] {
        var posts: [String: PostRecord] = [:]
        for spec in DemoSeedDataset.posts {
            guard let author = users[spec.author] else { continue }
            let authorId = try author.requireID()
            let media = try await storeImage(
                key: "post.\(spec.key)",
                ownerId: authorId,
                red: spec.red, green: spec.green, blue: spec.blue,
                width: spec.width, height: spec.height,
                altText: spec.altText
            )
            let post = PostRecord()
            post.id = SeedIdentity.uuid("post.\(spec.key)")
            post.$author.id = authorId
            post.caption = spec.caption
            post.commentsEnabled = true
            post.isArchived = false
            post.likeCount = 0
            post.commentCount = 0
            if let spaceKey = spec.space {
                post.$space.id = try spaces[spaceKey]?.requireID()
            }
            if let eventKey = spec.event {
                post.$event.id = try events[eventKey]?.requireID()
            }
            if let placeKey = spec.place {
                post.$place.id = try places[placeKey]?.requireID()
            }
            try await post.create(on: db)
            let attachment = PostMediaRecord()
            attachment.$post.id = try post.requireID()
            attachment.$media.id = try media.requireID()
            attachment.position = 0
            try await attachment.create(on: db)
            try await writeTags(caption: spec.caption, postId: try post.requireID(), users: users)
            post.createdAt = Date().addingTimeInterval(-spec.hoursAgo * 3_600)
            try await post.save(on: db)
            posts[spec.key] = post
        }
        return posts
    }

    func insertEngagement(
        users: [String: UserRecord],
        posts: [String: PostRecord],
        events: [String: EventRecord]
    ) async throws {
        try await like(post: "12", by: ["emir", "sara", "lejla", "yusuf"], users: users, posts: posts)
        try await like(post: "9", by: ["amina", "emir", "nermin"], users: users, posts: posts)
        try await like(post: "1", by: ["amina", "sara"], users: users, posts: posts)

        try await comment(
            post: "12",
            author: "emir",
            body: "You've got this. See you at the fair?",
            users: users,
            posts: posts
        )
        try await comment(
            post: "9",
            author: "amina",
            body: "Hall A is packed already. #careerfair",
            users: users,
            posts: posts
        )
        try await comment(
            post: "4",
            author: "amina",
            body: "I'll bring the blankets.",
            users: users,
            posts: posts
        )

        if let amina = users["amina"], let post = posts["1"] {
            let save = SaveRecord()
            save.$user.id = try amina.requireID()
            save.$post.id = try post.requireID()
            try await insertIgnoringConflict(save, on: db)
        }

        try await rsvp(event: "career", status: .going, users: ["amina", "emir", "nermin", "yusuf"], all: users, events: events)
        try await rsvp(event: "openday", status: .interested, users: ["amina", "haris", "lejla"], all: users, events: events)
        try await rsvp(event: "film", status: .going, users: ["amina", "lejla", "maja"], all: users, events: events)
    }

    func insertConversation(users: [String: UserRecord]) async throws {
        guard let amina = users["amina"], let emir = users["emir"] else { return }
        let aminaId = try amina.requireID()
        let emirId = try emir.requireID()
        let conversation = ConversationRecord()
        conversation.id = SeedIdentity.uuid("conversation.amina-emir")
        conversation.kind = .direct
        conversation.$createdBy.id = emirId
        conversation.directKey = ConversationRecord.directKey(between: aminaId, and: emirId)
        try await conversation.create(on: db)
        let conversationId = try conversation.requireID()

        for (userId, unread, accepted) in [
            (aminaId, 2, true),
            (emirId, 0, true)
        ] {
            let participant = ConversationParticipantRecord()
            participant.$conversation.id = conversationId
            participant.$user.id = userId
            participant.unreadCount = unread
            participant.hasAccepted = accepted
            try await participant.create(on: db)
        }

        let first = try await insertMessage(
            "Are you going to the career fair? Hall A is already loud.",
            key: "1",
            conversationId: conversationId,
            senderId: emirId
        )
        let second = try await insertMessage(
            "I'll save you a seat near the SE booth.",
            key: "2",
            conversationId: conversationId,
            senderId: emirId
        )
        conversation.$lastMessage.id = try second.requireID()
        try await conversation.save(on: db)
        _ = first
    }

    func raiseNotifications(
        users: [String: UserRecord],
        posts: [String: PostRecord],
        events: [String: EventRecord]
    ) async throws {
        guard let amina = users["amina"] else { return }
        let aminaId = try amina.requireID()
        let notifications = NotificationService(
            database: db,
            realtime: RealtimeBroadcaster(registry: app.realtimeRegistry, logger: app.logger),
            urls: app.dependencies.urls
        )
        if let post = posts["12"] {
            let postId = try post.requireID()
            for key in ["emir", "sara", "lejla"] {
                guard let actor = users[key] else { continue }
                _ = try await notifications.raise(.like, to: aminaId, from: try actor.requireID(), subject: .post(postId))
            }
            if let emir = users["emir"] {
                _ = try await notifications.raise(
                    .comment,
                    to: aminaId,
                    from: try emir.requireID(),
                    subject: .post(postId)
                )
            }
        }
        if let emir = users["emir"] {
            _ = try await notifications.raise(.follow, to: aminaId, from: try emir.requireID())
        }
        if let event = events["career"] {
            _ = try await notifications.raise(
                .eventReminder,
                to: aminaId,
                from: .system,
                subject: .event(try event.requireID())
            )
        }
        if let post = posts["4"], let lejla = users["lejla"] {
            _ = try await notifications.raise(
                .mention,
                to: aminaId,
                from: try lejla.requireID(),
                subject: .post(try post.requireID())
            )
        }
    }
}
