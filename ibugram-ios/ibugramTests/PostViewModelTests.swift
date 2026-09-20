import Foundation
import Testing

@testable import ibugram

@Suite("Post comments")
@MainActor
struct PostViewModelTests {
    @Test("an optimistic like on a post is rolled back when the request fails")
    func postLikeRollsBackOnFailure() async {
        let api = PostScriptedAPIClient(likeError: .offline)
        let viewModel = PostDetailViewModel(api: api, postID: FeedFixtures.singleImage.id)
        await viewModel.load()

        #expect(viewModel.post?.hasLiked == false)
        let likes = viewModel.post?.counts.likes ?? 0
        await viewModel.toggleLike()

        #expect(viewModel.post?.hasLiked == false)
        #expect(viewModel.post?.counts.likes == likes)
        #expect(viewModel.presentedError != nil)
    }

    @Test("a comment is inserted immediately and kept when the server accepts it")
    func commentInsertsOptimistically() async {
        let api = PostScriptedAPIClient()
        let viewModel = PostDetailViewModel(api: api, postID: FeedFixtures.singleImage.id)
        await viewModel.load()

        let before = viewModel.comments.count
        viewModel.draft = "See you on the lawn"
        await viewModel.sendComment()

        #expect(viewModel.comments.count == before + 1)
        #expect(viewModel.comments.last?.body == "See you on the lawn")
        #expect(viewModel.draft.isEmpty)
        #expect(viewModel.presentedError == nil)
    }
}

actor PostScriptedAPIClient: APIRequesting {
    private let likeError: APIError?

    init(likeError: APIError? = nil) {
        self.likeError = likeError
    }

    func send<E: Endpoint>(_ endpoint: E) async throws -> E.Response {
        if endpoint is PostEndpoint.Like || endpoint is PostEndpoint.Unlike {
            if let likeError { throw likeError }
            return try typed(EmptyResponse())
        }
        if endpoint is UserEndpoint.Me {
            return try typed(SampleData.amina)
        }
        if endpoint is PostEndpoint.Detail {
            return try typed(FeedFixtures.singleImage)
        }
        if endpoint is PostEndpoint.Comments {
            return try typed(Page(items: PostFixtures.comments, nextCursor: nil))
        }
        if let create = endpoint as? PostEndpoint.CreateComment {
            let comment = Comment(
                id: UUID(),
                postId: FeedFixtures.singleImage.id,
                author: SampleData.amina,
                body: create.bodyText,
                parentId: create.parentID,
                replyCount: 0,
                likeCount: 0,
                viewer: CommentViewerState(hasLiked: false),
                createdAt: .now
            )
            return try typed(comment)
        }
        throw APIError.notFound
    }

    private func typed<Value, Response>(_ value: Value) throws -> Response {
        guard let typed = value as? Response else {
            throw APIError.decoding("stub type mismatch")
        }
        return typed
    }
}
