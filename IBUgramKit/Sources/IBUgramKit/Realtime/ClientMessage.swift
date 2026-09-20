import Foundation

public enum ClientMessage: Codable, Sendable, Hashable {
    case ping
    case typingStart(ConversationScope)
    case typingStop(ConversationScope)
    case subscribeConversation(ConversationScope)
    case unsubscribeConversation(ConversationScope)
    case markRead(MarkReadPayload)

    public enum Kind: String, Sendable, Hashable, CaseIterable {
        case ping
        case typingStart = "typing_start"
        case typingStop = "typing_stop"
        case subscribeConversation = "subscribe_conversation"
        case unsubscribeConversation = "unsubscribe_conversation"
        case markRead = "mark_read"
    }

    public var kind: Kind {
        switch self {
        case .ping: .ping
        case .typingStart: .typingStart
        case .typingStop: .typingStop
        case .subscribeConversation: .subscribeConversation
        case .unsubscribeConversation: .unsubscribeConversation
        case .markRead: .markRead
        }
    }

    public init(from decoder: any Decoder) throws {
        let type = try FrameCoding.discriminator(from: decoder)
        guard let kind = Kind(rawValue: type) else {
            throw FrameCoding.unrecognisedType(type, in: decoder)
        }
        switch kind {
        case .ping:
            self = .ping
        case .typingStart:
            self = .typingStart(try FrameCoding.payload(ConversationScope.self, from: decoder))
        case .typingStop:
            self = .typingStop(try FrameCoding.payload(ConversationScope.self, from: decoder))
        case .subscribeConversation:
            self = .subscribeConversation(try FrameCoding.payload(ConversationScope.self, from: decoder))
        case .unsubscribeConversation:
            self = .unsubscribeConversation(try FrameCoding.payload(ConversationScope.self, from: decoder))
        case .markRead:
            self = .markRead(try FrameCoding.payload(MarkReadPayload.self, from: decoder))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        switch self {
        case .ping:
            try FrameCoding.encode(type: kind.rawValue, payload: EmptyPayload(), to: encoder)
        case .typingStart(let scope), .typingStop(let scope),
             .subscribeConversation(let scope), .unsubscribeConversation(let scope):
            try FrameCoding.encode(type: kind.rawValue, payload: scope, to: encoder)
        case .markRead(let payload):
            try FrameCoding.encode(type: kind.rawValue, payload: payload, to: encoder)
        }
    }
}
