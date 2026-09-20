import Foundation

enum NotificationEndpoints {
    struct List: Endpoint {
        typealias Response = Page<ActivityNotification>

        var cursor: String?
        var limit: Int = 20

        var path: String { "/notifications" }
        var queryItems: [URLQueryItem] {
            var items = [URLQueryItem(name: "limit", value: String(limit))]
            if let cursor { items.append(URLQueryItem(name: "cursor", value: cursor)) }
            return items
        }
    }

    struct UnreadCount: Endpoint {
        typealias Response = UnreadCountResponse

        var path: String { "/notifications/unread-count" }
    }

    struct MarkRead: Endpoint {
        typealias Response = EmptyResponse

        let ids: [UUID]

        var method: HTTPMethod { .post }
        var path: String { "/notifications/read" }
        var body: HTTPBody? { .json(Payload(ids: ids)) }

        private struct Payload: Encodable, Sendable {
            let ids: [UUID]
        }
    }
}
