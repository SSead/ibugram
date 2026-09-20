import Fluent
import SQLKit

struct CreateUser: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(UserRecord.schema)
            .id()
            .field("email", .string, .required)
            .field("username", .string)
            .field("display_name", .string)
            .field("bio", .string)
            .field("role", .string, .required)
            .field("department", .string)
            .field("year_of_study", .int)
            .field("is_verified", .bool, .required, .sql(.default(false)))
            .field("is_moderator", .bool, .required, .sql(.default(false)))
            .field("is_suspended", .bool, .required, .sql(.default(false)))
            .field("last_seen_at", .datetime)
            .field("post_count", .int, .required, .sql(.default(0)))
            .field("follower_count", .int, .required, .sql(.default(0)))
            .field("following_count", .int, .required, .sql(.default(0)))
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "email")
            .create()

        try await database.execute(sql: """
            CREATE UNIQUE INDEX users_username_lower_key ON users (lower(username))
            """)
    }

    func revert(on database: any Database) async throws {
        try await database.schema(UserRecord.schema).delete()
    }
}

struct CreateOTPChallenge: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(OTPChallengeRecord.schema)
            .id()
            .field("email", .string, .required)
            .field("code_hash", .string, .required)
            .field("attempt_count", .int, .required, .sql(.default(0)))
            .field("expires_at", .datetime, .required)
            .field("consumed_at", .datetime)
            .field("requested_ip", .string)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(OTPChallengeRecord.schema).delete()
    }
}

struct CreateAuthSession: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(AuthSessionRecord.schema)
            .id()
            .field("user_id", .uuid, .required, .references(UserRecord.schema, "id", onDelete: .cascade))
            .field("family_id", .uuid, .required)
            .field("token_hash", .string, .required)
            .field("device_name", .string)
            .field("user_agent", .string)
            .field("ip_address", .string)
            .field("expires_at", .datetime, .required)
            .field("last_used_at", .datetime, .required)
            .field("revoked_at", .datetime)
            .field("revoked_reason", .string)
            .field("replaced_by_id", .uuid, .references(AuthSessionRecord.schema, "id", onDelete: .setNull))
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "token_hash")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(AuthSessionRecord.schema).delete()
    }
}

struct CreateFollow: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(FollowRecord.schema)
            .id()
            .field("follower_id", .uuid, .required, .references(UserRecord.schema, "id", onDelete: .cascade))
            .field("followee_id", .uuid, .required, .references(UserRecord.schema, "id", onDelete: .cascade))
            .field("created_at", .datetime)
            .unique(on: "follower_id", "followee_id")
            .create()

        try await database.execute(sql: """
            ALTER TABLE follows ADD CONSTRAINT follows_not_self CHECK (follower_id <> followee_id)
            """)
    }

    func revert(on database: any Database) async throws {
        try await database.schema(FollowRecord.schema).delete()
    }
}

struct CreateBlock: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(BlockRecord.schema)
            .id()
            .field("blocker_id", .uuid, .required, .references(UserRecord.schema, "id", onDelete: .cascade))
            .field("blocked_id", .uuid, .required, .references(UserRecord.schema, "id", onDelete: .cascade))
            .field("created_at", .datetime)
            .unique(on: "blocker_id", "blocked_id")
            .create()

        try await database.execute(sql: """
            ALTER TABLE blocks ADD CONSTRAINT blocks_not_self CHECK (blocker_id <> blocked_id)
            """)
    }

    func revert(on database: any Database) async throws {
        try await database.schema(BlockRecord.schema).delete()
    }
}
