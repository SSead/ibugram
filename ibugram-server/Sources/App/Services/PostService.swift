import Fluent
import Foundation
import IBUgramKit
import SQLKit
import Vapor

struct PostService: Sendable {
    func postsForUsername(
        _ username: String,
        page: IBUgramKit.PageRequest,
        viewer: UserRecord,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> Paginated<Post> {
        let author = try await SocialService().visibleUser(username: username, viewer: viewer, on: database)
        return try await pagePosts(
            whereSQL: "posts.author_id = \(bind: author.requireID()) AND posts.is_archived = false",
            page: page,
            viewer: viewer,
            urls: urls,
            on: database
        )
    }

    func savedPosts(
        viewer: UserRecord,
        page: IBUgramKit.PageRequest,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> Paginated<Post> {
        let viewerId = try viewer.requireID()
        let sql = try sqlDatabase(database)
        var query: SQLQueryString = """
            SELECT posts.id, EXTRACT(EPOCH FROM saves.created_at) AS created_epoch, saves.id AS cursor_id
            FROM saves
            JOIN posts ON posts.id = saves.post_id
            WHERE saves.user_id = \(bind: viewerId)
              AND posts.is_archived = false
              AND \(authorVisible(viewerId: viewerId))
            """
        if let cursor = page.cursor {
            let decoded = try KeysetCursor.decode(cursor)
            query += """
                 AND (saves.created_at, saves.id) < (TO_TIMESTAMP(\(bind: decoded.date.timeIntervalSince1970)), \(bind: decoded.id))
                """
        }
        query += """
             ORDER BY saves.created_at DESC, saves.id DESC
            LIMIT \(unsafeRaw: String(page.limit + 1))
            """
        let rows = try await sql.raw(query).all()
        let (pageRows, nextCursor) = PageSlice.take(rows, limit: page.limit) { row in
            KeysetCursor.encode(
                date: (try? sqlEpochDate(row)) ?? Date(),
                id: (try? row.decode(column: "cursor_id", as: UUID.self)) ?? UUID()
            )
        }
        let ids: [UUID] = try pageRows.map { try $0.decode(column: "id", as: UUID.self) }
        let items = try await assemble(ids: ids, viewerId: viewerId, urls: urls, on: database)
        return Paginated(items: items, nextCursor: nextCursor)
    }

    func create(
        body: CreatePostBody,
        author: UserRecord,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> Post {
        let authorId = try author.requireID()
        try validate(body)
        let media = try await loadOwnedMedia(ids: body.mediaIds, authorId: authorId, on: database)
        let postId = UUID()
        try await database.transaction { transaction in
            let post = PostRecord()
            post.id = postId
            post.$author.id = authorId
            post.caption = trimmedCaption(body.caption)
            post.commentsEnabled = body.commentsEnabled
            post.isArchived = false
            post.likeCount = 0
            post.commentCount = 0
            post.$space.id = try await resolveSpace(body.spaceId, authorId: authorId, on: transaction)
            post.$place.id = try await resolvePlace(body.place, on: transaction)
            post.$event.id = try await resolveEvent(body.event, hostId: authorId, on: transaction)
            try await post.create(on: transaction)
            try await attach(media: media, to: postId, on: transaction)
            try await writeTags(caption: post.caption, postId: postId, on: transaction)
        }
        let assembled = try await assemble(ids: [postId], viewerId: authorId, urls: urls, on: database)
        guard let created = assembled.first else {
            throw APIError(code: .internalError, message: "The post could not be loaded after saving.")
        }
        return created
    }

    func detail(id: UUID, viewer: UserRecord, urls: MediaURLBuilder, on database: any Database) async throws -> Post {
        let viewerId = try viewer.requireID()
        let post = try await requirePost(id, on: database)
        if post.isArchived, post.$author.id != viewerId {
            throw APIError.notFound("That post does not exist.")
        }
        try await denyIfAuthorHidden(post.$author.id, viewerId: viewerId, on: database)
        let assembled = try await assemble(ids: [id], viewerId: viewerId, urls: urls, on: database)
        guard let dto = assembled.first else {
            throw APIError.notFound("That post does not exist.")
        }
        return dto
    }

    func update(
        id: UUID,
        body: UpdatePostBody,
        viewer: UserRecord,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> Post {
        let viewerId = try viewer.requireID()
        let post = try await requirePost(id, on: database)
        guard post.$author.id == viewerId else {
            throw APIError.forbidden("Only the author can edit this post.")
        }
        try await database.transaction { transaction in
            if let caption = body.caption {
                post.caption = trimmedCaption(caption)
                try await replaceTags(caption: post.caption, postId: id, on: transaction)
            }
            if let commentsEnabled = body.commentsEnabled {
                post.commentsEnabled = commentsEnabled
            }
            post.editedAt = Date()
            try await post.save(on: transaction)
        }
        return try await detail(id: id, viewer: viewer, urls: urls, on: database)
    }

    func delete(id: UUID, viewer: UserRecord, on database: any Database) async throws {
        let post = try await requirePost(id, on: database)
        guard post.$author.id == (try viewer.requireID()) else {
            throw APIError.forbidden("Only the author can delete this post.")
        }
        try await post.delete(on: database)
    }

    func like(id: UUID, viewer: UserRecord, on database: any Database) async throws {
        let post = try await requireVisiblePost(id, viewer: viewer, on: database)
        let row = PostLikeRecord()
        row.$post.id = try post.requireID()
        row.$user.id = try viewer.requireID()
        try await insertIgnoringConflict(row, on: database)
    }

    func unlike(id: UUID, viewer: UserRecord, on database: any Database) async throws {
        try await PostLikeRecord.query(on: database)
            .filter(\.$post.$id == id)
            .filter(\.$user.$id == (try viewer.requireID()))
            .delete()
    }

    func save(id: UUID, viewer: UserRecord, on database: any Database) async throws {
        let post = try await requireVisiblePost(id, viewer: viewer, on: database)
        let row = SaveRecord()
        row.$post.id = try post.requireID()
        row.$user.id = try viewer.requireID()
        try await insertIgnoringConflict(row, on: database)
    }

    func unsave(id: UUID, viewer: UserRecord, on database: any Database) async throws {
        try await SaveRecord.query(on: database)
            .filter(\.$post.$id == id)
            .filter(\.$user.$id == (try viewer.requireID()))
            .delete()
    }

    func likes(
        id: UUID,
        page: IBUgramKit.PageRequest,
        viewer: UserRecord,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> Paginated<IBUgramKit.User> {
        _ = try await requireVisiblePost(id, viewer: viewer, on: database)
        let viewerId = try viewer.requireID()
        let sql = try sqlDatabase(database)
        var query: SQLQueryString = """
            SELECT post_likes.id, EXTRACT(EPOCH FROM post_likes.created_at) AS created_epoch, post_likes.user_id
            FROM post_likes
            WHERE post_likes.post_id = \(bind: id)
              AND NOT EXISTS (
                SELECT 1 FROM blocks
                WHERE (blocker_id = \(bind: viewerId) AND blocked_id = post_likes.user_id)
                   OR (blocked_id = \(bind: viewerId) AND blocker_id = post_likes.user_id)
            )
            """
        if let cursor = page.cursor {
            let decoded = try KeysetCursor.decode(cursor)
            query += """
                 AND (post_likes.created_at, post_likes.id) < (TO_TIMESTAMP(\(bind: decoded.date.timeIntervalSince1970)), \(bind: decoded.id))
                """
        }
        query += """
             ORDER BY post_likes.created_at DESC, post_likes.id DESC
            LIMIT \(unsafeRaw: String(page.limit + 1))
            """
        let rows = try await sql.raw(query).all()
        let (pageRows, nextCursor) = PageSlice.take(rows, limit: page.limit) { row in
            KeysetCursor.encode(
                date: (try? sqlEpochDate(row)) ?? Date(),
                id: (try? row.decode(column: "id", as: UUID.self)) ?? UUID()
            )
        }
        let userIds: [UUID] = try pageRows.map { try $0.decode(column: "user_id", as: UUID.self) }
        let users = try await loadUsers(ids: userIds, on: database)
        let lookup = try await ViewerLookup.load(viewerId: viewerId, userIds: userIds, on: database)
        let items = try users.map { user in
            try user.asDTO(viewer: lookup.userState(for: user.requireID()), urls: urls)
        }
        return Paginated(items: items, nextCursor: nextCursor)
    }

    func requireVisiblePost(_ id: UUID, viewer: UserRecord, on database: any Database) async throws -> PostRecord {
        let post = try await requirePost(id, on: database)
        let viewerId = try viewer.requireID()
        if post.isArchived, post.$author.id != viewerId {
            throw APIError.notFound("That post does not exist.")
        }
        try await denyIfAuthorHidden(post.$author.id, viewerId: viewerId, on: database)
        return post
    }

    func assemble(
        ids: [UUID],
        viewerId: UUID,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> [Post] {
        guard !ids.isEmpty else { return [] }
        let records = try await PostRecord.query(on: database)
            .filter(\.$id ~~ ids)
            .with(\.$author) { $0.with(\.$avatarMedia) }
            .with(\.$attachedMedia) { $0.with(\.$media) }
            .with(\.$space) { $0.with(\.$avatarMedia) }
            .with(\.$event) { event in
                event.with(\.$host) { $0.with(\.$avatarMedia) }
                event.with(\.$place)
                event.with(\.$space) { $0.with(\.$avatarMedia) }
            }
            .with(\.$place)
            .all()
        let byId = Dictionary(uniqueKeysWithValues: records.compactMap { record -> (UUID, PostRecord)? in
            guard let id = record.id else { return nil }
            return (id, record)
        })
        let ordered = ids.compactMap { byId[$0] }
        let hashtags = try await hashtagsByPost(ids: ids, on: database)
        let mentionRecords = try await mentionsByPost(ids: ids, on: database)
        var userIds = Set(ordered.map(\.$author.id))
        for users in mentionRecords.values {
            userIds.formUnion(users.map(\.$user.id))
        }
        for post in ordered {
            if let event = post.event {
                userIds.insert(event.$host.id)
            }
        }
        let lookup = try await ViewerLookup.load(
            viewerId: viewerId,
            userIds: Array(userIds),
            postIds: ids,
            on: database
        )
        let mentionUsers = try await loadUsers(
            ids: Array(Set(mentionRecords.values.flatMap { $0.map(\.$user.id) })),
            on: database
        )
        let mentionDTOs = Dictionary(uniqueKeysWithValues: try mentionUsers.map { user in
            (try user.requireID(), try user.asDTO(viewer: lookup.userState(for: user.requireID()), urls: urls))
        })
        return try ordered.map { post in
            try mapPost(
                post,
                hashtags: hashtags[try post.requireID()] ?? [],
                mentionIds: (mentionRecords[try post.requireID()] ?? []).map(\.$user.id),
                mentionDTOs: mentionDTOs,
                lookup: lookup,
                urls: urls
            )
        }
    }
}

extension PostService {
    fileprivate func pagePosts(
        whereSQL: SQLQueryString,
        page: IBUgramKit.PageRequest,
        viewer: UserRecord,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> Paginated<Post> {
        let viewerId = try viewer.requireID()
        let sql = try sqlDatabase(database)
        var query: SQLQueryString = """
            SELECT posts.id, EXTRACT(EPOCH FROM posts.created_at) AS created_epoch
            FROM posts
            WHERE \(whereSQL)
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
        let items = try await assemble(ids: ids, viewerId: viewerId, urls: urls, on: database)
        return Paginated(items: items, nextCursor: nextCursor)
    }

    fileprivate func mapPost(
        _ post: PostRecord,
        hashtags: [String],
        mentionIds: [UUID],
        mentionDTOs: [UUID: IBUgramKit.User],
        lookup: ViewerLookup,
        urls: MediaURLBuilder
    ) throws -> Post {
        let author = try post.author.asDTO(viewer: lookup.userState(for: post.$author.id), urls: urls)
        return try post.asDTO(
            author: author,
            media: try post.carouselMedia(urls: urls),
            hashtags: hashtags,
            mentions: mentionIds.compactMap { mentionDTOs[$0] },
            space: try post.space.map { try $0.asSummary(urls: urls) },
            event: try post.event.map { try $0.asDTO(viewerRSVP: .none, urls: urls, postId: post.id) },
            location: try post.place.map { try $0.asDTO() },
            viewer: lookup.postState(for: post.requireID())
        )
    }

    fileprivate func requirePost(_ id: UUID, on database: any Database) async throws -> PostRecord {
        guard let post = try await PostRecord.find(id, on: database) else {
            throw APIError.notFound("That post does not exist.")
        }
        return post
    }

    fileprivate func denyIfAuthorHidden(_ authorId: UUID, viewerId: UUID, on database: any Database) async throws {
        let hidden = try await ViewerLookup.hiddenAuthors(for: viewerId, on: database)
        if hidden.contains(authorId) {
            throw APIError.notFound("That post does not exist.")
        }
    }

    fileprivate func validate(_ body: CreatePostBody) throws {
        let unique = Set(body.mediaIds)
        guard !body.mediaIds.isEmpty, body.mediaIds.count <= IBUgram.maxPostMediaCount else {
            throw APIError.validationFailed(
                "A post needs between 1 and \(IBUgram.maxPostMediaCount) images.",
                details: ["media_ids": .string("count")]
            )
        }
        guard unique.count == body.mediaIds.count else {
            throw APIError.validationFailed(
                "Each image can appear only once.",
                details: ["media_ids": .string("duplicate")]
            )
        }
        if let caption = body.caption, caption.count > 2_200 {
            throw APIError.validationFailed(
                "That caption is too long.",
                details: ["caption": .string("must be 2200 characters or fewer")]
            )
        }
    }

    fileprivate func trimmedCaption(_ caption: String?) -> String? {
        guard let caption else { return nil }
        let trimmed = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    fileprivate func loadOwnedMedia(ids: [UUID], authorId: UUID, on database: any Database) async throws -> [MediaRecord] {
        let records = try await MediaRecord.query(on: database).filter(\.$id ~~ ids).all()
        let byId = Dictionary(uniqueKeysWithValues: records.compactMap { media -> (UUID, MediaRecord)? in
            guard let id = media.id else { return nil }
            return (id, media)
        })
        return try ids.map { id in
            guard let media = byId[id] else {
                throw APIError.notFound("That image does not exist.")
            }
            guard media.$uploadedBy.id == authorId else {
                throw APIError.forbidden("You can only attach images you uploaded.")
            }
            return media
        }
    }

    fileprivate func attach(media: [MediaRecord], to postId: UUID, on database: any Database) async throws {
        for (index, item) in media.enumerated() {
            let row = PostMediaRecord()
            row.$post.id = postId
            row.$media.id = try item.requireID()
            row.position = index
            try await row.create(on: database)
        }
    }

    fileprivate func writeTags(caption: String?, postId: UUID, on database: any Database) async throws {
        guard let caption else { return }
        let tags = HashtagParser.hashtags(in: caption)
        let hashtags = try await upsertHashtags(tags, on: database)
        for hashtag in hashtags {
            let row = PostHashtagRecord()
            row.$post.id = postId
            row.$hashtag.id = try hashtag.requireID()
            try await insertIgnoringConflict(row, on: database)
        }
        let mentionNames = HashtagParser.mentions(in: caption)
        guard !mentionNames.isEmpty else { return }
        let users = try await UserRecord.query(on: database).filter(\.$username ~~ mentionNames).all()
        for user in users {
            let row = MentionRecord()
            row.$post.id = postId
            row.$user.id = try user.requireID()
            try await insertIgnoringConflict(row, on: database)
        }
    }

    fileprivate func replaceTags(caption: String?, postId: UUID, on database: any Database) async throws {
        try await PostHashtagRecord.query(on: database).filter(\.$post.$id == postId).delete()
        try await MentionRecord.query(on: database).filter(\.$post.$id == postId).delete()
        try await writeTags(caption: caption, postId: postId, on: database)
    }

    fileprivate func upsertHashtags(_ tags: [String], on database: any Database) async throws -> [HashtagRecord] {
        var records: [HashtagRecord] = []
        records.reserveCapacity(tags.count)
        for tag in tags {
            if let existing = try await HashtagRecord.query(on: database).filter(\.$tag == tag).first() {
                records.append(existing)
                continue
            }
            let created = HashtagRecord(tag: tag)
            do {
                try await created.create(on: database)
                records.append(created)
            } catch let error as any DatabaseError where error.isConstraintFailure {
                if let again = try await HashtagRecord.query(on: database).filter(\.$tag == tag).first() {
                    records.append(again)
                }
            }
        }
        return records
    }

    fileprivate func resolveSpace(_ spaceId: UUID?, authorId: UUID, on database: any Database) async throws -> UUID? {
        guard let spaceId else { return nil }
        guard let space = try await SpaceRecord.find(spaceId, on: database) else {
            throw APIError.notFound("That space does not exist.")
        }
        if space.visibility != .public {
            let membership = try await SpaceMembershipRecord.query(on: database)
                .filter(\.$space.$id == spaceId)
                .filter(\.$user.$id == authorId)
                .filter(\.$role != .pending)
                .first()
            guard membership != nil else {
                throw APIError.forbidden("You cannot post in that space.")
            }
        }
        return spaceId
    }

    fileprivate func resolvePlace(_ input: PlaceInput?, on database: any Database) async throws -> UUID? {
        guard let input else { return nil }
        if let id = input.id {
            guard try await PlaceRecord.find(id, on: database) != nil else {
                throw APIError.notFound("That place does not exist.")
            }
            return id
        }
        let place = PlaceRecord()
        place.id = UUID()
        place.name = input.name
        place.latitude = input.latitude
        place.longitude = input.longitude
        place.isCampusLocation = input.isCampusLocation
        try await place.create(on: database)
        return place.id
    }

    fileprivate func resolveEvent(_ input: PostEventInput?, hostId: UUID, on database: any Database) async throws -> UUID? {
        guard let input else { return nil }
        if let id = input.id {
            guard try await EventRecord.find(id, on: database) != nil else {
                throw APIError.notFound("That event does not exist.")
            }
            return id
        }
        guard let title = input.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty,
              let startsAt = input.startsAt
        else {
            throw APIError.validationFailed(
                "A new event needs a title and a start time.",
                details: ["event": .string("incomplete")]
            )
        }
        if let endsAt = input.endsAt, endsAt < startsAt {
            throw APIError.validationFailed("An event cannot end before it starts.")
        }
        if let capacity = input.capacity, capacity <= 0 {
            throw APIError.validationFailed("Capacity must be greater than zero.")
        }
        let event = EventRecord()
        event.id = UUID()
        event.title = title
        event.description = input.description
        event.startsAt = startsAt
        event.endsAt = input.endsAt
        event.$host.id = hostId
        event.$place.id = try await resolvePlace(input.place, on: database)
        event.capacity = input.capacity
        event.goingCount = 0
        event.interestedCount = 0
        try await event.create(on: database)
        return event.id
    }

    fileprivate func hashtagsByPost(ids: [UUID], on database: any Database) async throws -> [UUID: [String]] {
        guard !ids.isEmpty else { return [:] }
        let rows = try await PostHashtagRecord.query(on: database)
            .filter(\.$post.$id ~~ ids)
            .with(\.$hashtag)
            .all()
        var grouped: [UUID: [String]] = [:]
        for row in rows {
            grouped[row.$post.id, default: []].append(row.hashtag.tag)
        }
        return grouped
    }

    fileprivate func mentionsByPost(ids: [UUID], on database: any Database) async throws -> [UUID: [MentionRecord]] {
        guard !ids.isEmpty else { return [:] }
        let rows = try await MentionRecord.query(on: database)
            .filter(\.$post.$id ~~ ids)
            .all()
        var grouped: [UUID: [MentionRecord]] = [:]
        for row in rows {
            if let postId = row.$post.id {
                grouped[postId, default: []].append(row)
            }
        }
        return grouped
    }
}

func authorVisible(viewerId: UUID) -> SQLQueryString {
    """
    NOT EXISTS (
        SELECT 1 FROM blocks
        WHERE (blocker_id = \(bind: viewerId) AND blocked_id = posts.author_id)
           OR (blocked_id = \(bind: viewerId) AND blocker_id = posts.author_id)
    )
    AND EXISTS (
        SELECT 1 FROM users
        WHERE users.id = posts.author_id AND users.is_suspended = false
    )
    """
}
