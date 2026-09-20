import Foundation
import IBUgramKit
import NIOCore
import NIOWebSocket
import Vapor

typealias WebSocketErrorCode = NIOWebSocket.WebSocketErrorCode
typealias TimeAmount = NIOCore.TimeAmount
typealias PageRequest = IBUgramKit.PageRequest

struct UsernameAvailability: Content, Sendable {
    var available: Bool
}

extension Post: @retroactive Content {}
extension Comment: @retroactive Content {}
extension Hashtag: @retroactive Content {}
extension SearchResults: @retroactive Content {}
extension CreatePostBody: @retroactive Content {}
extension UpdatePostBody: @retroactive Content {}
extension CreateCommentBody: @retroactive Content {}

extension Paginated: @retroactive RequestDecodable, @retroactive ResponseEncodable, @retroactive AsyncRequestDecodable, @retroactive AsyncResponseEncodable, @retroactive Content where Item: Codable {
    public static func decodeRequest(_ request: Request) -> EventLoopFuture<Self> {
        do {
            return request.eventLoop.makeSucceededFuture(try request.content.decode(Self.self))
        } catch {
            return request.eventLoop.makeFailedFuture(error)
        }
    }

    public static func decodeRequest(_ request: Request) async throws -> Self {
        try request.content.decode(Self.self)
    }

    public func encodeResponse(for request: Request) -> EventLoopFuture<Response> {
        do {
            let response = Response()
            try response.content.encode(self)
            return request.eventLoop.makeSucceededFuture(response)
        } catch {
            return request.eventLoop.makeFailedFuture(error)
        }
    }

    public func encodeResponse(for request: Request) async throws -> Response {
        let response = Response()
        try response.content.encode(self)
        return response
    }
}


extension Request {
    var page: IBUgramKit.PageRequest {
        IBUgramKit.PageRequest(
            limit: query[Int.self, at: "limit"] ?? IBUgram.defaultPageSize,
            cursor: query[String.self, at: "cursor"]
        )
    }

    var pageRequest: IBUgramKit.PageRequest { page }
}

enum KeysetCursor {
    static func encode(date: Date, id: UUID) -> String {
        encodeRaw("\(date.timeIntervalSince1970)|\(id.uuidString)")
    }

    static func decode(_ cursor: String) throws -> (date: Date, id: UUID) {
        let text = try decodeRaw(cursor)
        let parts = text.split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2,
              let interval = TimeInterval(parts[0]),
              let id = UUID(uuidString: String(parts[1]))
        else {
            throw APIError.validationFailed(
                "That cursor is not valid.",
                details: ["cursor": .string("malformed")]
            )
        }
        return (Date(timeIntervalSince1970: interval), id)
    }

    static func encodeRanked(score: Double, date: Date, id: UUID) -> String {
        encodeRaw("\(Self.scoreText(score))|\(date.timeIntervalSince1970)|\(id.uuidString)")
    }

    static func decodeRanked(_ cursor: String) throws -> (score: Double, date: Date, id: UUID) {
        let text = try decodeRaw(cursor)
        let parts = text.split(separator: "|", omittingEmptySubsequences: false)
        guard parts.count == 3,
              let score = Double(parts[0]),
              let interval = TimeInterval(parts[1]),
              let id = UUID(uuidString: String(parts[2]))
        else {
            throw APIError.validationFailed(
                "That cursor is not valid.",
                details: ["cursor": .string("malformed")]
            )
        }
        return (score, Date(timeIntervalSince1970: interval), id)
    }

    static func scoreText(_ score: Double) -> String {
        String(format: "%.8f", score)
    }

    private static func encodeRaw(_ payload: String) -> String {
        Data(payload.utf8)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func decodeRaw(_ cursor: String) throws -> String {
        var base64 = cursor
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64.append("=") }
        guard let data = Data(base64Encoded: base64),
              let text = String(data: data, encoding: .utf8)
        else {
            throw APIError.validationFailed(
                "That cursor is not valid.",
                details: ["cursor": .string("malformed")]
            )
        }
        return text
    }
}

enum PageSlice {
    static func take<Item>(_ rows: [Item], limit: Int, cursor: (Item) -> String) -> ([Item], String?) {
        let hasMore = rows.count > limit
        let page = hasMore ? Array(rows.prefix(limit)) : rows
        return (page, hasMore ? page.last.map(cursor) : nil)
    }
}
