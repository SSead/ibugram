import Foundation
import Testing

@testable import ibugram
import IBUgramKit

@Suite("Composer upload")
@MainActor
struct ComposerViewModelTests {
    @Test("each image is uploaded in order before the post is created")
    func imagesUploadInOrderThenCreatePost() async {
        let api = ComposerScriptedAPIClient()
        let viewModel = ComposerViewModel(api: api, imageIntelligence: StubImageIntelligence())
        await viewModel.addImages([Data("one".utf8), Data("two".utf8)])
        viewModel.caption = "Hello from campus #burch"

        let published = await viewModel.publish()

        #expect(published)
        #expect(await api.calls == ["POST /media", "POST /media", "POST /posts"])
        #expect(await api.uploadedFilenames == ["post-1.jpg", "post-2.jpg"])
        #expect(viewModel.publishedPost != nil)
        #expect(viewModel.caption == "Hello from campus #burch")
    }

    @Test("a failed upload keeps the caption and retries only remaining images")
    func failedUploadPreservesCaptionAndSkipsCompletedImages() async {
        let api = ComposerScriptedAPIClient(failingUploadIndex: 1)
        let viewModel = ComposerViewModel(api: api, imageIntelligence: StubImageIntelligence())
        await viewModel.addImages([Data("one".utf8), Data("two".utf8)])
        viewModel.caption = "Do not lose this"

        let first = await viewModel.publish()
        #expect(first == false)
        #expect(viewModel.caption == "Do not lose this")
        #expect(viewModel.images.first?.phase == .uploaded)
        #expect(viewModel.images.last?.phase == .failed)

        await api.clearFailure()
        viewModel.retryImage(id: viewModel.images[1].id)
        let second = await viewModel.publish()

        #expect(second)
        #expect(await api.calls == ["POST /media", "POST /media", "POST /media", "POST /posts"])
        #expect(viewModel.caption == "Do not lose this")
    }
}

actor ComposerScriptedAPIClient: APIRequesting {
    private(set) var calls: [String] = []
    private(set) var uploadedFilenames: [String] = []
    private var failingUploadIndex: Int?
    private var mediaUploads = 0

    init(failingUploadIndex: Int? = nil) {
        self.failingUploadIndex = failingUploadIndex
    }

    func clearFailure() {
        failingUploadIndex = nil
    }

    func send<E: ibugram.Endpoint>(_ endpoint: E) async throws -> E.Response {
        let key = "\(endpoint.method.rawValue) \(endpoint.path)"
        if let upload = endpoint as? MediaEndpoint.Upload {
            if failingUploadIndex == mediaUploads {
                calls.append(key)
                mediaUploads += 1
                throw ibugram.APIError.offline
            }
            calls.append(key)
            uploadedFilenames.append(upload.filename)
            mediaUploads += 1
            let media = Media(
                id: UUID(),
                url: FeedFixtures.url("https://media.ibugram.invalid/\(mediaUploads).jpg"),
                thumbnailUrl: FeedFixtures.url("https://media.ibugram.invalid/\(mediaUploads)-thumb.jpg"),
                width: 1080,
                height: 1080,
                altText: upload.altText,
                blurhash: nil
            )
            return try typed(media)
        }
        if endpoint is PostEndpoint.Create {
            calls.append(key)
            return try typed(FeedFixtures.singleImage)
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
