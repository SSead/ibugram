import Fluent

/// One index per read path the API contract implies. Unique constraints already index
/// their own columns, so only the remaining access patterns appear here.
struct AddQueryIndexes: AsyncMigration {
    private static let definitions: [(name: String, body: String)] = [
        ("posts_author_created_idx", "posts (author_id, created_at DESC)"),
        ("posts_created_idx", "posts (created_at DESC)"),
        ("posts_space_created_idx", "posts (space_id, created_at DESC) WHERE space_id IS NOT NULL"),
        ("posts_event_idx", "posts (event_id) WHERE event_id IS NOT NULL"),
        ("posts_place_idx", "posts (place_id) WHERE place_id IS NOT NULL"),
        ("follows_followee_idx", "follows (followee_id, follower_id)"),
        ("blocks_blocked_idx", "blocks (blocked_id)"),
        ("comments_post_created_idx", "comments (post_id, created_at)"),
        ("comments_parent_created_idx", "comments (parent_id, created_at) WHERE parent_id IS NOT NULL"),
        ("post_likes_user_idx", "post_likes (user_id, created_at DESC)"),
        ("comment_likes_user_idx", "comment_likes (user_id)"),
        ("saves_user_created_idx", "saves (user_id, created_at DESC)"),
        ("post_hashtags_hashtag_idx", "post_hashtags (hashtag_id, post_id)"),
        ("hashtags_tag_prefix_idx", "hashtags (tag text_pattern_ops)"),
        ("hashtags_post_count_idx", "hashtags (post_count DESC)"),
        ("mentions_user_idx", "mentions (user_id)"),
        ("media_uploader_idx", "media (uploaded_by_id, created_at DESC)"),
        ("space_memberships_user_idx", "space_memberships (user_id, role)"),
        ("events_starts_idx", "events (starts_at)"),
        ("events_space_starts_idx", "events (space_id, starts_at) WHERE space_id IS NOT NULL"),
        ("event_rsvps_user_idx", "event_rsvps (user_id, status)"),
        ("places_coordinates_idx", "places (latitude, longitude)"),
        ("messages_conversation_created_idx", "messages (conversation_id, created_at DESC)"),
        ("conversation_participants_user_idx", "conversation_participants (user_id)"),
        ("message_reads_user_idx", "message_reads (user_id)"),
        ("notifications_recipient_created_idx", "notifications (recipient_id, created_at DESC)"),
        ("notifications_unread_idx", "notifications (recipient_id) WHERE is_read = false"),
        ("auth_sessions_user_active_idx", "auth_sessions (user_id) WHERE revoked_at IS NULL"),
        ("auth_sessions_family_idx", "auth_sessions (family_id)"),
        ("otp_challenges_email_created_idx", "otp_challenges (email, created_at DESC)"),
        ("reports_status_created_idx", "reports (status, created_at DESC)")
    ]

    func prepare(on database: any Database) async throws {
        for definition in Self.definitions {
            try await database.execute(sql: "CREATE INDEX \(unsafeRaw: definition.name) ON \(unsafeRaw: definition.body)")
        }
    }

    func revert(on database: any Database) async throws {
        for definition in Self.definitions.reversed() {
            try await database.execute(sql: "DROP INDEX IF EXISTS \(unsafeRaw: definition.name)")
        }
    }
}
