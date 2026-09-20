import Foundation
import Testing

@testable import ibugram
import IBUgramKit

@Suite("Feed pagination")
@MainActor
struct FeedViewModelPaginationTests {
    @Test("loading the next page appends items and then stops when the cursor is exhausted")
    func paginationAdvancesThenTerminates() async {
        let api = FeedScriptedAPIClient(
            pages: [
                nil: Paginated(items: [FeedFixtures.singleImage], nextCursor: "page-2"),
                "page-2": Paginated(items: [FeedFixtures.carousel], nextCursor: nil)
            ]
        )
        let viewModel = FeedViewModel(api: api, happeningNow: { [] })

        await viewModel.load()
        #expect(viewModel.displayPosts.map(\.id) == [FeedFixtures.singleImage.id])
        #expect(viewModel.hasReachedEnd == false)

        await viewModel.loadNextPage()
        #expect(viewModel.displayPosts.map(\.id) == [FeedFixtures.singleImage.id, FeedFixtures.carousel.id])
        #expect(viewModel.hasReachedEnd)

        await viewModel.loadNextPage()
        #expect(viewModel.displayPosts.count == 2)
    }

    @Test("a first page without a continuation cursor is treated as complete")
    func firstPageWithoutCursorTerminates() async {
        let api = FeedScriptedAPIClient(
            pages: [
                nil: Paginated(items: [FeedFixtures.liked], nextCursor: nil)
            ]
        )
        let viewModel = FeedViewModel(api: api, happeningNow: { [] })

        await viewModel.load()
        #expect(viewModel.displayPosts.count == 1)
        #expect(viewModel.hasReachedEnd)

        await viewModel.loadNextPage()
        #expect(viewModel.displayPosts.count == 1)
        #expect(await api.followingLoads == 1)
    }
}

@Suite("Feed likes")
@MainActor
struct FeedViewModelLikeTests {
    @Test("an optimistic like is rolled back when the request fails")
    func optimisticLikeRollsBackOnFailure() async {
        let api = FeedScriptedAPIClient(
            pages: [nil: Paginated(items: [FeedFixtures.singleImage], nextCursor: nil)],
            mutationError: .offline
        )
        let viewModel = FeedViewModel(api: api, happeningNow: { [] })
        await viewModel.load()

        #expect(viewModel.displayPosts.first?.hasLiked == false)
        let likeCount = viewModel.displayPosts.first?.counts.likes ?? 0

        await viewModel.toggleLike(of: viewModel.displayPosts[0])

        #expect(viewModel.displayPosts.first?.hasLiked == false)
        #expect(viewModel.displayPosts.first?.counts.likes == likeCount)
        #expect(viewModel.presentedError != nil)
    }

    @Test("a successful like stays flipped and increments the count")
    func successfulLikeStaysFlipped() async {
        let api = FeedScriptedAPIClient(
            pages: [nil: Paginated(items: [FeedFixtures.singleImage], nextCursor: nil)]
        )
        let viewModel = FeedViewModel(api: api, happeningNow: { [] })
        await viewModel.load()
        let likeCount = viewModel.displayPosts[0].counts.likes

        await viewModel.toggleLike(of: viewModel.displayPosts[0])

        #expect(viewModel.displayPosts.first?.hasLiked == true)
        #expect(viewModel.displayPosts.first?.counts.likes == likeCount + 1)
        #expect(viewModel.presentedError == nil)
    }
}

actor FeedScriptedAPIClient: APIRequesting {
    private let pages: [String?: Paginated<Post>]
    private let mutationError: ibugram.APIError?
    private(set) var followingLoads = 0

    init(pages: [String?: Paginated<Post>], mutationError: ibugram.APIError? = nil) {
        self.pages = pages
        self.mutationError = mutationError
    }

    func send<E: ibugram.Endpoint>(_ endpoint: E) async throws -> E.Response {
        if endpoint is PostEndpoint.Like || endpoint is PostEndpoint.Unlike
            || endpoint is PostEndpoint.Save || endpoint is PostEndpoint.Unsave
        {
            if let mutationError { throw mutationError }
            return try typed(EmptyResponse())
        }
        if let following = endpoint as? FeedEndpoint.Following {
            followingLoads += 1
            guard let page = pages[following.cursor] else { throw ibugram.APIError.notFound }
            return try typed(page)
        }
        if let discover = endpoint as? FeedEndpoint.Discover {
            guard let page = pages[discover.cursor] else { throw ibugram.APIError.notFound }
            return try typed(page)
        }
        throw ibugram.APIError.notFound
    }

    private func typed<Value, Response>(_ value: Value) throws -> Response {
        guard let typed = value as? Response else {
            throw ibugram.APIError.decoding("stub type mismatch")
        }
        return typed
    }
}
