import Foundation
import IBUgramKit

enum MessageFixtures {
    static let now = Date(timeIntervalSince1970: 1_779_638_400)

    static let inboxID = UUID(uuidString: "77777777-7777-4777-8777-777777777701") ?? UUID()
    static let requestID = UUID(uuidString: "77777777-7777-4777-8777-777777777702") ?? UUID()
    static let emptyThreadID = UUID(uuidString: "77777777-7777-4777-8777-777777777703") ?? UUID()

    static let viewer = ProfileFixtures.currentUser
    static let peer = ProfileFixtures.followedStudent
    static let requester = ProfileFixtures.unfollowedFaculty

    static let photo = ProfileFixtures.campusLawn

    static let inboxLastMessage = message(
        id: "88888888-8888-4888-8888-888888888801",
        conversationID: inboxID,
        sender: peer,
        body: "Are you going to demo night?",
        createdAt: now.addingTimeInterval(-12 * 60)
    )

    static let inboxEarlier = message(
        id: "88888888-8888-4888-8888-888888888802",
        conversationID: inboxID,
        sender: viewer,
        body: "Working on the line follower now.",
        createdAt: now.addingTimeInterval(-40 * 60)
    )

    static let inboxPhoto = message(
        id: "88888888-8888-4888-8888-888888888803",
        conversationID: inboxID,
        sender: peer,
        body: nil,
        media: [photo],
        createdAt: now.addingTimeInterval(-55 * 60)
    )

    static let requestMessage = message(
        id: "88888888-8888-4888-8888-888888888804",
        conversationID: requestID,
        sender: requester,
        body: "Could you send the lab notes from Thursday?",
        createdAt: now.addingTimeInterval(-3 * 60 * 60)
    )

    static let inboxConversation = Conversation(
        id: inboxID,
        kind: .direct,
        title: nil,
        avatarUrl: nil,
        participants: [viewer, peer],
        lastMessage: inboxLastMessage,
        unreadCount: 2,
        isRequest: false,
        updatedAt: inboxLastMessage.createdAt
    )

    static let requestConversation = Conversation(
        id: requestID,
        kind: .direct,
        title: nil,
        avatarUrl: nil,
        participants: [viewer, requester],
        lastMessage: requestMessage,
        unreadCount: 1,
        isRequest: true,
        updatedAt: requestMessage.createdAt
    )

    static let emptyConversation = Conversation(
        id: emptyThreadID,
        kind: .direct,
        title: nil,
        participants: [viewer, peer],
        unreadCount: 0,
        isRequest: false,
        updatedAt: now
    )

    static let inboxMessages = [inboxLastMessage, inboxEarlier, inboxPhoto]
    static let requestMessages = [requestMessage]

    static var inboxPage: Paginated<Conversation> { Paginated(items: [inboxConversation]) }
    static var requestsPage: Paginated<Conversation> { Paginated(items: [requestConversation]) }
    static var emptyPage: Paginated<Conversation> { Paginated(items: []) }
    static var inboxMessagePage: Paginated<Message> { Paginated(items: inboxMessages) }
    static var emptyMessagePage: Paginated<Message> { Paginated(items: []) }

    static var inboxStubs: [String: any Sendable] {
        [
            "GET /users/me": viewer,
            "GET /conversations": inboxPage,
            "GET /conversations/\(inboxID.uuidString)/messages": inboxMessagePage,
            "POST /conversations/\(inboxID.uuidString)/read": UnreadCount(count: 0),
            "GET /search": SearchResults(users: [peer, requester]),
            "GET /users/suggested": Paginated(items: [peer, requester]),
            "POST /conversations": inboxConversation
        ]
    }

    static var requestStubs: [String: any Sendable] {
        [
            "GET /users/me": viewer,
            "GET /conversations": requestsPage,
            "GET /conversations/\(requestID.uuidString)/messages": Paginated(items: requestMessages),
            "POST /conversations/\(requestID.uuidString)/accept": acceptedRequest,
            "POST /conversations/\(requestID.uuidString)/read": UnreadCount(count: 0)
        ]
    }

    static var emptyStubs: [String: any Sendable] {
        [
            "GET /users/me": viewer,
            "GET /conversations": emptyPage,
            "GET /search": SearchResults(users: [peer]),
            "GET /users/suggested": Paginated(items: [peer])
        ]
    }

    static var threadStubs: [String: any Sendable] {
        var stubs = inboxStubs
        stubs["GET /conversations/\(emptyThreadID.uuidString)/messages"] = emptyMessagePage
        return stubs
    }

    static var acceptedRequest: Conversation {
        var copy = requestConversation
        copy.isRequest = false
        copy.unreadCount = 0
        return copy
    }

    static func message(
        id: String,
        conversationID: UUID,
        sender: User,
        body: String?,
        media: [Media] = [],
        delivery: MessageDelivery = .sent,
        createdAt: Date
    ) -> Message {
        Message(
            id: UUID(uuidString: id) ?? UUID(),
            conversationId: conversationID,
            sender: sender,
            body: body,
            media: media,
            delivery: delivery,
            readBy: [],
            createdAt: createdAt
        )
    }
}
