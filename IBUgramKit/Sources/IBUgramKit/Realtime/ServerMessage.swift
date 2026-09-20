import Foundation

public enum ServerMessage: Codable, Sendable, Hashable {
    case pong
    case messageCreated(MessageCreatedPayload)
    case messageRead(MessageReadPayload)
    case typing(TypingPayload)
    case presenceChanged(PresenceChangedPayload)
    case notificationCreated(NotificationCreatedPayload)
    case unreadCountChanged(UnreadCountChangedPayload)

    public enum Kind: String, Sendable, Hashable, CaseIterable {
        case pong
        case messageCreated = "message_created"
        case messageRead = "message_read"
        case typing
        case presenceChanged = "presence_changed"
        case notificationCreated = "notification_created"
        case unreadCountChanged = "unread_count_changed"
    }

    public var kind: Kind {
        switch self {
        case .pong: .pong
        case .messageCreated: .messageCreated
        case .messageRead: .messageRead
        case .typing: .typing
        case .presenceChanged: .presenceChanged
        case .notificationCreated: .notificationCreated
        case .unreadCountChanged: .unreadCountChanged
        }
    }

    public init(from decoder: any Decoder) throws {
        let type = try FrameCoding.discriminator(from: decoder)
        guard let kind = Kind(rawValue: type) else {
            throw FrameCoding.unrecognisedType(type, in: decoder)
        }
        switch kind {
        case .pong:
            self = .pong
        case .messageCreated:
            self = .messageCreated(try FrameCoding.payload(MessageCreatedPayload.self, from: decoder))
        case .messageRead:
            self = .messageRead(try FrameCoding.payload(MessageReadPayload.self, from: decoder))
        case .typing:
            self = .typing(try FrameCoding.payload(TypingPayload.self, from: decoder))
        case .presenceChanged:
            self = .presenceChanged(try FrameCoding.payload(PresenceChangedPayload.self, from: decoder))
        case .notificationCreated:
            self = .notificationCreated(try FrameCoding.payload(NotificationCreatedPayload.self, from: decoder))
        case .unreadCountChanged:
            self = .unreadCountChanged(try FrameCoding.payload(UnreadCountChangedPayload.self, from: decoder))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        switch self {
        case .pong:
            try FrameCoding.encode(type: kind.rawValue, payload: EmptyPayload(), to: encoder)
        case .messageCreated(let payload):
            try FrameCoding.encode(type: kind.rawValue, payload: payload, to: encoder)
        case .messageRead(let payload):
            try FrameCoding.encode(type: kind.rawValue, payload: payload, to: encoder)
        case .typing(let payload):
            try FrameCoding.encode(type: kind.rawValue, payload: payload, to: encoder)
        case .presenceChanged(let payload):
            try FrameCoding.encode(type: kind.rawValue, payload: payload, to: encoder)
        case .notificationCreated(let payload):
            try FrameCoding.encode(type: kind.rawValue, payload: payload, to: encoder)
        case .unreadCountChanged(let payload):
            try FrameCoding.encode(type: kind.rawValue, payload: payload, to: encoder)
        }
    }
}
