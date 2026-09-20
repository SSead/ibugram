import Fluent
import IBUgramKit
import JWT
import Vapor

struct AccessTokenPayload: JWTPayload {
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
        case issuedAt = "iat"
        case tokenId = "jti"
        case sessionFamily = "sfm"
        case role
    }

    var subject: SubjectClaim
    var expiration: ExpirationClaim
    var issuedAt: IssuedAtClaim
    var tokenId: IDClaim
    var sessionFamily: UUID
    var role: UserRole

    var userId: UUID? { UUID(uuidString: subject.value) }

    func verify(using algorithm: some JWTAlgorithm) async throws {
        try expiration.verifyNotExpired()
    }
}

/// The signed-in account for the current request.
struct AuthenticatedUser: Sendable {
    let id: UUID
    let role: UserRole
    let sessionFamily: UUID
}

struct AccessTokenAuthenticator: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        guard let token = request.headers.bearerAuthorization?.token else {
            throw APIError.unauthorized("This endpoint needs a bearer token.")
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
        guard try await isFamilyLive(payload.sessionFamily, on: request) else {
            throw APIError.unauthorized("That session has been signed out.")
        }
        request.authenticatedUser = AuthenticatedUser(
            id: userId,
            role: payload.role,
            sessionFamily: payload.sessionFamily
        )
        request.currentUserRecord = user
        return try await next.respond(to: request)
    }

    /// Access tokens are checked against the session family rather than the individual
    /// session row, so a normal refresh does not invalidate an access token the client
    /// is still using, while logout, user revocation and reuse detection take effect at once.
    private func isFamilyLive(_ familyId: UUID, on request: Request) async throws -> Bool {
        try await AuthSessionRecord.query(on: request.db)
            .filter(\.$familyId == familyId)
            .filter(\.$revokedAt == nil)
            .filter(\.$expiresAt > Date())
            .count() > 0
    }
}

extension Request {
    private struct AuthenticatedUserKey: StorageKey {
        typealias Value = AuthenticatedUser
    }

    private struct CurrentUserRecordKey: StorageKey {
        typealias Value = UserRecord
    }

    var authenticatedUser: AuthenticatedUser? {
        get { storage[AuthenticatedUserKey.self] }
        set { storage[AuthenticatedUserKey.self] = newValue }
    }

    fileprivate(set) var currentUserRecord: UserRecord? {
        get { storage[CurrentUserRecordKey.self] }
        set { storage[CurrentUserRecordKey.self] = newValue }
    }

    func requireAuthenticatedUser() throws -> AuthenticatedUser {
        guard let authenticatedUser else {
            throw APIError.unauthorized("This endpoint needs a bearer token.")
        }
        return authenticatedUser
    }

    func requireCurrentUserRecord() throws -> UserRecord {
        guard let currentUserRecord else {
            throw APIError.unauthorized("This endpoint needs a bearer token.")
        }
        return currentUserRecord
    }
}
