import Foundation

public struct AuthSession: Codable, Sendable, Hashable {
    public var accessToken: String
    public var refreshToken: String
    public var expiresIn: Int
    public var user: User
    public var needsOnboarding: Bool

    public init(
        accessToken: String,
        refreshToken: String,
        expiresIn: Int,
        user: User,
        needsOnboarding: Bool
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.user = user
        self.needsOnboarding = needsOnboarding
    }
}

public struct RequestCodeResponse: Codable, Sendable, Hashable {
    public var expiresAt: Date
    public var resendAfter: Int
    /// Present only when the server runs in the `development` environment.
    public var debugCode: String?

    public init(expiresAt: Date, resendAfter: Int, debugCode: String? = nil) {
        self.expiresAt = expiresAt
        self.resendAfter = resendAfter
        self.debugCode = debugCode
    }
}

/// One live refresh-token session, as listed by `GET /auth/sessions`.
public struct Session: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    public var deviceName: String?
    public var userAgent: String?
    public var ipAddress: String?
    public var isCurrent: Bool
    public var createdAt: Date
    public var lastUsedAt: Date
    public var expiresAt: Date

    public init(
        id: UUID,
        deviceName: String? = nil,
        userAgent: String? = nil,
        ipAddress: String? = nil,
        isCurrent: Bool = false,
        createdAt: Date,
        lastUsedAt: Date,
        expiresAt: Date
    ) {
        self.id = id
        self.deviceName = deviceName
        self.userAgent = userAgent
        self.ipAddress = ipAddress
        self.isCurrent = isCurrent
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.expiresAt = expiresAt
    }
}

public struct HealthStatus: Codable, Sendable, Hashable {
    public var status: String
    public var database: String
    public var version: String

    public init(status: String, database: String, version: String) {
        self.status = status
        self.database = database
        self.version = version
    }
}
