import Foundation

public struct Media: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    public var url: String
    public var thumbnailUrl: String
    public var width: Int
    public var height: Int
    public var altText: String?
    public var blurhash: String?

    public init(
        id: UUID,
        url: String,
        thumbnailUrl: String,
        width: Int,
        height: Int,
        altText: String? = nil,
        blurhash: String? = nil
    ) {
        self.id = id
        self.url = url
        self.thumbnailUrl = thumbnailUrl
        self.width = width
        self.height = height
        self.altText = altText
        self.blurhash = blurhash
    }

    public var aspectRatio: Double {
        height == 0 ? 1 : Double(width) / Double(height)
    }
}

/// Multipart field names for `POST /media`.
public enum MediaUploadField {
    public static let file = "file"
    public static let altText = "alt_text"
}
