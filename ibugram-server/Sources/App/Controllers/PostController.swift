import Fluent
import Foundation
import IBUgramKit
import Vapor

struct PostController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let authenticated = routes.grouped(AccessTokenAuthenticator())
        authenticated.on(API.Posts.create, use: create)
        authenticated.on(API.Posts.detailTemplate, use: detail)
        authenticated.on(API.Posts.updateTemplate, use: update)
        authenticated.on(API.Posts.deleteTemplate, use: delete)
        authenticated.on(API.Posts.likeTemplate, use: like)
        authenticated.on(API.Posts.unlikeTemplate, use: unlike)
        authenticated.on(API.Posts.saveTemplate, use: save)
        authenticated.on(API.Posts.unsaveTemplate, use: unsave)
        authenticated.on(API.Posts.likesTemplate, use: likes)
        authenticated.on(API.Users.savedPosts, use: saved)
    }

    private func create(_ request: Request) async throws -> Response {
        let post = try await PostService().create(
            body: try request.content.decode(CreatePostBody.self),
            author: try request.requireCurrentUserRecord(),
            urls: request.dependencies.urls,
            on: request.db
        )
        return try Response.json(post, status: .created)
    }

    private func detail(_ request: Request) async throws -> Response {
        let post = try await PostService().detail(
            id: try requirePostID(request),
            viewer: try request.requireCurrentUserRecord(),
            urls: request.dependencies.urls,
            on: request.db
        )
        return try Response.json(post)
    }

    private func update(_ request: Request) async throws -> Response {
        let post = try await PostService().update(
            id: try requirePostID(request),
            body: try request.content.decode(UpdatePostBody.self),
            viewer: try request.requireCurrentUserRecord(),
            urls: request.dependencies.urls,
            on: request.db
        )
        return try Response.json(post)
    }

    private func delete(_ request: Request) async throws -> Response {
        try await PostService().delete(
            id: try requirePostID(request),
            viewer: try request.requireCurrentUserRecord(),
            on: request.db
        )
        return .empty()
    }

    private func like(_ request: Request) async throws -> Response {
        try await PostService().like(
            id: try requirePostID(request),
            viewer: try request.requireCurrentUserRecord(),
            on: request.db
        )
        return .empty()
    }

    private func unlike(_ request: Request) async throws -> Response {
        try await PostService().unlike(
            id: try requirePostID(request),
            viewer: try request.requireCurrentUserRecord(),
            on: request.db
        )
        return .empty()
    }

    private func save(_ request: Request) async throws -> Response {
        try await PostService().save(
            id: try requirePostID(request),
            viewer: try request.requireCurrentUserRecord(),
            on: request.db
        )
        return .empty()
    }

    private func unsave(_ request: Request) async throws -> Response {
        try await PostService().unsave(
            id: try requirePostID(request),
            viewer: try request.requireCurrentUserRecord(),
            on: request.db
        )
        return .empty()
    }

    private func likes(_ request: Request) async throws -> Response {
        let page = try await PostService().likes(
            id: try requirePostID(request),
            page: request.page,
            viewer: try request.requireCurrentUserRecord(),
            urls: request.dependencies.urls,
            on: request.db
        )
        return try Response.json(page)
    }

    private func saved(_ request: Request) async throws -> Response {
        let page = try await PostService().savedPosts(
            viewer: try request.requireCurrentUserRecord(),
            page: request.page,
            urls: request.dependencies.urls,
            on: request.db
        )
        return try Response.json(page)
    }

    private func requirePostID(_ request: Request) throws -> UUID {
        guard let identifier = request.parameters.get("id", as: UUID.self) else {
            throw APIError.validationFailed("That post id is not a UUID.")
        }
        return identifier
    }
}
