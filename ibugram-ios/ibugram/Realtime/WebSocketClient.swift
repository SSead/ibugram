import Foundation

actor WebSocketClient {
    enum ConnectionStatus: Sendable, Equatable {
        case disconnected
        case connecting
        case connected
        case reconnecting(attempt: Int)
    }

    private let configuration: APIConfiguration
    private let tokenStore: any TokenStoring
    private let session: URLSession
    private let decoder = JSONDecoder.ibugram
    private let encoder = JSONEncoder.ibugram

    private var socket: URLSessionWebSocketTask?
    private var lifecycle: Task<Void, Never>?
    private var keepAlive: Task<Void, Never>?
    private var subscribers: [UUID: AsyncStream<ServerFrame>.Continuation] = [:]
    private var subscribedConversations: Set<UUID> = []
    private var isActive = false
    private var reconnectAttempt = 0

    private(set) var status: ConnectionStatus = .disconnected

    init(configuration: APIConfiguration, tokenStore: any TokenStoring, session: URLSession = .shared) {
        self.configuration = configuration
        self.tokenStore = tokenStore
        self.session = session
    }

    /// Every consumer gets its own stream; frames are fanned out to all of them.
    func events() -> AsyncStream<ServerFrame> {
        let (stream, continuation) = AsyncStream<ServerFrame>.makeStream()
        let id = UUID()
        subscribers[id] = continuation
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSubscriber(id) }
        }
        return stream
    }

    func connect() {
        guard !isActive else { return }
        isActive = true
        lifecycle = Task { await self.runConnectionLifecycle() }
    }

    func disconnect() {
        isActive = false
        reconnectAttempt = 0
        closeSocket()
        lifecycle?.cancel()
        lifecycle = nil
        status = .disconnected
    }

    func send(_ frame: ClientFrame) async throws {
        guard let socket else { throw APIError.transport("web socket is not connected") }
        let data = try encoder.encode(frame)
        try await socket.send(.data(data))
    }

    func subscribe(toConversation id: UUID) async {
        subscribedConversations.insert(id)
        try? await send(.subscribe(conversationID: id))
    }

    func unsubscribe(fromConversation id: UUID) async {
        subscribedConversations.remove(id)
        try? await send(.unsubscribe(conversationID: id))
    }

    private func removeSubscriber(_ id: UUID) {
        subscribers[id] = nil
    }
}

// MARK: - Connection lifecycle

private extension WebSocketClient {
    func runConnectionLifecycle() async {
        while isActive, !Task.isCancelled {
            let didConnect = await openAndPumpFrames()
            guard isActive, !Task.isCancelled else { break }
            if didConnect { reconnectAttempt = 0 }
            status = .reconnecting(attempt: reconnectAttempt)
            let delay = WebSocketClient.backoffDelay(forAttempt: reconnectAttempt)
            reconnectAttempt += 1
            try? await Task.sleep(for: delay)
        }
        status = .disconnected
    }

    /// Returns whether the socket successfully opened, so a long-lived connection resets backoff.
    func openAndPumpFrames() async -> Bool {
        status = .connecting
        guard let tokens = await tokenStore.currentTokens(),
              let url = configuration.webSocketURL(token: tokens.accessToken) else { return false }

        let task = session.webSocketTask(with: url)
        socket = task
        task.resume()
        status = .connected
        await resubscribeAll()
        startKeepAlive()

        while isActive, !Task.isCancelled {
            do {
                let message = try await task.receive()
                if let frame = decodeFrame(from: message) { broadcast(frame) }
            } catch {
                break
            }
        }
        closeSocket()
        return true
    }

    func startKeepAlive() {
        keepAlive?.cancel()
        keepAlive = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                guard let self, !Task.isCancelled else { return }
                try? await self.send(.ping)
            }
        }
    }

    func closeSocket() {
        keepAlive?.cancel()
        keepAlive = nil
        socket?.cancel(with: .goingAway, reason: nil)
        socket = nil
    }

    func resubscribeAll() async {
        for id in subscribedConversations {
            try? await send(.subscribe(conversationID: id))
        }
    }

    func broadcast(_ frame: ServerFrame) {
        for continuation in subscribers.values {
            continuation.yield(frame)
        }
    }

    func decodeFrame(from message: URLSessionWebSocketTask.Message) -> ServerFrame? {
        let data: Data? = switch message {
        case .data(let data): data
        case .string(let string): Data(string.utf8)
        @unknown default: nil
        }
        guard let data, let envelope = try? decoder.decode(RawFrame.self, from: data) else { return nil }
        guard let type = ServerFrameType(rawValue: envelope.type) else { return nil }
        return ServerFrame(type: type, payload: envelope.payload)
    }

}

extension WebSocketClient {
    /// The contract caps backoff at 30s starting from 1s.
    static func backoffDelay(forAttempt attempt: Int) -> Duration {
        let exponential = min(30, pow(2, Double(attempt)))
        let jittered = exponential * Double.random(in: 0.8...1.2)
        return .milliseconds(Int(min(30, max(1, jittered)) * 1_000))
    }
}

private struct RawFrame: Decodable {
    let type: String
    let payload: Data?

    private enum CodingKeys: String, CodingKey {
        case type
        case payload
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        if let nested = try? container.decode(AnyJSON.self, forKey: .payload) {
            payload = nested.data
        } else {
            payload = nil
        }
    }
}

/// Keeps a frame's payload as raw bytes so the team that owns its DTO decodes it.
private struct AnyJSON: Decodable {
    let data: Data

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let json = try container.decode(JSONValue.self)
        data = try JSONEncoder().encode(json)
    }
}
