import Fluent
import Foundation
import IBUgramKit
import SQLKit
import Vapor

struct ViewerLookup: Sendable {
    let viewerId: UUID
    let following: Set<UUID>
    let followedBy: Set<UUID>
    let blockedByViewer: Set<UUID>
    let blockedViewer: Set<UUID>
    let likedPostIds: Set<UUID>
    let savedPostIds: Set<UUID>
    let likedCommentIds: Set<UUID>

    var hiddenUserIds: Set<UUID> {
        blockedByViewer.union(blockedViewer)
    }

    func userState(for userId: UUID) -> UserViewerState {
        UserViewerState(
            isFollowing: following.contains(userId),
            isFollowedBy: followedBy.contains(userId),
            isBlocked: blockedByViewer.contains(userId)
        )
    }

    func postState(for postId: UUID) -> PostViewerState {
        PostViewerState(
            hasLiked: likedPostIds.contains(postId),
            hasSaved: savedPostIds.contains(postId)
        )
    }

    func commentState(for commentId: UUID) -> CommentViewerState {
        CommentViewerState(hasLiked: likedCommentIds.contains(commentId))
    }

    static func load(
        viewerId: UUID,
        userIds: [UUID],
        postIds: [UUID] = [],
        commentIds: [UUID] = [],
        on database: any Database
    ) async throws -> ViewerLookup {
        let uniqueUsers = Array(Set(userIds).subtracting([viewerId]))
        async let following = outgoingFollows(from: viewerId, to: uniqueUsers, on: database)
        async let followedBy = incomingFollows(to: viewerId, from: uniqueUsers, on: database)
        async let blockedByViewer = blocks(from: viewerId, to: uniqueUsers, on: database)
        async let blockedViewer = blocks(fromIds: uniqueUsers, to: viewerId, on: database)
        async let likedPosts = postLikes(by: viewerId, among: postIds, on: database)
        async let savedPosts = saves(by: viewerId, among: postIds, on: database)
        async let likedComments = commentLikes(by: viewerId, among: commentIds, on: database)
        return try await ViewerLookup(
            viewerId: viewerId,
            following: following,
            followedBy: followedBy,
            blockedByViewer: blockedByViewer,
            blockedViewer: blockedViewer,
            likedPostIds: likedPosts,
            savedPostIds: savedPosts,
            likedCommentIds: likedComments
        )
    }

    static func hiddenAuthors(for viewerId: UUID, on database: any Database) async throws -> Set<UUID> {
        let outgoing = try await BlockRecord.query(on: database).filter(\.$blocker.$id == viewerId).all()
        let incoming = try await BlockRecord.query(on: database).filter(\.$blocked.$id == viewerId).all()
        return Set(outgoing.map(\.$blocked.id)).union(incoming.map(\.$blocker.id))
    }
}

private func outgoingFollows(from viewerId: UUID, to userIds: [UUID], on database: any Database) async throws -> Set<UUID> {
    guard !userIds.isEmpty else { return [] }
    let rows = try await FollowRecord.query(on: database)
        .filter(\.$follower.$id == viewerId)
        .filter(\.$followee.$id ~~ userIds)
        .all()
    return Set(rows.map(\.$followee.id))
}

private func incomingFollows(to viewerId: UUID, from userIds: [UUID], on database: any Database) async throws -> Set<UUID> {
    guard !userIds.isEmpty else { return [] }
    let rows = try await FollowRecord.query(on: database)
        .filter(\.$followee.$id == viewerId)
        .filter(\.$follower.$id ~~ userIds)
        .all()
    return Set(rows.map(\.$follower.id))
}

private func blocks(from viewerId: UUID, to userIds: [UUID], on database: any Database) async throws -> Set<UUID> {
    guard !userIds.isEmpty else { return [] }
    let rows = try await BlockRecord.query(on: database)
        .filter(\.$blocker.$id == viewerId)
        .filter(\.$blocked.$id ~~ userIds)
        .all()
    return Set(rows.map(\.$blocked.id))
}

private func blocks(fromIds userIds: [UUID], to viewerId: UUID, on database: any Database) async throws -> Set<UUID> {
    guard !userIds.isEmpty else { return [] }
    let rows = try await BlockRecord.query(on: database)
        .filter(\.$blocked.$id == viewerId)
        .filter(\.$blocker.$id ~~ userIds)
        .all()
    return Set(rows.map(\.$blocker.id))
}

private func postLikes(by viewerId: UUID, among postIds: [UUID], on database: any Database) async throws -> Set<UUID> {
    guard !postIds.isEmpty else { return [] }
    let rows = try await PostLikeRecord.query(on: database)
        .filter(\.$user.$id == viewerId)
        .filter(\.$post.$id ~~ postIds)
        .all()
    return Set(rows.map(\.$post.id))
}

private func saves(by viewerId: UUID, among postIds: [UUID], on database: any Database) async throws -> Set<UUID> {
    guard !postIds.isEmpty else { return [] }
    let rows = try await SaveRecord.query(on: database)
        .filter(\.$user.$id == viewerId)
        .filter(\.$post.$id ~~ postIds)
        .all()
    return Set(rows.map(\.$post.id))
}

private func commentLikes(by viewerId: UUID, among commentIds: [UUID], on database: any Database) async throws -> Set<UUID> {
    guard !commentIds.isEmpty else { return [] }
    let rows = try await CommentLikeRecord.query(on: database)
        .filter(\.$user.$id == viewerId)
        .filter(\.$comment.$id ~~ commentIds)
        .all()
    return Set(rows.map(\.$comment.id))
}

struct SocialService: Sendable {
    func profile(
        username: String,
        viewer: UserRecord,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> IBUgramKit.User {
        let user = try await requireUser(username: username, on: database)
        let userId = try user.requireID()
        let viewerId = try viewer.requireID()
        if try await isBlocked(viewerId: viewerId, by: userId, on: database) {
            throw APIError.notFound("That account does not exist.")
        }
        let lookup = try await ViewerLookup.load(viewerId: viewerId, userIds: [userId], on: database)
        return try user.asDTO(viewer: lookup.userState(for: userId), urls: urls)
    }

    func usernameAvailability(_ raw: String, on database: any Database) async throws -> UsernameAvailability {
        let username = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard Username.validate(username) == nil else {
            return UsernameAvailability(available: false)
        }
        let taken = try await UserRecord.query(on: database).filter(\.$username == username).count()
        return UsernameAvailability(available: taken == 0)
    }

    func suggestedUsers(
        viewer: UserRecord,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> Paginated<IBUgramKit.User> {
        let viewerId = try viewer.requireID()
        guard let department = viewer.department, !department.isEmpty else {
            return Paginated(items: [])
        }
        let hidden = try await ViewerLookup.hiddenAuthors(for: viewerId, on: database)
        let following = try await FollowRecord.query(on: database)
            .filter(\.$follower.$id == viewerId)
            .all()
            .map(\.$followee.id)

        let query = UserRecord.query(on: database)
            .filter(\.$department == department)
            .filter(\.$id != viewerId)
            .filter(\.$username != nil)
            .filter(\.$isSuspended == false)
            .sort(\.$followerCount, .descending)
            .sort(\.$id, .descending)
            .limit(20)
        let excluded = Array(Set(following).union(hidden))
        if !excluded.isEmpty {
            query.filter(\.$id !~ excluded)
        }
        let users = try await query.all()
        let lookup = try await ViewerLookup.load(
            viewerId: viewerId,
            userIds: try users.map { try $0.requireID() },
            on: database
        )
        let items = try users.map { user in
            try user.asDTO(viewer: lookup.userState(for: user.requireID()), urls: urls)
        }
        return Paginated(items: items)
    }

    func followers(
        username: String,
        page: IBUgramKit.PageRequest,
        viewer: UserRecord,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> Paginated<IBUgramKit.User> {
        let user = try await visibleUser(username: username, viewer: viewer, on: database)
        return try await followList(
            of: user,
            direction: .followers,
            page: page,
            viewer: viewer,
            urls: urls,
            on: database
        )
    }

    func following(
        username: String,
        page: IBUgramKit.PageRequest,
        viewer: UserRecord,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> Paginated<IBUgramKit.User> {
        let user = try await visibleUser(username: username, viewer: viewer, on: database)
        return try await followList(
            of: user,
            direction: .following,
            page: page,
            viewer: viewer,
            urls: urls,
            on: database
        )
    }

    func follow(viewer: UserRecord, targetId: UUID, on database: any Database) async throws {
        let viewerId = try viewer.requireID()
        guard viewerId != targetId else {
            throw APIError.validationFailed("You cannot follow yourself.")
        }
        let target = try await requireUser(id: targetId, on: database)
        try await assertNotBlocked(viewerId: viewerId, otherId: try target.requireID(), on: database)
        let row = FollowRecord(followerId: viewerId, followeeId: try target.requireID())
        try await insertIgnoringConflict(row, on: database)
    }

    func unfollow(viewer: UserRecord, targetId: UUID, on database: any Database) async throws {
        let viewerId = try viewer.requireID()
        try await FollowRecord.query(on: database)
            .filter(\.$follower.$id == viewerId)
            .filter(\.$followee.$id == targetId)
            .delete()
    }

    func block(viewer: UserRecord, targetId: UUID, on database: any Database) async throws {
        let viewerId = try viewer.requireID()
        guard viewerId != targetId else {
            throw APIError.validationFailed("You cannot block yourself.")
        }
        _ = try await requireUser(id: targetId, on: database)
        try await database.transaction { transaction in
            try await FollowRecord.query(on: transaction)
                .group(.or) { group in
                    group.group(.and) {
                        $0.filter(\.$follower.$id == viewerId).filter(\.$followee.$id == targetId)
                    }
                    group.group(.and) {
                        $0.filter(\.$follower.$id == targetId).filter(\.$followee.$id == viewerId)
                    }
                }
                .delete()
            try await insertIgnoringConflict(
                BlockRecord(blockerId: viewerId, blockedId: targetId),
                on: transaction
            )
        }
    }

    func unblock(viewer: UserRecord, targetId: UUID, on database: any Database) async throws {
        try await BlockRecord.query(on: database)
            .filter(\.$blocker.$id == (try viewer.requireID()))
            .filter(\.$blocked.$id == targetId)
            .delete()
    }

    func requireUser(username: String, on database: any Database) async throws -> UserRecord {
        let normalized = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard let user = try await UserRecord.query(on: database).filter(\.$username == normalized).first() else {
            throw APIError.notFound("That account does not exist.")
        }
        return user
    }

    func requireUser(id: UUID, on database: any Database) async throws -> UserRecord {
        guard let user = try await UserRecord.find(id, on: database) else {
            throw APIError.notFound("That account does not exist.")
        }
        return user
    }

    func visibleUser(username: String, viewer: UserRecord, on database: any Database) async throws -> UserRecord {
        let user = try await requireUser(username: username, on: database)
        if try await isBlocked(viewerId: viewer.requireID(), by: user.requireID(), on: database) {
            throw APIError.notFound("That account does not exist.")
        }
        return user
    }

    func isBlocked(viewerId: UUID, by otherId: UUID, on database: any Database) async throws -> Bool {
        try await BlockRecord.query(on: database)
            .filter(\.$blocker.$id == otherId)
            .filter(\.$blocked.$id == viewerId)
            .count() > 0
    }

    func assertNotBlocked(viewerId: UUID, otherId: UUID, on database: any Database) async throws {
        if try await isBlocked(viewerId: viewerId, by: otherId, on: database) {
            throw APIError.notFound("That account does not exist.")
        }
        if try await BlockRecord.query(on: database)
            .filter(\.$blocker.$id == viewerId)
            .filter(\.$blocked.$id == otherId)
            .count() > 0
        {
            throw APIError.forbidden("Unblock this account before following.")
        }
    }
}

private enum FollowListDirection {
    case followers
    case following
}

extension SocialService {
    private func followList(
        of user: UserRecord,
        direction: FollowListDirection,
        page: IBUgramKit.PageRequest,
        viewer: UserRecord,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> Paginated<IBUgramKit.User> {
        let userId = try user.requireID()
        let viewerId = try viewer.requireID()
        let sql = try sqlDatabase(database)
        var query: SQLQueryString
        switch direction {
        case .followers:
            query = """
                SELECT follows.id, EXTRACT(EPOCH FROM follows.created_at) AS created_epoch, follows.follower_id AS user_id
                FROM follows
                WHERE follows.followee_id = \(bind: userId)
                """
        case .following:
            query = """
                SELECT follows.id, EXTRACT(EPOCH FROM follows.created_at) AS created_epoch, follows.followee_id AS user_id
                FROM follows
                WHERE follows.follower_id = \(bind: userId)
                """
        }
        query += """
             AND NOT EXISTS (
                SELECT 1 FROM blocks
                WHERE (blocker_id = \(bind: viewerId) AND blocked_id = follows.\(unsafeRaw: direction == .followers ? "follower_id" : "followee_id"))
                   OR (blocked_id = \(bind: viewerId) AND blocker_id = follows.\(unsafeRaw: direction == .followers ? "follower_id" : "followee_id"))
            )
            """
        if let cursor = page.cursor {
            let decoded = try KeysetCursor.decode(cursor)
            query += """
                 AND (follows.created_at, follows.id) < (TO_TIMESTAMP(\(bind: decoded.date.timeIntervalSince1970)), \(bind: decoded.id))
                """
        }
        query += """
             ORDER BY follows.created_at DESC, follows.id DESC
            LIMIT \(unsafeRaw: String(page.limit + 1))
            """
        let rows = try await sql.raw(query).all()
        let sliced = Array(rows.prefix(page.limit + 1))
        let (pageRows, nextCursor) = PageSlice.take(sliced, limit: page.limit) { row in
            let created = (try? sqlEpochDate(row)) ?? Date()
            let id = (try? row.decode(column: "id", as: UUID.self)) ?? UUID()
            return KeysetCursor.encode(date: created, id: id)
        }
        let userIds: [UUID] = try pageRows.map { try $0.decode(column: "user_id", as: UUID.self) }
        let users = try await loadUsers(ids: userIds, on: database)
        let lookup = try await ViewerLookup.load(viewerId: viewerId, userIds: userIds, on: database)
        let items = try users.map { user in
            try user.asDTO(viewer: lookup.userState(for: user.requireID()), urls: urls)
        }
        return Paginated(items: items, nextCursor: nextCursor)
    }
}

func insertIgnoringConflict(_ model: some Model, on database: any Database) async throws {
    do {
        try await model.create(on: database)
    } catch let error as any DatabaseError where error.isConstraintFailure {
        return
    }
}

func sqlDatabase(_ database: any Database) throws -> any SQLDatabase {
    guard let sql = database as? any SQLDatabase else {
        throw DatabaseCapabilityError.rawSQLUnsupported
    }
    return sql
}

func sqlEpochDate(_ row: SQLRow) throws -> Date {
    Date(timeIntervalSince1970: try row.decode(column: "created_epoch", as: Double.self))
}

func loadUsers(ids: [UUID], on database: any Database) async throws -> [UserRecord] {
    guard !ids.isEmpty else { return [] }
    let records = try await UserRecord.query(on: database)
        .filter(\.$id ~~ ids)
        .with(\.$avatarMedia)
        .all()
    let byId = Dictionary(uniqueKeysWithValues: records.compactMap { record -> (UUID, UserRecord)? in
        guard let id = record.id else { return nil }
        return (id, record)
    })
    return ids.compactMap { byId[$0] }
}
