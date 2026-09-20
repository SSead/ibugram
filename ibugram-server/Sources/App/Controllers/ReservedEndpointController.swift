import IBUgramKit
import Vapor

/// The whole contract is registered so the route table is complete and a client gets a
/// structured `501` instead of a bare `404` while a feature team is still building.
/// Deleting a line here is the first step of implementing that endpoint.
struct ReservedEndpointController: RouteCollection {
    static let reserved: [Endpoint] = []

    func boot(routes: any RoutesBuilder) throws {
        let authenticated = routes.grouped(AccessTokenAuthenticator())
        for endpoint in Self.reserved {
            authenticated.on(endpoint, use: Self.placeholder(for: endpoint))
        }
    }

    private static func placeholder(for endpoint: Endpoint) -> @Sendable (Request) throws -> Response {
        let label = "\(endpoint.method.rawValue) \(endpoint.fullPath)"
        return { _ in try Response.json(APIError.notImplemented(label), status: .notImplemented) }
    }
}
