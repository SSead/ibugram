import Fluent

struct CreateNotification: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(NotificationRecord.schema)
            .id()
            .field("recipient_id", .uuid, .required, .references(UserRecord.schema, "id", onDelete: .cascade))
            .field("kind", .string, .required)
            .field("group_key", .string, .required)
            .field("group_count", .int, .required, .sql(.default(1)))
            .field("post_id", .uuid, .references(PostRecord.schema, "id", onDelete: .cascade))
            .field("comment_id", .uuid, .references(CommentRecord.schema, "id", onDelete: .cascade))
            .field("space_id", .uuid, .references(SpaceRecord.schema, "id", onDelete: .cascade))
            .field("event_id", .uuid, .references(EventRecord.schema, "id", onDelete: .cascade))
            .field("is_read", .bool, .required, .sql(.default(false)))
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "recipient_id", "group_key")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(NotificationRecord.schema).delete()
    }
}

struct CreateNotificationActor: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(NotificationActorRecord.schema)
            .id()
            .field(
                "notification_id", .uuid, .required,
                .references(NotificationRecord.schema, "id", onDelete: .cascade)
            )
            .field("user_id", .uuid, .required, .references(UserRecord.schema, "id", onDelete: .cascade))
            .field("created_at", .datetime)
            .unique(on: "notification_id", "user_id")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(NotificationActorRecord.schema).delete()
    }
}

struct CreateReport: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(ReportRecord.schema)
            .id()
            .field("reporter_id", .uuid, .required, .references(UserRecord.schema, "id", onDelete: .cascade))
            .field("subject", .string, .required)
            .field("post_id", .uuid, .references(PostRecord.schema, "id", onDelete: .cascade))
            .field("comment_id", .uuid, .references(CommentRecord.schema, "id", onDelete: .cascade))
            .field("subject_user_id", .uuid, .references(UserRecord.schema, "id", onDelete: .cascade))
            .field("reason", .string, .required)
            .field("detail", .string)
            .field("status", .string, .required, .sql(.default("open")))
            .field("handled_by_id", .uuid, .references(UserRecord.schema, "id", onDelete: .setNull))
            .field("handled_at", .datetime)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()

        try await database.execute(sql: """
            ALTER TABLE reports ADD CONSTRAINT reports_exactly_one_subject CHECK (
              (post_id IS NOT NULL)::int
              + (comment_id IS NOT NULL)::int
              + (subject_user_id IS NOT NULL)::int = 1
            )
            """)
    }

    func revert(on database: any Database) async throws {
        try await database.schema(ReportRecord.schema).delete()
    }
}
