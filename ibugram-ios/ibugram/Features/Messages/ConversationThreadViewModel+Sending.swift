import Foundation
import IBUgramKit

extension ConversationThreadViewModel {
    func sendDraft() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        draft = ""
        await submit(MessageOutboxDraft(clientID: UUID(), body: text, mediaIDs: [], media: []))
        await stopTyping()
    }

    func sendImage(jpeg data: Data) async {
        do {
            let media = try await api.send(MediaEndpoint.upload(jpeg: data, filename: "message.jpg"))
            await submit(
                MessageOutboxDraft(clientID: UUID(), body: nil, mediaIDs: [media.id], media: [media])
            )
        } catch {
            present(error) { [weak self] in await self?.sendImage(jpeg: data) }
        }
    }

    func retryOutbox(clientID: UUID) async {
        guard let draft = outbox[clientID] else { return }
        await submit(draft)
    }

    func submit(_ item: MessageOutboxDraft) async {
        outbox[item.clientID] = item
        lastSentClientID = item.clientID
        isSending = true
        upsert(optimisticMessage(for: item))
        defer { isSending = false }
        do {
            let sent = try await api.send(
                ConversationEndpoints.sendMessage(
                    conversationID: conversationID,
                    body: item.body,
                    mediaIDs: item.mediaIDs.isEmpty ? nil : item.mediaIDs,
                    clientID: item.clientID
                )
            )
            messages.removeAll { $0.id == item.clientID }
            outbox[item.clientID] = nil
            upsert(sent)
        } catch {
            messages.removeAll { $0.id == item.clientID }
            present(error) { [weak self] in await self?.retryOutbox(clientID: item.clientID) }
        }
    }

    func optimisticMessage(for item: MessageOutboxDraft) -> Message {
        Message(
            id: item.clientID,
            conversationId: conversationID,
            sender: currentUser,
            body: item.body,
            media: item.media,
            delivery: .sending,
            readBy: [],
            createdAt: Date()
        )
    }

    func upsert(_ message: Message) {
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index] = message
        } else {
            messages.append(message)
        }
    }
}
