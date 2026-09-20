import Foundation

enum AuthEndpoint {
    struct RequestCode: Endpoint {
        typealias Response = OneTimeCodeChallenge

        let email: String

        var method: HTTPMethod { .post }
        var path: String { "/auth/request-code" }
        var requiresAuthentication: Bool { false }
        var body: HTTPBody? { .json(Payload(email: email)) }

        private struct Payload: Encodable, Sendable {
            let email: String
        }
    }

    struct VerifyCode: Endpoint {
        typealias Response = AuthSession

        let email: String
        let code: String

        var method: HTTPMethod { .post }
        var path: String { "/auth/verify-code" }
        var requiresAuthentication: Bool { false }
        var body: HTTPBody? { .json(Payload(email: email, code: code)) }

        private struct Payload: Encodable, Sendable {
            let email: String
            let code: String
        }
    }

    struct Refresh: Endpoint {
        typealias Response = AuthSession

        let refreshToken: String

        var method: HTTPMethod { .post }
        var path: String { "/auth/refresh" }
        var requiresAuthentication: Bool { false }
        var body: HTTPBody? { .json(Payload(refreshToken: refreshToken)) }

        private struct Payload: Encodable, Sendable {
            let refreshToken: String
        }
    }

    struct Logout: Endpoint {
        typealias Response = EmptyResponse

        let refreshToken: String

        var method: HTTPMethod { .post }
        var path: String { "/auth/logout" }
        var body: HTTPBody? { .json(Payload(refreshToken: refreshToken)) }

        private struct Payload: Encodable, Sendable {
            let refreshToken: String
        }
    }

    static func requestCode(email: String) -> RequestCode { RequestCode(email: email) }
    static func verifyCode(email: String, code: String) -> VerifyCode { VerifyCode(email: email, code: code) }
    static func refresh(refreshToken: String) -> Refresh { Refresh(refreshToken: refreshToken) }
    static func logout(refreshToken: String) -> Logout { Logout(refreshToken: refreshToken) }
}
