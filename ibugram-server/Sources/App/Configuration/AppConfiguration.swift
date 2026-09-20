import Foundation
import IBUgramKit
import Vapor

enum ConfigurationError: Error, CustomStringConvertible {
    case missingRequiredValue(String)

    var description: String {
        switch self {
        case .missingRequiredValue(let key):
            "\(key) must be set in this environment."
        }
    }
}

struct AppConfiguration: Sendable {
    struct DatabaseSettings: Sendable {
        var hostname: String
        var port: Int
        var username: String
        var password: String?
        var database: String
    }

    var environment: Environment
    var database: DatabaseSettings
    var jwtSecret: String
    var accessTokenLifetime: TimeInterval
    var refreshTokenLifetime: TimeInterval
    var mediaDirectory: URL
    var publicBaseURL: String
    var maxUploadBytes: Int
    var thumbnailMaxPixelSize: Int
    var jpegCompressionQuality: Double
    var version: String

    /// The OTP is echoed back only when the server is explicitly running as a developer
    /// workstation, so a production deployment cannot leak it however it is configured.
    var exposesDebugCode: Bool { environment == .development }

    static func load(for environment: Environment) throws -> AppConfiguration {
        let isProduction = environment == .production
        let secret = Environment.get("JWT_SECRET")
        if isProduction, secret == nil {
            throw ConfigurationError.missingRequiredValue("JWT_SECRET")
        }

        let mediaPath = Environment.get("MEDIA_DIRECTORY")
            ?? FileManager.default.currentDirectoryPath + "/.media"

        return AppConfiguration(
            environment: environment,
            database: DatabaseSettings(
                hostname: Environment.get("DATABASE_HOST") ?? "127.0.0.1",
                port: Environment.get("DATABASE_PORT").flatMap(Int.init) ?? 5432,
                username: Environment.get("DATABASE_USERNAME") ?? "sead",
                password: Environment.get("DATABASE_PASSWORD"),
                database: Environment.get("DATABASE_NAME") ?? defaultDatabaseName(for: environment)
            ),
            jwtSecret: secret ?? "ibugram-development-secret-do-not-use-in-production",
            accessTokenLifetime: Environment.get("ACCESS_TOKEN_LIFETIME").flatMap(TimeInterval.init)
                ?? IBUgram.accessTokenLifetime,
            refreshTokenLifetime: Environment.get("REFRESH_TOKEN_LIFETIME").flatMap(TimeInterval.init)
                ?? IBUgram.refreshTokenLifetime,
            mediaDirectory: URL(fileURLWithPath: mediaPath, isDirectory: true),
            publicBaseURL: Environment.get("PUBLIC_BASE_URL") ?? "http://127.0.0.1:8080",
            maxUploadBytes: Environment.get("MAX_UPLOAD_BYTES").flatMap(Int.init) ?? IBUgram.maxUploadBytes,
            thumbnailMaxPixelSize: Environment.get("THUMBNAIL_MAX_PIXELS").flatMap(Int.init) ?? 400,
            jpegCompressionQuality: Environment.get("JPEG_QUALITY").flatMap(Double.init) ?? 0.82,
            version: Environment.get("APP_VERSION") ?? "1.0.0"
        )
    }

    private static func defaultDatabaseName(for environment: Environment) -> String {
        environment == .testing ? "ibugram_test" : "ibugram_dev"
    }
}

extension Application {
    private struct ConfigurationKey: StorageKey {
        typealias Value = AppConfiguration
    }

    var configuration: AppConfiguration {
        get {
            guard let stored = storage[ConfigurationKey.self] else {
                fatalError("Application.configuration read before configure(_:) ran.")
            }
            return stored
        }
        set { storage[ConfigurationKey.self] = newValue }
    }
}

extension Request {
    var configuration: AppConfiguration { application.configuration }
}
