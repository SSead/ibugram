import Fluent
import Foundation
import SQLKit
import Vapor
import VaporTesting
@testable import App

/// Collects the codes the auth flow "sends" so a test can read one without the server
/// having to expose it.
actor SentCodeLog: EmailSender {
    private var codesByAddress: [String: [String]] = [:]

    func sendVerificationCode(_ code: String, to address: String, expiresIn minutes: Int) async throws {
        codesByAddress[address, default: []].append(code)
    }

    func latestCode(for address: String) -> String? {
        codesByAddress[address]?.last
    }

    func deliveryCount(for address: String) -> Int {
        codesByAddress[address]?.count ?? 0
    }
}

/// Swift Testing runs suites concurrently, but every test here shares one PostgreSQL
/// database, so they take turns. This is what makes the tests order-independent and
/// repeatable rather than dependent on which suite happened to truncate last.
actor ExclusiveDatabaseAccess {
    static let shared = ExclusiveDatabaseAccess()

    private var isHeld = false
    private var waiting: [CheckedContinuation<Void, Never>] = []

    func acquire() async {
        guard isHeld else {
            isHeld = true
            return
        }
        await withCheckedContinuation { waiting.append($0) }
    }

    func release() {
        if waiting.isEmpty {
            isHeld = false
        } else {
            waiting.removeFirst().resume()
        }
    }
}

/// Rebuilds the schema once per test process, then hands each test an empty database.
actor TestDatabase {
    static let shared = TestDatabase()

    private var isPrepared = false

    func prepareSchema(on app: Application) async throws {
        guard !isPrepared else { return }
        try await app.execute(sql: "DROP SCHEMA IF EXISTS public CASCADE")
        try await app.execute(sql: "CREATE SCHEMA public")
        try await app.autoMigrate()
        isPrepared = true
    }
}

extension Application {
    fileprivate func execute(sql query: SQLQueryString) async throws {
        guard let sql = db as? any SQLDatabase else { return }
        try await sql.raw(query).run()
    }
}

enum TestSupport {
    static let tables = [
        "notification_actors", "notifications", "reports", "message_reads", "message_media",
        "messages", "conversation_participants", "conversations", "saves", "comment_likes",
        "post_likes", "mentions", "comments", "post_hashtags", "hashtags", "post_media",
        "posts", "event_rsvps", "events", "space_memberships", "spaces", "places",
        "blocks", "follows", "auth_sessions", "otp_challenges", "media", "users"
    ]

    static func configuration(for environment: Environment) -> AppConfiguration {
        AppConfiguration(
            environment: environment,
            database: AppConfiguration.DatabaseSettings(
                hostname: "127.0.0.1",
                port: 5432,
                username: "sead",
                password: nil,
                database: "ibugram_test"
            ),
            jwtSecret: "test-secret-that-is-long-enough-for-hmac-sha256",
            accessTokenLifetime: 900,
            refreshTokenLifetime: 5_184_000,
            mediaDirectory: FileManager.default.temporaryDirectory
                .appendingPathComponent("ibugram-test-media", isDirectory: true),
            publicBaseURL: "http://127.0.0.1:8080",
            maxUploadBytes: 10 * 1024 * 1024,
            thumbnailMaxPixelSize: 200,
            jpegCompressionQuality: 0.8,
            version: "test"
        )
    }
}

struct TestContext {
    let app: Application
    let codes: SentCodeLog
}

func withTestServer<T>(
    environment: Environment = .testing,
    _ body: (TestContext) async throws -> T
) async throws -> T {
    await ExclusiveDatabaseAccess.shared.acquire()
    do {
        let result = try await runServer(environment: environment, body)
        await ExclusiveDatabaseAccess.shared.release()
        return result
    } catch {
        await ExclusiveDatabaseAccess.shared.release()
        throw error
    }
}

private func runServer<T>(
    environment: Environment,
    _ body: (TestContext) async throws -> T
) async throws -> T {
    let app = try await Application.make(environment)
    do {
        try await configure(app, using: TestSupport.configuration(for: environment))
        try await TestDatabase.shared.prepareSchema(on: app)
        try await truncateEverything(on: app)

        let codes = SentCodeLog()
        var dependencies = app.dependencies
        dependencies.emailSender = codes
        dependencies.otp = OTPService(emailSender: codes, hashCost: 4)
        app.dependencies = dependencies

        let result = try await body(TestContext(app: app, codes: codes))
        try await app.asyncShutdown()
        return result
    } catch {
        try? await app.asyncShutdown()
        throw TestFailure(detail: String(reflecting: error))
    }
}

private func truncateEverything(on app: Application) async throws {
    guard let sql = app.db as? any SQLDatabase else { return }
    let list = TestSupport.tables.joined(separator: ", ")
    try await sql.raw("TRUNCATE TABLE \(unsafeRaw: list) RESTART IDENTITY CASCADE").run()
    await app.dependencies.authRateLimiter.reset()
}

/// PostgreSQL errors describe themselves opaquely by default; tests need the detail.
struct TestFailure: Error, CustomStringConvertible {
    let detail: String

    var description: String { detail }
}
