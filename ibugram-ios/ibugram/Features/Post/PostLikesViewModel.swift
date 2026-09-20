import Foundation
import IBUgramKit

@MainActor
@Observable
final class PostLikesViewModel: ErrorPresenting {
    var presentedError: PresentedError?

    private let likes: PagedList<User>

    init(api: any APIRequesting, postID: UUID) {
        self.likes = PagedList { cursor in
            try await api.send(PostEndpoint.likes(postID: postID, cursor: cursor))
        }
    }

    var users: [User] { likes.items }
    var phase: PagedList<User>.Phase { likes.phase }
    var isEmpty: Bool { likes.isEmpty }
    var isInitialLoading: Bool { likes.phase == .loading && likes.items.isEmpty }
    var isLoadingMore: Bool { likes.isLoadingMore }

    func load() async {
        await likes.loadFirstPageIfNeeded()
    }

    func reload() async {
        await likes.reload()
        if case .failed(let error) = likes.phase, !likes.items.isEmpty {
            present(error) { [weak self] in await self?.reload() }
        }
    }

    func loadNextPage() async {
        await likes.loadNextPage()
    }
}
