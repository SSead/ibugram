import Fluent
import Foundation
import IBUgramKit
import Vapor

struct EventController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let authenticated = routes.grouped(AccessTokenAuthenticator())
        authenticated.on(API.Events.list, use: list)
        authenticated.on(API.Events.create, use: create)
        authenticated.on(API.Events.happeningNow, use: happeningNow)
        authenticated.on(API.Events.map, use: mapContents)
        authenticated.on(API.Events.detailTemplate, use: detail)
        authenticated.on(API.Events.updateTemplate, use: update)
        authenticated.on(API.Events.deleteTemplate, use: delete)
        authenticated.on(API.Events.rsvpTemplate, use: rsvp)
        authenticated.on(API.Events.attendeesTemplate, use: attendees)
    }

    private func list(_ request: Request) async throws -> Response {
        let viewer = try request.requireAuthenticatedUser()
        let page = try await request.dependencies.events.list(
            from: try parseDate(request.query[String.self, at: "from"], field: "from"),
            to: try parseDate(request.query[String.self, at: "to"], field: "to"),
            spaceId: try parseUUID(request.query[String.self, at: "space_id"], field: "space_id"),
            page: request.page,
            viewerId: viewer.id,
            urls: request.dependencies.urls,
            on: request.db
        )
        return try Response.json(page)
    }

    private func happeningNow(_ request: Request) async throws -> Response {
        let viewer = try request.requireAuthenticatedUser()
        let page = try await request.dependencies.events.happeningNow(
            page: request.page,
            viewerId: viewer.id,
            urls: request.dependencies.urls,
            on: request.db
        )
        return try Response.json(page)
    }

    private func mapContents(_ request: Request) async throws -> Response {
        let viewer = try request.requireAuthenticatedUser()
        let bbox = try BoundingBoxParser.parse(request.query[String.self, at: "bbox"])
        let contents = try await request.dependencies.events.mapContents(
            bbox: bbox,
            viewerId: viewer.id,
            urls: request.dependencies.urls,
            on: request.db
        )
        return try Response.json(contents)
    }

    private func create(_ request: Request) async throws -> Response {
        let host = try request.requireCurrentUserRecord()
        try CreateEventBody.validate(content: request)
        let body = try request.content.decode(CreateEventBody.self)
        let event = try await request.dependencies.events.create(
            body,
            host: host,
            urls: request.dependencies.urls,
            on: request.db
        )
        return try Response.json(event, status: .created)
    }

    private func detail(_ request: Request) async throws -> Response {
        let viewer = try request.requireAuthenticatedUser()
        let event = try await request.dependencies.events.detail(
            id: try requireEventID(request),
            viewerId: viewer.id,
            urls: request.dependencies.urls,
            on: request.db
        )
        return try Response.json(event)
    }

    private func update(_ request: Request) async throws -> Response {
        let viewer = try request.requireAuthenticatedUser()
        try UpdateEventBody.validate(content: request)
        let body = try request.content.decode(UpdateEventBody.self)
        let event = try await request.dependencies.events.update(
            id: try requireEventID(request),
            body: body,
            actorId: viewer.id,
            urls: request.dependencies.urls,
            on: request.db
        )
        return try Response.json(event)
    }

    private func delete(_ request: Request) async throws -> Response {
        let viewer = try request.requireAuthenticatedUser()
        try await request.dependencies.events.delete(
            id: try requireEventID(request),
            actorId: viewer.id,
            on: request.db
        )
        return .empty()
    }

    private func rsvp(_ request: Request) async throws -> Response {
        let viewer = try request.requireAuthenticatedUser()
        try SetRSVPBody.validate(content: request)
        let body = try request.content.decode(SetRSVPBody.self)
        let event = try await request.dependencies.events.setRSVP(
            eventId: try requireEventID(request),
            userId: viewer.id,
            status: body.status,
            urls: request.dependencies.urls,
            on: request.db
        )
        return try Response.json(event)
    }

    private func attendees(_ request: Request) async throws -> Response {
        _ = try request.requireAuthenticatedUser()
        let page = try await request.dependencies.events.attendees(
            eventId: try requireEventID(request),
            page: request.page,
            urls: request.dependencies.urls,
            on: request.db
        )
        return try Response.json(page)
    }

    private func requireEventID(_ request: Request) throws -> UUID {
        guard let id = request.parameters.get("id", as: UUID.self) else {
            throw APIError.validationFailed("That event id is not a UUID.")
        }
        return id
    }

    private func parseDate(_ raw: String?, field: String) throws -> Date? {
        guard let raw, !raw.isEmpty else { return nil }
        guard let date = IBUgramDateCoding.date(from: raw) else {
            throw APIError.validationFailed(
                "That timestamp is not valid.",
                details: [field: .string("must be ISO-8601")]
            )
        }
        return date
    }

    private func parseUUID(_ raw: String?, field: String) throws -> UUID? {
        guard let raw, !raw.isEmpty else { return nil }
        guard let id = UUID(uuidString: raw) else {
            throw APIError.validationFailed(
                "That id is not a UUID.",
                details: [field: .string("must be a UUID")]
            )
        }
        return id
    }
}

extension CreateEventBody: @retroactive Validatable {
    public static func validations(_ validations: inout Validations) {
        validations.add("title", as: String.self, is: !.empty && .count(1...120))
        validations.add("description", as: String?.self, is: .nil || .count(...4_000), required: false)
        validations.add("capacity", as: Int?.self, is: .nil || .range(1...), required: false)
    }
}

extension UpdateEventBody: @retroactive Validatable {
    public static func validations(_ validations: inout Validations) {
        validations.add("title", as: String?.self, is: .nil || .count(1...120), required: false)
        validations.add("description", as: String?.self, is: .nil || .count(...4_000), required: false)
        validations.add("capacity", as: Int?.self, is: .nil || .range(1...), required: false)
    }
}

extension SetRSVPBody: @retroactive Validatable {
    public static func validations(_ validations: inout Validations) {
        validations.add("status", as: String.self, is: !.empty)
    }
}
