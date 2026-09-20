import IBUgramKit
import Vapor

/// `Content` is Vapor's marker for a body type. The DTOs live in a Foundation-only
/// package that cannot import Vapor, so the conformance is declared here instead.
extension APIError: @retroactive AsyncRequestDecodable {}
extension APIError: @retroactive AsyncResponseEncodable {}
extension APIError: @retroactive Content {}

extension User: @retroactive AsyncRequestDecodable {}
extension User: @retroactive AsyncResponseEncodable {}
extension User: @retroactive Content {}

extension Media: @retroactive AsyncRequestDecodable {}
extension Media: @retroactive AsyncResponseEncodable {}
extension Media: @retroactive Content {}

extension AuthSession: @retroactive AsyncRequestDecodable {}
extension AuthSession: @retroactive AsyncResponseEncodable {}
extension AuthSession: @retroactive Content {}

extension RequestCodeResponse: @retroactive AsyncRequestDecodable {}
extension RequestCodeResponse: @retroactive AsyncResponseEncodable {}
extension RequestCodeResponse: @retroactive Content {}

extension IBUgramKit.Session: @retroactive AsyncRequestDecodable {}
extension IBUgramKit.Session: @retroactive AsyncResponseEncodable {}
extension IBUgramKit.Session: @retroactive Content {}

extension HealthStatus: @retroactive AsyncRequestDecodable {}
extension HealthStatus: @retroactive AsyncResponseEncodable {}
extension HealthStatus: @retroactive Content {}

extension RequestCodeBody: @retroactive AsyncRequestDecodable {}
extension RequestCodeBody: @retroactive AsyncResponseEncodable {}
extension RequestCodeBody: @retroactive Content {}

extension VerifyCodeBody: @retroactive AsyncRequestDecodable {}
extension VerifyCodeBody: @retroactive AsyncResponseEncodable {}
extension VerifyCodeBody: @retroactive Content {}

extension RefreshTokenBody: @retroactive AsyncRequestDecodable {}
extension RefreshTokenBody: @retroactive AsyncResponseEncodable {}
extension RefreshTokenBody: @retroactive Content {}

extension LogoutBody: @retroactive AsyncRequestDecodable {}
extension LogoutBody: @retroactive AsyncResponseEncodable {}
extension LogoutBody: @retroactive Content {}

extension UpdateProfileBody: @retroactive AsyncRequestDecodable {}
extension UpdateProfileBody: @retroactive AsyncResponseEncodable {}
extension UpdateProfileBody: @retroactive Content {}

extension SetUsernameBody: @retroactive AsyncRequestDecodable {}
extension SetUsernameBody: @retroactive AsyncResponseEncodable {}
extension SetUsernameBody: @retroactive Content {}
