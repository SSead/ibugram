import Foundation
import IBUgramKit

struct MessageOutboxDraft: Sendable, Hashable, Identifiable {
    var id: UUID { clientID }
    let clientID: UUID
    let body: String?
    let mediaIDs: [UUID]
    let media: [Media]
}

@MainActor
@Observable
final class ConversationThreadViewModel: ErrorPresenting {
    var draft = ""
    var presentedError: PresentedError?

    var conversation: Conversation?
    var messages: [Message] = []
    private(set) var phase: Phase = .loading
    private(set) var isLoadingOlder = false
    var typingUserIDs: Set<UUID> = []
    var presenceByUserID: [UUID: PresenceChangedPayload] = [:]
    var outbox: [UUID: MessageOutboxDraft] = [:]
    var lastSentClientID: UUID?
    var isSending = false
    private(set) var isAccepting = false

    let api: any APIRequesting
    let realtime: WebSocketClient
    let conversationID: UUID
    let currentUser: User
    var typingStopTask: Task<Void, Never>?
    var isMarkingRead = false

    private var nextCursor: String?
    private var hasReachedEnd = false

    enum Phase: Equatable {
        case loading
        case loaded
        case failed(APIError)
    }

    init(
        api: any APIRequesting,
        realtime: WebSocketClient,
        conversationID: UUID,
        currentUser: User,
        conversation: Conversation? = nil
    ) {
        self.api = api
        self.realtime = realtime
        self.conversationID = conversationID
        self.currentUser = currentUser
        self.conversation = conversation
    }

    var chronological: [Message] {
        messages.sorted { lhs, rhs in
            if lhs.createdAt == rhs.createdAt { return lhs.id.uuidString < rhs.id.uuidString }
            return lhs.createdAt < rhs.createdAt
        }
    }

    var isInitialLoading: Bool { phase == .loading && messages.isEmpty }
    var isEmpty: Bool { messages.isEmpty && phase == .loaded && outbox.isEmpty }
    var isRequest: Bool { conversation?.isRequest == true }
    var title: String {
        if let conversation {
            return ConversationPresentation.title(for: conversation, currentUserID: currentUser.id)
        }
        return peerFromMessages?.displayName ?? "Chat"
    }

    var typingLabel: String? {
        let names = typingUserIDs.compactMap { id in
            conversation?.participants.first { $0.id == id }?.displayName
                ?? messages.first { $0.sender.id == id }?.sender.displayName
        }
        guard let name = names.first else { return nil }
        return names.count == 1 ? "\(name) is typing…" : "Several people are typing…"
    }

    var peerPresenceLabel: String? {
        guard let peer = conversation.flatMap({ ConversationPresentation.peer(in: $0, currentUserID: currentUser.id) }),
              let presence = presenceByUserID[peer.id]
        else { return nil }
        return ConversationPresentation.presenceLabel(isOnline: presence.isOnline, lastSeenAt: presence.lastSeenAt)
    }

    func load() async {
        if messages.isEmpty { phase = .loading }
        async let history = api.send(ConversationEndpoints.messages(conversationID: conversationID))
        async let inbox = api.send(ConversationEndpoints.list(filter: .inbox))
        async let requests = api.send(ConversationEndpoints.list(filter: .requests))
        do {
            let page = try await history
            messages = page.items
            nextCursor = page.nextCursor
            hasReachedEnd = page.nextCursor == nil
            let inboxItems = (try? await inbox)?.items ?? []
            let requestItems = (try? await requests)?.items ?? []
            conversation = (inboxItems + requestItems).first { $0.id == conversationID } ?? conversation
            phase = .loaded
            await markVisibleAsRead()
        } catch {
            phase = .failed(error.asAPIError)
        }
    }

    func loadOlderMessages() async {
        guard !isLoadingOlder, !hasReachedEnd, let cursor = nextCursor else { return }
        isLoadingOlder = true
        defer { isLoadingOlder = false }
        do {
            let page = try await api.send(ConversationEndpoints.messages(conversationID: conversationID, cursor: cursor))
            let known = Set(messages.map(\.id))
            messages.append(contentsOf: page.items.filter { !known.contains($0.id) })
            nextCursor = page.nextCursor
            hasReachedEnd = page.nextCursor == nil
        } catch {
            hasReachedEnd = false
        }
    }

    func acceptRequest() async {
        isAccepting = true
        defer { isAccepting = false }
        do {
            conversation = try await api.send(ConversationEndpoints.accept(conversationID: conversationID))
        } catch {
            present(error) { [weak self] in await self?.acceptRequest() }
        }
    }

    func isFromCurrentUser(_ message: Message) -> Bool {
        message.sender.id == currentUser.id
    }

    private var peerFromMessages: User? {
        messages.first { $0.sender.id != currentUser.id }?.sender
    }
}
