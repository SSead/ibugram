import Foundation
import Testing
@testable import ibugram
import IBUgramKit

@Suite("Search debounce and scopes")
@MainActor
struct SearchViewModelTests {
    private func isolatedRecents() -> RecentSearchStore {
        let suite = "ibugram.tests.recents.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        return RecentSearchStore(defaults: defaults)
    }

    @Test("rapid query edits only search the latest value when the debounce is flushed")
    func debounceKeepsTheLatestQuery() async {
        let client = ScriptedAPIClient(stubs: [
            "GET /search": SearchFixtures.mixedResults
        ])
        let viewModel = SearchViewModel(
            api: client,
            recents: isolatedRecents(),
            debounce: .seconds(30)
        )

        viewModel.query = "a"
        viewModel.query = "am"
        viewModel.query = "amina"
        await viewModel.flushPendingSearch()

        let calls = await client.recordedCalls()
        #expect(calls.filter { $0 == "GET /search" }.count == 1)
        #expect(await client.queryValue("q") == "amina")
        #expect(await client.queryValue("type") == SearchScope.all.rawValue)
        #expect(viewModel.phase == .results)
    }

    @Test("changing scope searches immediately with the selected type")
    func scopeSwitchPassesType() async {
        let client = ScriptedAPIClient(stubs: [
            "GET /search": SearchFixtures.peopleResults
        ])
        let viewModel = SearchViewModel(
            api: client,
            recents: isolatedRecents(),
            debounce: .seconds(30)
        )
        viewModel.query = "leila"
        await viewModel.flushPendingSearch()
        await viewModel.selectScope(.users)

        #expect(await client.queryValue("type") == SearchScope.users.rawValue)
        #expect(await client.queryValue("q") == "leila")
        let calls = await client.recordedCalls()
        #expect(calls.filter { $0 == "GET /search" }.count == 2)
        #expect(viewModel.scope == .users)
    }

    @Test("cancel restores the idle state without leaving a query")
    func cancelRestoresIdle() async {
        let client = ScriptedAPIClient(stubs: [
            "GET /search": SearchFixtures.mixedResults,
            "GET /search/trending": Paginated(items: SearchFixtures.trending),
            "GET /users/suggested": Paginated(items: [ProfileFixtures.followedStudent])
        ])
        let viewModel = SearchViewModel(
            api: client,
            recents: isolatedRecents(),
            debounce: .seconds(30)
        )
        await viewModel.loadIdleContent()
        viewModel.query = "robotics"
        await viewModel.flushPendingSearch()
        #expect(viewModel.phase == .results)

        viewModel.cancel()

        #expect(viewModel.isIdle)
        #expect(viewModel.phase == .idle)
        #expect(viewModel.trending.isEmpty == false)
    }
}
