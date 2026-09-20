import Foundation
import IBUgramKit

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

struct APIErrorEnvelope: Decodable, Sendable {
    let error: APIErrorPayload
}
