import Foundation
import IBUgramKit

actor APIClient: APIRequesting {
    private let configuration: APIConfiguration
    private let tokenStore: any TokenStoring
    private let sessionInvalidation: SessionInvalidationSignal
    private let session: URLSession
    private let decoder = JSONDecoder.ibugram
    private let encoder = JSONEncoder.ibugram
    private var refreshInFlight: Task<TokenPair, Error>?

    init(
        configuration: APIConfiguration,
        tokenStore: any TokenStoring,
        sessionInvalidation: SessionInvalidationSignal = SessionInvalidationSignal(),
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.tokenStore = tokenStore
        self.sessionInvalidation = sessionInvalidation
        self.session = session
    }

    func send<E: Endpoint>(_ endpoint: E) async throws -> E.Response {
        let data = try await perform(endpoint, allowingTokenRefresh: endpoint.requiresAuthentication)
        return try decode(data, as: E.Response.self)
    }

    private func perform<E: Endpoint>(_ endpoint: E, allowingTokenRefresh: Bool) async throws -> Data {
        let request = try await makeRequest(for: endpoint)
        let (data, response) = try await execute(request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }

        switch http.statusCode {
        case 200..<300:
            return data
        case 401 where allowingTokenRefresh:
            _ = try await refreshedTokens()
            return try await perform(endpoint, allowingTokenRefresh: false)
        default:
            throw failure(from: data, response: http)
        }
    }

    private func execute(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch let error as URLError {
            throw error.code == .notConnectedToInternet ? APIError.offline : .transport(error.localizedDescription)
        }
    }

    private func decode<T: Decodable>(_ data: Data, as type: T.Type) throws -> T {
        if let empty = EmptyResponse() as? T { return empty }
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw APIError.decoding(String(describing: error))
        }
    }

    private func failure(from data: Data, response: HTTPURLResponse) -> APIError {
        let retryAfter = (response.value(forHTTPHeaderField: "Retry-After")).flatMap(Int.init)
        guard let envelope = try? decoder.decode(APIErrorEnvelope.self, from: data) else {
            return .server(status: response.statusCode, code: "internal_error", message: "Unrecognized error envelope")
        }
        return APIError(envelope: envelope, statusCode: response.statusCode, retryAfter: retryAfter)
    }
}

// MARK: - Request construction

private extension APIClient {
    func makeRequest<E: Endpoint>(for endpoint: E) async throws -> URLRequest {
        guard let url = configuration.url(path: endpoint.path, queryItems: endpoint.queryItems) else {
            throw APIError.invalidURL(endpoint.path)
        }
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        try attach(endpoint.body, to: &request)
        if endpoint.requiresAuthentication, let tokens = await tokenStore.currentTokens() {
            request.setValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    func attach(_ body: HTTPBody?, to request: inout URLRequest) throws {
        switch body {
        case .none:
            return
        case .json(let value):
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                request.httpBody = try encoder.encode(value)
            } catch {
                throw APIError.decoding(String(describing: error))
            }
        case .multipart(let form):
            request.setValue(form.contentType, forHTTPHeaderField: "Content-Type")
            request.httpBody = form.encoded()
        }
    }
}

// MARK: - Token refresh

private extension APIClient {
    /// Concurrent 401s collapse onto a single refresh: the first caller creates the task,
    /// everyone else awaits its result.
    func refreshedTokens() async throws -> TokenPair {
        if let refreshInFlight { return try await refreshInFlight.value }

        let task = Task<TokenPair, Error> { [weak self] in
            guard let self else { throw APIError.unauthorized }
            return try await self.performRefresh()
        }
        refreshInFlight = task
        defer { refreshInFlight = nil }
        return try await task.value
    }

    func performRefresh() async throws -> TokenPair {
        guard let current = await tokenStore.currentTokens() else {
            await invalidateSession()
            throw APIError.unauthorized
        }
        do {
            let endpoint = AuthEndpoint.refresh(refreshToken: current.refreshToken)
            let data = try await perform(endpoint, allowingTokenRefresh: false)
            let session = try decode(data, as: AuthSession.self)
            let tokens = TokenPair(session: session)
            try await tokenStore.save(tokens)
            return tokens
        } catch {
            await invalidateSession()
            throw APIError.unauthorized
        }
    }

    func invalidateSession() async {
        try? await tokenStore.clear()
        sessionInvalidation.invalidate()
    }
}
