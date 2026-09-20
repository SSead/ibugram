import Fluent
import Foundation
import IBUgramKit
import Vapor

struct SpaceService: Sendable {
    func browse(
        kind: SpaceKind?,
        page: IBUgramKit.PageRequest,
        viewerId: UUID,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> Paginated<Space> {
        var query = SpaceRecord.query(on: database)
            .with(\.$createdBy) { $0.with(\.$avatarMedia) }
            .sort(\.$createdAt, .descending)
            .sort(\.$id, .descending)
        if let kind {
            query = query.filter(\.$kind == kind)
        }
        if let (date, id) = try CommunityCursor.decode(page.cursor) {
            query = query.group(.or) { group in
                group.group(.and) { inner in
                    inner.filter(\.$createdAt == date)
                    inner.filter(\.$id < id)
                }
                group.filter(\.$createdAt < date)
            }
        }
        let rows = try await query.limit(page.limit + 1).all()
        let pageRows = Array(rows.prefix(page.limit))
        let roles = try await memberships(for: viewerId, spaceIds: pageRows.compactMap(\.id), on: database)
        let items = try pageRows.map { space in
            try space.asDTO(membership: roles[space.requireID()] ?? .none, urls: urls)
        }
        return Paginated(
            items: items,
            nextCursor: try nextCursor(rows: rows, limit: page.limit) { ($0.createdAt ?? Date(), try $0.requireID()) }
        )
    }

    func create(
        _ body: CreateSpaceBody,
        creator: UserRecord,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> Space {
        let slug = body.slug.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = body.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard SpaceSlug.isValid(slug) else {
            throw APIError.validationFailed(
                "That slug is not allowed.",
                details: ["slug": .string("invalid")]
            )
        }
        guard (1...80).contains(name.count) else {
            throw APIError.validationFailed(
                "A space needs a name between 1 and 80 characters.",
                details: ["name": .string("must be 1 to 80 characters")]
            )
        }
        if let description = body.description, description.count > 2_000 {
            throw APIError.validationFailed(
                "That description is too long.",
                details: ["description": .string("must be 2000 characters or fewer")]
            )
        }
        if body.isOfficial, creator.role != .faculty {
            throw APIError.forbidden("Only faculty can create official Spaces.")
        }

        let creatorId = try creator.requireID()
        try await MediaOwnership.ensure(body.avatarMediaId, belongsTo: creatorId, on: database)
        try await MediaOwnership.ensure(body.bannerMediaId, belongsTo: creatorId, on: database)

        let space = SpaceRecord()
        space.id = UUID()
        space.slug = slug
        space.name = name
        space.description = body.description
        space.kind = body.kind
        space.visibility = body.visibility
        space.isOfficial = body.isOfficial
        space.$avatarMedia.id = body.avatarMediaId
        space.$bannerMedia.id = body.bannerMediaId
        space.$createdBy.id = creatorId
        space.memberCount = 0
        do {
            try await space.create(on: database)
        } catch let error as any DatabaseError where error.isConstraintFailure {
            throw APIError.conflict("That space slug is already taken.")
        }

        let membership = SpaceMembershipRecord()
        membership.id = UUID()
        membership.$space.id = try space.requireID()
        membership.$user.id = creatorId
        membership.role = .owner
        try await membership.create(on: database)
        let saved = try await requireSpace(slug: space.slug, on: database)
        return try saved.asDTO(membership: .owner, urls: urls)
    }

    func detail(
        slug: String,
        viewerId: UUID,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> Space {
        let space = try await requireSpace(slug: slug, on: database)
        let role = try await membership(for: viewerId, spaceId: space.requireID(), on: database)
        return try space.asDTO(membership: role, urls: urls)
    }

    func update(
        slug: String,
        body: UpdateSpaceBody,
        actor: UserRecord,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> Space {
        let space = try await requireSpace(slug: slug, on: database)
        let actorId = try actor.requireID()
        let role = try await membership(for: actorId, spaceId: space.requireID(), on: database)
        guard role.canModerate else {
            throw APIError.forbidden("Only owners and moderators can edit this space.")
        }
        if let name = body.name {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard (1...80).contains(trimmed.count) else {
                throw APIError.validationFailed(
                    "A space needs a name between 1 and 80 characters.",
                    details: ["name": .string("must be 1 to 80 characters")]
                )
            }
            space.name = trimmed
        }
        if let description = body.description {
            guard description.count <= 2_000 else {
                throw APIError.validationFailed(
                    "That description is too long.",
                    details: ["description": .string("must be 2000 characters or fewer")]
                )
            }
            space.description = description
        }
        if let visibility = body.visibility {
            space.visibility = visibility
        }
        try await MediaOwnership.ensure(body.avatarMediaId, belongsTo: actorId, on: database)
        try await MediaOwnership.ensure(body.bannerMediaId, belongsTo: actorId, on: database)
        if let avatarMediaId = body.avatarMediaId {
            space.$avatarMedia.id = avatarMediaId
        }
        if let bannerMediaId = body.bannerMediaId {
            space.$bannerMedia.id = bannerMediaId
        }
        try await space.save(on: database)
        try await space.$createdBy.load(on: database)
        return try space.asDTO(membership: role, urls: urls)
    }

    func posts(
        slug: String,
        page: IBUgramKit.PageRequest,
        viewerId: UUID,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> Paginated<Post> {
        let space = try await requireSpace(slug: slug, on: database)
        let spaceId = try space.requireID()
        let role = try await membership(for: viewerId, spaceId: spaceId, on: database)
        guard SpaceAccess.canReadPosts(visibility: space.visibility, membership: role) else {
            throw APIError.forbidden("You must be a member to see posts in this space.")
        }

        var query = PostRecord.query(on: database)
            .filter(\.$space.$id == spaceId)
            .filter(\.$isArchived == false)
            .with(\.$author) { $0.with(\.$avatarMedia) }
            .with(\.$attachedMedia) { $0.with(\.$media) }
            .with(\.$place)
            .with(\.$space)
            .with(\.$event) { event in
                event.with(\.$host) { $0.with(\.$avatarMedia) }
                event.with(\.$place)
                event.with(\.$space)
            }
            .sort(\.$createdAt, .descending)
            .sort(\.$id, .descending)
        if let cursor = page.cursor {
            let decoded = try KeysetCursor.decode(cursor)
            query = query.group(.or) { group in
                group.group(.and) { inner in
                    inner.filter(\.$createdAt == decoded.date)
                    inner.filter(\.$id < decoded.id)
                }
                group.filter(\.$createdAt < decoded.date)
            }
        }
        let rows = try await query.limit(page.limit + 1).all()
        let pageRows = Array(rows.prefix(page.limit))
        let items = try await CommunityPostAssembler.assemble(
            posts: pageRows,
            viewerId: viewerId,
            urls: urls,
            on: database
        )
        return Paginated(
            items: items,
            nextCursor: try nextCursor(rows: rows, limit: page.limit) { ($0.createdAt ?? Date(), try $0.requireID()) }
        )
    }

    func members(
        slug: String,
        page: IBUgramKit.PageRequest,
        viewerId: UUID,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> Paginated<SpaceMember> {
        let space = try await requireSpace(slug: slug, on: database)
        let spaceId = try space.requireID()
        let role = try await membership(for: viewerId, spaceId: spaceId, on: database)
        guard SpaceAccess.canReadMembers(visibility: space.visibility, membership: role) else {
            throw APIError.forbidden("You must be a member to see this member list.")
        }

        var query = SpaceMembershipRecord.query(on: database)
            .filter(\.$space.$id == spaceId)
            .with(\.$user) { $0.with(\.$avatarMedia) }
            .sort(\.$createdAt, .ascending)
            .sort(\.$id, .ascending)
        if !role.canModerate {
            query = query.filter(\.$role != .pending)
        }
        if let cursor = page.cursor {
            let decoded = try KeysetCursor.decode(cursor)
            query = query.group(.or) { group in
                group.group(.and) { inner in
                    inner.filter(\.$createdAt == decoded.date)
                    inner.filter(\.$id > decoded.id)
                }
                group.filter(\.$createdAt > decoded.date)
            }
        }
        let rows = try await query.limit(page.limit + 1).all()
        let pageRows = Array(rows.prefix(page.limit))
        return Paginated(
            items: try pageRows.map { try $0.asDTO(urls: urls) },
            nextCursor: try nextCursor(rows: rows, limit: page.limit) { ($0.createdAt ?? Date(), try $0.requireID()) }
        )
    }

    func join(
        slug: String,
        userId: UUID,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> Space {
        let space = try await requireSpace(slug: slug, on: database)
        let spaceId = try space.requireID()
        if let existing = try await SpaceMembershipRecord.query(on: database)
            .filter(\.$space.$id == spaceId)
            .filter(\.$user.$id == userId)
            .first()
        {
            try await space.$createdBy.load(on: database)
            return try space.asDTO(membership: existing.role, urls: urls)
        }
        switch space.visibility {
        case .invite:
            throw APIError.forbidden("This space is invite-only.")
        case .public, .request:
            break
        }

        let membership = SpaceMembershipRecord()
        membership.id = UUID()
        membership.$space.id = spaceId
        membership.$user.id = userId
        membership.role = space.visibility == .public ? .member : .pending
        try await membership.create(on: database)
        let saved = try await requireSpace(slug: space.slug, on: database)
        return try saved.asDTO(membership: membership.role, urls: urls)
    }

    func leave(slug: String, userId: UUID, on database: any Database) async throws {
        let space = try await requireSpace(slug: slug, on: database)
        let spaceId = try space.requireID()
        guard let membership = try await SpaceMembershipRecord.query(on: database)
            .filter(\.$space.$id == spaceId)
            .filter(\.$user.$id == userId)
            .first()
        else {
            throw APIError.notFound("You are not a member of this space.")
        }
        if membership.role == .owner {
            let owners = try await ownerCount(spaceId: spaceId, on: database)
            if owners <= 1 {
                throw APIError.forbidden("The last owner cannot leave this space.")
            }
        }
        try await membership.delete(on: database)
    }

    func setRole(
        slug: String,
        targetUserId: UUID,
        newRole: SpaceMembership,
        actorId: UUID,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> SpaceMember {
        let space = try await requireSpace(slug: slug, on: database)
        let spaceId = try space.requireID()
        let actorRole = try await membership(for: actorId, spaceId: spaceId, on: database)
        guard actorRole.canModerate else {
            throw APIError.forbidden("Only owners and moderators can change member roles.")
        }
        if newRole == .pending {
            throw APIError.validationFailed(
                "A member cannot be moved to pending.",
                details: ["role": .string("pending is not a assignable role")]
            )
        }

        let existing = try await SpaceMembershipRecord.query(on: database)
            .filter(\.$space.$id == spaceId)
            .filter(\.$user.$id == targetUserId)
            .with(\.$user) { $0.with(\.$avatarMedia) }
            .first()

        if newRole == .none {
            try await removeMember(
                existing,
                actorRole: actorRole,
                spaceId: spaceId,
                targetUserId: targetUserId,
                on: database
            )
            guard let existing else {
                throw APIError.notFound("That person is not a member of this space.")
            }
            return try existing.asDTO(urls: urls)
        }

        if let existing {
            try await applyRoleChange(
                existing,
                newRole: newRole,
                actorRole: actorRole,
                spaceId: spaceId,
                on: database
            )
            return try existing.asDTO(urls: urls)
        }

        guard newRole != .owner || actorRole == .owner else {
            throw APIError.forbidden("Only an owner can grant ownership.")
        }
        guard actorRole == .owner || newRole != .owner else {
            throw APIError.forbidden("A moderator cannot assign the owner role.")
        }
        guard try await UserRecord.find(targetUserId, on: database) != nil else {
            throw APIError.notFound("That user does not exist.")
        }
        let membership = SpaceMembershipRecord()
        membership.id = UUID()
        membership.$space.id = spaceId
        membership.$user.id = targetUserId
        membership.role = newRole
        try await membership.create(on: database)
        let created = try await SpaceMembershipRecord.query(on: database)
            .filter(\.$id == membership.requireID())
            .with(\.$user) { $0.with(\.$avatarMedia) }
            .first()
        guard let created else {
            throw APIError.notFound("That user does not exist.")
        }
        return try created.asDTO(urls: urls)
    }

    func requireSpace(slug: String, on database: any Database) async throws -> SpaceRecord {
        let space = try await SpaceRecord.query(on: database)
            .filter(\.$slug == slug)
            .with(\.$createdBy) { $0.with(\.$avatarMedia) }
            .first()
        guard let space else {
            throw APIError.notFound("That space does not exist.")
        }
        return space
    }

    func membership(for userId: UUID, spaceId: UUID, on database: any Database) async throws -> SpaceMembership {
        try await SpaceMembershipRecord.query(on: database)
            .filter(\.$space.$id == spaceId)
            .filter(\.$user.$id == userId)
            .first()?.role ?? .none
    }

    func memberships(
        for userId: UUID,
        spaceIds: [UUID],
        on database: any Database
    ) async throws -> [UUID: SpaceMembership] {
        guard !spaceIds.isEmpty else { return [:] }
        let rows = try await SpaceMembershipRecord.query(on: database)
            .filter(\.$user.$id == userId)
            .filter(\.$space.$id ~~ spaceIds)
            .all()
        return Dictionary(uniqueKeysWithValues: rows.map { ($0.$space.id, $0.role) })
    }

    private func ownerCount(spaceId: UUID, on database: any Database) async throws -> Int {
        try await SpaceMembershipRecord.query(on: database)
            .filter(\.$space.$id == spaceId)
            .filter(\.$role == .owner)
            .count()
    }

    private func removeMember(
        _ existing: SpaceMembershipRecord?,
        actorRole: SpaceMembership,
        spaceId: UUID,
        targetUserId: UUID,
        on database: any Database
    ) async throws {
        guard let existing else { return }
        if existing.role == .owner {
            guard actorRole == .owner else {
                throw APIError.forbidden("A moderator cannot remove an owner.")
            }
            if try await ownerCount(spaceId: spaceId, on: database) <= 1 {
                throw APIError.forbidden("The last owner cannot be removed.")
            }
        }
        try await existing.delete(on: database)
        _ = targetUserId
    }

    private func applyRoleChange(
        _ existing: SpaceMembershipRecord,
        newRole: SpaceMembership,
        actorRole: SpaceMembership,
        spaceId: UUID,
        on database: any Database
    ) async throws {
        if existing.role == newRole { return }
        if existing.role == .owner {
            guard actorRole == .owner else {
                throw APIError.forbidden("A moderator cannot demote an owner.")
            }
            if newRole != .owner, try await ownerCount(spaceId: spaceId, on: database) <= 1 {
                throw APIError.forbidden("The last owner cannot demote themselves.")
            }
        }
        if newRole == .owner, actorRole != .owner {
            throw APIError.forbidden("Only an owner can grant ownership.")
        }
        existing.role = newRole
        try await existing.save(on: database)
    }
}

enum SpaceAccess {
    static func canReadPosts(visibility: SpaceVisibility, membership: SpaceMembership) -> Bool {
        switch visibility {
        case .public: true
        case .request, .invite: membership.canPost
        }
    }

    static func canReadMembers(visibility: SpaceVisibility, membership: SpaceMembership) -> Bool {
        switch visibility {
        case .public: true
        case .request, .invite: membership.canPost
        }
    }
}

enum MediaOwnership {
    static func ensure(_ mediaId: UUID?, belongsTo userId: UUID, on database: any Database) async throws {
        guard let mediaId else { return }
        guard let media = try await MediaRecord.find(mediaId, on: database) else {
            throw APIError.notFound("That image does not exist.")
        }
        guard media.$uploadedBy.id == userId else {
            throw APIError.forbidden("You can only use media you uploaded.")
        }
    }
}

func nextCursor<Row>(
    rows: [Row],
    limit: Int,
    stamp: (Row) throws -> (Date, UUID)
) rethrows -> String? {
    guard rows.count > limit, let last = rows.prefix(limit).last else { return nil }
    let (date, id) = try stamp(last)
    return KeysetCursor.encode(date: date, id: id)
}

enum CommunityPostAssembler {
    static func assemble(
        posts: [PostRecord],
        viewerId: UUID,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> [Post] {
        let postIds = posts.compactMap(\.id)
        guard !postIds.isEmpty else { return [] }

        let hashtagLinks = try await PostHashtagRecord.query(on: database)
            .filter(\.$post.$id ~~ postIds)
            .with(\.$hashtag)
            .all()
        var hashtags: [UUID: [String]] = [:]
        for link in hashtagLinks {
            hashtags[link.$post.id, default: []].append(link.hashtag.tag)
        }

        let mentionRows = try await MentionRecord.query(on: database)
            .filter(\.$post.$id ~~ postIds)
            .with(\.$user) { $0.with(\.$avatarMedia) }
            .all()
        var mentions: [UUID: [User]] = [:]
        for mention in mentionRows {
            guard let postId = mention.$post.id else { continue }
            mentions[postId, default: []].append(try mention.user.asDTO(urls: urls))
        }

        let likedIds = Set(
            try await PostLikeRecord.query(on: database)
                .filter(\.$user.$id == viewerId)
                .filter(\.$post.$id ~~ postIds)
                .all()
                .map(\.$post.id)
        )
        let savedIds = Set(
            try await SaveRecord.query(on: database)
                .filter(\.$user.$id == viewerId)
                .filter(\.$post.$id ~~ postIds)
                .all()
                .map(\.$post.id)
        )

        let eventIds = posts.compactMap(\.$event.id)
        var rsvps: [UUID: RSVPStatus] = [:]
        if !eventIds.isEmpty {
            let rows = try await EventRSVPRecord.query(on: database)
                .filter(\.$user.$id == viewerId)
                .filter(\.$event.$id ~~ eventIds)
                .all()
            rsvps = Dictionary(uniqueKeysWithValues: rows.map { ($0.$event.id, $0.status) })
        }

        return try posts.map { post in
            let id = try post.requireID()
            let event = try post.event.map { record in
                try record.asDTO(
                    viewerRSVP: rsvps[record.requireID()] ?? .none,
                    urls: urls,
                    postId: nil
                )
            }
            return try SpacePostMapper.dto(
                from: post,
                hashtags: hashtags[id] ?? [],
                mentions: mentions[id] ?? [],
                liked: likedIds.contains(id),
                saved: savedIds.contains(id),
                event: event,
                urls: urls
            )
        }
    }
}

extension AppServices {
    var spaces: SpaceService { SpaceService() }
}
