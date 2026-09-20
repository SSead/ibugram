import Foundation
import IBUgramKit

struct APIConfiguration: Sendable {
    let scheme: String
    let host: String
    let port: Int?
    let basePath: String

    static let development = APIConfiguration(
        scheme: "http",
        host: "127.0.0.1",
        port: 8080,
        basePath: IBUgram.apiVersionPath
    )

    static let preview = APIConfiguration(
        scheme: "https",
        host: "preview.ibugram.invalid",
        port: nil,
        basePath: IBUgram.apiVersionPath
    )
}

extension APIConfiguration {
    func url(path: String, queryItems: [URLQueryItem] = []) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.port = port
        components.path = basePath + path
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        return components.url
    }

    func webSocketURL(token: String) -> URL? {
        var components = URLComponents()
        components.scheme = scheme == "https" ? "wss" : "ws"
        components.host = host
        components.port = port
        components.path = basePath + "/ws"
        components.queryItems = [URLQueryItem(name: "token", value: token)]
        return components.url
    }

    /// Media URLs may arrive host-relative; anything already absolute is returned untouched.
    func resolve(_ url: URL) -> URL {
        guard url.host() == nil else { return url }
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.port = port
        components.path = url.path()
        return components.url ?? url
    }
}
