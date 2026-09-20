import Foundation
import IBUgramKit

@MainActor
@Observable
final class NewConversationViewModel: ErrorPresenting {
    var query = "" {
        didSet { scheduleSearch() }
    }
    var presentedError: PresentedError?

    private(set) var phase: Phase = .idle
    private(set) var people: [User] = []
    private(set) var suggested: [User] = []
    private(set) var isCreating = false
    private(set) var openedConversation: Conversation?

    private let api: any APIRequesting
    private let currentUserID: UUID
    private let debounce: Duration
    private var pendingSearch: Task<Void, Never>?
    private var generation = 0

    enum Phase: Equatable {
        case idle
        case searching
        case results
        case failed(APIError)
    }

    init(
        api: any APIRequesting,
        currentUserID: UUID,
        debounce: Duration = .milliseconds(300)
    ) {
        self.api = api
        self.currentUserID = currentUserID
        self.debounce = debounce
    }

    var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isIdle: Bool { trimmedQuery.isEmpty }
    var showsEmptyResults: Bool { phase == .results && people.isEmpty }

    func loadSuggested() async {
        suggested = (try? await api.send(UserEndpoints.Suggested()))?.items
            .filter { $0.id != currentUserID } ?? []
    }

    func flushPendingSearch() async {
        pendingSearch?.cancel()
        await performSearch()
    }

    func openConversation(with user: User) async {
        guard !isCreating else { return }
        isCreating = true
        defer { isCreating = false }
        do {
            openedConversation = try await api.send(
                ConversationEndpoints.create(participantIDs: [user.id])
            )
        } catch {
            present(error) { [weak self] in await self?.openConversation(with: user) }
        }
    }

    private func scheduleSearch() {
        pendingSearch?.cancel()
        generation += 1
        let token = generation
        let delay = debounce
        pendingSearch = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard let self, !Task.isCancelled, self.generation == token else { return }
            await self.performSearch()
        }
    }

    private func performSearch() async {
        generation += 1
        let token = generation
        let value = trimmedQuery
        guard !value.isEmpty else {
            people = []
            phase = .idle
            return
        }
        phase = .searching
        do {
            let results = try await api.send(SearchEndpoints.Query(q: value, type: .users))
            guard generation == token else { return }
            people = results.users.filter { $0.id != currentUserID }
            phase = .results
        } catch is CancellationError {
            return
        } catch {
            guard generation == token else { return }
            phase = .failed(error.asAPIError)
        }
    }
}
