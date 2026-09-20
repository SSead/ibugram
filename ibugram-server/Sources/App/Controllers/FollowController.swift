import Fluent
import Foundation
import IBUgramKit
import Vapor

struct FollowController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let authenticated = routes.grouped(AccessTokenAuthenticator())
        authenticated.on(API.Users.followTemplate, use: follow)
        authenticated.on(API.Users.unfollowTemplate, use: unfollow)
        authenticated.on(API.Users.blockTemplate, use: block)
        authenticated.on(API.Users.unblockTemplate, use: unblock)
    }

    private func follow(_ request: Request) async throws -> Response {
        try await SocialService().follow(
            viewer: try request.requireCurrentUserRecord(),
            targetId: try requireUserID(request),
            on: request.db
        )
        return .empty()
    }

    private func unfollow(_ request: Request) async throws -> Response {
        try await SocialService().unfollow(
            viewer: try request.requireCurrentUserRecord(),
            targetId: try requireUserID(request),
            on: request.db
        )
        return .empty()
    }

    private func block(_ request: Request) async throws -> Response {
        try await SocialService().block(
            viewer: try request.requireCurrentUserRecord(),
            targetId: try requireUserID(request),
            on: request.db
        )
        return .empty()
    }

    private func unblock(_ request: Request) async throws -> Response {
        try await SocialService().unblock(
            viewer: try request.requireCurrentUserRecord(),
            targetId: try requireUserID(request),
            on: request.db
        )
        return .empty()
    }

    private func requireUserID(_ request: Request) throws -> UUID {
        guard let identifier = request.parameters.get("id", as: UUID.self) else {
            throw APIError.validationFailed("That user id is not a UUID.")
        }
        return identifier
    }
}
