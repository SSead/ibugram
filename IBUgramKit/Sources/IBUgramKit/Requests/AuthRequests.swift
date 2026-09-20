import Foundation

public struct RequestCodeBody: Codable, Sendable, Hashable {
    public var email: String

    public init(email: String) {
        self.email = email
    }
}

public struct VerifyCodeBody: Codable, Sendable, Hashable {
    public var email: String
    public var code: String
    public var deviceName: String?

    public init(email: String, code: String, deviceName: String? = nil) {
        self.email = email
        self.code = code
        self.deviceName = deviceName
    }
}

public struct RefreshTokenBody: Codable, Sendable, Hashable {
    public var refreshToken: String

    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}

public struct LogoutBody: Codable, Sendable, Hashable {
    public var refreshToken: String

    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}
