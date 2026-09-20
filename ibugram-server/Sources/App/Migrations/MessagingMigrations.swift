import Fluent

struct CreateConversation: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(ConversationRecord.schema)
            .id()
            .field("kind", .string, .required)
            .field("title", .string)
            .field("avatar_media_id", .uuid, .references(MediaRecord.schema, "id", onDelete: .setNull))
            .field("created_by_id", .uuid, .references(UserRecord.schema, "id", onDelete: .setNull))
            .field("direct_key", .string)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "direct_key")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(ConversationRecord.schema).delete()
    }
}

struct CreateConversationParticipant: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(ConversationParticipantRecord.schema)
            .id()
            .field(
                "conversation_id", .uuid, .required,
                .references(ConversationRecord.schema, "id", onDelete: .cascade)
            )
            .field("user_id", .uuid, .required, .references(UserRecord.schema, "id", onDelete: .cascade))
            .field("unread_count", .int, .required, .sql(.default(0)))
            .field("has_accepted", .bool, .required, .sql(.default(false)))
            .field("muted_at", .datetime)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "conversation_id", "user_id")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(ConversationParticipantRecord.schema).delete()
    }
}

struct CreateMessage: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(MessageRecord.schema)
            .id()
            .field(
                "conversation_id", .uuid, .required,
                .references(ConversationRecord.schema, "id", onDelete: .cascade)
            )
            .field("sender_id", .uuid, .required, .references(UserRecord.schema, "id", onDelete: .cascade))
            .field("body", .string)
            .field("client_id", .uuid, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "conversation_id", "client_id")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(MessageRecord.schema).delete()
    }
}

struct CreateMessageMedia: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(MessageMediaRecord.schema)
            .id()
            .field("message_id", .uuid, .required, .references(MessageRecord.schema, "id", onDelete: .cascade))
            .field("media_id", .uuid, .required, .references(MediaRecord.schema, "id", onDelete: .cascade))
            .field("position", .int, .required)
            .field("created_at", .datetime)
            .unique(on: "message_id", "media_id")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(MessageMediaRecord.schema).delete()
    }
}

struct CreateMessageRead: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(MessageReadRecord.schema)
            .id()
            .field("message_id", .uuid, .required, .references(MessageRecord.schema, "id", onDelete: .cascade))
            .field("user_id", .uuid, .required, .references(UserRecord.schema, "id", onDelete: .cascade))
            .field("read_at", .datetime, .required)
            .field("created_at", .datetime)
            .unique(on: "message_id", "user_id")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(MessageReadRecord.schema).delete()
    }
}

/// Conversations point at their newest message and participants at their read cursor;
/// both columns wait until `messages` exists.
struct AddConversationMessagePointers: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(ConversationRecord.schema)
            .field("last_message_id", .uuid, .references(MessageRecord.schema, "id", onDelete: .setNull))
            .update()
        try await database.schema(ConversationParticipantRecord.schema)
            .field("last_read_message_id", .uuid, .references(MessageRecord.schema, "id", onDelete: .setNull))
            .update()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(ConversationParticipantRecord.schema)
            .deleteField("last_read_message_id")
            .update()
        try await database.schema(ConversationRecord.schema)
            .deleteField("last_message_id")
            .update()
    }
}
