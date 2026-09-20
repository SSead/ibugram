import Fluent
import Foundation
import IBUgramKit

final class SpaceRecord: Model, @unchecked Sendable {
    static let schema = "spaces"

    @ID(key: .id) var id: UUID?
    @Field(key: "slug") var slug: String
    @Field(key: "name") var name: String
    @OptionalField(key: "description") var description: String?
    @Field(key: "kind") var kind: SpaceKind
    @Field(key: "visibility") var visibility: SpaceVisibility
    @Field(key: "is_official") var isOfficial: Bool
    @OptionalParent(key: "avatar_media_id") var avatarMedia: MediaRecord?
    @OptionalParent(key: "banner_media_id") var bannerMedia: MediaRecord?
    @OptionalParent(key: "created_by_id") var createdBy: UserRecord?
    @Field(key: "member_count") var memberCount: Int
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    @Children(for: \.$space) var memberships: [SpaceMembershipRecord]

    init() {}
}

final class SpaceMembershipRecord: Model, @unchecked Sendable {
    static let schema = "space_memberships"

    @ID(key: .id) var id: UUID?
    @Parent(key: "space_id") var space: SpaceRecord
    @Parent(key: "user_id") var user: UserRecord
    @Field(key: "role") var role: SpaceMembership
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}
}
