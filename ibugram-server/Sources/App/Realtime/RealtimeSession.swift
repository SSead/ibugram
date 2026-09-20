import Fluent
import Foundation
import IBUgramKit
import Vapor

/// One socket's lifetime: register, serve frames in the order they arrived, then deregister.
///
/// Inbound frames go through an `AsyncStream` rather than being handled inside the socket
/// callback. That keeps them strictly ordered behind registration, so a client that sends
/// `subscribe_conversation` immediately after the upgrade cannot have it dropped, and it gives
/// every disconnect — clean close, abrupt drop, or a ping the peer never answers — the same
/// single teardown path.
actor RealtimeSession {
    private let connection: RealtimeConnection
    private let registry: RealtimeRegistry
    private let broadcaster: RealtimeBroadcaster
    private let database: any Database
    private let urls: MediaURLBuilder
    private let logger: Logger

    private static let keepAliveInterval = TimeAmount.seconds(30)

    private var conversations: ConversationService {
        ConversationService(database: database, realtime: broadcaster, urls: urls)
    }

    private init(
        connection: RealtimeConnection,
        registry: RealtimeRegistry,
        broadcaster: RealtimeBroadcaster,
        database: any Database,
        urls: MediaURLBuilder,
        logger: Logger
    ) {
        self.connection = connection
        self.registry = registry
        self.broadcaster = broadcaster
        self.database = database
        self.urls = urls
        self.logger = logger
    }

    static func start(
        socket: WebSocket,
        identity: RealtimeIdentity,
        application: Application,
        logger: Logger
    ) {
        let registry = application.realtimeRegistry
        let connection = RealtimeConnection(
            userId: identity.userId,
            sessionFamily: identity.sessionFamily,
            socket: socket,
            logger: logger
        )
        let session = RealtimeSession(
            connection: connection,
            registry: registry,
            broadcaster: RealtimeBroadcaster(registry: registry, logger: logger),
            database: application.db,
            urls: application.dependencies.urls,
            logger: logger
        )

        /// WebSocketKit closes the channel when a ping goes unanswered before the next one is
        /// due, which is what turns a silently dead peer into a close event.
        socket.pingInterval = keepAliveInterval

        let (frames, continuation) = AsyncStream<String>.makeStream()
        socket.onText { _, text in continuation.yield(text) }
        socket.onClose.whenComplete { _ in continuation.finish() }

        Task {
            await session.open()
            for await frame in frames {
                await session.handle(frame)
            }
            await session.close()
        }
    }

    private func open() async {
        let transition = await registry.add(connection)
        logger.info(
            "Realtime socket opened",
            metadata: [
                "user": .string(connection.userId.uuidString),
                "connection": .string(connection.id.uuidString)
            ]
        )
        await sendUnreadCounts()
        guard transition == .cameOnline else { return }
        await announcePresence(isOnline: true, lastSeenAt: nil)
    }

    private func close() async {
        let transition = await registry.remove(connectionId: connection.id, for: connection.userId)
        logger.info(
            "Realtime socket closed",
            metadata: [
                "user": .string(connection.userId.uuidString),
                "connection": .string(connection.id.uuidString)
            ]
        )
        guard transition == .wentOffline else { return }
        let lastSeenAt = Date()
        do {
            try await UserRecord.query(on: database)
                .filter(\.$id == connection.userId)
                .set(\.$lastSeenAt, to: lastSeenAt)
                .update()
        } catch {
            logger.debug("Could not record last_seen_at", metadata: ["reason": .string("\(error)")])
        }
        await announcePresence(isOnline: false, lastSeenAt: lastSeenAt)
    }

    private func handle(_ frame: String) async {
        let message: ClientMessage
        do {
            message = try RealtimeFrameCoding.decode(frame)
        } catch {
            logger.debug(
                "Ignoring an unreadable realtime frame",
                metadata: ["reason": .string("\(error)")]
            )
            return
        }

        switch message {
        case .ping:
            await closeIfSessionRevoked()
            send(.pong)
        case .subscribeConversation(let scope):
            await subscribe(to: scope.conversationId)
        case .unsubscribeConversation(let scope):
            await registry.unsubscribe(connectionId: connection.id, from: scope.conversationId)
        case .typingStart(let scope):
            await relayTyping(in: scope.conversationId, isTyping: true)
        case .typingStop(let scope):
            await relayTyping(in: scope.conversationId, isTyping: false)
        case .markRead(let payload):
            await markRead(payload)
        }
    }

    private func subscribe(to conversationId: UUID) async {
        guard await isParticipant(of: conversationId) else { return }
        await registry.subscribe(connectionId: connection.id, to: conversationId)
    }

    private func relayTyping(in conversationId: UUID, isTyping: Bool) async {
        guard let membership = await membership(of: conversationId) else { return }
        let payload = TypingPayload(
            conversationId: conversationId,
            userId: connection.userId,
            isTyping: isTyping
        )
        await broadcaster.send(
            .typing(payload),
            to: membership.otherParticipantIds,
            subscribedTo: conversationId
        )
    }

    private func markRead(_ payload: MarkReadPayload) async {
        do {
            _ = try await conversations.markRead(
                conversationId: payload.conversationId,
                upTo: payload.upToMessageId,
                viewer: connection.userId
            )
        } catch {
            logger.debug(
                "Ignoring a mark_read frame",
                metadata: ["reason": .string("\(error)")]
            )
        }
    }

    /// Logout revokes the session family, and an access token is only good while its family
    /// lives (A1.2). The client's keep-alive ping is the cheapest place to notice, so a socket
    /// opened before a logout does not outlive it.
    private func closeIfSessionRevoked() async {
        do {
            guard try await RealtimeAuthentication.isFamilyLive(connection.sessionFamily, on: database) else {
                logger.info(
                    "Closing a realtime socket whose session was revoked",
                    metadata: ["user": .string(connection.userId.uuidString)]
                )
                connection.close(code: .policyViolation)
                return
            }
        } catch {
            logger.debug("Could not revalidate a socket session", metadata: ["reason": .string("\(error)")])
        }
    }

    private func announcePresence(isOnline: Bool, lastSeenAt: Date?) async {
        let peers = await conversationPeers()
        guard !peers.isEmpty else { return }
        let payload = PresenceChangedPayload(
            userId: connection.userId,
            isOnline: isOnline,
            lastSeenAt: lastSeenAt
        )
        await broadcaster.send(.presenceChanged(payload), to: peers)
    }

    /// Presence is shared with the people you actually talk to, not the whole campus.
    private func conversationPeers() async -> [UUID] {
        do {
            let mine = try await ConversationParticipantRecord.query(on: database)
                .filter(\.$user.$id == connection.userId)
                .all()
                .map(\.$conversation.id)
            guard !mine.isEmpty else { return [] }
            let peers = try await ConversationParticipantRecord.query(on: database)
                .filter(\.$conversation.$id ~~ mine)
                .filter(\.$user.$id != connection.userId)
                .all()
                .map(\.$user.id)
            return Array(Set(peers))
        } catch {
            logger.debug("Could not resolve conversation peers", metadata: ["reason": .string("\(error)")])
            return []
        }
    }

    private func sendUnreadCounts() async {
        do {
            let counts = try await UnreadTotals.load(for: connection.userId, on: database)
            send(.unreadCountChanged(counts))
        } catch {
            logger.debug("Could not send opening unread counts", metadata: ["reason": .string("\(error)")])
        }
    }

    private func membership(of conversationId: UUID) async -> ConversationMembership? {
        do {
            return try await conversations.requireMembership(of: conversationId, viewer: connection.userId)
        } catch {
            return nil
        }
    }

    private func isParticipant(of conversationId: UUID) async -> Bool {
        await membership(of: conversationId) != nil
    }

    private func send(_ message: ServerMessage) {
        do {
            connection.deliver(try RealtimeFrameCoding.encode(message))
        } catch {
            logger.error(
                "Could not encode a realtime frame",
                metadata: ["type": .string(message.kind.rawValue), "reason": .string("\(error)")]
            )
        }
    }
}
