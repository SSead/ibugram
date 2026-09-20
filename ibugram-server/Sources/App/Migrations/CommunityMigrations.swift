import Fluent

struct CreatePlace: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(PlaceRecord.schema)
            .id()
            .field("name", .string, .required)
            .field("latitude", .double, .required)
            .field("longitude", .double, .required)
            .field("is_campus_location", .bool, .required, .sql(.default(false)))
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(PlaceRecord.schema).delete()
    }
}

struct CreateSpace: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(SpaceRecord.schema)
            .id()
            .field("slug", .string, .required)
            .field("name", .string, .required)
            .field("description", .string)
            .field("kind", .string, .required)
            .field("visibility", .string, .required)
            .field("is_official", .bool, .required, .sql(.default(false)))
            .field("avatar_media_id", .uuid, .references(MediaRecord.schema, "id", onDelete: .setNull))
            .field("banner_media_id", .uuid, .references(MediaRecord.schema, "id", onDelete: .setNull))
            .field("created_by_id", .uuid, .references(UserRecord.schema, "id", onDelete: .setNull))
            .field("member_count", .int, .required, .sql(.default(0)))
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "slug")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(SpaceRecord.schema).delete()
    }
}

struct CreateSpaceMembership: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(SpaceMembershipRecord.schema)
            .id()
            .field("space_id", .uuid, .required, .references(SpaceRecord.schema, "id", onDelete: .cascade))
            .field("user_id", .uuid, .required, .references(UserRecord.schema, "id", onDelete: .cascade))
            .field("role", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "space_id", "user_id")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(SpaceMembershipRecord.schema).delete()
    }
}

struct CreateEvent: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(EventRecord.schema)
            .id()
            .field("title", .string, .required)
            .field("description", .string)
            .field("starts_at", .datetime, .required)
            .field("ends_at", .datetime)
            .field("place_id", .uuid, .references(PlaceRecord.schema, "id", onDelete: .setNull))
            .field("capacity", .int)
            .field("host_id", .uuid, .required, .references(UserRecord.schema, "id", onDelete: .cascade))
            .field("space_id", .uuid, .references(SpaceRecord.schema, "id", onDelete: .setNull))
            .field("going_count", .int, .required, .sql(.default(0)))
            .field("interested_count", .int, .required, .sql(.default(0)))
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()

        try await database.execute(sql: """
            ALTER TABLE events ADD CONSTRAINT events_end_after_start
            CHECK (ends_at IS NULL OR ends_at >= starts_at)
            """)
        try await database.execute(sql: """
            ALTER TABLE events ADD CONSTRAINT events_capacity_positive
            CHECK (capacity IS NULL OR capacity > 0)
            """)
    }

    func revert(on database: any Database) async throws {
        try await database.schema(EventRecord.schema).delete()
    }
}

struct CreateEventRSVP: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(EventRSVPRecord.schema)
            .id()
            .field("event_id", .uuid, .required, .references(EventRecord.schema, "id", onDelete: .cascade))
            .field("user_id", .uuid, .required, .references(UserRecord.schema, "id", onDelete: .cascade))
            .field("status", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "event_id", "user_id")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(EventRSVPRecord.schema).delete()
    }
}
