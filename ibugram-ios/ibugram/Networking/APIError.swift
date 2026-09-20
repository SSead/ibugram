import Foundation
import IBUgramKit

enum APIError: Error, Sendable, Equatable {
    case offline
    case transport(String)
    case invalidURL(String)
    case invalidResponse
    case decoding(String)
    case unauthorized
    case forbidden
    case notFound
    case validationFailed(message: String)
    case domainNotAllowed
    case otpInvalid
    case otpExpired
    case otpThrottled(retryAfter: Int?)
    case rateLimited(retryAfter: Int?)
    case usernameTaken
    case conflict
    case payloadTooLarge
    case server(status: Int, code: String, message: String)

    init(envelope: APIErrorEnvelope, statusCode: Int, retryAfter: Int?) {
        let failure = envelope.error
        switch failure.code {
        case .unauthorized: self = .unauthorized
        case .forbidden: self = .forbidden
        case .notFound: self = .notFound
        case .validationFailed: self = .validationFailed(message: failure.message)
        case .domainNotAllowed: self = .domainNotAllowed
        case .otpInvalid: self = .otpInvalid
        case .otpExpired: self = .otpExpired
        case .otpThrottled: self = .otpThrottled(retryAfter: retryAfter)
        case .rateLimited: self = .rateLimited(retryAfter: retryAfter)
        case .usernameTaken: self = .usernameTaken
        case .conflict: self = .conflict
        case .payloadTooLarge: self = .payloadTooLarge
        case .internalError, .unknown:
            self = .server(status: statusCode, code: failure.code.rawValue, message: failure.message)
        }
    }
}

extension APIError {
    /// The contract forbids showing the server's `message` except as a last-resort fallback.
    var userFacingDescription: String {
        switch self {
        case .offline:
            "You appear to be offline. Check your connection and try again."
        case .transport, .invalidURL, .invalidResponse, .decoding:
            "IBUgram could not reach the campus server. Please try again."
        case .unauthorized:
            "Your session has expired. Sign in again to continue."
        case .forbidden:
            "You do not have permission to do that."
        case .notFound:
            "That content is no longer available."
        case .validationFailed(let message):
            message
        case .domainNotAllowed:
            "IBUgram is only open to ibu.edu.ba and stu.ibu.edu.ba addresses."
        case .otpInvalid:
            "That code is not correct. Check the digits and try again."
        case .otpExpired:
            "That code has expired. Request a new one."
        case .otpThrottled(let retryAfter):
            retryAfter.map { "Too many requests. Try again in \($0) seconds." }
                ?? "Too many requests. Try again in a minute."
        case .rateLimited:
            "You are doing that too quickly. Take a short break and try again."
        case .usernameTaken:
            "That username is already taken."
        case .conflict:
            "That change conflicts with something that already exists."
        case .payloadTooLarge:
            "That file is too large. Images must be under 10 MB."
        case .server:
            "Something went wrong on the campus server. Please try again."
        }
    }

    var isRetryable: Bool {
        switch self {
        case .offline, .transport, .invalidResponse, .server, .rateLimited:
            true
        default:
            false
        }
    }
}
