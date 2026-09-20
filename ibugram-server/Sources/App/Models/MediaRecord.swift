import Fluent
import Foundation

final class MediaRecord: Model, @unchecked Sendable {
    static let schema = "media"

    @ID(key: .id) var id: UUID?
    @Parent(key: "uploaded_by_id") var uploadedBy: UserRecord
    @Field(key: "storage_key") var storageKey: String
    @Field(key: "thumbnail_storage_key") var thumbnailStorageKey: String
    @Field(key: "content_type") var contentType: String
    @Field(key: "byte_size") var byteSize: Int
    @Field(key: "width") var width: Int
    @Field(key: "height") var height: Int
    @OptionalField(key: "alt_text") var altText: String?
    @OptionalField(key: "blurhash") var blurhash: String?
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}

    init(
        id: UUID,
        uploadedById: UUID,
        storageKey: String,
        thumbnailStorageKey: String,
        contentType: String,
        byteSize: Int,
        width: Int,
        height: Int,
        altText: String?
    ) {
        self.id = id
        self.$uploadedBy.id = uploadedById
        self.storageKey = storageKey
        self.thumbnailStorageKey = thumbnailStorageKey
        self.contentType = contentType
        self.byteSize = byteSize
        self.width = width
        self.height = height
        self.altText = altText
    }
}
