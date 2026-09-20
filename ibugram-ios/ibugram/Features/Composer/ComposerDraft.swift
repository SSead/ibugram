import Foundation

enum ComposerImagePhase: Equatable, Sendable {
    case pending
    case uploading
    case uploaded
    case failed
}

struct ComposerDraftImage: Identifiable, Equatable, Sendable {
    let id: UUID
    var data: Data
    var altText: String
    var suggestedAltText: String?
    var uploadProgress: Double
    var mediaID: UUID?
    var phase: ComposerImagePhase

    init(
        id: UUID = UUID(),
        data: Data,
        altText: String = "",
        suggestedAltText: String? = nil,
        uploadProgress: Double = 0,
        mediaID: UUID? = nil,
        phase: ComposerImagePhase = .pending
    ) {
        self.id = id
        self.data = data
        self.altText = altText
        self.suggestedAltText = suggestedAltText
        self.uploadProgress = uploadProgress
        self.mediaID = mediaID
        self.phase = phase
    }
}
