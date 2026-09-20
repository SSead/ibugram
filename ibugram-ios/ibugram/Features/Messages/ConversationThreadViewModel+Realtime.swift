import Foundation
import IBUgramKit

extension ConversationThreadViewModel {
    func draftDidChange(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            await stopTyping()
            return
        }
        try? await realtime.send(.typingStart(ConversationScope(conversationId: conversationID)))
        typingStopTask?.cancel()
        typingStopTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard let self, !Task.isCancelled else { return }
            await self.stopTyping()
        }
    }

    func listenForRealtime() async {
        await realtime.subscribe(toConversation: conversationID)
        defer {
            let realtime = realtime
            let conversationID = conversationID
            Task { await realtime.unsubscribe(fromConversation: conversationID) }
        }
        for await frame in await realtime.events() {
            ingest(frame)
        }
    }

    func ingest(_ frame: ServerMessage) {
        switch frame {
        case .messageCreated(let payload):
            guard payload.message.conversationId == conversationID else { return }
            upsert(payload.message)
            Task { await markVisibleAsRead() }
        case .typing(let payload):
            applyTyping(payload)
        case .messageRead(let payload):
            guard payload.conversationId == conversationID else { return }
            applyRead(payload)
        case .presenceChanged(let payload):
            presenceByUserID[payload.userId] = payload
        default:
            break
        }
    }

    func stopTyping() async {
        typingStopTask?.cancel()
        typingStopTask = nil
        try? await realtime.send(.typingStop(ConversationScope(conversationId: conversationID)))
    }

    func markVisibleAsRead() async {
        guard !isMarkingRead,
              let latest = chronological.last(where: { $0.sender.id != currentUser.id }),
              !latest.readBy.contains(currentUser.id),
              latest.delivery != .sending
        else { return }
        isMarkingRead = true
        defer { isMarkingRead = false }
        do {
            _ = try await api.send(
                ConversationEndpoints.markRead(conversationID: conversationID, upToMessageID: latest.id)
            )
            try? await realtime.send(
                .markRead(MarkReadPayload(conversationId: conversationID, upToMessageId: latest.id))
            )
            conversation?.unreadCount = 0
        } catch {
            return
        }
    }

    func applyTyping(_ payload: TypingPayload) {
        guard payload.conversationId == conversationID, payload.userId != currentUser.id else { return }
        if payload.isTyping {
            typingUserIDs.insert(payload.userId)
        } else {
            typingUserIDs.remove(payload.userId)
        }
    }

    func applyRead(_ payload: MessageReadPayload) {
        guard let cutoff = messages.first(where: { $0.id == payload.upToMessageId })?.createdAt else { return }
        for index in messages.indices where messages[index].createdAt <= cutoff {
            if !messages[index].readBy.contains(payload.userId) {
                messages[index].readBy.append(payload.userId)
            }
            if messages[index].sender.id != payload.userId {
                messages[index].delivery = .read
            }
        }
    }
}
