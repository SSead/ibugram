import Fluent
import Foundation
import IBUgramKit
import Vapor

struct FeedController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let authenticated = routes.grouped(AccessTokenAuthenticator())
        authenticated.on(API.Feed.following, use: following)
        authenticated.on(API.Feed.discover, use: discover)
    }

    private func following(_ request: Request) async throws -> Response {
        let page = try await FeedService().following(
            viewer: try request.requireCurrentUserRecord(),
            page: request.page,
            urls: request.dependencies.urls,
            on: request.db
        )
        return try Response.json(page)
    }

    private func discover(_ request: Request) async throws -> Response {
        let page = try await FeedService().discover(
            viewer: try request.requireCurrentUserRecord(),
            page: request.page,
            urls: request.dependencies.urls,
            on: request.db
        )
        return try Response.json(page)
    }
}
