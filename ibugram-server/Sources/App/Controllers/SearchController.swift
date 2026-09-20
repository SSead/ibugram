import Fluent
import Foundation
import IBUgramKit
import Vapor

struct SearchController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let authenticated = routes.grouped(AccessTokenAuthenticator())
        authenticated.on(API.Search.query, use: search)
        authenticated.on(API.Search.trending, use: trending)
        authenticated.on(API.Search.hashtagPostsTemplate, use: hashtagPosts)
    }

    private func search(_ request: Request) async throws -> Response {
        let query = request.query[String.self, at: "q"] ?? ""
        let scope = request.query[String.self, at: "type"].flatMap(SearchScope.init(rawValue:)) ?? .all
        let results = try await SearchService().search(
            query: query,
            scope: scope,
            viewer: try request.requireCurrentUserRecord(),
            urls: request.dependencies.urls,
            on: request.db
        )
        return try Response.json(results)
    }

    private func trending(_ request: Request) async throws -> Response {
        _ = try request.requireCurrentUserRecord()
        let tags = try await SearchService().trending(on: request.db)
        return try Response.json(tags)
    }

    private func hashtagPosts(_ request: Request) async throws -> Response {
        guard let tag = request.parameters.get("tag"), !tag.isEmpty else {
            throw APIError.validationFailed("A hashtag is required.")
        }
        let page = try await SearchService().posts(
            tagged: tag,
            page: request.page,
            viewer: try request.requireCurrentUserRecord(),
            urls: request.dependencies.urls,
            on: request.db
        )
        return try Response.json(page)
    }
}
