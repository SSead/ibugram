import Fluent
import Foundation
import IBUgramKit
import Vapor

/// The only way a feature reaches a live socket. Every method is failure-isolated: an
/// encoding problem or a dead peer is logged and skipped, never propagated to the caller,
/// because a socket is a best-effort channel and REST is the source of truth.
struct RealtimeBroadcaster: Sendable {
    let registry: RealtimeRegistry
    let logger: Logger

    func send(_ message: ServerMessage, to recipients: some Sequence<UUID>) async {
        let ids = Array(recipients)
        guard let frame = encode(message) else { return }
        for connection in await registry.connections(for: ids) {
            connection.deliver(frame)
        }
    }

    func send(
        _ message: ServerMessage,
        to recipients: some Sequence<UUID>,
        subscribedTo conversationId: UUID
    ) async {
        let ids = Array(recipients)
        guard let frame = encode(message) else { return }
        for connection in await registry.connections(for: ids, subscribedTo: conversationId) {
            connection.deliver(frame)
        }
    }

    /// `unread_count_changed` is per recipient, so each user gets their own frame.
    func sendUnreadCounts(to recipients: some Sequence<UUID>, on database: any Database) async {
        for recipient in Set(recipients) {
            guard await registry.isOnline(recipient) else { continue }
            do {
                let counts = try await UnreadTotals.load(for: recipient, on: database)
                await send(.unreadCountChanged(counts), to: [recipient])
            } catch {
                logger.debug(
                    "Could not compute unread counts for a realtime update",
                    metadata: ["user": .string(recipient.uuidString), "reason": .string("\(error)")]
                )
            }
        }
    }

    private func encode(_ message: ServerMessage) -> String? {
        do {
            return try RealtimeFrameCoding.encode(message)
        } catch {
            logger.error(
                "Could not encode a realtime frame",
                metadata: ["type": .string(message.kind.rawValue), "reason": .string("\(error)")]
            )
            return nil
        }
    }
}

/// The two badge numbers the client shows: unread messages across accepted conversations,
/// and unread notification rows. Message requests are excluded deliberately — an unaccepted
/// request must not light up the inbox badge.
enum UnreadTotals {
    static func load(for userId: UUID, on database: any Database) async throws -> UnreadCountChangedPayload {
        UnreadCountChangedPayload(
            conversations: try await conversationUnreadCount(for: userId, on: database),
            notifications: try await notificationUnreadCount(for: userId, on: database)
        )
    }

    static func conversationUnreadCount(for userId: UUID, on database: any Database) async throws -> Int {
        try await ConversationParticipantRecord.query(on: database)
            .filter(\.$user.$id == userId)
            .filter(\.$hasAccepted == true)
            .sum(\.$unreadCount) ?? 0
    }

    static func notificationUnreadCount(for userId: UUID, on database: any Database) async throws -> Int {
        try await NotificationRecord.query(on: database)
            .filter(\.$recipient.$id == userId)
            .filter(\.$isRead == false)
            .count()
    }
}

extension Request {
    var realtime: RealtimeBroadcaster {
        RealtimeBroadcaster(registry: application.realtimeRegistry, logger: logger)
    }
}
