import Fluent
import Foundation
import IBUgramKit
import SQLKit
import Testing
import Vapor
import VaporTesting
@testable import App

extension TestContext {
    func requestCode(for email: String) async throws -> TestingHTTPResponse {
        try await app.testing().sendRequest(
            .POST,
            API.Auth.requestCode.fullPath,
            beforeRequest: { try $0.content.encode(RequestCodeBody(email: email)) }
        )
    }

    func signIn(as email: String) async throws -> AuthSession {
        _ = try await requestCode(for: email)
        let code = try #require(await codes.latestCode(for: email))
        let response = try await app.testing().sendRequest(
            .POST,
            API.Auth.verifyCode.fullPath,
            beforeRequest: { try $0.content.encode(VerifyCodeBody(email: email, code: code)) }
        )
        #expect(response.status == .ok)
        return try response.content.decode(AuthSession.self)
    }

    func authorized(_ token: String) -> HTTPHeaders {
        var headers = HTTPHeaders()
        headers.bearerAuthorization = BearerAuthorization(token: token)
        return headers
    }

    /// Lets a test reach a time-dependent branch without sleeping.
    func backdateChallenges(for email: String, seconds: Int) async throws {
        guard let sql = app.db as? any SQLDatabase else { return }
        try await sql.raw("""
            UPDATE otp_challenges
            SET created_at = created_at - interval '\(unsafeRaw: String(seconds)) seconds'
            WHERE email = \(bind: email)
            """).run()
    }

    func expireChallenges(for email: String) async throws {
        guard let sql = app.db as? any SQLDatabase else { return }
        try await sql.raw("""
            UPDATE otp_challenges SET expires_at = now() - interval '1 minute'
            WHERE email = \(bind: email)
            """).run()
    }
}

extension TestingHTTPResponse {
    var apiError: APIError? {
        try? content.decode(APIError.self)
    }
}
