import Fluent
import Foundation
import IBUgramKit
import JWT
import Vapor

struct IssuedTokens: Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let session: AuthSessionRecord
}

struct SessionContext: Sendable {
    let deviceName: String?
    let userAgent: String?
    let ipAddress: String?

    init(request: Request, deviceName: String? = nil) {
        self.deviceName = deviceName
        self.userAgent = request.headers.first(name: .userAgent)
        self.ipAddress = request.remoteAddress?.ipAddress
    }
}

struct TokenService: Sendable {
    let accessTokenLifetime: TimeInterval
    let refreshTokenLifetime: TimeInterval

    func startSession(
        for user: UserRecord,
        context: SessionContext,
        on request: Request
    ) async throws -> IssuedTokens {
        try await createSession(for: user, familyId: UUID(), context: context, on: request)
    }

    /// Rotation is unconditional: the presented token is retired even when the caller
    /// never uses the replacement, which is what makes reuse detectable.
    func rotateSession(
        presenting refreshToken: String,
        context: SessionContext,
        on request: Request
    ) async throws -> IssuedTokens {
        let presentedHash = Self.hash(refreshToken)
        guard let existing = try await AuthSessionRecord.query(on: request.db)
            .filter(\.$tokenHash == presentedHash)
            .with(\.$user)
            .first()
        else {
            throw APIError.unauthorized("That refresh token is not valid.")
        }

        if existing.revokedAt != nil {
            if existing.revokedReason == .rotated {
                try await revokeFamily(existing.familyId, reason: .reuseDetected, on: request.db)
                request.logger.warning(
                    "Refresh token reuse detected",
                    metadata: ["family": .string(existing.familyId.uuidString)]
                )
            }
            throw APIError.unauthorized("That refresh token is not valid.")
        }

        guard existing.expiresAt > Date() else {
            existing.revokedAt = Date()
            existing.revokedReason = .expired
            try await existing.save(on: request.db)
            throw APIError.unauthorized("That session has expired. Sign in again.")
        }

        let replacement = try await createSession(
            for: existing.user,
            familyId: existing.familyId,
            context: SessionContext(
                request: request,
                deviceName: context.deviceName ?? existing.deviceName
            ),
            on: request
        )
        existing.revokedAt = Date()
        existing.revokedReason = .rotated
        existing.$replacedBy.id = replacement.session.id
        try await existing.save(on: request.db)
        return replacement
    }

    func revokeSession(presenting refreshToken: String, on database: any Database) async throws {
        guard let existing = try await AuthSessionRecord.query(on: database)
            .filter(\.$tokenHash == Self.hash(refreshToken))
            .first(),
            existing.revokedAt == nil
        else { return }
        try await revokeFamily(existing.familyId, reason: .loggedOut, on: database)
    }

    func revokeFamily(
        _ familyId: UUID,
        reason: SessionRevocationReason,
        on database: any Database
    ) async throws {
        try await AuthSessionRecord.query(on: database)
            .filter(\.$familyId == familyId)
            .filter(\.$revokedAt == nil)
            .set(\.$revokedAt, to: Date())
            .set(\.$revokedReason, to: reason)
            .update()
    }

    func activeSessions(forUser userId: UUID, on database: any Database) async throws -> [AuthSessionRecord] {
        try await AuthSessionRecord.query(on: database)
            .filter(\.$user.$id == userId)
            .filter(\.$revokedAt == nil)
            .filter(\.$expiresAt > Date())
            .sort(\.$lastUsedAt, .descending)
            .all()
    }

    private func createSession(
        for user: UserRecord,
        familyId: UUID,
        context: SessionContext,
        on request: Request
    ) async throws -> IssuedTokens {
        let userId = try user.requireID()
        let now = Date()
        let refreshToken = Self.generateRefreshToken()
        let session = AuthSessionRecord(
            userId: userId,
            familyId: familyId,
            tokenHash: Self.hash(refreshToken),
            deviceName: context.deviceName,
            userAgent: context.userAgent,
            ipAddress: context.ipAddress,
            expiresAt: now.addingTimeInterval(refreshTokenLifetime),
            now: now
        )
        try await session.save(on: request.db)

        let payload = AccessTokenPayload(
            subject: SubjectClaim(value: userId.uuidString),
            expiration: ExpirationClaim(value: now.addingTimeInterval(accessTokenLifetime)),
            issuedAt: IssuedAtClaim(value: now),
            tokenId: IDClaim(value: try session.requireID().uuidString),
            sessionFamily: familyId,
            role: user.role
        )
        return IssuedTokens(
            accessToken: try await request.jwt.sign(payload),
            refreshToken: refreshToken,
            expiresIn: Int(accessTokenLifetime),
            session: session
        )
    }

    static func hash(_ token: String) -> String {
        SHA256.hash(data: Data(token.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    private static func generateRefreshToken() -> String {
        Data([UInt8].random(count: 32))
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
