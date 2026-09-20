import Foundation
import IBUgramKit
import Vapor

struct MessageController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let authenticated = routes.grouped(AccessTokenAuthenticator())
        authenticated.on(API.Conversations.messagesTemplate, use: history)
        authenticated.on(API.Conversations.sendMessageTemplate, use: send)
    }

    private func history(_ request: Request) async throws -> Response {
        let viewer = try request.requireAuthenticatedUser()
        return try Response.json(
            try await request.messages.history(
                in: try MessagingQuery.conversationId(from: request),
                viewer: viewer.id,
                page: MessagingQuery.page(from: request)
            )
        )
    }

    /// A retry from the offline outbox carries the `client_id` the first attempt used, so it
    /// answers `200` with the message that already exists instead of creating a second one.
    private func send(_ request: Request) async throws -> Response {
        let viewer = try request.requireAuthenticatedUser()
        try CreateMessageBody.validate(content: request)
        let body = try request.content.decode(CreateMessageBody.self)
        let sent = try await request.messages.send(
            body,
            in: try MessagingQuery.conversationId(from: request),
            from: viewer.id
        )
        return try Response.json(sent.message, status: sent.isNew ? .created : .ok)
    }
}
