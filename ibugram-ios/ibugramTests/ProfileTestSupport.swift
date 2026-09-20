import Foundation
import Testing
@testable import ibugram

actor ScriptedAPIClient: APIRequesting {
    private var stubs: [String: any Sendable]
    private var failures: [String: APIError]
    private(set) var recorded: [String] = []
    private(set) var lastQueryItems: [URLQueryItem] = []

    init(
        stubs: [String: any Sendable] = [:],
        failures: [String: APIError] = [:]
    ) {
        self.stubs = stubs
        self.failures = failures
    }

    func send<E: Endpoint>(_ endpoint: E) async throws -> E.Response {
        let key = "\(endpoint.method.rawValue) \(endpoint.path)"
        recorded.append(key)
        lastQueryItems = endpoint.queryItems
        if let failure = failures[key] {
            throw failure
        }
        if let stub = stubs[key] {
            guard let typed = stub as? E.Response else {
                throw APIError.decoding("stub for \(key) is \(type(of: stub)), not \(E.Response.self)")
            }
            return typed
        }
        if let empty = EmptyResponse() as? E.Response {
            return empty
        }
        throw APIError.notFound
    }

    func recordedCalls() -> [String] { recorded }

    func queryValue(_ name: String) -> String? {
        lastQueryItems.first { $0.name == name }?.value
    }

    func fail(_ key: String, with error: APIError) {
        failures[key] = error
    }

    func stub(_ key: String, with value: any Sendable) {
        stubs[key] = value
    }
}
