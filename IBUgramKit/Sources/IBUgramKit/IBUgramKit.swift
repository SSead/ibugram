import Foundation

public enum IBUgram {
    public static let allowedEmailDomains: Set<String> = Set(EmailDomain.allCases.map(\.rawValue))
    public static let apiVersionPath = "/api/v1"

    public static let maxPostMediaCount = 10
    public static let maxUploadBytes = 10 * 1024 * 1024
    public static let defaultPageSize = 20
    public static let maxPageSize = 100

    public static let otpDigitCount = 6
    public static let otpLifetime: TimeInterval = 600
    public static let otpMaxAttempts = 5
    public static let otpResendInterval: TimeInterval = 60
    public static let otpHourlyLimit = 5

    public static let accessTokenLifetime: TimeInterval = 15 * 60
    public static let refreshTokenLifetime: TimeInterval = 60 * 24 * 60 * 60
}
