import Foundation
import IBUgramKit

enum AuthEndpoint {
    struct RequestCode: Endpoint {
        typealias Response = RequestCodeResponse

        let email: String

        var method: HTTPMethod { .post }
        var path: String { "/auth/request-code" }
        var requiresAuthentication: Bool { false }
        var body: HTTPBody? { .json(RequestCodeBody(email: email)) }
    }

    struct VerifyCode: Endpoint {
        typealias Response = AuthSession

        let email: String
        let code: String

        var method: HTTPMethod { .post }
        var path: String { "/auth/verify-code" }
        var requiresAuthentication: Bool { false }
        var body: HTTPBody? { .json(VerifyCodeBody(email: email, code: code)) }
    }

    struct Refresh: Endpoint {
        typealias Response = AuthSession

        let refreshToken: String

        var method: HTTPMethod { .post }
        var path: String { "/auth/refresh" }
        var requiresAuthentication: Bool { false }
        var body: HTTPBody? { .json(RefreshTokenBody(refreshToken: refreshToken)) }
    }

    struct Logout: Endpoint {
        typealias Response = EmptyResponse

        let refreshToken: String

        var method: HTTPMethod { .post }
        var path: String { "/auth/logout" }
        var body: HTTPBody? { .json(LogoutBody(refreshToken: refreshToken)) }
    }

    struct Sessions: Endpoint {
        typealias Response = [Session]

        var path: String { "/auth/sessions" }
    }

    struct RevokeSession: Endpoint {
        typealias Response = EmptyResponse

        let id: UUID

        var method: HTTPMethod { .delete }
        var path: String { "/auth/sessions/\(id.uuidString)" }
    }

    static func requestCode(email: String) -> RequestCode { RequestCode(email: email) }
    static func verifyCode(email: String, code: String) -> VerifyCode { VerifyCode(email: email, code: code) }
    static func refresh(refreshToken: String) -> Refresh { Refresh(refreshToken: refreshToken) }
    static func logout(refreshToken: String) -> Logout { Logout(refreshToken: refreshToken) }
}
