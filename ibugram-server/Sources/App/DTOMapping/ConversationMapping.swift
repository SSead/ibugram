import Foundation
import IBUgramKit
import Vapor

extension MessageRecord {
    func asDTO(
        sender: UserRecord,
        media: [MediaRecord],
        readBy: [UUID],
        urls: MediaURLBuilder
    ) throws -> IBUgramKit.Message {
        let readers = readBy.filter { $0 != $sender.id }
        return IBUgramKit.Message(
            id: try requireID(),
            conversationId: $conversation.id,
            sender: try sender.asDTO(urls: urls),
            body: body,
            media: try media.map { try $0.asDTO(urls: urls) },
            delivery: readers.isEmpty ? .sent : .read,
            readBy: readers,
            createdAt: createdAt ?? Date()
        )
    }
}

extension ConversationRecord {
    func asDTO(
        participants: [UserRecord],
        lastMessage: IBUgramKit.Message?,
        unreadCount: Int,
        isRequest: Bool,
        urls: MediaURLBuilder
    ) throws -> Conversation {
        Conversation(
            id: try requireID(),
            kind: kind,
            title: title,
            avatarUrl: $avatarMedia.id.map(urls.url(forMedia:)),
            participants: try participants.map { try $0.asDTO(urls: urls) },
            lastMessage: lastMessage,
            unreadCount: unreadCount,
            isRequest: isRequest,
            updatedAt: updatedAt ?? createdAt ?? Date()
        )
    }
}

extension Conversation: @retroactive AsyncRequestDecodable {}
extension Conversation: @retroactive AsyncResponseEncodable {}
extension Conversation: @retroactive Content {}

extension IBUgramKit.Message: @retroactive AsyncRequestDecodable {}
extension IBUgramKit.Message: @retroactive AsyncResponseEncodable {}
extension IBUgramKit.Message: @retroactive Content {}

extension CreateConversationBody: @retroactive AsyncRequestDecodable {}
extension CreateConversationBody: @retroactive AsyncResponseEncodable {}
extension CreateConversationBody: @retroactive Content {}

extension CreateMessageBody: @retroactive AsyncRequestDecodable {}
extension CreateMessageBody: @retroactive AsyncResponseEncodable {}
extension CreateMessageBody: @retroactive Content {}

extension MarkConversationReadBody: @retroactive AsyncRequestDecodable {}
extension MarkConversationReadBody: @retroactive AsyncResponseEncodable {}
extension MarkConversationReadBody: @retroactive Content {}

extension CreateConversationBody: @retroactive Validatable {
    public static func validations(_ validations: inout Validations) {
        // Keys are camelCase because JSONDecoder.ibugram converts snake_case on the way in.
        validations.add("participantIds", as: [UUID].self, is: !.empty)
        validations.add("title", as: String?.self, is: .nil || .count(1...80), required: false)
    }
}

extension CreateMessageBody: @retroactive Validatable {
    public static func validations(_ validations: inout Validations) {
        validations.add("body", as: String?.self, is: .nil || .count(1...4000), required: false)
    }
}
