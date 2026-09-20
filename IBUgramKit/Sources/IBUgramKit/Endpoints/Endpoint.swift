import Foundation

public enum HTTPMethod: String, Sendable, Hashable, CaseIterable {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case put = "PUT"
    case delete = "DELETE"
}

public enum PathSegment: Sendable, Hashable {
    case literal(String)
    case parameter(String)
}

/// A single route in the contract. Templates carry `:name` placeholders; the builder
/// functions in `API` substitute real values so no caller assembles a URL by hand.
public struct Endpoint: Sendable, Hashable {
    public let method: HTTPMethod
    public let path: String
    /// `/health` is the only route the contract places outside the `/api/v1` prefix.
    public let isVersioned: Bool

    public init(_ method: HTTPMethod, _ path: String, isVersioned: Bool = true) {
        self.method = method
        self.path = path
        self.isVersioned = isVersioned
    }

    public var fullPath: String {
        isVersioned ? IBUgram.apiVersionPath + path : path
    }

    public var segments: [PathSegment] {
        fullPath.split(separator: "/").map { component in
            component.hasPrefix(":")
                ? .parameter(String(component.dropFirst()))
                : .literal(String(component))
        }
    }

    public var parameterNames: [String] {
        segments.compactMap { segment in
            if case .parameter(let name) = segment { return name }
            return nil
        }
    }

    public func substituting(_ values: [String: String]) -> Endpoint {
        let resolved = segments.map { segment -> String in
            switch segment {
            case .literal(let text): text
            case .parameter(let name): Endpoint.escape(values[name] ?? ":\(name)")
            }
        }
        return Endpoint(method, "/" + resolved.joined(separator: "/"), isVersioned: false)
    }

    public func url(relativeTo baseURL: URL, query: [URLQueryItem] = []) -> URL? {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(fullPath),
            resolvingAgainstBaseURL: false
        ) else { return nil }
        components.queryItems = query.isEmpty ? nil : query
        return components.url
    }

    static func escape(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .ibugramPathSegment) ?? value
    }
}

extension CharacterSet {
    fileprivate static let ibugramPathSegment: CharacterSet = {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return allowed
    }()
}
