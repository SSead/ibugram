import Foundation

@MainActor
@Observable
final class ComposerViewModel: ErrorPresenting {
    var caption = ""
    var locationName = ""
    var selectedSpace: SpaceSummary?
    var commentsEnabled = true
    var presentedError: PresentedError?
    private(set) var images: [ComposerDraftImage] = []
    private(set) var isPublishing = false
    private(set) var publishedPost: Post?

    private let api: any APIRequesting
    private let imageIntelligence: any ImageIntelligenceProviding

    init(api: any APIRequesting, imageIntelligence: any ImageIntelligenceProviding) {
        self.api = api
        self.imageIntelligence = imageIntelligence
    }

    var canAddMoreImages: Bool { images.count < ComposerLimits.maximumImageCount }
    var remainingImageSlots: Int { max(0, ComposerLimits.maximumImageCount - images.count) }
    var characterCount: Int { caption.count }
    var isCaptionOverLimit: Bool { characterCount > ComposerLimits.maximumCaptionLength }
    var canPublish: Bool {
        !images.isEmpty && !isPublishing && !isCaptionOverLimit && images.allSatisfy { $0.phase != .uploading }
    }

    var publishStatus: String? {
        guard isPublishing else { return nil }
        if images.contains(where: { $0.phase == .uploading }) {
            let finished = images.filter { $0.phase == .uploaded }.count
            return "Uploading \(finished + 1) of \(images.count)…"
        }
        return "Creating post…"
    }

    func addImages(_ data: [Data]) async {
        for item in data where canAddMoreImages {
            let draft = ComposerDraftImage(data: item)
            images.append(draft)
            await suggestAltText(for: draft.id, data: item)
        }
    }

    func removeImage(id: UUID) {
        images.removeAll { $0.id == id }
    }

    func moveImages(from offsets: IndexSet, to destination: Int) {
        images.move(fromOffsets: offsets, toOffset: destination)
    }

    func moveImage(id: UUID, by offset: Int) {
        guard let index = images.firstIndex(where: { $0.id == id }) else { return }
        let destination = index + offset
        guard images.indices.contains(destination) else { return }
        images.swapAt(index, destination)
    }

    func updateAltText(id: UUID, text: String) {
        guard let index = images.firstIndex(where: { $0.id == id }) else { return }
        images[index].altText = text
    }

    func retryImage(id: UUID) {
        guard let index = images.firstIndex(where: { $0.id == id }) else { return }
        images[index].phase = .pending
        images[index].uploadProgress = 0
        images[index].mediaID = nil
    }

    func publish() async -> Bool {
        guard canPublish else { return false }
        isPublishing = true
        defer { isPublishing = false }
        do {
            let mediaIDs = try await uploadPendingImages()
            let created = try await api.send(PostEndpoint.create(makePayload(mediaIDs: mediaIDs)))
            publishedPost = created
            return true
        } catch {
            present(error) { [weak self] in _ = await self?.publish() }
            return false
        }
    }

    private func uploadPendingImages() async throws -> [UUID] {
        var mediaIDs: [UUID] = []
        for index in images.indices {
            if let existing = images[index].mediaID {
                mediaIDs.append(existing)
                continue
            }
            images[index].phase = .uploading
            images[index].uploadProgress = 0.2
            do {
                let alt = images[index].altText.trimmingCharacters(in: .whitespacesAndNewlines)
                let media = try await api.send(
                    MediaEndpoint.upload(
                        jpeg: images[index].data,
                        filename: "post-\(index + 1).jpg",
                        altText: alt.isEmpty ? nil : alt
                    )
                )
                images[index].mediaID = media.id
                images[index].uploadProgress = 1
                images[index].phase = .uploaded
                mediaIDs.append(media.id)
            } catch {
                images[index].phase = .failed
                images[index].uploadProgress = 0
                throw error
            }
        }
        return mediaIDs
    }

    private func makePayload(mediaIDs: [UUID]) -> CreatePostBody {
        let trimmed = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        let place = placeInput()
        return CreatePostBody(
            mediaIds: mediaIDs,
            caption: trimmed.isEmpty ? nil : trimmed,
            spaceId: selectedSpace?.id,
            place: place,
            commentsEnabled: commentsEnabled
        )
    }

    private func placeInput() -> PlaceInput? {
        let name = locationName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        let known = ComposerFixtures.campusPlaces.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
        return PlaceInput(
            id: known?.id,
            name: name,
            latitude: known?.latitude ?? FeedFixtures.campusLawn.latitude,
            longitude: known?.longitude ?? FeedFixtures.campusLawn.longitude,
            isCampusLocation: known?.isCampusLocation ?? false
        )
    }

    private func suggestAltText(for id: UUID, data: Data) async {
        guard let insight = try? await imageIntelligence.insight(forImageData: data) else { return }
        let suggestion = insight.suggestedAltText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !suggestion.isEmpty, let index = images.firstIndex(where: { $0.id == id }) else { return }
        images[index].suggestedAltText = suggestion
        if images[index].altText.isEmpty {
            images[index].altText = suggestion
        }
    }
}
