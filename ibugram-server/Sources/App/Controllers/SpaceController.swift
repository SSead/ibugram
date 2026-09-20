import Fluent
import Foundation
import IBUgramKit
import Vapor

struct SpaceController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let authenticated = routes.grouped(AccessTokenAuthenticator())
        authenticated.on(API.Spaces.browse, use: browse)
        authenticated.on(API.Spaces.create, use: create)
        authenticated.on(API.Spaces.detailTemplate, use: detail)
        authenticated.on(API.Spaces.updateTemplate, use: update)
        authenticated.on(API.Spaces.postsTemplate, use: posts)
        authenticated.on(API.Spaces.membersTemplate, use: members)
        authenticated.on(API.Spaces.joinTemplate, use: join)
        authenticated.on(API.Spaces.leaveTemplate, use: leave)
        authenticated.on(API.Spaces.setMemberRoleTemplate, use: setMemberRole)
    }

    private func browse(_ request: Request) async throws -> Response {
        let viewer = try request.requireAuthenticatedUser()
        let kind = try parseKind(request.query[String.self, at: "kind"])
        let page = try await request.dependencies.spaces.browse(
            kind: kind,
            page: request.page,
            viewerId: viewer.id,
            urls: request.dependencies.urls,
            on: request.db
        )
        return try Response.json(page)
    }

    private func create(_ request: Request) async throws -> Response {
        let creator = try request.requireCurrentUserRecord()
        try CreateSpaceBody.validate(content: request)
        let body = try request.content.decode(CreateSpaceBody.self)
        let space = try await request.dependencies.spaces.create(
            body,
            creator: creator,
            urls: request.dependencies.urls,
            on: request.db
        )
        return try Response.json(space, status: .created)
    }

    private func detail(_ request: Request) async throws -> Response {
        let viewer = try request.requireAuthenticatedUser()
        let space = try await request.dependencies.spaces.detail(
            slug: try requireSlug(request),
            viewerId: viewer.id,
            urls: request.dependencies.urls,
            on: request.db
        )
        return try Response.json(space)
    }

    private func update(_ request: Request) async throws -> Response {
        let actor = try request.requireCurrentUserRecord()
        try UpdateSpaceBody.validate(content: request)
        let body = try request.content.decode(UpdateSpaceBody.self)
        let space = try await request.dependencies.spaces.update(
            slug: try requireSlug(request),
            body: body,
            actor: actor,
            urls: request.dependencies.urls,
            on: request.db
        )
        return try Response.json(space)
    }

    private func posts(_ request: Request) async throws -> Response {
        let viewer = try request.requireAuthenticatedUser()
        let page = try await request.dependencies.spaces.posts(
            slug: try requireSlug(request),
            page: request.page,
            viewerId: viewer.id,
            urls: request.dependencies.urls,
            on: request.db
        )
        return try Response.json(page)
    }

    private func members(_ request: Request) async throws -> Response {
        let viewer = try request.requireAuthenticatedUser()
        let page = try await request.dependencies.spaces.members(
            slug: try requireSlug(request),
            page: request.page,
            viewerId: viewer.id,
            urls: request.dependencies.urls,
            on: request.db
        )
        return try Response.json(page)
    }

    private func join(_ request: Request) async throws -> Response {
        let viewer = try request.requireAuthenticatedUser()
        let space = try await request.dependencies.spaces.join(
            slug: try requireSlug(request),
            userId: viewer.id,
            urls: request.dependencies.urls,
            on: request.db
        )
        return try Response.json(space)
    }

    private func leave(_ request: Request) async throws -> Response {
        let viewer = try request.requireAuthenticatedUser()
        try await request.dependencies.spaces.leave(
            slug: try requireSlug(request),
            userId: viewer.id,
            on: request.db
        )
        return .empty()
    }

    private func setMemberRole(_ request: Request) async throws -> Response {
        let viewer = try request.requireAuthenticatedUser()
        try SetSpaceMemberRoleBody.validate(content: request)
        let body = try request.content.decode(SetSpaceMemberRoleBody.self)
        guard let userID = request.parameters.get("userID", as: UUID.self) else {
            throw APIError.validationFailed("That user id is not a UUID.")
        }
        let member = try await request.dependencies.spaces.setRole(
            slug: try requireSlug(request),
            targetUserId: userID,
            newRole: body.role,
            actorId: viewer.id,
            urls: request.dependencies.urls,
            on: request.db
        )
        return try Response.json(member)
    }

    private func requireSlug(_ request: Request) throws -> String {
        guard let slug = request.parameters.get("slug"), !slug.isEmpty else {
            throw APIError.validationFailed("A space slug is required.")
        }
        return slug
    }

    private func parseKind(_ raw: String?) throws -> SpaceKind? {
        guard let raw else { return nil }
        guard let kind = SpaceKind(rawValue: raw) else {
            throw APIError.validationFailed(
                "That space kind is not recognised.",
                details: ["kind": .string("must be club, department, course or community")]
            )
        }
        return kind
    }
}

extension CreateSpaceBody: @retroactive Validatable {
    public static func validations(_ validations: inout Validations) {
        validations.add("slug", as: String.self, is: !.empty && .count(SpaceSlug.minimumLength...SpaceSlug.maximumLength))
        validations.add("name", as: String.self, is: !.empty && .count(1...80))
        validations.add("description", as: String?.self, is: .nil || .count(...2_000), required: false)
    }
}

extension UpdateSpaceBody: @retroactive Validatable {
    public static func validations(_ validations: inout Validations) {
        validations.add("name", as: String?.self, is: .nil || .count(1...80), required: false)
        validations.add("description", as: String?.self, is: .nil || .count(...2_000), required: false)
    }
}

extension SetSpaceMemberRoleBody: @retroactive Validatable {
    public static func validations(_ validations: inout Validations) {
        validations.add("role", as: String.self, is: !.empty)
    }
}
