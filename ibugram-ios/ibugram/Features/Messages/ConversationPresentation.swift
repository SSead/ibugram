import Foundation
import IBUgramKit

enum ConversationPresentation {
    static func title(for conversation: Conversation, currentUserID: UUID) -> String {
        if let title = conversation.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty {
            return title
        }
        let others = conversation.participants.filter { $0.id != currentUserID }
        if others.isEmpty { return "Conversation" }
        return others.map(\.displayName).joined(separator: ", ")
    }

    static func peer(in conversation: Conversation, currentUserID: UUID) -> User? {
        conversation.participants.first { $0.id != currentUserID } ?? conversation.participants.first
    }

    static func preview(for conversation: Conversation) -> String {
        guard let last = conversation.lastMessage else { return "No messages yet" }
        if let body = last.body?.trimmingCharacters(in: .whitespacesAndNewlines), !body.isEmpty {
            return body
        }
        if !last.media.isEmpty { return "Photo" }
        return "No messages yet"
    }

    static func presenceLabel(isOnline: Bool, lastSeenAt: Date?) -> String {
        if isOnline { return "Active now" }
        guard let lastSeenAt else { return "Offline" }
        return "Active \(RelativeTimestamp.abbreviated(from: lastSeenAt))"
    }
}
