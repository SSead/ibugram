import IBUgramKit
import Vapor

extension Endpoint {
    var vaporMethod: HTTPMethod {
        switch method {
        case .get: .GET
        case .post: .POST
        case .patch: .PATCH
        case .put: .PUT
        case .delete: .DELETE
        }
    }

    /// Relative to the version group the route is registered under, so the `/api/v1`
    /// prefix is applied exactly once.
    var vaporPath: [PathComponent] {
        path.split(separator: "/").map { component in
            component.hasPrefix(":")
                ? PathComponent.parameter(String(component.dropFirst()))
                : PathComponent.constant(String(component))
        }
    }
}

extension RoutesBuilder {
    /// Registering from `IBUgramKit.Endpoint` keeps the server's route table and the
    /// client's URL builder provably identical.
    @discardableResult
    func on(
        _ endpoint: Endpoint,
        body: HTTPBodyStreamStrategy = .collect,
        use closure: @Sendable @escaping (Request) async throws -> some AsyncResponseEncodable
    ) -> Route {
        on(endpoint.vaporMethod, endpoint.vaporPath, body: body, use: closure)
    }
}
