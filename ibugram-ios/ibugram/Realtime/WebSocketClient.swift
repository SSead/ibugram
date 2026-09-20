import Foundation
import IBUgramKit

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
    private var subscribers: [UUID: AsyncStream<ServerMessage>.Continuation] = [:]
    private var subscribedConversations: Set<UUID> = []
    private var isActive = false
    private var reconnectAttempt = 0

    private(set) var status: ConnectionStatus = .disconnected

    init(configuration: APIConfiguration, tokenStore: any TokenStoring, session: URLSession = .shared) {
        self.configuration = configuration
        self.tokenStore = tokenStore
        self.session = session
    }

    func events() -> AsyncStream<ServerMessage> {
        let (stream, continuation) = AsyncStream<ServerMessage>.makeStream()
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

    func send(_ message: ClientMessage) async throws {
        guard let socket else { throw APIError.transport("web socket is not connected") }
        let data = try encoder.encode(message)
        try await socket.send(.data(data))
    }

    func subscribe(toConversation id: UUID) async {
        subscribedConversations.insert(id)
        try? await send(.subscribeConversation(ConversationScope(conversationId: id)))
    }

    func unsubscribe(fromConversation id: UUID) async {
        subscribedConversations.remove(id)
        try? await send(.unsubscribeConversation(ConversationScope(conversationId: id)))
    }

    private func removeSubscriber(_ id: UUID) {
        subscribers[id] = nil
    }
}

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
            try? await send(.subscribeConversation(ConversationScope(conversationId: id)))
        }
    }

    func broadcast(_ frame: ServerMessage) {
        for continuation in subscribers.values {
            continuation.yield(frame)
        }
    }

    func decodeFrame(from message: URLSessionWebSocketTask.Message) -> ServerMessage? {
        let data: Data? = switch message {
        case .data(let data): data
        case .string(let string): Data(string.utf8)
        @unknown default: nil
        }
        guard let data else { return nil }
        return try? decoder.decode(ServerMessage.self, from: data)
    }
}

extension WebSocketClient {
    static func backoffDelay(forAttempt attempt: Int) -> Duration {
        let exponential = min(30, pow(2, Double(attempt)))
        let jittered = exponential * Double.random(in: 0.8...1.2)
        return .milliseconds(Int(min(30, max(1, jittered)) * 1_000))
    }
}
