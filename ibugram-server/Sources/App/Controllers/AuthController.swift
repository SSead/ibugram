import Fluent
import Foundation
import IBUgramKit
import Vapor

struct AuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.on(API.Auth.requestCode, use: requestCode)
        routes.on(API.Auth.verifyCode, use: verifyCode)
        routes.on(API.Auth.refresh, use: refresh)
        routes.on(API.Auth.logout, use: logout)

        let authenticated = routes.grouped(AccessTokenAuthenticator())
        authenticated.on(API.Auth.sessions, use: listSessions)
        authenticated.on(API.Auth.revokeSessionTemplate, use: revokeSession)
    }

    private func requestCode(_ request: Request) async throws -> Response {
        try RequestCodeBody.validate(content: request)
        let body = try request.content.decode(RequestCodeBody.self)
        guard let email = EmailAddress.normalized(body.email), EmailAddress.isAllowed(email) else {
            throw APIError(
                code: .domainNotAllowed,
                message: "Use your @ibu.edu.ba or @stu.ibu.edu.ba address.",
                details: ["allowed_domains": .array(IBUgram.allowedEmailDomains.sorted().map(JSONValue.string))]
            )
        }

        let challenge = try await request.dependencies.otp.issueChallenge(
            toEmail: email,
            clientAddress: request.remoteAddress?.ipAddress,
            on: request.db
        )
        let payload = RequestCodeResponse(
            expiresAt: challenge.expiresAt,
            resendAfter: challenge.resendAfter,
            debugCode: request.configuration.exposesDebugCode ? challenge.code : nil
        )
        return try Response.json(payload, status: .accepted)
    }

    private func verifyCode(_ request: Request) async throws -> Response {
        try VerifyCodeBody.validate(content: request)
        let body = try request.content.decode(VerifyCodeBody.self)
        guard let email = EmailAddress.normalized(body.email), EmailAddress.isAllowed(email) else {
            throw APIError(code: .domainNotAllowed, message: "That address is not a university address.")
        }

        try await request.dependencies.otp.consumeChallenge(
            forEmail: email,
            code: body.code.trimmingCharacters(in: .whitespaces),
            on: request.db
        )
        let user = try await request.dependencies.accounts.findOrCreateUser(email: email, on: request.db)
        let tokens = try await request.dependencies.tokens.startSession(
            for: user,
            context: SessionContext(request: request, deviceName: body.deviceName),
            on: request
        )
        return try Response.json(try session(from: tokens, user: user, on: request))
    }

    private func refresh(_ request: Request) async throws -> Response {
        let body = try request.content.decode(RefreshTokenBody.self)
        let tokens = try await request.dependencies.tokens.rotateSession(
            presenting: body.refreshToken,
            context: SessionContext(request: request),
            on: request
        )
        let user = try await tokens.session.$user.get(on: request.db)
        return try Response.json(try session(from: tokens, user: user, on: request))
    }

    private func logout(_ request: Request) async throws -> Response {
        let body = try request.content.decode(LogoutBody.self)
        try await request.dependencies.tokens.revokeSession(presenting: body.refreshToken, on: request.db)
        return .empty()
    }

    private func listSessions(_ request: Request) async throws -> Response {
        let viewer = try request.requireAuthenticatedUser()
        let sessions = try await request.dependencies.tokens.activeSessions(
            forUser: viewer.id,
            on: request.db
        )
        return try Response.json(
            try sessions.map { try $0.asDTO(isCurrent: $0.familyId == viewer.sessionFamily) }
        )
    }

    private func revokeSession(_ request: Request) async throws -> Response {
        let viewer = try request.requireAuthenticatedUser()
        guard let identifier = request.parameters.get("id", as: UUID.self) else {
            throw APIError.validationFailed("That session id is not a UUID.")
        }
        guard let session = try await AuthSessionRecord.find(identifier, on: request.db),
              session.$user.id == viewer.id
        else {
            throw APIError.notFound("That session does not exist.")
        }
        try await request.dependencies.tokens.revokeFamily(
            session.familyId,
            reason: .revokedByUser,
            on: request.db
        )
        return .empty()
    }

    private func session(from tokens: IssuedTokens, user: UserRecord, on request: Request) throws -> AuthSession {
        AuthSession(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            expiresIn: tokens.expiresIn,
            user: try user.asDTO(urls: request.dependencies.urls),
            needsOnboarding: !user.hasCompletedOnboarding
        )
    }
}

extension RequestCodeBody: @retroactive Validatable {
    public static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: !.empty && .count(3...254))
    }
}

extension VerifyCodeBody: @retroactive Validatable {
    public static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: !.empty && .count(3...254))
        validations.add("code", as: String.self, is: .count(IBUgram.otpDigitCount...IBUgram.otpDigitCount))
    }
}
