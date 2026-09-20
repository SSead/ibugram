import Fluent
import FluentPostgresDriver
import Foundation
import IBUgramKit
import JWT
import Vapor

public func configure(_ app: Application) async throws {
    try await configure(app, using: AppConfiguration.load(for: app.environment))
}

/// Tests supply a configuration directly so they can exercise a non-testing environment
/// without touching the process environment.
func configure(_ app: Application, using configuration: AppConfiguration) async throws {
    app.configuration = configuration

    ContentConfiguration.global.use(encoder: JSONEncoder.ibugram, for: .json)
    ContentConfiguration.global.use(decoder: JSONDecoder.ibugram, for: .json)

    app.routes.defaultMaxBodySize = ByteCount(value: configuration.maxUploadBytes + 1_048_576)
    app.middleware = Middlewares()
    app.middleware.use(APIErrorMiddleware())

    try configureDatabase(app, with: configuration)
    await app.jwt.keys.add(hmac: HMACKey(from: configuration.jwtSecret), digestAlgorithm: .sha256)
    app.dependencies = try makeServices(app, with: configuration)
    registerMigrations(app)

    try registerRoutes(app)
    app.asyncCommands.use(SeedCommand(), as: "seed")
}

private func configureDatabase(_ app: Application, with configuration: AppConfiguration) throws {
    let postgres = SQLPostgresConfiguration(
        hostname: configuration.database.hostname,
        port: configuration.database.port,
        username: configuration.database.username,
        password: configuration.database.password,
        database: configuration.database.database,
        tls: .disable
    )
    app.databases.use(.postgres(configuration: postgres), as: .psql)
}

private func makeServices(_ app: Application, with configuration: AppConfiguration) throws -> AppServices {
    AppServices(
        emailSender: ConsoleEmailSender(logger: app.logger),
        mediaStore: try FileSystemMediaStore(root: configuration.mediaDirectory),
        imageProcessor: ImageProcessor(
            thumbnailPixelSize: configuration.thumbnailMaxPixelSize,
            compressionQuality: configuration.jpegCompressionQuality
        ),
        otp: OTPService(
            emailSender: ConsoleEmailSender(logger: app.logger),
            hashCost: configuration.environment == .testing ? 4 : 10
        ),
        tokens: TokenService(
            accessTokenLifetime: configuration.accessTokenLifetime,
            refreshTokenLifetime: configuration.refreshTokenLifetime
        ),
        accounts: AccountService(),
        urls: MediaURLBuilder(publicBaseURL: configuration.publicBaseURL),
        authRateLimiter: RequestRateLimiter()
    )
}

func registerMigrations(_ app: Application) {
    app.migrations.add(CreateUser())
    app.migrations.add(CreateOTPChallenge())
    app.migrations.add(CreateAuthSession())
    app.migrations.add(CreateFollow())
    app.migrations.add(CreateBlock())
    app.migrations.add(CreateMediaAsset())
    app.migrations.add(AddUserAvatarMedia())
    app.migrations.add(CreatePlace())
    app.migrations.add(CreateSpace())
    app.migrations.add(CreateSpaceMembership())
    app.migrations.add(CreateEvent())
    app.migrations.add(CreateEventRSVP())
    app.migrations.add(CreatePost())
    app.migrations.add(CreatePostMedia())
    app.migrations.add(CreateHashtag())
    app.migrations.add(CreatePostHashtag())
    app.migrations.add(CreateComment())
    app.migrations.add(CreateMention())
    app.migrations.add(CreatePostLike())
    app.migrations.add(CreateCommentLike())
    app.migrations.add(CreateSave())
    app.migrations.add(CreateConversation())
    app.migrations.add(CreateConversationParticipant())
    app.migrations.add(CreateMessage())
    app.migrations.add(CreateMessageMedia())
    app.migrations.add(CreateMessageRead())
    app.migrations.add(AddConversationMessagePointers())
    app.migrations.add(CreateNotification())
    app.migrations.add(CreateNotificationActor())
    app.migrations.add(CreateReport())
    app.migrations.add(AddFullTextSearch())
    app.migrations.add(AddQueryIndexes())
    app.migrations.add(AddValueConstraints())
    app.migrations.add(AddCounterTriggers())
}
