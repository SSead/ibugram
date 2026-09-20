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
    try api.register(collection: MediaController())
    try api.register(collection: ReservedEndpointController())
}
