import Foundation
import IBUgramKit

enum SearchEndpoints {
    struct Query: Endpoint {
        typealias Response = SearchResults

        let q: String
        var type: SearchScope = .all

        var path: String { "/search" }
        var queryItems: [URLQueryItem] {
            [
                URLQueryItem(name: "q", value: q),
                URLQueryItem(name: "type", value: type.rawValue)
            ]
        }
    }

    struct Trending: Endpoint {
        typealias Response = Paginated<Hashtag>

        var path: String { "/search/trending" }
    }

    struct HashtagPosts: Endpoint {
        typealias Response = Paginated<Post>

        let tag: String
        var cursor: String?
        var limit: Int = 20

        var path: String { "/hashtags/\(tag)/posts" }
        var queryItems: [URLQueryItem] {
            var items = [URLQueryItem(name: "limit", value: String(limit))]
            if let cursor { items.append(URLQueryItem(name: "cursor", value: cursor)) }
            return items
        }
    }
}
