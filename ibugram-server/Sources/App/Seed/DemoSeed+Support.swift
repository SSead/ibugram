import Fluent
import Foundation
import IBUgramKit
import Vapor

extension DemoSeed {
    func storeImage(
        key: String,
        ownerId: UUID,
        red: Double,
        green: Double,
        blue: Double,
        width: Int,
        height: Int,
        altText: String
    ) async throws -> MediaRecord {
        let identifier = SeedIdentity.uuid("media.\(key)")
        let keys = SeedIdentity.mediaKeys(for: identifier)
        let jpeg = try SeedJPEG.solid(red: red, green: green, blue: blue, width: width, height: height)
        let thumb = try SeedJPEG.solid(
            red: red, green: green, blue: blue,
            width: min(width, 400),
            height: min(height, 400)
        )
        try await store.write(jpeg, to: keys.full)
        try await store.write(thumb, to: keys.thumbnail)
        let record = MediaRecord(
            id: identifier,
            uploadedById: ownerId,
            storageKey: keys.full,
            thumbnailStorageKey: keys.thumbnail,
            contentType: "image/jpeg",
            byteSize: jpeg.count,
            width: width,
            height: height,
            altText: altText
        )
        try await record.create(on: db)
        return record
    }

    func writeTags(caption: String, postId: UUID, users: [String: UserRecord]) async throws {
        for tag in HashtagParser.hashtags(in: caption) {
            let hashtag: HashtagRecord
            if let existing = try await HashtagRecord.query(on: db).filter(\.$tag == tag).first() {
                hashtag = existing
            } else {
                let created = HashtagRecord(tag: tag)
                try await created.create(on: db)
                hashtag = created
            }
            let link = PostHashtagRecord()
            link.$post.id = postId
            link.$hashtag.id = try hashtag.requireID()
            try await insertIgnoringConflict(link, on: db)
        }
        let names = HashtagParser.mentions(in: caption)
        guard !names.isEmpty else { return }
        let mentioned = users.values.filter { user in
            names.contains(user.username ?? "")
        }
        for user in mentioned {
            let mention = MentionRecord()
            mention.$post.id = postId
            mention.$user.id = try user.requireID()
            try await insertIgnoringConflict(mention, on: db)
        }
    }

    func like(
        post key: String,
        by authorKeys: [String],
        users: [String: UserRecord],
        posts: [String: PostRecord]
    ) async throws {
        guard let post = posts[key] else { return }
        let postId = try post.requireID()
        for authorKey in authorKeys {
            guard let user = users[authorKey] else { continue }
            let like = PostLikeRecord()
            like.$post.id = postId
            like.$user.id = try user.requireID()
            try await insertIgnoringConflict(like, on: db)
        }
    }

    func comment(
        post key: String,
        author authorKey: String,
        body: String,
        users: [String: UserRecord],
        posts: [String: PostRecord]
    ) async throws {
        guard let post = posts[key], let author = users[authorKey] else { return }
        let comment = CommentRecord()
        comment.id = SeedIdentity.uuid("comment.\(key).\(authorKey)")
        comment.$post.id = try post.requireID()
        comment.$author.id = try author.requireID()
        comment.body = body
        comment.likeCount = 0
        comment.replyCount = 0
        try await comment.create(on: db)
    }

    func rsvp(
        event key: String,
        status: RSVPStatus,
        users keys: [String],
        all users: [String: UserRecord],
        events: [String: EventRecord]
    ) async throws {
        guard let event = events[key] else { return }
        let eventId = try event.requireID()
        for userKey in keys {
            guard let user = users[userKey] else { continue }
            let row = EventRSVPRecord()
            row.$event.id = eventId
            row.$user.id = try user.requireID()
            row.status = status
            try await insertIgnoringConflict(row, on: db)
        }
    }

    func insertMessage(
        _ body: String,
        key: String,
        conversationId: UUID,
        senderId: UUID
    ) async throws -> MessageRecord {
        let message = MessageRecord()
        message.id = SeedIdentity.uuid("message.\(key)")
        message.$conversation.id = conversationId
        message.$sender.id = senderId
        message.body = body
        message.clientId = SeedIdentity.uuid("message.\(key).client")
        try await message.create(on: db)
        return message
    }

    func printSummary() {
        let emails = DemoSeedDataset.emails
        print("IBUgram demo accounts — request an OTP at sign-in:")
        print("  Primary student: \(DemoSeedDataset.users.first { $0.key == DemoSeedDataset.primaryKey }?.email ?? "")")
        for email in emails where !email.contains("amina.hodzic") {
            print("  \(email)")
        }
        print("Seeded \(DemoSeedDataset.users.count) users, \(DemoSeedDataset.posts.count) posts, \(DemoSeedDataset.spaces.count) spaces, \(DemoSeedDataset.events.count) events.")
    }
}
