import Foundation

/// A code the server may return in the error envelope. Unrecognised codes decode to
/// `.unknown` so that a server deploying a new code never breaks an older client.
public enum APIErrorCode: RawRepresentable, Codable, Sendable, Hashable {
    case unauthorized
    case forbidden
    case notFound
    case validationFailed
    case domainNotAllowed
    case otpInvalid
    case otpExpired
    case otpThrottled
    case rateLimited
    case usernameTaken
    case conflict
    case payloadTooLarge
    case internalError
    case unknown(String)

    public static let canonical: [APIErrorCode] = [
        .unauthorized, .forbidden, .notFound, .validationFailed, .domainNotAllowed,
        .otpInvalid, .otpExpired, .otpThrottled, .rateLimited, .usernameTaken,
        .conflict, .payloadTooLarge, .internalError
    ]

    public init(rawValue: String) {
        switch rawValue {
        case "unauthorized": self = .unauthorized
        case "forbidden": self = .forbidden
        case "not_found": self = .notFound
        case "validation_failed": self = .validationFailed
        case "domain_not_allowed": self = .domainNotAllowed
        case "otp_invalid": self = .otpInvalid
        case "otp_expired": self = .otpExpired
        case "otp_throttled": self = .otpThrottled
        case "rate_limited": self = .rateLimited
        case "username_taken": self = .usernameTaken
        case "conflict": self = .conflict
        case "payload_too_large": self = .payloadTooLarge
        case "internal_error": self = .internalError
        default: self = .unknown(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .unauthorized: "unauthorized"
        case .forbidden: "forbidden"
        case .notFound: "not_found"
        case .validationFailed: "validation_failed"
        case .domainNotAllowed: "domain_not_allowed"
        case .otpInvalid: "otp_invalid"
        case .otpExpired: "otp_expired"
        case .otpThrottled: "otp_throttled"
        case .rateLimited: "rate_limited"
        case .usernameTaken: "username_taken"
        case .conflict: "conflict"
        case .payloadTooLarge: "payload_too_large"
        case .internalError: "internal_error"
        case .unknown(let raw): raw
        }
    }

    public var isRecognised: Bool {
        if case .unknown = self { return false }
        return true
    }

    /// The status the server sends with this code; the client uses it to classify a
    /// failure it does not otherwise recognise.
    public var httpStatus: Int {
        switch self {
        case .unauthorized: 401
        case .forbidden: 403
        case .notFound: 404
        case .validationFailed: 422
        case .domainNotAllowed: 403
        case .otpInvalid: 400
        case .otpExpired: 410
        case .otpThrottled: 429
        case .rateLimited: 429
        case .usernameTaken: 409
        case .conflict: 409
        case .payloadTooLarge: 413
        case .internalError, .unknown: 500
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(rawValue: try container.decode(String.self))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

public struct APIErrorPayload: Codable, Sendable, Hashable {
    public var code: APIErrorCode
    public var message: String
    public var details: [String: JSONValue]

    public init(code: APIErrorCode, message: String, details: [String: JSONValue] = [:]) {
        self.code = code
        self.message = message
        self.details = details
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decode(APIErrorCode.self, forKey: .code)
        message = try container.decode(String.self, forKey: .message)
        details = try container.decodeIfPresent([String: JSONValue].self, forKey: .details) ?? [:]
    }
}

/// The complete body of every non-2xx response.
public struct APIError: Error, Codable, Sendable, Hashable {
    public var error: APIErrorPayload

    public init(error: APIErrorPayload) {
        self.error = error
    }

    public init(code: APIErrorCode, message: String, details: [String: JSONValue] = [:]) {
        self.error = APIErrorPayload(code: code, message: message, details: details)
    }

    public var code: APIErrorCode { error.code }
    public var message: String { error.message }
    public var details: [String: JSONValue] { error.details }
}

extension APIError: CustomStringConvertible {
    public var description: String { "\(code.rawValue): \(message)" }
}
