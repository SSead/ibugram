import IBUgramKit
import Vapor

extension APIError {
    var status: HTTPResponseStatus {
        HTTPResponseStatus(statusCode: code.httpStatus)
    }

    static func unauthorized(_ message: String = "Sign in to continue.") -> APIError {
        APIError(code: .unauthorized, message: message)
    }

    static func forbidden(_ message: String = "You cannot do that.") -> APIError {
        APIError(code: .forbidden, message: message)
    }

    static func notFound(_ message: String = "That does not exist.") -> APIError {
        APIError(code: .notFound, message: message)
    }

    static func conflict(_ message: String) -> APIError {
        APIError(code: .conflict, message: message)
    }

    static func validationFailed(_ message: String, details: [String: JSONValue] = [:]) -> APIError {
        APIError(code: .validationFailed, message: message, details: details)
    }

    static func notImplemented(_ endpoint: String) -> APIError {
        APIError(
            code: .unknown("not_implemented"),
            message: "This endpoint is reserved and not implemented yet.",
            details: ["endpoint": .string(endpoint)]
        )
    }
}

extension Response {
    static func json(_ value: some Encodable, status: HTTPResponseStatus = .ok) throws -> Response {
        let response = Response(status: status)
        try response.content.encode(value, as: .json)
        return response
    }

    static func empty(status: HTTPResponseStatus = .noContent) -> Response {
        Response(status: status)
    }
}
