import IBUgramKit
import Vapor

func registerRoutes(_ app: Application) throws {
    try app.register(collection: HealthController())

    let api = app.grouped(
        PathComponent(stringLiteral: "api"),
        PathComponent(stringLiteral: "v1")
    )
    api.on(API.versionedHealth, use: HealthController().health)

    let throttledAuth = api.grouped(
        RateLimitMiddleware(
            limiter: app.dependencies.authRateLimiter,
            limit: 30,
            window: 60
        )
    )
    try throttledAuth.register(collection: AuthController())

    try api.register(collection: UserController())
    try api.register(collection: FollowController())
    try api.register(collection: FeedController())
    try api.register(collection: PostController())
    try api.register(collection: CommentController())
    try api.register(collection: SearchController())
    try api.register(collection: MediaController())
    try api.register(collection: SpaceController())
    try api.register(collection: EventController())
    try api.register(collection: ReportController())
    try api.register(collection: ConversationController())
    try api.register(collection: MessageController())
    try api.register(collection: NotificationController())
    try api.register(collection: RealtimeController())
    try api.register(collection: ReservedEndpointController())
}
