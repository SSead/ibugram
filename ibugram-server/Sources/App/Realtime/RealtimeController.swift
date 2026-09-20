import Fluent
import Foundation
import IBUgramKit
import JWT
import Vapor

struct RealtimeIdentity: Sendable {
    let userId: UUID
    let sessionFamily: UUID
}

struct RealtimeController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.on(API.webSocket, use: upgrade)
    }

    /// Authentication happens before the upgrade, so a rejected socket is an ordinary JSON
    /// `401` the client can read rather than a closed connection it has to guess about.
    private func upgrade(_ request: Request) async throws -> Response {
        let identity = try await authenticate(request)
        return request.webSocket { upgraded, socket in
            RealtimeSession.start(
                socket: socket,
                identity: identity,
                application: upgraded.application,
                logger: upgraded.logger
            )
        }
    }

    /// The token arrives as a query parameter (A1.5), which puts this outside the bearer
    /// middleware. The checks are the same ones `AccessTokenAuthenticator` makes, including
    /// the session-family liveness rule from A1.2: a signed-out family must not hold a socket.
    private func authenticate(_ request: Request) async throws -> RealtimeIdentity {
        guard let token = request.query[String.self, at: "token"], !token.isEmpty else {
            throw APIError.unauthorized("The socket needs ?token=<access_token>.")
        }
        let payload: AccessTokenPayload
        do {
            payload = try await request.jwt.verify(token, as: AccessTokenPayload.self)
        } catch {
            throw APIError.unauthorized("That access token is not valid.")
        }
        guard let userId = payload.userId else {
            throw APIError.unauthorized("That access token is not valid.")
        }
        guard let user = try await UserRecord.find(userId, on: request.db), !user.isSuspended else {
            throw APIError.unauthorized("That account is no longer active.")
        }
        guard try await RealtimeAuthentication.isFamilyLive(payload.sessionFamily, on: request.db) else {
            throw APIError.unauthorized("That session has been signed out.")
        }
        return RealtimeIdentity(userId: userId, sessionFamily: payload.sessionFamily)
    }
}

enum RealtimeAuthentication {
    static func isFamilyLive(_ familyId: UUID, on database: any Database) async throws -> Bool {
        try await AuthSessionRecord.query(on: database)
            .filter(\.$familyId == familyId)
            .filter(\.$revokedAt == nil)
            .filter(\.$expiresAt > Date())
            .count() > 0
    }
}
