import Fluent
import Foundation
import IBUgramKit
import SQLKit
import Vapor

struct EventService: Sendable {
    func list(
        from: Date?,
        to: Date?,
        spaceId: UUID?,
        page: IBUgramKit.PageRequest,
        viewerId: UUID,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> Paginated<Event> {
        let start = from ?? Date()
        var query = EventRecord.query(on: database)
            .filter(\.$startsAt >= start)
            .with(\.$host) { $0.with(\.$avatarMedia) }
            .with(\.$place)
            .with(\.$space)
            .sort(\.$startsAt, .ascending)
            .sort(\.$id, .ascending)
        if let to {
            query = query.filter(\.$startsAt <= to)
        }
        if let spaceId {
            query = query.filter(\.$space.$id == spaceId)
        }
        if let (date, id) = try CommunityCursor.decode(page.cursor) {
            query = query.group(.or) { group in
                group.group(.and) { inner in
                    inner.filter(\.$startsAt == date)
                    inner.filter(\.$id > id)
                }
                group.filter(\.$startsAt > date)
            }
        }
        let rows = try await query.limit(page.limit + 1).all()
        let pageRows = Array(rows.prefix(page.limit))
        let items = try await mapEvents(pageRows, viewerId: viewerId, urls: urls, on: database)
        return Paginated(
            items: items,
            nextCursor: try nextCursor(rows: rows, limit: page.limit) { ($0.startsAt, try $0.requireID()) }
        )
    }

    func happeningNow(
        page: IBUgramKit.PageRequest,
        viewerId: UUID,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> Paginated<Event> {
        let now = Date()
        let windowStart = now.addingTimeInterval(-24 * 60 * 60)
        var query = EventRecord.query(on: database)
            .filter(\.$startsAt <= now)
            .group(.or) { group in
                group.filter(\.$endsAt >= now)
                group.group(.and) { inner in
                    inner.filter(\.$endsAt == nil)
                    inner.filter(\.$startsAt >= windowStart)
                }
            }
            .with(\.$host) { $0.with(\.$avatarMedia) }
            .with(\.$place)
            .with(\.$space)
            .sort(\.$startsAt, .descending)
            .sort(\.$id, .descending)
        if let (date, id) = try CommunityCursor.decode(page.cursor) {
            query = query.group(.or) { group in
                group.group(.and) { inner in
                    inner.filter(\.$startsAt == date)
                    inner.filter(\.$id < id)
                }
                group.filter(\.$startsAt < date)
            }
        }
        let rows = try await query.limit(page.limit + 1).all()
        let pageRows = Array(rows.prefix(page.limit))
        let items = try await mapEvents(pageRows, viewerId: viewerId, urls: urls, on: database)
        return Paginated(
            items: items,
            nextCursor: try nextCursor(rows: rows, limit: page.limit) { ($0.startsAt, try $0.requireID()) }
        )
    }

    func mapContents(
        bbox: BoundingBox,
        viewerId: UUID,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> MapContents {
        let places = try await PlaceRecord.query(on: database)
            .filter(\.$latitude >= bbox.minimumLatitude)
            .filter(\.$latitude <= bbox.maximumLatitude)
            .filter(\.$longitude >= bbox.minimumLongitude)
            .filter(\.$longitude <= bbox.maximumLongitude)
            .all()
        let placeIds = places.compactMap(\.id)
        guard !placeIds.isEmpty else { return MapContents() }

        let now = Date()
        let eventRows = try await EventRecord.query(on: database)
            .filter(\.$place.$id ~~ placeIds)
            .group(.or) { group in
                group.filter(\.$endsAt == nil)
                group.filter(\.$endsAt >= now)
            }
            .with(\.$host) { $0.with(\.$avatarMedia) }
            .with(\.$place)
            .with(\.$space)
            .sort(\.$startsAt, .ascending)
            .all()

        let postRows = try await PostRecord.query(on: database)
            .filter(\.$place.$id ~~ placeIds)
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
            .limit(IBUgram.maxPageSize)
            .all()

        let events = try await mapEvents(eventRows, viewerId: viewerId, urls: urls, on: database)
        let posts = try await CommunityPostAssembler.assemble(
            posts: postRows,
            viewerId: viewerId,
            urls: urls,
            on: database
        )
        return MapContents(events: events, posts: posts)
    }

    func create(
        _ body: CreateEventBody,
        host: UserRecord,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> Event {
        try validateCreate(body)
        let hostId = try host.requireID()
        if let spaceId = body.spaceId {
            try await ensureCanAttach(spaceId: spaceId, userId: hostId, on: database)
        }
        let placeId = try await PlaceLookup.resolve(body.place, on: database)?.id

        let event = EventRecord()
        event.id = UUID()
        event.title = body.title.trimmingCharacters(in: .whitespacesAndNewlines)
        event.description = body.description
        event.startsAt = body.startsAt
        event.endsAt = body.endsAt
        event.$place.id = placeId
        event.capacity = body.capacity
        event.$host.id = hostId
        event.$space.id = body.spaceId
        event.goingCount = 0
        event.interestedCount = 0
        try await event.create(on: database)
        return try await detail(id: event.requireID(), viewerId: hostId, urls: urls, on: database)
    }

    func detail(
        id: UUID,
        viewerId: UUID,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> Event {
        let event = try await requireEvent(id, on: database)
        let items = try await mapEvents([event], viewerId: viewerId, urls: urls, on: database)
        return items[0]
    }

    func update(
        id: UUID,
        body: UpdateEventBody,
        actorId: UUID,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> Event {
        let event = try await requireEvent(id, on: database)
        guard event.$host.id == actorId else {
            throw APIError.forbidden("Only the host can edit this event.")
        }
        if let title = body.title {
            let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard (1...120).contains(trimmed.count) else {
                throw APIError.validationFailed(
                    "A title must be between 1 and 120 characters.",
                    details: ["title": .string("must be 1 to 120 characters")]
                )
            }
            event.title = trimmed
        }
        if let description = body.description {
            guard description.count <= 4_000 else {
                throw APIError.validationFailed(
                    "That description is too long.",
                    details: ["description": .string("must be 4000 characters or fewer")]
                )
            }
            event.description = description
        }
        if let startsAt = body.startsAt {
            event.startsAt = startsAt
        }
        if let endsAt = body.endsAt {
            event.endsAt = endsAt
        }
        let effectiveEnd = event.endsAt
        if let effectiveEnd, effectiveEnd < event.startsAt {
            throw APIError.validationFailed(
                "An event cannot end before it starts.",
                details: ["ends_at": .string("must be on or after starts_at")]
            )
        }
        if let capacity = body.capacity {
            guard capacity > 0 else {
                throw APIError.validationFailed(
                    "Capacity must be greater than zero.",
                    details: ["capacity": .string("must be greater than zero")]
                )
            }
            event.capacity = capacity
        }
        if let place = body.place {
            event.$place.id = try await PlaceLookup.resolve(place, on: database)?.id
        }
        try await event.save(on: database)
        return try await detail(id: id, viewerId: actorId, urls: urls, on: database)
    }

    func delete(id: UUID, actorId: UUID, on database: any Database) async throws {
        let event = try await requireEvent(id, on: database)
        guard event.$host.id == actorId else {
            throw APIError.forbidden("Only the host can delete this event.")
        }
        try await event.delete(on: database)
    }

    func setRSVP(
        eventId: UUID,
        userId: UUID,
        status: RSVPStatus,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> Event {
        try await database.transaction { transaction in
            try await lockEvent(eventId, on: transaction)
            guard let event = try await EventRecord.find(eventId, on: transaction) else {
                throw APIError.notFound("That event does not exist.")
            }
            let existing = try await EventRSVPRecord.query(on: transaction)
                .filter(\.$event.$id == eventId)
                .filter(\.$user.$id == userId)
                .first()
            let alreadyGoing = existing?.status == .going
            if status == .going, !alreadyGoing {
                try await enforceCapacity(event, on: transaction)
            }
            if let existing {
                existing.status = status
                try await existing.save(on: transaction)
            } else {
                let rsvp = EventRSVPRecord()
                rsvp.id = UUID()
                rsvp.$event.id = eventId
                rsvp.$user.id = userId
                rsvp.status = status
                try await rsvp.create(on: transaction)
            }
        }
        return try await detail(id: eventId, viewerId: userId, urls: urls, on: database)
    }

    func attendees(
        eventId: UUID,
        page: IBUgramKit.PageRequest,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> Paginated<EventAttendee> {
        _ = try await requireEvent(eventId, on: database)
        var query = EventRSVPRecord.query(on: database)
            .filter(\.$event.$id == eventId)
            .filter(\.$status != .none)
            .with(\.$user) { $0.with(\.$avatarMedia) }
            .sort(\.$createdAt, .ascending)
            .sort(\.$id, .ascending)
        if let (date, id) = try CommunityCursor.decode(page.cursor) {
            query = query.group(.or) { group in
                group.group(.and) { inner in
                    inner.filter(\.$createdAt == date)
                    inner.filter(\.$id > id)
                }
                group.filter(\.$createdAt > date)
            }
        }
        let rows = try await query.limit(page.limit + 1).all()
        let pageRows = Array(rows.prefix(page.limit))
        return Paginated(
            items: try pageRows.map { try $0.asAttendee(urls: urls) },
            nextCursor: try nextCursor(rows: rows, limit: page.limit) { ($0.createdAt ?? Date(), try $0.requireID()) }
        )
    }

    /// Locks the event row so capacity checks and RSVP writes serialize in PostgreSQL.
    /// Two concurrent "last seat" RSVPs cannot both succeed because the second waits
    /// here until the first transaction commits and the going count is up to date.
    private func lockEvent(_ eventId: UUID, on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else {
            throw DatabaseCapabilityError.rawSQLUnsupported
        }
        try await sql.raw("SELECT id FROM events WHERE id = \(bind: eventId) FOR UPDATE").run()
    }

    private func enforceCapacity(_ event: EventRecord, on database: any Database) async throws {
        guard let capacity = event.capacity else { return }
        let going = try await EventRSVPRecord.query(on: database)
            .filter(\.$event.$id == event.requireID())
            .filter(\.$status == .going)
            .count()
        if going >= capacity {
            throw APIError.conflict("This event is full.")
        }
    }

    private func requireEvent(_ id: UUID, on database: any Database) async throws -> EventRecord {
        let event = try await EventRecord.query(on: database)
            .filter(\.$id == id)
            .with(\.$host) { $0.with(\.$avatarMedia) }
            .with(\.$place)
            .with(\.$space)
            .first()
        guard let event else {
            throw APIError.notFound("That event does not exist.")
        }
        return event
    }

    private func mapEvents(
        _ events: [EventRecord],
        viewerId: UUID,
        urls: MediaURLBuilder,
        on database: any Database
    ) async throws -> [Event] {
        let eventIds = events.compactMap(\.id)
        var rsvps: [UUID: RSVPStatus] = [:]
        var postIds: [UUID: UUID] = [:]
        if !eventIds.isEmpty {
            let rsvpRows = try await EventRSVPRecord.query(on: database)
                .filter(\.$user.$id == viewerId)
                .filter(\.$event.$id ~~ eventIds)
                .all()
            rsvps = Dictionary(uniqueKeysWithValues: rsvpRows.map { ($0.$event.id, $0.status) })
            let linkedPosts = try await PostRecord.query(on: database)
                .filter(\.$event.$id ~~ eventIds)
                .sort(\.$createdAt, .ascending)
                .all()
            for post in linkedPosts {
                guard let eventId = post.$event.id, let postId = post.id, postIds[eventId] == nil else { continue }
                postIds[eventId] = postId
            }
        }
        return try events.map { event in
            let id = try event.requireID()
            return try event.asDTO(
                viewerRSVP: rsvps[id] ?? .none,
                urls: urls,
                postId: postIds[id]
            )
        }
    }

    private func validateCreate(_ body: CreateEventBody) throws {
        let title = body.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (1...120).contains(title.count) else {
            throw APIError.validationFailed(
                "A title must be between 1 and 120 characters.",
                details: ["title": .string("must be 1 to 120 characters")]
            )
        }
        if let description = body.description, description.count > 4_000 {
            throw APIError.validationFailed(
                "That description is too long.",
                details: ["description": .string("must be 4000 characters or fewer")]
            )
        }
        if let endsAt = body.endsAt, endsAt < body.startsAt {
            throw APIError.validationFailed(
                "An event cannot end before it starts.",
                details: ["ends_at": .string("must be on or after starts_at")]
            )
        }
        if let capacity = body.capacity, capacity <= 0 {
            throw APIError.validationFailed(
                "Capacity must be greater than zero.",
                details: ["capacity": .string("must be greater than zero")]
            )
        }
    }

    private func ensureCanAttach(spaceId: UUID, userId: UUID, on database: any Database) async throws {
        guard try await SpaceRecord.find(spaceId, on: database) != nil else {
            throw APIError.notFound("That space does not exist.")
        }
        let role = try await SpaceMembershipRecord.query(on: database)
            .filter(\.$space.$id == spaceId)
            .filter(\.$user.$id == userId)
            .first()?.role ?? .none
        guard role.canPost else {
            throw APIError.forbidden("You must be a member to attach this space.")
        }
    }
}

extension AppServices {
    var events: EventService { EventService() }
}
