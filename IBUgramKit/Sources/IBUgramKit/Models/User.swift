import Foundation

public enum UserRole: String, Codable, Sendable, Hashable, CaseIterable {
    case student
    case faculty
}

public struct UserCounts: Codable, Sendable, Hashable {
    public var posts: Int
    public var followers: Int
    public var following: Int

    public init(posts: Int = 0, followers: Int = 0, following: Int = 0) {
        self.posts = posts
        self.followers = followers
        self.following = following
    }
}

public struct UserViewerState: Codable, Sendable, Hashable {
    public var isFollowing: Bool
    public var isFollowedBy: Bool
    public var isBlocked: Bool

    public init(isFollowing: Bool = false, isFollowedBy: Bool = false, isBlocked: Bool = false) {
        self.isFollowing = isFollowing
        self.isFollowedBy = isFollowedBy
        self.isBlocked = isBlocked
    }
}

public struct User: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    public var username: String
    public var displayName: String
    public var avatarUrl: String?
    public var bio: String?
    public var role: UserRole
    public var department: String?
    public var yearOfStudy: Int?
    public var isVerified: Bool
    public var counts: UserCounts
    public var viewer: UserViewerState?
    public var createdAt: Date

    public init(
        id: UUID,
        username: String,
        displayName: String,
        avatarUrl: String? = nil,
        bio: String? = nil,
        role: UserRole,
        department: String? = nil,
        yearOfStudy: Int? = nil,
        isVerified: Bool = false,
        counts: UserCounts = UserCounts(),
        viewer: UserViewerState? = nil,
        createdAt: Date
    ) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.bio = bio
        self.role = role
        self.department = department
        self.yearOfStudy = yearOfStudy
        self.isVerified = isVerified
        self.counts = counts
        self.viewer = viewer
        self.createdAt = createdAt
    }
}
