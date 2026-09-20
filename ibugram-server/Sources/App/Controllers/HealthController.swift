import Fluent
import IBUgramKit
import SQLKit
import Vapor

struct HealthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.on(API.health, use: health)
    }

    /// Unauthenticated by design; it is on the documented public list in the contract.
    func health(_ request: Request) async throws -> Response {
        let databaseStatus = await Self.databaseStatus(on: request.db)
        let payload = HealthStatus(
            status: databaseStatus == "ok" ? "ok" : "degraded",
            database: databaseStatus,
            version: request.configuration.version
        )
        return try Response.json(payload, status: databaseStatus == "ok" ? .ok : .serviceUnavailable)
    }

    private static func databaseStatus(on database: any Database) async -> String {
        guard let sql = database as? any SQLDatabase else { return "unavailable" }
        do {
            _ = try await sql.raw("SELECT 1").first()
            return "ok"
        } catch {
            return "unavailable"
        }
    }
}
