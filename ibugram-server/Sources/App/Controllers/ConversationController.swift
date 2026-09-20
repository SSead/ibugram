import Fluent
import Foundation
import IBUgramKit
import Vapor

struct ConversationController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let authenticated = routes.grouped(AccessTokenAuthenticator())
        authenticated.on(API.Conversations.list, use: list)
        authenticated.on(API.Conversations.create, use: create)
        authenticated.on(API.Conversations.acceptTemplate, use: accept)
        authenticated.on(API.Conversations.readTemplate, use: markRead)
    }

    private func list(_ request: Request) async throws -> Response {
        let viewer = try request.requireAuthenticatedUser()
        let page = MessagingQuery.page(from: request)
        let filter = try MessagingQuery.conversationFilter(from: request)
        return try Response.json(
            try await request.conversations.list(for: viewer.id, filter: filter, page: page)
        )
    }

    private func create(_ request: Request) async throws -> Response {
        let viewer = try request.requireAuthenticatedUser()
        try CreateConversationBody.validate(content: request)
        let body = try request.content.decode(CreateConversationBody.self)
        let result = try await request.conversations.create(body, creator: viewer.id)
        return try Response.json(result.conversation, status: result.isNew ? .created : .ok)
    }

    private func accept(_ request: Request) async throws -> Response {
        let viewer = try request.requireAuthenticatedUser()
        let conversationId = try MessagingQuery.conversationId(from: request)
        return try Response.json(
            try await request.conversations.accept(conversationId: conversationId, viewer: viewer.id)
        )
    }

    private func markRead(_ request: Request) async throws -> Response {
        let viewer = try request.requireAuthenticatedUser()
        let conversationId = try MessagingQuery.conversationId(from: request)
        let body = try request.content.decode(MarkConversationReadBody.self)
        let receipt = try await request.conversations.markRead(
            conversationId: conversationId,
            upTo: body.upToMessageId,
            viewer: viewer.id
        )
        return try Response.json(UnreadCount(count: receipt.remainingUnreadCount))
    }
}

/// Query and path decoding shared by the messaging and notification controllers.
enum MessagingQuery {
    static func conversationId(from request: Request) throws -> UUID {
        guard let identifier = request.parameters.get("id", as: UUID.self) else {
            throw APIError.validationFailed("That conversation id is not a UUID.")
        }
        return identifier
    }

    static func conversationFilter(from request: Request) throws -> ConversationFilter {
        guard let raw = request.query[String.self, at: "filter"] else { return .inbox }
        guard let filter = ConversationFilter(rawValue: raw) else {
            throw APIError.validationFailed("filter must be inbox or requests.")
        }
        return filter
    }

    static func page(from request: Request) -> PageRequest {
        PageRequest(
            limit: request.query[Int.self, at: "limit"] ?? IBUgram.defaultPageSize,
            cursor: request.query[String.self, at: "cursor"]
        )
    }
}
