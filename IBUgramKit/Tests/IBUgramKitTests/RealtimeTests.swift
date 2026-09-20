import Foundation
import Testing
@testable import IBUgramKit

@Suite("WebSocket frames")
struct RealtimeTests {
    @Test("A client frame encodes to a type and payload pair")
    func clientFrameShape() throws {
        let frame = ClientMessage.typingStart(ConversationScope(conversationId: Fixture.conversationId))
        let data = try JSONEncoder.ibugram.encode(frame)
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(object?["type"] as? String == "typing_start")
        let payload = object?["payload"] as? [String: Any]
        #expect(payload?["conversation_id"] as? String == Fixture.conversationId.uuidString)
    }

    @Test("Ping carries an empty payload object")
    func pingCarriesEmptyPayload() throws {
        let data = try JSONEncoder.ibugram.encode(ClientMessage.ping)
        let text = String(decoding: data, as: UTF8.self)
        #expect(text.contains(#""type":"ping""#))
        #expect(text.contains(#""payload":{}"#))
        #expect(try JSONDecoder.ibugram.decode(ClientMessage.self, from: data) == .ping)
    }

    @Test("Every client message kind survives a round trip")
    func clientMessagesRoundTrip() throws {
        let scope = ConversationScope(conversationId: Fixture.conversationId)
        let messages: [ClientMessage] = [
            .ping,
            .typingStart(scope),
            .typingStop(scope),
            .subscribeConversation(scope),
            .unsubscribeConversation(scope),
            .markRead(MarkReadPayload(conversationId: Fixture.conversationId, upToMessageId: Fixture.messageId))
        ]
        #expect(messages.map(\.kind.rawValue) == ClientMessage.Kind.allCases.map(\.rawValue))
        for message in messages {
            let data = try JSONEncoder.ibugram.encode(message)
            #expect(try JSONDecoder.ibugram.decode(ClientMessage.self, from: data) == message)
        }
    }

    @Test("Every server message kind survives a round trip")
    func serverMessagesRoundTrip() throws {
        let messages: [ServerMessage] = [
            .pong,
            .messageCreated(MessageCreatedPayload(message: Fixture.message)),
            .messageRead(MessageReadPayload(
                conversationId: Fixture.conversationId,
                userId: Fixture.studentId,
                upToMessageId: Fixture.messageId,
                readAt: Fixture.timestamp
            )),
            .typing(TypingPayload(
                conversationId: Fixture.conversationId,
                userId: Fixture.studentId,
                isTyping: true
            )),
            .presenceChanged(PresenceChangedPayload(
                userId: Fixture.studentId,
                isOnline: false,
                lastSeenAt: Fixture.timestamp
            )),
            .notificationCreated(NotificationCreatedPayload(notification: Fixture.notification)),
            .unreadCountChanged(UnreadCountChangedPayload(conversations: 3, notifications: 11))
        ]
        #expect(messages.map(\.kind.rawValue) == ServerMessage.Kind.allCases.map(\.rawValue))
        for message in messages {
            let data = try JSONEncoder.ibugram.encode(message)
            #expect(try JSONDecoder.ibugram.decode(ServerMessage.self, from: data) == message)
        }
    }

    @Test("A frame type the client does not know is rejected rather than misread")
    func unknownFrameTypeThrows() {
        let data = Data(#"{"type":"cosmic_ray","payload":{}}"#.utf8)
        #expect(throws: DecodingError.self) {
            try JSONDecoder.ibugram.decode(ServerMessage.self, from: data)
        }
    }

    @Test("The generic envelope decodes a typed payload")
    func genericEnvelopeDecodes() throws {
        let frame = WebSocketFrame(type: "typing", payload: TypingPayload(
            conversationId: Fixture.conversationId,
            userId: Fixture.facultyId,
            isTyping: false
        ))
        let data = try JSONEncoder.ibugram.encode(frame)
        let decoded = try JSONDecoder.ibugram.decode(WebSocketFrame<TypingPayload>.self, from: data)
        #expect(decoded == frame)
    }
}
