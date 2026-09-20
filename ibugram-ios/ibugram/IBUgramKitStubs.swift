import Foundation

// Temporary local stand-in for the parts of IBUgramKit the app foundation compiles
// against. The Backend Architect owns the real definitions; when they land, delete this
// entire file and add `import IBUgramKit` to the files that reference these names.
// Nothing outside this file may define a DTO.

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case put = "PUT"
    case delete = "DELETE"
}

enum HTTPBody: Sendable {
    case json(any Encodable & Sendable)
    case multipart(MultipartFormData)
}

protocol Endpoint: Sendable {
    associatedtype Response: Decodable & Sendable

    var method: HTTPMethod { get }
    var path: String { get }
    var queryItems: [URLQueryItem] { get }
    var body: HTTPBody? { get }
    var requiresAuthentication: Bool { get }
}

extension Endpoint {
    var method: HTTPMethod { .get }
    var queryItems: [URLQueryItem] { [] }
    var body: HTTPBody? { nil }
    var requiresAuthentication: Bool { true }
}

struct EmptyResponse: Decodable, Sendable {}

struct Page<Item: Decodable & Sendable>: Decodable, Sendable {
    let items: [Item]
    let nextCursor: String?

    init(items: [Item], nextCursor: String? = nil) {
        self.items = items
        self.nextCursor = nextCursor
    }
}

enum APIErrorCode: String, Decodable, Sendable {
    case unauthorized
    case forbidden
    case notFound = "not_found"
    case validationFailed = "validation_failed"
    case domainNotAllowed = "domain_not_allowed"
    case otpInvalid = "otp_invalid"
    case otpExpired = "otp_expired"
    case otpThrottled = "otp_throttled"
    case rateLimited = "rate_limited"
    case usernameTaken = "username_taken"
    case conflict
    case payloadTooLarge = "payload_too_large"
    case internalError = "internal_error"
}

struct APIErrorEnvelope: Decodable, Sendable {
    struct Failure: Decodable, Sendable {
        let code: String
        let message: String
    }

    let error: Failure
}

enum UserRole: String, Codable, Sendable {
    case student
    case faculty
}

struct UserCounts: Codable, Sendable, Hashable {
    let posts: Int
    let followers: Int
    let following: Int
}

struct ViewerRelationship: Codable, Sendable, Hashable {
    let isFollowing: Bool
    let isFollowedBy: Bool
    let isBlocked: Bool
}

struct User: Codable, Sendable, Hashable, Identifiable {
    let id: UUID
    let username: String
    let displayName: String
    let avatarUrl: URL?
    let bio: String?
    let role: UserRole
    let department: String?
    let yearOfStudy: Int?
    let isVerified: Bool
    let counts: UserCounts
    let viewer: ViewerRelationship?
    let createdAt: Date
}

struct Media: Codable, Sendable, Hashable, Identifiable {
    let id: UUID
    let url: URL
    let thumbnailUrl: URL
    let width: Int
    let height: Int
    let altText: String?
    let blurhash: String?
}

struct AuthSession: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let user: User
    let needsOnboarding: Bool
}

struct OneTimeCodeChallenge: Decodable, Sendable {
    let expiresAt: Date
    let resendAfter: Int
    let debugCode: String?
}

enum ServerFrameType: String, Decodable, Sendable {
    case pong
    case messageCreated = "message_created"
    case messageRead = "message_read"
    case typing
    case presenceChanged = "presence_changed"
    case notificationCreated = "notification_created"
    case unreadCountChanged = "unread_count_changed"
}

struct ServerFrame: Sendable {
    let type: ServerFrameType
    let payload: Data?

    func decodePayload<T: Decodable>(as payloadType: T.Type) throws -> T {
        guard let payload else { throw APIError.decoding("frame \(type.rawValue) carried no payload") }
        return try JSONDecoder.ibugram.decode(payloadType, from: payload)
    }
}

enum ClientFrameType: String, Encodable, Sendable {
    case ping
    case typingStart = "typing_start"
    case typingStop = "typing_stop"
    case subscribeConversation = "subscribe_conversation"
    case unsubscribeConversation = "unsubscribe_conversation"
    case markRead = "mark_read"
}

struct ClientFrame: Encodable, Sendable {
    let type: ClientFrameType
    let payload: [String: String]?

    static let ping = ClientFrame(type: .ping, payload: nil)

    static func typingStart(conversationID: UUID) -> ClientFrame {
        ClientFrame(type: .typingStart, payload: ["conversation_id": conversationID.uuidString])
    }

    static func typingStop(conversationID: UUID) -> ClientFrame {
        ClientFrame(type: .typingStop, payload: ["conversation_id": conversationID.uuidString])
    }

    static func subscribe(conversationID: UUID) -> ClientFrame {
        ClientFrame(type: .subscribeConversation, payload: ["conversation_id": conversationID.uuidString])
    }

    static func unsubscribe(conversationID: UUID) -> ClientFrame {
        ClientFrame(type: .unsubscribeConversation, payload: ["conversation_id": conversationID.uuidString])
    }

    static func markRead(conversationID: UUID, upToMessageID: UUID) -> ClientFrame {
        ClientFrame(
            type: .markRead,
            payload: [
                "conversation_id": conversationID.uuidString,
                "up_to_message_id": upToMessageID.uuidString
            ]
        )
    }
}
