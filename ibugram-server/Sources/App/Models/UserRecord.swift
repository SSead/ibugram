import Fluent
import Foundation
import IBUgramKit

final class UserRecord: Model, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id) var id: UUID?
    @Field(key: "email") var email: String
    @OptionalField(key: "username") var username: String?
    @OptionalField(key: "display_name") var displayName: String?
    @OptionalField(key: "bio") var bio: String?
    @Field(key: "role") var role: UserRole
    @OptionalField(key: "department") var department: String?
    @OptionalField(key: "year_of_study") var yearOfStudy: Int?
    @Field(key: "is_verified") var isVerified: Bool
    @Field(key: "is_moderator") var isModerator: Bool
    @Field(key: "is_suspended") var isSuspended: Bool
    @OptionalParent(key: "avatar_media_id") var avatarMedia: MediaRecord?
    @OptionalField(key: "last_seen_at") var lastSeenAt: Date?
    @Field(key: "post_count") var postCount: Int
    @Field(key: "follower_count") var followerCount: Int
    @Field(key: "following_count") var followingCount: Int
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}

    init(email: String, role: UserRole) {
        self.email = email
        self.role = role
        self.isVerified = role == .faculty
        self.isModerator = false
        self.isSuspended = false
        self.postCount = 0
        self.followerCount = 0
        self.followingCount = 0
    }

    var hasCompletedOnboarding: Bool {
        username != nil && displayName != nil
    }
}

final class FollowRecord: Model, @unchecked Sendable {
    static let schema = "follows"

    @ID(key: .id) var id: UUID?
    @Parent(key: "follower_id") var follower: UserRecord
    @Parent(key: "followee_id") var followee: UserRecord
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?

    init() {}

    init(followerId: UUID, followeeId: UUID) {
        self.$follower.id = followerId
        self.$followee.id = followeeId
    }
}

final class BlockRecord: Model, @unchecked Sendable {
    static let schema = "blocks"

    @ID(key: .id) var id: UUID?
    @Parent(key: "blocker_id") var blocker: UserRecord
    @Parent(key: "blocked_id") var blocked: UserRecord
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?

    init() {}

    init(blockerId: UUID, blockedId: UUID) {
        self.$blocker.id = blockerId
        self.$blocked.id = blockedId
    }
}
