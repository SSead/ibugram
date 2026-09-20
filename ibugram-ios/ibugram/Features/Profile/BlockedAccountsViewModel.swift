import Foundation

@MainActor
@Observable
final class BlockedAccountsViewModel: ErrorPresenting {
    private(set) var users: [User] = []
    private(set) var phase: Paginated<User>.Phase = .idle
    var presentedError: PresentedError?

    private let api: any APIRequesting
    private let cache: BlockedAccountsStore

    init(api: any APIRequesting, cache: BlockedAccountsStore = BlockedAccountsStore()) {
        self.api = api
        self.cache = cache
    }

    func load() async {
        phase = .loading
        do {
            let page = try await api.send(UserEndpoints.Blocked())
            users = page.items
            page.items.forEach(cache.register)
            phase = .loaded
        } catch {
            users = cache.load()
            phase = .loaded
        }
    }

    func unblock(_ user: User) async {
        let previous = users
        users.removeAll { $0.id == user.id }
        cache.remove(user.id)
        do {
            _ = try await api.send(UserEndpoints.Unblock(userID: user.id))
        } catch {
            users = previous
            cache.register(user)
            present(error) { [weak self] in await self?.unblock(user) }
        }
    }
}
