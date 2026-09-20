import Fluent
import Foundation
import IBUgramKit
import SQLKit
import Vapor

struct SearchService: Sendable {
    func search(
        query raw: String,
        scope: SearchScope,
        viewer: UserRecord,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> SearchResults {
        let query = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return SearchResults() }
        let viewerId = try viewer.requireID()
        var results = SearchResults()
        if scope == .all || scope == .users {
            results.users = try await searchUsers(query: query, viewerId: viewerId, urls: urls, on: database)
        }
        if scope == .all || scope == .posts {
            results.posts = try await searchPosts(query: query, viewerId: viewerId, urls: urls, on: database)
        }
        if scope == .all || scope == .hashtags {
            results.hashtags = try await searchHashtags(query: query, on: database)
        }
        if scope == .all || scope == .spaces {
            results.spaces = try await searchSpaces(query: query, urls: urls, on: database)
        }
        return results
    }

    func trending(on database: any Database) async throws -> [Hashtag] {
        let rows = try await HashtagRecord.query(on: database)
            .filter(\.$postCount > 0)
            .sort(\.$postCount, .descending)
            .sort(\.$tag, .ascending)
            .limit(20)
            .all()
        return try rows.map { try Hashtag(id: $0.requireID(), tag: $0.tag, postCount: $0.postCount) }
    }

    func posts(
        tagged tag: String,
        page: IBUgramKit.PageRequest,
        viewer: UserRecord,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> Paginated<Post> {
        let normalized = tag.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
            .lowercased()
        guard let hashtag = try await HashtagRecord.query(on: database).filter(\.$tag == normalized).first() else {
            return Paginated(items: [])
        }
        let hashtagId = try hashtag.requireID()
        let viewerId = try viewer.requireID()
        let sql = try sqlDatabase(database)
        var query: SQLQueryString = """
            SELECT posts.id, EXTRACT(EPOCH FROM posts.created_at) AS created_epoch
            FROM post_hashtags
            JOIN posts ON posts.id = post_hashtags.post_id
            WHERE post_hashtags.hashtag_id = \(bind: hashtagId)
              AND posts.is_archived = false
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

    private func searchUsers(
        query: String,
        viewerId: UUID,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> [IBUgramKit.User] {
        let sql = try sqlDatabase(database)
        let rows = try await sql.raw("""
            SELECT users.id
            FROM users
            WHERE users.username IS NOT NULL
              AND users.is_suspended = false
              AND users.search_vector @@ plainto_tsquery('simple', \(bind: query))
              AND NOT EXISTS (
                SELECT 1 FROM blocks
                WHERE (blocker_id = \(bind: viewerId) AND blocked_id = users.id)
                   OR (blocked_id = \(bind: viewerId) AND blocker_id = users.id)
              )
            ORDER BY ts_rank(users.search_vector, plainto_tsquery('simple', \(bind: query))) DESC,
                     users.follower_count DESC
            LIMIT 20
            """).all()
        let ids: [UUID] = try rows.map { try $0.decode(column: "id", as: UUID.self) }
        let users = try await loadUsers(ids: ids, on: database)
        let lookup = try await ViewerLookup.load(viewerId: viewerId, userIds: ids, on: database)
        return try users.map { user in
            try user.asDTO(viewer: lookup.userState(for: user.requireID()), urls: urls)
        }
    }

    private func searchPosts(
        query: String,
        viewerId: UUID,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> [Post] {
        let sql = try sqlDatabase(database)
        let rows = try await sql.raw("""
            SELECT posts.id
            FROM posts
            WHERE posts.is_archived = false
              AND posts.search_vector @@ plainto_tsquery('simple', \(bind: query))
              AND \(authorVisible(viewerId: viewerId))
            ORDER BY ts_rank(posts.search_vector, plainto_tsquery('simple', \(bind: query))) DESC,
                     posts.created_at DESC
            LIMIT 20
            """).all()
        let ids: [UUID] = try rows.map { try $0.decode(column: "id", as: UUID.self) }
        return try await PostService().assemble(ids: ids, viewerId: viewerId, urls: urls, on: database)
    }

    private func searchHashtags(query: String, on database: any Database) async throws -> [Hashtag] {
        let prefix = sanitizePrefix(query.trimmingCharacters(in: CharacterSet(charactersIn: "#")).lowercased())
        guard !prefix.isEmpty else { return [] }
        let sql = try sqlDatabase(database)
        let rows = try await sql.raw("""
            SELECT id, tag, post_count
            FROM hashtags
            WHERE tag LIKE \(bind: prefix + "%")
            ORDER BY post_count DESC, tag ASC
            LIMIT 20
            """).all()
        return try rows.map { row in
            Hashtag(
                id: try row.decode(column: "id", as: UUID.self),
                tag: try row.decode(column: "tag", as: String.self),
                postCount: try row.decode(column: "post_count", as: Int.self)
            )
        }
    }

    private func searchSpaces(query: String, urls: MediaURLBuilder, on database: any Database) async throws -> [SpaceSummary] {
        let sql = try sqlDatabase(database)
        let pattern = "%" + sanitizePrefix(query.lowercased()) + "%"
        let rows = try await sql.raw("""
            SELECT id FROM spaces
            WHERE lower(name) LIKE \(bind: pattern)
               OR lower(slug) LIKE \(bind: pattern)
            ORDER BY member_count DESC, name ASC
            LIMIT 20
            """).all()
        let ids: [UUID] = try rows.map { try $0.decode(column: "id", as: UUID.self) }
        guard !ids.isEmpty else { return [] }
        let spaces = try await SpaceRecord.query(on: database)
            .filter(\.$id ~~ ids)
            .with(\.$avatarMedia)
            .all()
        let byId = Dictionary(uniqueKeysWithValues: spaces.compactMap { space -> (UUID, SpaceRecord)? in
            guard let id = space.id else { return nil }
            return (id, space)
        })
        return try ids.compactMap { byId[$0] }.map { try $0.asSummary(urls: urls) }
    }

    private func sanitizePrefix(_ raw: String) -> String {
        raw.filter { $0 != "%" && $0 != "_" && $0 != "\\" }
    }
}
