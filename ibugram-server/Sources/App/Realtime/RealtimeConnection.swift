import Foundation
import Vapor

/// One live socket belonging to one signed-in device. A user holds one connection per
/// device, so the identity that matters for fan-out is `userId`, not `id`.
final class RealtimeConnection: Sendable {
    let id: UUID
    let userId: UUID
    let sessionFamily: UUID

    private let socket: WebSocket
    private let logger: Logger

    init(id: UUID = UUID(), userId: UUID, sessionFamily: UUID, socket: WebSocket, logger: Logger) {
        self.id = id
        self.userId = userId
        self.sessionFamily = sessionFamily
        self.socket = socket
        self.logger = logger
    }

    var isClosed: Bool { socket.isClosed }

    /// Deliberately non-throwing: a socket that has gone away must not fail the HTTP
    /// request that triggered the fan-out. A failed write closes the socket, and the
    /// close handler is what removes it from the registry.
    func deliver(_ frame: String) {
        guard !socket.isClosed else { return }
        let promise = socket.eventLoop.makePromise(of: Void.self)
        socket.send(frame, promise: promise)
        promise.futureResult.whenFailure { [socket, logger, id] error in
            logger.debug(
                "Dropping realtime connection after a failed write",
                metadata: ["connection": .string(id.uuidString), "reason": .string("\(error)")]
            )
            socket.close(code: .unexpectedServerError, promise: nil)
        }
    }

    func close(code: WebSocketErrorCode = .goingAway) {
        socket.close(code: code, promise: nil)
    }
}
