import Foundation
import IBUgramKit

enum SpaceEndpoints {
    struct Browse: Endpoint {
        typealias Response = Paginated<Space>

        var kind: SpaceKind?
        var cursor: String?
        var limit: Int = IBUgram.defaultPageSize

        var path: String { "/spaces" }
        var queryItems: [URLQueryItem] {
            var items = PageRequest(limit: limit, cursor: cursor).queryItems
            if let kind {
                items.append(URLQueryItem(name: "kind", value: kind.rawValue))
            }
            return items
        }
    }

    struct Create: Endpoint {
        typealias Response = Space

        let bodyValue: CreateSpaceBody

        var method: HTTPMethod { .post }
        var path: String { "/spaces" }
        var body: HTTPBody? { .json(bodyValue) }
    }

    struct Detail: Endpoint {
        typealias Response = Space

        let slug: String

        var path: String { "/spaces/\(slug)" }
    }

    struct Posts: Endpoint {
        typealias Response = Paginated<Post>

        let slug: String
        var cursor: String?
        var limit: Int = IBUgram.defaultPageSize

        var path: String { "/spaces/\(slug)/posts" }
        var queryItems: [URLQueryItem] { PageRequest(limit: limit, cursor: cursor).queryItems }
    }

    struct Members: Endpoint {
        typealias Response = Paginated<SpaceMember>

        let slug: String
        var cursor: String?
        var limit: Int = IBUgram.defaultPageSize

        var path: String { "/spaces/\(slug)/members" }
        var queryItems: [URLQueryItem] { PageRequest(limit: limit, cursor: cursor).queryItems }
    }

    struct Join: Endpoint {
        typealias Response = EmptyResponse

        let slug: String

        var method: HTTPMethod { .post }
        var path: String { "/spaces/\(slug)/membership" }
    }

    struct Leave: Endpoint {
        typealias Response = EmptyResponse

        let slug: String

        var method: HTTPMethod { .delete }
        var path: String { "/spaces/\(slug)/membership" }
    }
}
