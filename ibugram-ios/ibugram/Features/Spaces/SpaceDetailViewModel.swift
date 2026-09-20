import Foundation
import IBUgramKit

@MainActor
@Observable
final class SpaceDetailViewModel: ErrorPresenting {
    enum Phase: Equatable {
        case loading
        case loaded
        case failed(APIError)
    }

    private(set) var phase: Phase = .loading
    private(set) var space: Space?
    private(set) var isMutatingMembership = false
    var presentedError: PresentedError?

    let posts: PagedList<Post>
    private let api: any APIRequesting
    private let slug: String

    init(api: any APIRequesting, slug: String) {
        self.api = api
        self.slug = slug
        posts = PagedList { cursor in
            try await api.send(SpaceEndpoints.Posts(slug: slug, cursor: cursor))
        }
    }

    var membership: SpaceMembership {
        space.map(SpaceJoinPolicy.membership(of:)) ?? .none
    }

    var canJoin: Bool {
        space.map(SpaceJoinPolicy.canJoin) ?? false
    }

    var canLeave: Bool {
        space.map(SpaceJoinPolicy.canLeave) ?? false
    }

    var isInviteOnlyLocked: Bool {
        guard let space else { return false }
        return space.visibility == .invite && membership == .none
    }

    func load() async {
        phase = .loading
        do {
            space = try await api.send(SpaceEndpoints.Detail(slug: slug))
            phase = .loaded
            await posts.loadFirstPageIfNeeded()
        } catch {
            phase = .failed(error.asAPIError)
        }
    }

    func reload() async {
        do {
            space = try await api.send(SpaceEndpoints.Detail(slug: slug))
            phase = .loaded
            await posts.reload()
        } catch {
            present(error) { [weak self] in await self?.reload() }
        }
    }

    func join() async {
        guard !isMutatingMembership, let current = space, let next = SpaceJoinPolicy.applyingJoin(current) else {
            return
        }
        space = next
        isMutatingMembership = true
        defer { isMutatingMembership = false }
        do {
            _ = try await api.send(SpaceEndpoints.Join(slug: slug))
        } catch {
            space = current
            present(error) { [weak self] in await self?.join() }
        }
    }

    func leave() async {
        guard !isMutatingMembership, let current = space, let next = SpaceJoinPolicy.applyingLeave(current) else {
            return
        }
        space = next
        isMutatingMembership = true
        defer { isMutatingMembership = false }
        do {
            _ = try await api.send(SpaceEndpoints.Leave(slug: slug))
        } catch {
            space = current
            present(error) { [weak self] in await self?.leave() }
        }
    }
}
