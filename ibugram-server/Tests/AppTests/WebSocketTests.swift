import Fluent
import Foundation
import IBUgramKit
import NIOConcurrencyHelpers
import Testing
import Vapor
import VaporTesting
@testable import App

/// Collects what the server actually wrote to a client socket. Recording is synchronous so
/// the frames stay in the order they arrived.
final class SocketRecorder: Sendable {
    private let received = NIOLockedValueBox<[ServerMessage]>([])
    private let undecodable = NIOLockedValueBox<[String]>([])

    func record(_ text: String) {
        guard let message = try? JSONDecoder.ibugram.decode(ServerMessage.self, from: Data(text.utf8)) else {
            undecodable.withLockedValue { $0.append(text) }
            return
        }
        received.withLockedValue { $0.append(message) }
    }

    func take(_ kind: ServerMessage.Kind) -> ServerMessage? {
        received.withLockedValue { frames in
            guard let index = frames.firstIndex(where: { $0.kind == kind }) else { return nil }
            return frames.remove(at: index)
        }
    }

    var unreadableFrames: [String] { undecodable.withLockedValue { $0 } }
}

struct TestSocket: Sendable {
    let socket: WebSocket
    let frames: SocketRecorder

    func send(_ message: ClientMessage) async throws {
        let data = try JSONEncoder.ibugram.encode(message)
        try await socket.send(String(decoding: data, as: UTF8.self))
    }

    func close() async throws {
        try await socket.close()
    }
}

extension TestContext {
    func openSocket(port: Int, token: String) async throws -> TestSocket {
        let frames = SocketRecorder()
        let opened = app.eventLoopGroup.any().makePromise(of: WebSocket.self)
        try await WebSocket.connect(
            to: "ws://127.0.0.1:\(port)/api/v1/ws?token=\(token)",
            on: app.eventLoopGroup
        ) { socket in
            socket.onText { _, text in frames.record(text) }
            opened.succeed(socket)
        }.get()
        return TestSocket(socket: try await opened.futureResult.get(), frames: frames)
    }

    /// Polls instead of sleeping a fixed interval: the test finishes as soon as the frame
    /// lands and fails loudly if it never does.
    func awaitFrame(
        _ kind: ServerMessage.Kind,
        on socket: TestSocket,
        within seconds: Double = 5
    ) async throws -> ServerMessage {
        let deadline = Date().addingTimeInterval(seconds)
        while Date() < deadline {
            if let message = socket.frames.take(kind) { return message }
            try await Task.sleep(for: .milliseconds(20))
        }
        throw TestFailure(detail: "No \(kind.rawValue) frame arrived within \(seconds)s")
    }

    func awaitCondition(
        _ description: String,
        within seconds: Double = 5,
        _ condition: () async throws -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(seconds)
        while Date() < deadline {
            if try await condition() { return }
            try await Task.sleep(for: .milliseconds(20))
        }
        throw TestFailure(detail: "Timed out waiting for \(description)")
    }
}

@Suite("WebSocket", .serialized)
struct WebSocketTests {
    private let amina = "amina.hodzic@stu.ibu.edu.ba"
    private let emir = "emir.kovacevic@stu.ibu.edu.ba"

    @Test("An upgrade without a usable token is refused before it becomes a socket")
    func badTokensAreRefused() async throws {
        try await withMessagingTestServer { context in
            let missing = try await context.app.testing().sendRequest(.GET, API.webSocket.fullPath)
            #expect(missing.status == .unauthorized)
            #expect(missing.apiError?.code == .unauthorized)

            let garbage = try await context.app.testing().sendRequest(
                .GET,
                API.webSocket.fullPath + "?token=not.a.jwt"
            )
            #expect(garbage.status == .unauthorized)
            #expect(garbage.apiError?.code == .unauthorized)
        }
    }

    @Test("A revoked session cannot open a socket even while its access token is unexpired")
    func revokedSessionsAreRefused() async throws {
        try await withMessagingTestServer { context in
            let session = try await context.signIn(as: amina)
            let accepted = try await context.app.testing().sendRequest(
                .GET,
                API.webSocket.fullPath + "?token=\(session.accessToken)"
            )
            #expect(accepted.status != .unauthorized)

            let loggedOut = try await context.app.testing().sendRequest(
                .POST,
                API.Auth.logout.fullPath,
                beforeRequest: {
                    try $0.content.encode(LogoutBody(refreshToken: session.refreshToken))
                }
            )
            #expect(loggedOut.status == .noContent)

            let refused = try await context.app.testing().sendRequest(
                .GET,
                API.webSocket.fullPath + "?token=\(session.accessToken)"
            )
            #expect(refused.status == .unauthorized)
        }
    }

    @Test("A ping is answered with a pong")
    func pingIsAnsweredWithPong() async throws {
        try await withMessagingTestServer(liveServerPort: 8101) { context in
            let session = try await context.signIn(as: amina)
            let socket = try await context.openSocket(port: 8101, token: session.accessToken)

            try await socket.send(.ping)
            let pong = try await context.awaitFrame(.pong, on: socket)
            #expect(pong == .pong)
            #expect(socket.frames.unreadableFrames.isEmpty)

            try await socket.close()
        }
    }

    @Test("A message sent over HTTP arrives on the recipient's socket")
    func messageCreatedReachesTheRecipient() async throws {
        try await withMessagingTestServer(liveServerPort: 8102) { context in
            let sender = try await context.signIn(as: amina)
            let recipient = try await context.signIn(as: emir)
            let socket = try await context.openSocket(port: 8102, token: recipient.accessToken)
            _ = try await context.awaitFrame(.unreadCountChanged, on: socket)

            let conversation = try await context.openConversation(sender, with: [recipient.user.id])
                .content.decode(Conversation.self)
            let sent = try await context.postMessage(
                sender,
                to: conversation.id,
                body: "The library closes at eight."
            ).content.decode(IBUgramKit.Message.self)

            let frame = try await context.awaitFrame(.messageCreated, on: socket)
            guard case .messageCreated(let payload) = frame else {
                throw TestFailure(detail: "Expected a message_created payload")
            }
            #expect(payload.message.id == sent.id)
            #expect(payload.message.conversationId == conversation.id)
            #expect(payload.message.body == "The library closes at eight.")
            #expect(payload.message.sender.id == sender.user.id)

            let counts = try await context.awaitFrame(.unreadCountChanged, on: socket)
            guard case .unreadCountChanged(let unread) = counts else {
                throw TestFailure(detail: "Expected an unread_count_changed payload")
            }
            #expect(unread.conversations == 0, "a request thread must not light up the inbox badge")

            try await socket.close()
        }
    }

    @Test("Both of a user's devices receive the same fan-out")
    func fanOutReachesEveryDevice() async throws {
        try await withMessagingTestServer(liveServerPort: 8103) { context in
            let sender = try await context.signIn(as: amina)
            let recipient = try await context.signIn(as: emir)
            let phone = try await context.openSocket(port: 8103, token: recipient.accessToken)
            let laptop = try await context.openSocket(port: 8103, token: recipient.accessToken)

            let registry = context.app.realtimeRegistry
            try await context.awaitCondition("two live connections") {
                await registry.connectionCount(for: recipient.user.id) == 2
            }

            let conversation = try await context.openConversation(sender, with: [recipient.user.id])
                .content.decode(Conversation.self)
            _ = try await context.postMessage(sender, to: conversation.id, body: "Two devices")

            for socket in [phone, laptop] {
                let frame = try await context.awaitFrame(.messageCreated, on: socket)
                guard case .messageCreated(let payload) = frame else {
                    throw TestFailure(detail: "Expected a message_created payload")
                }
                #expect(payload.message.body == "Two devices")
            }

            try await phone.close()
            try await laptop.close()
        }
    }

    @Test("A closed socket leaves the registry")
    func closedSocketsAreEvicted() async throws {
        try await withMessagingTestServer(liveServerPort: 8104) { context in
            let session = try await context.signIn(as: amina)
            let socket = try await context.openSocket(port: 8104, token: session.accessToken)
            let registry = context.app.realtimeRegistry

            try await context.awaitCondition("the socket to register") {
                await registry.connectionCount(for: session.user.id) == 1
            }
            try await socket.close()
            try await context.awaitCondition("the socket to be evicted") {
                await registry.connectionCount() == 0
            }
        }
    }

    @Test("Typing reaches the other participant's subscribed socket")
    func typingIsRelayedToSubscribers() async throws {
        try await withMessagingTestServer(liveServerPort: 8105) { context in
            let sender = try await context.signIn(as: amina)
            let recipient = try await context.signIn(as: emir)
            let conversation = try await context.openConversation(sender, with: [recipient.user.id])
                .content.decode(Conversation.self)

            let senderSocket = try await context.openSocket(port: 8105, token: sender.accessToken)
            let recipientSocket = try await context.openSocket(port: 8105, token: recipient.accessToken)
            try await recipientSocket.send(.subscribeConversation(ConversationScope(conversationId: conversation.id)))

            let registry = context.app.realtimeRegistry
            try await context.awaitCondition("the subscription to register") {
                await !registry.connections(for: [recipient.user.id], subscribedTo: conversation.id).isEmpty
            }

            try await senderSocket.send(.typingStart(ConversationScope(conversationId: conversation.id)))
            let frame = try await context.awaitFrame(.typing, on: recipientSocket)
            guard case .typing(let payload) = frame else {
                throw TestFailure(detail: "Expected a typing payload")
            }
            #expect(payload.conversationId == conversation.id)
            #expect(payload.userId == sender.user.id)
            #expect(payload.isTyping)

            try await senderSocket.close()
            try await recipientSocket.close()
        }
    }

    @Test("mark_read over the socket clears the counter and tells the sender")
    func markReadOverTheSocket() async throws {
        try await withMessagingTestServer(liveServerPort: 8106) { context in
            let sender = try await context.signIn(as: amina)
            let recipient = try await context.signIn(as: emir)
            let conversation = try await context.openConversation(sender, with: [recipient.user.id])
                .content.decode(Conversation.self)
            let message = try await context.postMessage(sender, to: conversation.id, body: "Read me")
                .content.decode(IBUgramKit.Message.self)

            let senderSocket = try await context.openSocket(port: 8106, token: sender.accessToken)
            let recipientSocket = try await context.openSocket(port: 8106, token: recipient.accessToken)

            try await recipientSocket.send(
                .markRead(MarkReadPayload(conversationId: conversation.id, upToMessageId: message.id))
            )

            let frame = try await context.awaitFrame(.messageRead, on: senderSocket)
            guard case .messageRead(let payload) = frame else {
                throw TestFailure(detail: "Expected a message_read payload")
            }
            #expect(payload.conversationId == conversation.id)
            #expect(payload.userId == recipient.user.id)
            #expect(payload.upToMessageId == message.id)

            try await context.awaitCondition("the unread count to clear") {
                try await context.participant(in: conversation.id, for: recipient.user.id).unreadCount == 0
            }

            try await senderSocket.close()
            try await recipientSocket.close()
        }
    }

    @Test("A frame the server does not understand is ignored rather than fatal")
    func unknownFramesAreIgnored() async throws {
        try await withMessagingTestServer(liveServerPort: 8107) { context in
            let session = try await context.signIn(as: amina)
            let socket = try await context.openSocket(port: 8107, token: session.accessToken)

            try await socket.socket.send("{\"type\":\"nonsense\",\"payload\":{}}")
            try await socket.socket.send("not json at all")
            try await socket.send(.ping)

            #expect(try await context.awaitFrame(.pong, on: socket) == .pong)
            try await socket.close()
        }
    }
}
