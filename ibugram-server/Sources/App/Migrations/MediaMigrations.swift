import Fluent

struct CreateMediaAsset: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(MediaRecord.schema)
            .id()
            .field("uploaded_by_id", .uuid, .required, .references(UserRecord.schema, "id", onDelete: .cascade))
            .field("storage_key", .string, .required)
            .field("thumbnail_storage_key", .string, .required)
            .field("content_type", .string, .required)
            .field("byte_size", .int, .required)
            .field("width", .int, .required)
            .field("height", .int, .required)
            .field("alt_text", .string)
            .field("blurhash", .string)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "storage_key")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(MediaRecord.schema).delete()
    }
}

/// Split from `CreateUser` because users and media reference each other; the column is
/// added once both tables exist.
struct AddUserAvatarMedia: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(UserRecord.schema)
            .field("avatar_media_id", .uuid, .references(MediaRecord.schema, "id", onDelete: .setNull))
            .update()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(UserRecord.schema)
            .deleteField("avatar_media_id")
            .update()
    }
}
