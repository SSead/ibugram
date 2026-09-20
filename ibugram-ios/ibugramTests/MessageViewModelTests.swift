import Foundation
import Testing
@testable import ibugram
import IBUgramKit

@Suite("Conversation mailbox")
@MainActor
struct MessageInboxTests {
    @Test("inbox and requests load through the filter query parameter")
    func requestFilterIsSeparateFromInbox() async {
        let api = MessageScriptedAPIClient()
        let viewModel = ConversationListViewModel(
            api: api,
            realtime: previewRealtime(),
            currentUserID: MessageFixtures.viewer.id
        )

        await viewModel.load()

        #expect(await api.recordedFilters() == ["inbox"])
        #expect(viewModel.conversations.map(\.id) == [MessageFixtures.inboxID])
        #expect(viewModel.conversations.first?.isRequest == false)

        await viewModel.selectFilter(.requests)

        #expect(await api.recordedFilters() == ["inbox", "requests"])
        #expect(viewModel.conversations.map(\.id) == [MessageFixtures.requestID])
        #expect(viewModel.conversations.first?.isRequest == true)
    }

    @Test("accepting a request removes it from the requests mailbox")
    func acceptRemovesRequest() async {
        let api = MessageScriptedAPIClient()
        let viewModel = ConversationListViewModel(
            api: api,
            realtime: previewRealtime(),
            currentUserID: MessageFixtures.viewer.id,
            filter: .requests
        )
        await viewModel.load()
        await viewModel.accept(MessageFixtures.requestConversation)

        #expect(viewModel.conversations.isEmpty)
        #expect(await api.recordedCalls().contains("POST /conversations/\(MessageFixtures.requestID.uuidString)/accept"))
    }
}

@Suite("Message send")
@MainActor
struct MessageSendTests {
    @Test("a failed send rolls back the optimistic message and retries with the same client_id")
    func optimisticRollbackThenIdempotentRetry() async {
        let api = MessageScriptedAPIClient()
        await api.failSend(.offline)
        let viewModel = ConversationThreadViewModel(
            api: api,
            realtime: previewRealtime(),
            conversationID: MessageFixtures.inboxID,
            currentUser: MessageFixtures.viewer,
            conversation: MessageFixtures.inboxConversation
        )
        await viewModel.load()
        viewModel.draft = "Hello from campus"
        await viewModel.sendDraft()

        #expect(viewModel.chronological.contains { $0.body == "Hello from campus" } == false)
        #expect(viewModel.outbox.count == 1)
        let clientID = viewModel.lastSentClientID
        #expect(clientID != nil)
        #expect(viewModel.presentedError != nil)

        await api.clearSendFailure()
        await viewModel.retryOutbox(clientID: clientID ?? UUID())

        let clientIDs = await api.recordedClientIDs()
        #expect(clientIDs.count == 2)
        #expect(clientIDs.first == clientIDs.last)
        #expect(clientIDs.first == clientID)
        #expect(viewModel.chronological.contains { $0.body == "Hello from campus" && $0.delivery == .sent })
        #expect(viewModel.outbox.isEmpty)
    }

    @Test("two sends with the same client_id from the outbox do not keep a duplicate bubble")
    func clientIDRetryReplacesTheOptimisticRow() async {
        let api = MessageScriptedAPIClient()
        let viewModel = ConversationThreadViewModel(
            api: api,
            realtime: previewRealtime(),
            conversationID: MessageFixtures.inboxID,
            currentUser: MessageFixtures.viewer,
            conversation: MessageFixtures.inboxConversation
        )
        await viewModel.load()
        viewModel.draft = "One"
        await viewModel.sendDraft()

        let clientID = await api.recordedClientIDs().last
        #expect(viewModel.chronological.filter { $0.body == "One" }.count == 1)
        #expect(viewModel.chronological.contains { $0.id == clientID } == false)
    }
}

private func previewRealtime() -> WebSocketClient {
    WebSocketClient(configuration: .preview, tokenStore: InMemoryTokenStore())
}

actor MessageScriptedAPIClient: APIRequesting {
    private var sendError: ibugram.APIError?
    private var calls: [String] = []
    private var filters: [String] = []
    private var clientIDs: [UUID] = []

    func failSend(_ error: ibugram.APIError) {
        sendError = error
    }

    func clearSendFailure() {
        sendError = nil
    }

    func recordedCalls() -> [String] { calls }
    func recordedFilters() -> [String] { filters }
    func recordedClientIDs() -> [UUID] { clientIDs }

    func send<E: ibugram.Endpoint>(_ endpoint: E) async throws -> E.Response {
        let key = "\(endpoint.method.rawValue) \(endpoint.path)"
        calls.append(key)

        if let list = endpoint as? ConversationEndpoints.List {
            filters.append(list.filter.rawValue)
            let page = list.filter == .requests ? MessageFixtures.requestsPage : MessageFixtures.inboxPage
            return try typed(page, for: endpoint, key: key)
        }
        if let sendMessage = endpoint as? ConversationEndpoints.SendMessage {
            clientIDs.append(sendMessage.clientID)
            if let sendError { throw sendError }
            let message = Message(
                id: UUID(uuidString: "88888888-8888-4888-8888-888888888899") ?? UUID(),
                conversationId: sendMessage.conversationID,
                sender: MessageFixtures.viewer,
                body: sendMessage.bodyText,
                media: [],
                delivery: .sent,
                readBy: [],
                createdAt: MessageFixtures.now
            )
            return try typed(message, for: endpoint, key: key)
        }
        if endpoint is ConversationEndpoints.Accept {
            return try typed(MessageFixtures.acceptedRequest, for: endpoint, key: key)
        }
        if endpoint is ConversationEndpoints.MarkRead {
            return try typed(UnreadCount(count: 0), for: endpoint, key: key)
        }
        if endpoint is ConversationEndpoints.Messages {
            return try typed(MessageFixtures.inboxMessagePage, for: endpoint, key: key)
        }
        throw ibugram.APIError.notFound
    }

    private func typed<E: ibugram.Endpoint, Value: Sendable>(
        _ value: Value,
        for endpoint: E,
        key: String
    ) throws -> E.Response {
        guard let typed = value as? E.Response else {
            throw ibugram.APIError.decoding("stub for \(key) is \(type(of: value)), not \(E.Response.self)")
        }
        return typed
    }
}
