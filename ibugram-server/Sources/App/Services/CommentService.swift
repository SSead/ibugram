import Fluent
import Foundation
import IBUgramKit
import SQLKit
import Vapor

struct CommentService: Sendable {
    func list(
        postId: UUID,
        page: IBUgramKit.PageRequest,
        viewer: UserRecord,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> Paginated<Comment> {
        _ = try await PostService().requireVisiblePost(postId, viewer: viewer, on: database)
        let viewerId = try viewer.requireID()
        let sql = try sqlDatabase(database)
        var query: SQLQueryString = """
            SELECT comments.id, EXTRACT(EPOCH FROM comments.created_at) AS created_epoch
            FROM comments
            WHERE comments.post_id = \(bind: postId)
              AND NOT EXISTS (
                SELECT 1 FROM blocks
                WHERE (blocker_id = \(bind: viewerId) AND blocked_id = comments.author_id)
                   OR (blocked_id = \(bind: viewerId) AND blocker_id = comments.author_id)
            )
            """
        if let cursor = page.cursor {
            let decoded = try KeysetCursor.decode(cursor)
            query += """
                 AND (comments.created_at, comments.id) > (TO_TIMESTAMP(\(bind: decoded.date.timeIntervalSince1970)), \(bind: decoded.id))
                """
        }
        query += """
             ORDER BY comments.created_at ASC, comments.id ASC
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
        let items = try await assemble(ids: ids, viewerId: viewerId, urls: urls, on: database)
        return Paginated(items: items, nextCursor: nextCursor)
    }

    func create(
        postId: UUID,
        body: CreateCommentBody,
        viewer: UserRecord,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> Comment {
        let post = try await PostService().requireVisiblePost(postId, viewer: viewer, on: database)
        guard post.commentsEnabled else {
            throw APIError.forbidden("Comments are turned off on this post.")
        }
        let text = body.body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (1...1_000).contains(text.count) else {
            throw APIError.validationFailed(
                "A comment must be between 1 and 1000 characters.",
                details: ["body": .string("length")]
            )
        }
        if let parentId = body.parentId {
            guard let parent = try await CommentRecord.find(parentId, on: database),
                  parent.$post.id == postId
            else {
                throw APIError.notFound("That comment does not exist on this post.")
            }
        }
        let commentId = UUID()
        try await database.transaction { transaction in
            let comment = CommentRecord()
            comment.id = commentId
            comment.$post.id = postId
            comment.$author.id = try viewer.requireID()
            comment.$parent.id = body.parentId
            comment.body = text
            comment.likeCount = 0
            comment.replyCount = 0
            try await comment.create(on: transaction)
            try await writeMentions(text: text, commentId: commentId, on: transaction)
        }
        let assembled = try await assemble(ids: [commentId], viewerId: try viewer.requireID(), urls: urls, on: database)
        guard let created = assembled.first else {
            throw APIError(code: .internalError, message: "The comment could not be loaded after saving.")
        }
        return created
    }

    func delete(id: UUID, viewer: UserRecord, on database: any Database) async throws {
        guard let comment = try await CommentRecord.find(id, on: database) else {
            throw APIError.notFound("That comment does not exist.")
        }
        guard comment.$author.id == (try viewer.requireID()) else {
            throw APIError.forbidden("Only the author can delete this comment.")
        }
        try await comment.delete(on: database)
    }

    func like(id: UUID, viewer: UserRecord, on database: any Database) async throws {
        let comment = try await requireVisibleComment(id, viewer: viewer, on: database)
        let row = CommentLikeRecord()
        row.$comment.id = try comment.requireID()
        row.$user.id = try viewer.requireID()
        try await insertIgnoringConflict(row, on: database)
    }

    func unlike(id: UUID, viewer: UserRecord, on database: any Database) async throws {
        try await CommentLikeRecord.query(on: database)
            .filter(\.$comment.$id == id)
            .filter(\.$user.$id == viewer.requireID())
            .delete()
    }

    private func requireVisibleComment(_ id: UUID, viewer: UserRecord, on database: any Database) async throws -> CommentRecord {
        guard let comment = try await CommentRecord.find(id, on: database) else {
            throw APIError.notFound("That comment does not exist.")
        }
        _ = try await PostService().requireVisiblePost(comment.$post.id, viewer: viewer, on: database)
        let hidden = try await ViewerLookup.hiddenAuthors(for: try viewer.requireID(), on: database)
        if hidden.contains(comment.$author.id) {
            throw APIError.notFound("That comment does not exist.")
        }
        return comment
    }

    private func assemble(ids: [UUID], viewerId: UUID, urls: MediaURLBuilder, on database: any Database) async throws -> [Comment] {
        guard !ids.isEmpty else { return [] }
        let records = try await CommentRecord.query(on: database)
            .filter(\.$id ~~ ids)
            .with(\.$author) { $0.with(\.$avatarMedia) }
            .all()
        let byId = Dictionary(uniqueKeysWithValues: records.compactMap { record -> (UUID, CommentRecord)? in
            guard let id = record.id else { return nil }
            return (id, record)
        })
        let ordered = ids.compactMap { byId[$0] }
        let lookup = try await ViewerLookup.load(
            viewerId: viewerId,
            userIds: ordered.map(\.$author.id),
            commentIds: ids,
            on: database
        )
        return try ordered.map { comment in
            try comment.asDTO(
                author: try comment.author.asDTO(
                    viewer: lookup.userState(for: comment.$author.id),
                    urls: urls
                ),
                viewer: lookup.commentState(for: comment.requireID())
            )
        }
    }

    private func writeMentions(text: String, commentId: UUID, on database: any Database) async throws {
        let names = HashtagParser.mentions(in: text)
        guard !names.isEmpty else { return }
        let users = try await UserRecord.query(on: database).filter(\.$username ~~ names).all()
        for user in users {
            let row = MentionRecord()
            row.$comment.id = commentId
            row.$user.id = try user.requireID()
            try await insertIgnoringConflict(row, on: database)
        }
    }
}
