import Foundation

@MainActor
@Observable
final class HashtagDetailViewModel: ErrorPresenting {
    let posts: Paginated<Post>
    var presentedError: PresentedError?
    let tag: String

    init(api: any APIRequesting, tag: String) {
        self.tag = tag
        posts = Paginated { cursor in
            try await api.send(SearchEndpoints.HashtagPosts(tag: tag, cursor: cursor))
        }
    }

    func load() async {
        await posts.loadFirstPageIfNeeded()
    }

    func reload() async {
        await posts.reload()
    }
}
