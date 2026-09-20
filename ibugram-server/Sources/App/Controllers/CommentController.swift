import Fluent
import Foundation
import IBUgramKit
import Vapor

struct CommentController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let authenticated = routes.grouped(AccessTokenAuthenticator())
        authenticated.on(API.Posts.commentsTemplate, use: list)
        authenticated.on(API.Posts.createCommentTemplate, use: create)
        authenticated.on(API.Comments.deleteTemplate, use: delete)
        authenticated.on(API.Comments.likeTemplate, use: like)
        authenticated.on(API.Comments.unlikeTemplate, use: unlike)
    }

    private func list(_ request: Request) async throws -> Response {
        let page = try await CommentService().list(
            postId: try requireID(request),
            page: request.page,
            viewer: try request.requireCurrentUserRecord(),
            urls: request.dependencies.urls,
            on: request.db
        )
        return try Response.json(page)
    }

    private func create(_ request: Request) async throws -> Response {
        try CreateCommentBody.validate(content: request)
        let comment = try await CommentService().create(
            postId: try requireID(request),
            body: try request.content.decode(CreateCommentBody.self),
            viewer: try request.requireCurrentUserRecord(),
            urls: request.dependencies.urls,
            on: request.db
        )
        return try Response.json(comment, status: .created)
    }

    private func delete(_ request: Request) async throws -> Response {
        try await CommentService().delete(
            id: try requireID(request),
            viewer: try request.requireCurrentUserRecord(),
            on: request.db
        )
        return .empty()
    }

    private func like(_ request: Request) async throws -> Response {
        try await CommentService().like(
            id: try requireID(request),
            viewer: try request.requireCurrentUserRecord(),
            on: request.db
        )
        return .empty()
    }

    private func unlike(_ request: Request) async throws -> Response {
        try await CommentService().unlike(
            id: try requireID(request),
            viewer: try request.requireCurrentUserRecord(),
            on: request.db
        )
        return .empty()
    }

    private func requireID(_ request: Request) throws -> UUID {
        guard let identifier = request.parameters.get("id", as: UUID.self) else {
            throw APIError.validationFailed("That id is not a UUID.")
        }
        return identifier
    }
}

extension CreateCommentBody: @retroactive Validatable {
    public static func validations(_ validations: inout Validations) {
        validations.add("body", as: String.self, is: !.empty && .count(1...1_000))
    }
}
