import Foundation

@MainActor
final class BlockedAccountsStore {
    private let key = "ibugram.blockedAccounts"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func register(_ user: User) {
        var users = load()
        users.removeAll { $0.id == user.id }
        users.insert(user, at: 0)
        save(users)
    }

    func remove(_ id: UUID) {
        save(load().filter { $0.id != id })
    }

    func load() -> [User] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder.ibugram.decode([User].self, from: data)) ?? []
    }

    private func save(_ users: [User]) {
        defaults.set(try? JSONEncoder.ibugram.encode(users), forKey: key)
    }
}
