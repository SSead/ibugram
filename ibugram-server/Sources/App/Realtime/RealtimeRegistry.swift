import Foundation
import Vapor

/// The live socket table. Every mutation and every read goes through the actor, which is
/// what makes fan-out from concurrent HTTP requests safe under strict concurrency.
///
/// Closed sockets are removed by the socket's own close handler. The registry additionally
/// drops any connection that reports itself closed whenever it touches a user's list, so a
/// close callback that never arrives cannot turn into a permanent leak.
actor RealtimeRegistry {
    private var connectionsByUser: [UUID: [RealtimeConnection]] = [:]
    private var conversationSubscriptions: [UUID: Set<UUID>] = [:]

    enum PresenceTransition {
        case cameOnline
        case alreadyOnline
        case wentOffline
        case stillOnline
    }

    func add(_ connection: RealtimeConnection) -> PresenceTransition {
        let wasOnline = !liveConnections(for: connection.userId).isEmpty
        connectionsByUser[connection.userId, default: []].append(connection)
        return wasOnline ? .alreadyOnline : .cameOnline
    }

    func remove(connectionId: UUID, for userId: UUID) -> PresenceTransition {
        conversationSubscriptions[connectionId] = nil
        let remaining = liveConnections(for: userId).filter { $0.id != connectionId }
        connectionsByUser[userId] = remaining.isEmpty ? nil : remaining
        return remaining.isEmpty ? .wentOffline : .stillOnline
    }

    func connections(for userId: UUID) -> [RealtimeConnection] {
        liveConnections(for: userId)
    }

    func connections(for userIds: [UUID]) -> [RealtimeConnection] {
        userIds.flatMap(liveConnections(for:))
    }

    func connections(for userIds: [UUID], subscribedTo conversationId: UUID) -> [RealtimeConnection] {
        connections(for: userIds).filter {
            conversationSubscriptions[$0.id]?.contains(conversationId) ?? false
        }
    }

    func subscribe(connectionId: UUID, to conversationId: UUID) {
        conversationSubscriptions[connectionId, default: []].insert(conversationId)
    }

    func unsubscribe(connectionId: UUID, from conversationId: UUID) {
        conversationSubscriptions[connectionId]?.remove(conversationId)
    }

    func isOnline(_ userId: UUID) -> Bool {
        !liveConnections(for: userId).isEmpty
    }

    func connectionCount(for userId: UUID) -> Int {
        liveConnections(for: userId).count
    }

    func connectionCount() -> Int {
        connectionsByUser.keys.reduce(0) { $0 + liveConnections(for: $1).count }
    }

    func closeConnections(for userId: UUID, code: WebSocketErrorCode = .goingAway) {
        for connection in liveConnections(for: userId) {
            connection.close(code: code)
        }
    }

    private func liveConnections(for userId: UUID) -> [RealtimeConnection] {
        guard let stored = connectionsByUser[userId] else { return [] }
        let live = stored.filter { !$0.isClosed }
        guard live.count != stored.count else { return stored }
        for dropped in stored where dropped.isClosed {
            conversationSubscriptions[dropped.id] = nil
        }
        connectionsByUser[userId] = live.isEmpty ? nil : live
        return live
    }
}

extension Application {
    private struct RealtimeRegistryKey: StorageKey, LockKey {
        typealias Value = RealtimeRegistry
    }

    /// One registry per application. Created on first use behind the application lock so
    /// two concurrent upgrades cannot end up with separate tables.
    var realtimeRegistry: RealtimeRegistry {
        if let existing = storage[RealtimeRegistryKey.self] {
            return existing
        }
        return locks.lock(for: RealtimeRegistryKey.self).withLock {
            if let existing = storage[RealtimeRegistryKey.self] {
                return existing
            }
            let created = RealtimeRegistry()
            storage[RealtimeRegistryKey.self] = created
            return created
        }
    }
}
