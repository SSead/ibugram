import Foundation
import IBUgramKit

@MainActor
@Observable
final class ConversationListViewModel: ErrorPresenting {
    var selectedFilter: ConversationFilter
    var presentedError: PresentedError?

    private(set) var conversations: [Conversation] = []
    private(set) var phase: Phase = .loading
    private(set) var isLoadingMore = false
    private(set) var presenceByUserID: [UUID: PresenceChangedPayload] = [:]
    private(set) var inboxUnreadTotal = 0

    let currentUserID: UUID

    private let api: any APIRequesting
    private let realtime: WebSocketClient
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
        currentUserID: UUID,
        filter: ConversationFilter = .inbox
    ) {
        self.api = api
        self.realtime = realtime
        self.currentUserID = currentUserID
        self.selectedFilter = filter
    }

    var isEmpty: Bool { conversations.isEmpty && phase == .loaded }
    var isInitialLoading: Bool { phase == .loading && conversations.isEmpty }

    func load() async {
        if conversations.isEmpty { phase = .loading }
        await reload()
    }

    func reload() async {
        do {
            let page = try await api.send(ConversationEndpoints.list(filter: selectedFilter))
            conversations = page.items
            nextCursor = page.nextCursor
            hasReachedEnd = page.nextCursor == nil
            phase = .loaded
        } catch {
            if conversations.isEmpty {
                phase = .failed(error.asAPIError)
            } else {
                present(error) { [weak self] in await self?.reload() }
            }
        }
    }

    func selectFilter(_ filter: ConversationFilter) async {
        guard filter != selectedFilter else { return }
        selectedFilter = filter
        conversations = []
        nextCursor = nil
        hasReachedEnd = false
        phase = .loading
        await reload()
    }

    func loadNextPage() async {
        guard !isLoadingMore, !hasReachedEnd, let cursor = nextCursor else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let page = try await api.send(ConversationEndpoints.list(filter: selectedFilter, cursor: cursor))
            let known = Set(conversations.map(\.id))
            conversations.append(contentsOf: page.items.filter { !known.contains($0.id) })
            nextCursor = page.nextCursor
            hasReachedEnd = page.nextCursor == nil
        } catch {
            hasReachedEnd = false
        }
    }

    func accept(_ conversation: Conversation) async {
        do {
            _ = try await api.send(ConversationEndpoints.accept(conversationID: conversation.id))
            conversations.removeAll { $0.id == conversation.id }
        } catch {
            present(error) { [weak self] in await self?.accept(conversation) }
        }
    }

    func listenForRealtime() async {
        for await frame in await realtime.events() {
            ingest(frame)
        }
    }

    func ingest(_ frame: ServerMessage) {
        switch frame {
        case .messageCreated(let payload):
            applyMessageCreated(payload.message)
        case .messageRead(let payload):
            applyMessageRead(payload)
        case .presenceChanged(let payload):
            presenceByUserID[payload.userId] = payload
        case .unreadCountChanged(let payload):
            inboxUnreadTotal = max(payload.conversations, 0)
        default:
            break
        }
    }

    func isOnline(in conversation: Conversation) -> Bool {
        guard let peer = ConversationPresentation.peer(in: conversation, currentUserID: currentUserID) else {
            return false
        }
        return presenceByUserID[peer.id]?.isOnline == true
    }

    func title(for conversation: Conversation) -> String {
        ConversationPresentation.title(for: conversation, currentUserID: currentUserID)
    }

    private func applyMessageCreated(_ message: Message) {
        guard let index = conversations.firstIndex(where: { $0.id == message.conversationId }) else { return }
        var updated = conversations.remove(at: index)
        updated.lastMessage = message
        updated.updatedAt = message.createdAt
        if message.sender.id != currentUserID {
            updated.unreadCount += 1
        }
        conversations.insert(updated, at: 0)
    }

    private func applyMessageRead(_ payload: MessageReadPayload) {
        guard payload.userId == currentUserID,
              let index = conversations.firstIndex(where: { $0.id == payload.conversationId })
        else { return }
        conversations[index].unreadCount = 0
    }
}
