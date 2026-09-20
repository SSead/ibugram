import Fluent

/// Counters live in the database rather than in a service because every future feature
/// team, seed script and manual fix writes through the same tables; a trigger is the one
/// place that cannot be bypassed. High-frequency counters step by one, while the small
/// status-bearing ones recompute so a missed event self-heals on the next write.
struct AddCounterTriggers: AsyncMigration {
    private static let functions = [
        """
        CREATE FUNCTION ibugram_post_like_counts() RETURNS trigger AS $$
        BEGIN
          IF TG_OP = 'INSERT' THEN
            UPDATE posts SET like_count = like_count + 1 WHERE id = NEW.post_id;
          ELSE
            UPDATE posts SET like_count = GREATEST(like_count - 1, 0) WHERE id = OLD.post_id;
          END IF;
          RETURN NULL;
        END; $$ LANGUAGE plpgsql
        """,
        """
        CREATE FUNCTION ibugram_comment_like_counts() RETURNS trigger AS $$
        BEGIN
          IF TG_OP = 'INSERT' THEN
            UPDATE comments SET like_count = like_count + 1 WHERE id = NEW.comment_id;
          ELSE
            UPDATE comments SET like_count = GREATEST(like_count - 1, 0) WHERE id = OLD.comment_id;
          END IF;
          RETURN NULL;
        END; $$ LANGUAGE plpgsql
        """,
        """
        CREATE FUNCTION ibugram_comment_counts() RETURNS trigger AS $$
        BEGIN
          IF TG_OP = 'INSERT' THEN
            UPDATE posts SET comment_count = comment_count + 1 WHERE id = NEW.post_id;
            IF NEW.parent_id IS NOT NULL THEN
              UPDATE comments SET reply_count = reply_count + 1 WHERE id = NEW.parent_id;
            END IF;
          ELSE
            UPDATE posts SET comment_count = GREATEST(comment_count - 1, 0) WHERE id = OLD.post_id;
            IF OLD.parent_id IS NOT NULL THEN
              UPDATE comments SET reply_count = GREATEST(reply_count - 1, 0) WHERE id = OLD.parent_id;
            END IF;
          END IF;
          RETURN NULL;
        END; $$ LANGUAGE plpgsql
        """,
        """
        CREATE FUNCTION ibugram_post_counts() RETURNS trigger AS $$
        BEGIN
          IF TG_OP = 'INSERT' THEN
            UPDATE users SET post_count = post_count + 1 WHERE id = NEW.author_id;
          ELSE
            UPDATE users SET post_count = GREATEST(post_count - 1, 0) WHERE id = OLD.author_id;
          END IF;
          RETURN NULL;
        END; $$ LANGUAGE plpgsql
        """,
        """
        CREATE FUNCTION ibugram_follow_counts() RETURNS trigger AS $$
        BEGIN
          IF TG_OP = 'INSERT' THEN
            UPDATE users SET following_count = following_count + 1 WHERE id = NEW.follower_id;
            UPDATE users SET follower_count = follower_count + 1 WHERE id = NEW.followee_id;
          ELSE
            UPDATE users SET following_count = GREATEST(following_count - 1, 0) WHERE id = OLD.follower_id;
            UPDATE users SET follower_count = GREATEST(follower_count - 1, 0) WHERE id = OLD.followee_id;
          END IF;
          RETURN NULL;
        END; $$ LANGUAGE plpgsql
        """,
        """
        CREATE FUNCTION ibugram_hashtag_counts() RETURNS trigger AS $$
        BEGIN
          IF TG_OP = 'INSERT' THEN
            UPDATE hashtags SET post_count = post_count + 1 WHERE id = NEW.hashtag_id;
          ELSE
            UPDATE hashtags SET post_count = GREATEST(post_count - 1, 0) WHERE id = OLD.hashtag_id;
          END IF;
          RETURN NULL;
        END; $$ LANGUAGE plpgsql
        """,
        """
        CREATE FUNCTION ibugram_space_member_counts() RETURNS trigger AS $$
        DECLARE target uuid;
        BEGIN
          target := COALESCE(NEW.space_id, OLD.space_id);
          UPDATE spaces SET member_count = (
            SELECT count(*) FROM space_memberships
            WHERE space_id = target AND role <> 'pending'
          ) WHERE id = target;
          RETURN NULL;
        END; $$ LANGUAGE plpgsql
        """,
        """
        CREATE FUNCTION ibugram_event_rsvp_counts() RETURNS trigger AS $$
        DECLARE target uuid;
        BEGIN
          target := COALESCE(NEW.event_id, OLD.event_id);
          UPDATE events SET
            going_count = (SELECT count(*) FROM event_rsvps WHERE event_id = target AND status = 'going'),
            interested_count = (
              SELECT count(*) FROM event_rsvps WHERE event_id = target AND status = 'interested'
            )
          WHERE id = target;
          RETURN NULL;
        END; $$ LANGUAGE plpgsql
        """
    ]

    private struct Trigger {
        let table: String
        let events: String
        let function: String

        var name: String { "\(table)_counts" }
    }

    private static let triggers = [
        Trigger(table: "post_likes", events: "INSERT OR DELETE", function: "ibugram_post_like_counts"),
        Trigger(table: "comment_likes", events: "INSERT OR DELETE", function: "ibugram_comment_like_counts"),
        Trigger(table: "comments", events: "INSERT OR DELETE", function: "ibugram_comment_counts"),
        Trigger(table: "posts", events: "INSERT OR DELETE", function: "ibugram_post_counts"),
        Trigger(table: "follows", events: "INSERT OR DELETE", function: "ibugram_follow_counts"),
        Trigger(table: "post_hashtags", events: "INSERT OR DELETE", function: "ibugram_hashtag_counts"),
        Trigger(
            table: "space_memberships",
            events: "INSERT OR UPDATE OR DELETE",
            function: "ibugram_space_member_counts"
        ),
        Trigger(table: "event_rsvps", events: "INSERT OR UPDATE OR DELETE", function: "ibugram_event_rsvp_counts")
    ]

    func prepare(on database: any Database) async throws {
        for function in Self.functions {
            try await database.execute(sql: "\(unsafeRaw: function)")
        }
        for trigger in Self.triggers {
            try await database.execute(sql: """
                CREATE TRIGGER \(unsafeRaw: trigger.name) AFTER \(unsafeRaw: trigger.events)
                ON \(unsafeRaw: trigger.table)
                FOR EACH ROW EXECUTE FUNCTION \(unsafeRaw: trigger.function)()
                """)
        }
    }

    func revert(on database: any Database) async throws {
        for trigger in Self.triggers.reversed() {
            try await database.execute(sql: """
                DROP TRIGGER IF EXISTS \(unsafeRaw: trigger.name) ON \(unsafeRaw: trigger.table)
                """)
            try await database.execute(sql: "DROP FUNCTION IF EXISTS \(unsafeRaw: trigger.function)()")
        }
    }
}
