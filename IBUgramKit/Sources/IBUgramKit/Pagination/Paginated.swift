import Foundation

public struct Paginated<Item: Sendable>: Sendable {
    public var items: [Item]
    public var nextCursor: String?

    public init(items: [Item], nextCursor: String? = nil) {
        self.items = items
        self.nextCursor = nextCursor
    }

    public var hasMore: Bool { nextCursor != nil }

    public func map<Mapped: Sendable>(_ transform: (Item) throws -> Mapped) rethrows -> Paginated<Mapped> {
        Paginated<Mapped>(items: try items.map(transform), nextCursor: nextCursor)
    }
}

extension Paginated: Encodable where Item: Encodable {}
extension Paginated: Decodable where Item: Decodable {}
extension Paginated: Equatable where Item: Equatable {}
extension Paginated: Hashable where Item: Hashable {}

/// Query parameters shared by every cursor-paginated list endpoint.
public struct PageRequest: Sendable, Hashable, Codable {
    public var limit: Int
    public var cursor: String?

    public init(limit: Int = IBUgram.defaultPageSize, cursor: String? = nil) {
        self.limit = min(max(limit, 1), IBUgram.maxPageSize)
        self.cursor = cursor
    }

    public var queryItems: [URLQueryItem] {
        var items = [URLQueryItem(name: "limit", value: String(limit))]
        if let cursor {
            items.append(URLQueryItem(name: "cursor", value: cursor))
        }
        return items
    }
}
