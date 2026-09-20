import Fluent
import Foundation
import IBUgramKit
import Vapor

struct DemoSeed {
    let app: Application

    var db: any Database { app.db }
    var store: any MediaStore { app.dependencies.mediaStore }

    func run() async throws {
        try await wipePreviousSeed()
        let users = try await insertUsers()
        try await insertFollows(users)
        let places = try await insertPlaces()
        let spaces = try await insertSpaces(users)
        let events = try await insertEvents(users: users, places: places, spaces: spaces)
        let posts = try await insertPosts(users: users, places: places, spaces: spaces, events: events)
        try await insertEngagement(users: users, posts: posts, events: events)
        try await insertConversation(users: users)
        try await raiseNotifications(users: users, posts: posts, events: events)
        printSummary()
    }

    static func run(on app: Application) async throws {
        try await DemoSeed(app: app).run()
    }
}

extension DemoSeed {
    func wipePreviousSeed() async throws {
        let emails = DemoSeedDataset.emails
        let existing = try await UserRecord.query(on: db).filter(\.$email ~~ emails).all()
        for user in existing {
            user.$avatarMedia.id = nil
            try await user.save(on: db)
        }
        try await UserRecord.query(on: db).filter(\.$email ~~ emails).delete()
        try await SpaceRecord.query(on: db)
            .filter(\.$slug ~~ DemoSeedDataset.spaces.map(\.slug))
            .delete()
        try await PlaceRecord.query(on: db)
            .filter(\.$name ~~ DemoSeedDataset.places.map(\.name))
            .delete()
        try await db.execute(sql: """
            DELETE FROM conversations
            WHERE NOT EXISTS (
                SELECT 1 FROM conversation_participants
                WHERE conversation_participants.conversation_id = conversations.id
            )
            """)
    }

    func insertUsers() async throws -> [String: UserRecord] {
        var users: [String: UserRecord] = [:]
        for spec in DemoSeedDataset.users {
            let user = UserRecord(email: spec.email, role: EmailAddress.role(for: spec.email) ?? .student)
            user.id = SeedIdentity.uuid("user.\(spec.key)")
            user.username = spec.username
            user.displayName = spec.displayName
            user.bio = spec.bio
            user.department = spec.department
            user.yearOfStudy = spec.yearOfStudy
            try await user.create(on: db)
            let avatar = try await storeImage(
                key: "avatar.\(spec.key)",
                ownerId: try user.requireID(),
                red: spec.red, green: spec.green, blue: spec.blue,
                width: 400, height: 400,
                altText: "Avatar for \(spec.displayName)"
            )
            user.$avatarMedia.id = try avatar.requireID()
            try await user.save(on: db)
            users[spec.key] = user
        }
        return users
    }

    func insertFollows(_ users: [String: UserRecord]) async throws {
        for (followerKey, followeeKey) in DemoSeedDataset.follows {
            guard let follower = users[followerKey], let followee = users[followeeKey] else { continue }
            let row = FollowRecord(followerId: try follower.requireID(), followeeId: try followee.requireID())
            try await insertIgnoringConflict(row, on: db)
        }
    }
}
