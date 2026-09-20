import Foundation
import IBUgramKit

enum UserEndpoints {
    struct Posts: Endpoint {
        typealias Response = Paginated<Post>

        let username: String
        var cursor: String?
        var limit: Int = 20

        var path: String { "/users/\(username)/posts" }
        var queryItems: [URLQueryItem] { UserEndpoints.pageQuery(cursor: cursor, limit: limit) }
    }

    struct Following: Endpoint {
        typealias Response = Paginated<User>

        let username: String
        var cursor: String?
        var limit: Int = 20

        var path: String { "/users/\(username)/following" }
        var queryItems: [URLQueryItem] { UserEndpoints.pageQuery(cursor: cursor, limit: limit) }
    }

    struct Tagged: Endpoint {
        typealias Response = Paginated<Post>

        let username: String
        var cursor: String?
        var limit: Int = 20

        var path: String { "/users/\(username)/tagged" }
        var queryItems: [URLQueryItem] { UserEndpoints.pageQuery(cursor: cursor, limit: limit) }
    }

    struct Suggested: Endpoint {
        typealias Response = Paginated<User>

        var cursor: String?
        var limit: Int = 20

        var path: String { "/users/suggested" }
        var queryItems: [URLQueryItem] { UserEndpoints.pageQuery(cursor: cursor, limit: limit) }
    }

    struct Saved: Endpoint {
        typealias Response = Paginated<Post>

        var cursor: String?
        var limit: Int = 20

        var path: String { "/me/saved" }
        var queryItems: [URLQueryItem] { UserEndpoints.pageQuery(cursor: cursor, limit: limit) }
    }

    struct Follow: Endpoint {
        typealias Response = EmptyResponse

        let userID: UUID

        var method: HTTPMethod { .post }
        var path: String { "/users/\(userID.uuidString)/follow" }
    }

    struct Unfollow: Endpoint {
        typealias Response = EmptyResponse

        let userID: UUID

        var method: HTTPMethod { .delete }
        var path: String { "/users/\(userID.uuidString)/follow" }
    }

    struct Block: Endpoint {
        typealias Response = EmptyResponse

        let userID: UUID

        var method: HTTPMethod { .post }
        var path: String { "/users/\(userID.uuidString)/block" }
    }

    struct Unblock: Endpoint {
        typealias Response = EmptyResponse

        let userID: UUID

        var method: HTTPMethod { .delete }
        var path: String { "/users/\(userID.uuidString)/block" }
    }

    struct Blocked: Endpoint {
        typealias Response = Paginated<User>

        var cursor: String?
        var limit: Int = 20

        var path: String { "/users/me/blocked" }
        var queryItems: [URLQueryItem] { UserEndpoints.pageQuery(cursor: cursor, limit: limit) }
    }

    struct Report: Endpoint {
        typealias Response = EmptyResponse

        let subject: ReportSubject
        let subjectID: UUID
        let reason: ReportReason
        var detail: String?

        var method: HTTPMethod { .post }
        var path: String { "/reports" }
        var body: HTTPBody? {
            .json(
                ReportBody(subject: subject, subjectId: subjectID, reason: reason, detail: detail)
            )
        }
    }

    fileprivate static func pageQuery(cursor: String?, limit: Int) -> [URLQueryItem] {
        var items = [URLQueryItem(name: "limit", value: String(limit))]
        if let cursor { items.append(URLQueryItem(name: "cursor", value: cursor)) }
        return items
    }
}
