import Foundation
import IBUgramKit

@MainActor
@Observable
final class SearchViewModel: ErrorPresenting {
    enum Phase: Equatable {
        case idle
        case searching
        case results
        case failed(APIError)
    }

    var query = "" {
        didSet { scheduleSearch() }
    }
    private(set) var scope: SearchScope = .all
    private(set) var phase: Phase = .idle
    private(set) var results = SearchResults()
    private(set) var trending: [Hashtag] = []
    private(set) var suggested: [User] = []
    var presentedError: PresentedError?

    let recents: RecentSearchStore
    private let api: any APIRequesting
    private let debounce: Duration
    private var pendingSearch: Task<Void, Never>?
    private var generation = 0

    init(
        api: any APIRequesting,
        recents: RecentSearchStore = RecentSearchStore(),
        debounce: Duration = .milliseconds(300)
    ) {
        self.api = api
        self.recents = recents
        self.debounce = debounce
    }

    var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isIdle: Bool { trimmedQuery.isEmpty }

    var showsEmptyResults: Bool {
        phase == .results && results.isEmpty
    }

    func loadIdleContent() async {
        async let trendingPage = api.send(SearchEndpoints.Trending())
        async let suggestedPage = api.send(UserEndpoints.Suggested())
        trending = (try? await trendingPage)?.items ?? []
        suggested = (try? await suggestedPage)?.items ?? []
    }

    func selectScope(_ scope: SearchScope) async {
        self.scope = scope
        pendingSearch?.cancel()
        await performSearch()
    }

    func cancel() {
        pendingSearch?.cancel()
        query = ""
        results = SearchResults()
        phase = .idle
    }

    func submitCurrentQuery() {
        let value = trimmedQuery
        guard !value.isEmpty else { return }
        recents.record(value)
    }

    func applyRecent(_ value: String) async {
        query = value
        pendingSearch?.cancel()
        await performSearch()
    }

    func flushPendingSearch() async {
        pendingSearch?.cancel()
        await performSearch()
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
            results = SearchResults()
            phase = .idle
            return
        }
        phase = .searching
        do {
            let page = try await api.send(SearchEndpoints.Query(q: value, type: scope))
            guard generation == token else { return }
            results = page
            phase = .results
        } catch is CancellationError {
            return
        } catch {
            guard generation == token else { return }
            phase = .failed(error.asAPIError)
        }
    }
}

@MainActor
@Observable
final class RecentSearchStore {
    private(set) var items: [String]
    private let key = "ibugram.recentSearches"
    private let defaults: UserDefaults
    private let limit = 10

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        items = defaults.stringArray(forKey: key) ?? []
    }

    func record(_ query: String) {
        let value = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        items.removeAll { $0.caseInsensitiveCompare(value) == .orderedSame }
        items.insert(value, at: 0)
        if items.count > limit { items = Array(items.prefix(limit)) }
        persist()
    }

    func remove(_ query: String) {
        items.removeAll { $0 == query }
        persist()
    }

    func clear() {
        items = []
        persist()
    }

    private func persist() {
        defaults.set(items, forKey: key)
    }
}
