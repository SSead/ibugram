import Foundation
import IBUgramKit

enum FeedEndpoint {
    struct Following: Endpoint {
        typealias Response = Paginated<Post>

        var cursor: String?
        var limit: Int = 20

        var path: String { "/feed/following" }
        var queryItems: [URLQueryItem] {
            var items = [URLQueryItem(name: "limit", value: String(limit))]
            if let cursor { items.append(URLQueryItem(name: "cursor", value: cursor)) }
            return items
        }
    }

    struct Discover: Endpoint {
        typealias Response = Paginated<Post>

        var cursor: String?
        var limit: Int = 20

        var path: String { "/feed/discover" }
        var queryItems: [URLQueryItem] {
            var items = [URLQueryItem(name: "limit", value: String(limit))]
            if let cursor { items.append(URLQueryItem(name: "cursor", value: cursor)) }
            return items
        }
    }

    static func following(cursor: String? = nil, limit: Int = 20) -> Following {
        Following(cursor: cursor, limit: limit)
    }

    static func discover(cursor: String? = nil, limit: Int = 20) -> Discover {
        Discover(cursor: cursor, limit: limit)
    }
}
