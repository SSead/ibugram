import Fluent

struct CreatePost: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(PostRecord.schema)
            .id()
            .field("author_id", .uuid, .required, .references(UserRecord.schema, "id", onDelete: .cascade))
            .field("space_id", .uuid, .references(SpaceRecord.schema, "id", onDelete: .setNull))
            .field("event_id", .uuid, .references(EventRecord.schema, "id", onDelete: .setNull))
            .field("place_id", .uuid, .references(PlaceRecord.schema, "id", onDelete: .setNull))
            .field("caption", .string)
            .field("comments_enabled", .bool, .required, .sql(.default(true)))
            .field("is_archived", .bool, .required, .sql(.default(false)))
            .field("like_count", .int, .required, .sql(.default(0)))
            .field("comment_count", .int, .required, .sql(.default(0)))
            .field("edited_at", .datetime)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(PostRecord.schema).delete()
    }
}

struct CreatePostMedia: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(PostMediaRecord.schema)
            .id()
            .field("post_id", .uuid, .required, .references(PostRecord.schema, "id", onDelete: .cascade))
            .field("media_id", .uuid, .required, .references(MediaRecord.schema, "id", onDelete: .cascade))
            .field("position", .int, .required)
            .field("created_at", .datetime)
            .unique(on: "post_id", "media_id")
            .unique(on: "post_id", "position")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(PostMediaRecord.schema).delete()
    }
}

struct CreateHashtag: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(HashtagRecord.schema)
            .id()
            .field("tag", .string, .required)
            .field("post_count", .int, .required, .sql(.default(0)))
            .field("created_at", .datetime)
            .unique(on: "tag")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(HashtagRecord.schema).delete()
    }
}

struct CreatePostHashtag: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(PostHashtagRecord.schema)
            .id()
            .field("post_id", .uuid, .required, .references(PostRecord.schema, "id", onDelete: .cascade))
            .field("hashtag_id", .uuid, .required, .references(HashtagRecord.schema, "id", onDelete: .cascade))
            .field("created_at", .datetime)
            .unique(on: "post_id", "hashtag_id")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(PostHashtagRecord.schema).delete()
    }
}

struct CreateComment: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(CommentRecord.schema)
            .id()
            .field("post_id", .uuid, .required, .references(PostRecord.schema, "id", onDelete: .cascade))
            .field("author_id", .uuid, .required, .references(UserRecord.schema, "id", onDelete: .cascade))
            .field("parent_id", .uuid, .references(CommentRecord.schema, "id", onDelete: .cascade))
            .field("body", .string, .required)
            .field("like_count", .int, .required, .sql(.default(0)))
            .field("reply_count", .int, .required, .sql(.default(0)))
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(CommentRecord.schema).delete()
    }
}

struct CreateMention: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(MentionRecord.schema)
            .id()
            .field("post_id", .uuid, .references(PostRecord.schema, "id", onDelete: .cascade))
            .field("comment_id", .uuid, .references(CommentRecord.schema, "id", onDelete: .cascade))
            .field("user_id", .uuid, .required, .references(UserRecord.schema, "id", onDelete: .cascade))
            .field("created_at", .datetime)
            .create()

        try await database.execute(sql: """
            ALTER TABLE mentions ADD CONSTRAINT mentions_exactly_one_subject
            CHECK ((post_id IS NULL) <> (comment_id IS NULL))
            """)
        try await database.execute(sql: """
            CREATE UNIQUE INDEX mentions_post_user_key ON mentions (post_id, user_id)
            WHERE post_id IS NOT NULL
            """)
        try await database.execute(sql: """
            CREATE UNIQUE INDEX mentions_comment_user_key ON mentions (comment_id, user_id)
            WHERE comment_id IS NOT NULL
            """)
    }

    func revert(on database: any Database) async throws {
        try await database.schema(MentionRecord.schema).delete()
    }
}

struct CreatePostLike: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(PostLikeRecord.schema)
            .id()
            .field("post_id", .uuid, .required, .references(PostRecord.schema, "id", onDelete: .cascade))
            .field("user_id", .uuid, .required, .references(UserRecord.schema, "id", onDelete: .cascade))
            .field("created_at", .datetime)
            .unique(on: "post_id", "user_id")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(PostLikeRecord.schema).delete()
    }
}

struct CreateCommentLike: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(CommentLikeRecord.schema)
            .id()
            .field("comment_id", .uuid, .required, .references(CommentRecord.schema, "id", onDelete: .cascade))
            .field("user_id", .uuid, .required, .references(UserRecord.schema, "id", onDelete: .cascade))
            .field("created_at", .datetime)
            .unique(on: "comment_id", "user_id")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(CommentLikeRecord.schema).delete()
    }
}

struct CreateSave: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(SaveRecord.schema)
            .id()
            .field("user_id", .uuid, .required, .references(UserRecord.schema, "id", onDelete: .cascade))
            .field("post_id", .uuid, .required, .references(PostRecord.schema, "id", onDelete: .cascade))
            .field("collection_name", .string)
            .field("created_at", .datetime)
            .unique(on: "user_id", "post_id")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(SaveRecord.schema).delete()
    }
}
