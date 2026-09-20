import Foundation
import IBUgramKit
import Vapor

struct NotificationController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let authenticated = routes.grouped(AccessTokenAuthenticator())
        authenticated.on(API.Notifications.list, use: list)
        authenticated.on(API.Notifications.unreadCount, use: unreadCount)
        authenticated.on(API.Notifications.markRead, use: markRead)
    }

    private func list(_ request: Request) async throws -> Response {
        let viewer = try request.requireAuthenticatedUser()
        return try Response.json(
            try await request.notifications.list(
                for: viewer.id,
                page: MessagingQuery.page(from: request)
            )
        )
    }

    private func unreadCount(_ request: Request) async throws -> Response {
        let viewer = try request.requireAuthenticatedUser()
        let count = try await request.notifications.unreadCount(for: viewer.id)
        return try Response.json(UnreadCount(count: count))
    }

    private func markRead(_ request: Request) async throws -> Response {
        let viewer = try request.requireAuthenticatedUser()
        let body = (try? request.content.decode(MarkNotificationsReadBody.self))
            ?? MarkNotificationsReadBody()
        let remaining = try await request.notifications.markRead(ids: body.ids, for: viewer.id)
        return try Response.json(UnreadCount(count: remaining))
    }
}
