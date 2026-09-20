import Foundation
import IBUgramKit

enum ConversationEndpoints {
    struct List: Endpoint {
        typealias Response = Paginated<Conversation>

        var filter: ConversationFilter = .inbox
        var cursor: String?
        var limit: Int = 20

        var path: String { "/conversations" }
        var queryItems: [URLQueryItem] {
            var items = [
                URLQueryItem(name: "filter", value: filter.rawValue),
                URLQueryItem(name: "limit", value: String(limit))
            ]
            if let cursor { items.append(URLQueryItem(name: "cursor", value: cursor)) }
            return items
        }
    }

    struct Create: Endpoint {
        typealias Response = Conversation

        let participantIDs: [UUID]
        var title: String?

        var method: HTTPMethod { .post }
        var path: String { "/conversations" }
        var body: HTTPBody? {
            .json(CreateConversationBody(participantIds: participantIDs, title: title))
        }
    }

    struct Messages: Endpoint {
        typealias Response = Paginated<Message>

        let conversationID: UUID
        var cursor: String?
        var limit: Int = 20

        var path: String { "/conversations/\(conversationID.uuidString)/messages" }
        var queryItems: [URLQueryItem] {
            var items = [URLQueryItem(name: "limit", value: String(limit))]
            if let cursor { items.append(URLQueryItem(name: "cursor", value: cursor)) }
            return items
        }
    }

    struct SendMessage: Endpoint {
        typealias Response = Message

        let conversationID: UUID
        let bodyText: String?
        let mediaIDs: [UUID]?
        let clientID: UUID

        var method: HTTPMethod { .post }
        var path: String { "/conversations/\(conversationID.uuidString)/messages" }
        var body: HTTPBody? {
            .json(CreateMessageBody(body: bodyText, mediaIds: mediaIDs, clientId: clientID))
        }
    }

    struct MarkRead: Endpoint {
        typealias Response = UnreadCount

        let conversationID: UUID
        let upToMessageID: UUID

        var method: HTTPMethod { .post }
        var path: String { "/conversations/\(conversationID.uuidString)/read" }
        var body: HTTPBody? { .json(MarkConversationReadBody(upToMessageId: upToMessageID)) }
    }

    struct Accept: Endpoint {
        typealias Response = Conversation

        let conversationID: UUID

        var method: HTTPMethod { .post }
        var path: String { "/conversations/\(conversationID.uuidString)/accept" }
    }

    static func list(filter: ConversationFilter, cursor: String? = nil) -> List {
        List(filter: filter, cursor: cursor)
    }

    static func create(participantIDs: [UUID], title: String? = nil) -> Create {
        Create(participantIDs: participantIDs, title: title)
    }

    static func messages(conversationID: UUID, cursor: String? = nil) -> Messages {
        Messages(conversationID: conversationID, cursor: cursor)
    }

    static func sendMessage(
        conversationID: UUID,
        body: String? = nil,
        mediaIDs: [UUID]? = nil,
        clientID: UUID = UUID()
    ) -> SendMessage {
        SendMessage(conversationID: conversationID, bodyText: body, mediaIDs: mediaIDs, clientID: clientID)
    }

    static func markRead(conversationID: UUID, upToMessageID: UUID) -> MarkRead {
        MarkRead(conversationID: conversationID, upToMessageID: upToMessageID)
    }

    static func accept(conversationID: UUID) -> Accept {
        Accept(conversationID: conversationID)
    }
}
