import Fluent
import IBUgramKit
import Vapor

/// The single place a thrown error becomes a response body. Nothing below it is allowed
/// to describe an internal failure to a caller.
struct APIErrorMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        do {
            return try await next.respond(to: request)
        } catch {
            let apiError = Self.translate(error, logger: request.logger)
            request.logger.log(
                level: apiError.code == .internalError ? .error : .debug,
                "\(request.method) \(request.url.path) failed: \(apiError.code.rawValue)",
                metadata: ["reason": .string(apiError.message)]
            )
            return (try? Response.json(apiError, status: apiError.status))
                ?? Self.lastResortResponse()
        }
    }

    static func translate(_ error: any Error, logger: Logger) -> APIError {
        switch error {
        case let apiError as APIError:
            return apiError
        case let validations as ValidationsError:
            return APIError(
                code: .validationFailed,
                message: "Some fields are not valid.",
                details: details(from: validations)
            )
        case let decoding as DecodingError:
            return APIError(
                code: .validationFailed,
                message: "The request body could not be read.",
                details: ["reason": .string(summary(of: decoding))]
            )
        case let abort as any AbortError:
            return APIError(code: code(for: abort.status), message: abort.reason)
        default:
            logger.report(error: error)
            return APIError(code: .internalError, message: "Something went wrong on our side.")
        }
    }

    private static func details(from validations: ValidationsError) -> [String: JSONValue] {
        var details: [String: JSONValue] = [:]
        for failure in validations.failures {
            details[failure.key.stringValue] = .string(failure.result.failureDescription ?? "is not valid")
        }
        return details
    }

    private static func summary(of error: DecodingError) -> String {
        switch error {
        case .keyNotFound(let key, _): "missing field \(key.stringValue)"
        case .typeMismatch(_, let context), .valueNotFound(_, let context):
            context.codingPath.map(\.stringValue).joined(separator: ".")
        case .dataCorrupted(let context): context.debugDescription
        @unknown default: "malformed body"
        }
    }

    private static func code(for status: HTTPResponseStatus) -> APIErrorCode {
        switch status.code {
        case 401: .unauthorized
        case 403: .forbidden
        case 404: .notFound
        case 409: .conflict
        case 413: .payloadTooLarge
        case 422: .validationFailed
        case 429: .rateLimited
        default: status.code < 500 ? .validationFailed : .internalError
        }
    }

    /// Reached only if encoding the envelope itself fails, which must still not leak.
    private static func lastResortResponse() -> Response {
        let body = #"{"error":{"code":"internal_error","message":"Something went wrong on our side.","details":{}}}"#
        let response = Response(status: .internalServerError, body: .init(string: body))
        response.headers.contentType = .json
        return response
    }
}
