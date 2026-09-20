import Foundation

@MainActor
@Observable
final class FollowListViewModel: ErrorPresenting {
    enum Kind: String, Sendable {
        case followers
        case following

        var title: String {
            switch self {
            case .followers: "Followers"
            case .following: "Following"
            }
        }
    }

    let people: Paginated<User>
    var presentedError: PresentedError?
    private(set) var followOverrides: [UUID: Bool] = [:]

    private let api: any APIRequesting
    let kind: Kind
    let currentUserID: UUID?

    init(api: any APIRequesting, username: String, kind: Kind, currentUserID: UUID?) {
        self.api = api
        self.kind = kind
        self.currentUserID = currentUserID
        switch kind {
        case .followers:
            people = Paginated { cursor in
                try await api.send(UserEndpoint.followers(of: username, cursor: cursor))
            }
        case .following:
            people = Paginated { cursor in
                try await api.send(UserEndpoints.Following(username: username, cursor: cursor))
            }
        }
    }

    func load() async {
        await people.loadFirstPageIfNeeded()
    }

    func reload() async {
        await people.reload()
    }

    func isFollowing(_ user: User) -> Bool {
        followOverrides[user.id] ?? user.viewer?.isFollowing ?? false
    }

    func isCurrentUser(_ user: User) -> Bool {
        user.id == currentUserID
    }

    func toggleFollow(_ user: User) async {
        guard !isCurrentUser(user) else { return }
        let previous = isFollowing(user)
        followOverrides[user.id] = !previous
        do {
            if previous {
                _ = try await api.send(UserEndpoints.Unfollow(userID: user.id))
            } else {
                _ = try await api.send(UserEndpoints.Follow(userID: user.id))
            }
        } catch {
            followOverrides[user.id] = previous
            present(error) { [weak self] in await self?.toggleFollow(user) }
        }
    }
}
