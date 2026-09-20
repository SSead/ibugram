import Foundation

/// Preview and test double for `APIClient`. Stubs are keyed `"<METHOD> <path>"`, e.g.
/// `"GET /users/me"`. Anything unstubbed throws `.notFound`, which keeps previews honest.
actor MockAPIClient: APIRequesting {
    private var stubs: [String: any Sendable]
    private let failure: APIError?
    private let latency: Duration

    init(
        stubs: [String: any Sendable] = SampleData.defaultStubs,
        failure: APIError? = nil,
        latency: Duration = .zero
    ) {
        self.stubs = stubs
        self.failure = failure
        self.latency = latency
    }

    static func failing(_ error: APIError) -> MockAPIClient {
        MockAPIClient(stubs: [:], failure: error)
    }

    static func loadingForever() -> MockAPIClient {
        MockAPIClient(stubs: [:], latency: .seconds(60 * 60))
    }

    func stub<E: Endpoint>(_ endpoint: E, with response: E.Response) where E.Response: Sendable {
        stubs[Self.key(for: endpoint)] = response
    }

    func send<E: Endpoint>(_ endpoint: E) async throws -> E.Response {
        if latency > .zero { try await Task.sleep(for: latency) }
        if let failure { throw failure }
        if let empty = EmptyResponse() as? E.Response, stubs[Self.key(for: endpoint)] == nil {
            return empty
        }
        guard let stub = stubs[Self.key(for: endpoint)] else {
            throw APIError.notFound
        }
        guard let typed = stub as? E.Response else {
            throw APIError.decoding("stub for \(Self.key(for: endpoint)) is \(type(of: stub)), not \(E.Response.self)")
        }
        return typed
    }

    private static func key<E: Endpoint>(for endpoint: E) -> String {
        "\(endpoint.method.rawValue) \(endpoint.path)"
    }
}
