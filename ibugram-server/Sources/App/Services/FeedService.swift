import Fluent
import Foundation
import IBUgramKit
import SQLKit
import Vapor

struct FeedService: Sendable {
    func following(
        viewer: UserRecord,
        page: IBUgramKit.PageRequest,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> Paginated<Post> {
        let viewerId = try viewer.requireID()
        let sql = try sqlDatabase(database)
        var query: SQLQueryString = """
            SELECT posts.id, EXTRACT(EPOCH FROM posts.created_at) AS created_epoch
            FROM posts
            WHERE posts.is_archived = false
              AND (
                    posts.author_id = \(bind: viewerId)
                 OR posts.author_id IN (SELECT followee_id FROM follows WHERE follower_id = \(bind: viewerId))
                 OR posts.space_id IN (
                        SELECT space_id FROM space_memberships
                        WHERE user_id = \(bind: viewerId) AND role <> 'pending'
                    )
              )
              AND \(authorVisible(viewerId: viewerId))
            """
        if let cursor = page.cursor {
            let decoded = try KeysetCursor.decode(cursor)
            query += """
                 AND (posts.created_at, posts.id) < (TO_TIMESTAMP(\(bind: decoded.date.timeIntervalSince1970)), \(bind: decoded.id))
                """
        }
        query += """
             ORDER BY posts.created_at DESC, posts.id DESC
            LIMIT \(unsafeRaw: String(page.limit + 1))
            """
        let rows = try await sql.raw(query).all()
        let (pageRows, nextCursor) = PageSlice.take(rows, limit: page.limit) { row in
            KeysetCursor.encode(
                date: (try? sqlEpochDate(row)) ?? Date(),
                id: (try? row.decode(column: "id", as: UUID.self)) ?? UUID()
            )
        }
        let ids: [UUID] = try pageRows.map { try $0.decode(column: "id", as: UUID.self) }
        let items = try await PostService().assemble(ids: ids, viewerId: viewerId, urls: urls, on: database)
        return Paginated(items: items, nextCursor: nextCursor)
    }

    /// Discover ranks campus-wide posts from the last 21 days.
    /// score = exp(-age_hours / 36) * (1 + ln(1+likes) + 1.6 ln(1+comments)) * department_boost
    /// Department boost is 1.3 when the author shares the viewer's department, else 1.0.
    func discover(
        viewer: UserRecord,
        page: IBUgramKit.PageRequest,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> Paginated<Post> {
        let viewerId = try viewer.requireID()
        let sql = try sqlDatabase(database)
        var query: SQLQueryString = """
            WITH ranked AS (
                SELECT posts.id,
                       posts.created_at,
                       ROUND((
                           EXP(-EXTRACT(EPOCH FROM (NOW() - posts.created_at)) / 3600.0 / 36.0)
                           * (1.0 + LN(1.0 + posts.like_count) + 1.6 * LN(1.0 + posts.comment_count))
                           * CASE
                               WHEN authors.department IS NOT NULL
                                AND authors.department = \(bind: viewer.department)
                               THEN 1.3 ELSE 1.0
                             END
                       )::numeric, 8) AS rank_score
                FROM posts
                JOIN users AS authors ON authors.id = posts.author_id
                WHERE posts.is_archived = false
                  AND posts.created_at > NOW() - INTERVAL '21 days'
                  AND \(authorVisible(viewerId: viewerId))
            )
            SELECT ranked.id,
                   EXTRACT(EPOCH FROM ranked.created_at) AS created_epoch,
                   ranked.rank_score::float8 AS rank_score
            FROM ranked
            WHERE TRUE
            """
        if let cursor = page.cursor {
            let decoded = try KeysetCursor.decodeRanked(cursor)
            query += """
                 AND (ranked.rank_score, ranked.created_at, ranked.id) < (
                    SELECT c.rank_score, c.created_at, c.id FROM ranked AS c WHERE c.id = \(bind: decoded.id)
                 )
                """
        }
        query += """
             ORDER BY ranked.rank_score DESC, ranked.created_at DESC, ranked.id DESC
            LIMIT \(unsafeRaw: String(page.limit + 1))
            """
        let rows = try await sql.raw(query).all()
        let (pageRows, nextCursor) = PageSlice.take(rows, limit: page.limit) { row in
            KeysetCursor.encodeRanked(
                score: (try? row.decode(column: "rank_score", as: Double.self)) ?? 0,
                date: (try? sqlEpochDate(row)) ?? Date(),
                id: (try? row.decode(column: "id", as: UUID.self)) ?? UUID()
            )
        }
        let ids: [UUID] = try pageRows.map { try $0.decode(column: "id", as: UUID.self) }
        let items = try await PostService().assemble(ids: ids, viewerId: viewerId, urls: urls, on: database)
        return Paginated(items: items, nextCursor: nextCursor)
    }
}
