import Foundation
import IBUgramKit

enum ProfileContentTab: String, CaseIterable, Identifiable, Sendable {
    case posts
    case saved
    case tagged

    var id: String { rawValue }

    var title: String {
        switch self {
        case .posts: "Posts"
        case .saved: "Saved"
        case .tagged: "Tagged"
        }
    }

    var systemImage: String {
        switch self {
        case .posts: "square.grid.3x3"
        case .saved: "bookmark"
        case .tagged: "person.crop.rectangle"
        }
    }
}

@MainActor
@Observable
final class ProfileViewModel: ErrorPresenting {
    enum Phase: Equatable {
        case loading
        case loaded
        case failed(APIError)
    }

    private(set) var phase: Phase = .loading
    private(set) var user: User?
    private(set) var selectedTab: ProfileContentTab = .posts
    var presentedError: PresentedError?

    let posts: PagedList<Post>
    let saved: PagedList<Post>
    let tagged: PagedList<Post>

    private let api: any APIRequesting
    private let username: String
    private let blockedAccounts: BlockedAccountsStore
    private(set) var currentUser: User?

    init(
        api: any APIRequesting,
        username: String,
        currentUser: User?,
        blockedAccounts: BlockedAccountsStore = BlockedAccountsStore(),
        initialTab: ProfileContentTab = .posts
    ) {
        self.api = api
        self.username = username
        self.currentUser = currentUser
        self.blockedAccounts = blockedAccounts
        selectedTab = initialTab
        posts = PagedList { cursor in
            try await api.send(UserEndpoints.Posts(username: username, cursor: cursor))
        }
        saved = PagedList { cursor in
            try await api.send(UserEndpoints.Saved(cursor: cursor))
        }
        tagged = PagedList { cursor in
            do {
                return try await api.send(UserEndpoints.Tagged(username: username, cursor: cursor))
            } catch {
                let apiError = error.asAPIError
                if apiError == .notFound { return Paginated(items: []) }
                if case .server(let status, _, _) = apiError, status == 501 {
                    return Paginated(items: [])
                }
                throw error
            }
        }
    }

    var isOwnProfile: Bool {
        guard let currentUser else { return false }
        if let user { return user.id == currentUser.id }
        return currentUser.username.caseInsensitiveCompare(username) == .orderedSame
    }

    var showsSavedTab: Bool { isOwnProfile }

    var visibleTabs: [ProfileContentTab] {
        showsSavedTab ? ProfileContentTab.allCases : [.posts, .tagged]
    }

    func load() async {
        phase = .loading
        do {
            user = try await api.send(UserEndpoint.profile(username: username))
            phase = .loaded
            await reloadSelectedGrid()
        } catch {
            phase = .failed(error.asAPIError)
        }
    }

    func reload() async {
        do {
            user = try await api.send(UserEndpoint.profile(username: username))
            phase = .loaded
            await grid(for: selectedTab).reload()
        } catch {
            present(error) { [weak self] in await self?.reload() }
        }
    }

    func selectTab(_ tab: ProfileContentTab) async {
        selectedTab = tab
        await reloadSelectedGrid()
    }

    func applyEditedProfile(_ updated: User) {
        user = updated
        currentUser = updated
    }

    func toggleFollow() async {
        guard let current = user, !isOwnProfile else { return }
        let next = !(current.viewer?.isFollowing ?? false)
        user = current.withFollowState(isFollowing: next)
        do {
            if next {
                _ = try await api.send(UserEndpoints.Follow(userID: current.id))
            } else {
                _ = try await api.send(UserEndpoints.Unfollow(userID: current.id))
            }
        } catch {
            user = current
            present(error) { [weak self] in await self?.toggleFollow() }
        }
    }

    func toggleBlock() async {
        guard let current = user, !isOwnProfile else { return }
        let next = !(current.viewer?.isBlocked ?? false)
        do {
            if next {
                _ = try await api.send(UserEndpoints.Block(userID: current.id))
                blockedAccounts.register(current.withBlocked(true))
            } else {
                _ = try await api.send(UserEndpoints.Unblock(userID: current.id))
                blockedAccounts.remove(current.id)
            }
            user = current.withBlocked(next)
        } catch {
            present(error) { [weak self] in await self?.toggleBlock() }
        }
    }

    func report(reason: ReportReason) async {
        guard let current = user else { return }
        do {
            _ = try await api.send(
                UserEndpoints.Report(subject: .user, subjectID: current.id, reason: reason)
            )
        } catch {
            present(error) { [weak self] in await self?.report(reason: reason) }
        }
    }

    func grid(for tab: ProfileContentTab) -> PagedList<Post> {
        switch tab {
        case .posts: posts
        case .saved: saved
        case .tagged: tagged
        }
    }

    private func reloadSelectedGrid() async {
        await grid(for: selectedTab).loadFirstPageIfNeeded()
    }
}
