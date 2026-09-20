import Foundation
import IBUgramKit

enum FeedKind: String, CaseIterable, Identifiable, Sendable {
    case following
    case discover

    var id: String { rawValue }

    var title: String {
        switch self {
        case .following: "Following"
        case .discover: "Discover"
        }
    }

    var emptyTitle: String {
        switch self {
        case .following: "Your feed is quiet"
        case .discover: "Nothing to discover"
        }
    }

    var emptyMessage: String {
        switch self {
        case .following: "Follow classmates and Spaces. Their posts will land here."
        case .discover: "Pull to refresh, or check back when campus is awake."
        }
    }
}

@MainActor
@Observable
final class FeedViewModel: ErrorPresenting {
    var selectedKind: FeedKind = .following
    var presentedError: PresentedError?

    private let followingFeed: PagedList<Post>
    private let discoverFeed: PagedList<Post>
    private let api: any APIRequesting
    private let happeningNowOverride: (@Sendable () -> [Event])?
    private var happeningNowItems: [Event] = []
    private var engagement: [UUID: PostEngagement] = [:]
    private var inFlightLikes: Set<UUID> = []
    private var inFlightSaves: Set<UUID> = []

    init(
        api: any APIRequesting,
        happeningNow: (@Sendable () -> [Event])? = nil
    ) {
        self.api = api
        self.happeningNowOverride = happeningNow
        self.followingFeed = PagedList { cursor in
            try await api.send(FeedEndpoint.following(cursor: cursor))
        }
        self.discoverFeed = PagedList { cursor in
            try await api.send(FeedEndpoint.discover(cursor: cursor))
        }
    }

    var phase: PagedList<Post>.Phase { feed.phase }
    var isLoadingMore: Bool { feed.isLoadingMore }
    var isEmpty: Bool { feed.isEmpty }
    var hasReachedEnd: Bool { feed.hasReachedEnd }
    var isInitialLoading: Bool { feed.phase == .loading && feed.items.isEmpty }

    var displayPosts: [Post] {
        feed.items.map(resolved)
    }

    func happeningNowEvents() -> [Event] {
        happeningNowOverride?() ?? happeningNowItems
    }

    func load() async {
        await feed.loadFirstPageIfNeeded()
        await refreshHappeningNowIfNeeded()
    }

    func reload() async {
        await feed.reload()
        await refreshHappeningNow()
        if case .failed(let error) = feed.phase, !feed.items.isEmpty {
            present(error) { [weak self] in await self?.reload() }
        }
    }

    func loadNextPage() async {
        await feed.loadNextPage()
    }

    func toggleLike(of post: Post) async {
        guard !inFlightLikes.contains(post.id) else { return }
        let current = engagementState(for: post)
        let liked = !current.hasLiked
        let likeCount = current.likeCount + (liked ? 1 : -1)
        apply(PostEngagement(hasLiked: liked, hasSaved: current.hasSaved, likeCount: likeCount), to: post.id)
        inFlightLikes.insert(post.id)
        defer { inFlightLikes.remove(post.id) }
        do {
            if liked {
                _ = try await api.send(PostEndpoint.like(postID: post.id))
            } else {
                _ = try await api.send(PostEndpoint.unlike(postID: post.id))
            }
        } catch {
            apply(current, to: post.id)
            present(error) { [weak self] in await self?.toggleLike(of: post) }
        }
    }

    func likeIfNeeded(_ post: Post) async {
        guard !engagementState(for: post).hasLiked else { return }
        await toggleLike(of: post)
    }

    func toggleSave(of post: Post) async {
        guard !inFlightSaves.contains(post.id) else { return }
        let current = engagementState(for: post)
        let saved = !current.hasSaved
        apply(PostEngagement(hasLiked: current.hasLiked, hasSaved: saved, likeCount: current.likeCount), to: post.id)
        inFlightSaves.insert(post.id)
        defer { inFlightSaves.remove(post.id) }
        do {
            if saved {
                _ = try await api.send(PostEndpoint.save(postID: post.id))
            } else {
                _ = try await api.send(PostEndpoint.unsave(postID: post.id))
            }
        } catch {
            apply(current, to: post.id)
            present(error) { [weak self] in await self?.toggleSave(of: post) }
        }
    }

    func delete(_ post: Post) async {
        do {
            _ = try await api.send(PostEndpoint.delete(postID: post.id))
            await reload()
        } catch {
            present(error) { [weak self] in await self?.delete(post) }
        }
    }

    private var feed: PagedList<Post> {
        switch selectedKind {
        case .following: followingFeed
        case .discover: discoverFeed
        }
    }

    private func refreshHappeningNowIfNeeded() async {
        guard happeningNowOverride == nil, happeningNowItems.isEmpty else { return }
        await refreshHappeningNow()
    }

    private func refreshHappeningNow() async {
        guard happeningNowOverride == nil else { return }
        happeningNowItems = (try? await api.send(EventEndpoints.HappeningNow()))?.items ?? happeningNowItems
    }

    private func resolved(_ post: Post) -> Post {
        let state = engagementState(for: post)
        return post.applyingEngagement(hasLiked: state.hasLiked, hasSaved: state.hasSaved, likeCount: state.likeCount)
    }

    private func engagementState(for post: Post) -> PostEngagement {
        engagement[post.id] ?? PostEngagement(
            hasLiked: post.hasLiked,
            hasSaved: post.hasSaved,
            likeCount: post.counts.likes
        )
    }

    private func apply(_ state: PostEngagement, to postID: UUID) {
        engagement[postID] = state
    }
}

struct PostEngagement: Equatable, Sendable {
    var hasLiked: Bool
    var hasSaved: Bool
    var likeCount: Int
}
