import Foundation

public enum SpaceKind: String, Codable, Sendable, Hashable, CaseIterable {
    case club
    case department
    case course
    case community
}

public enum SpaceVisibility: String, Codable, Sendable, Hashable, CaseIterable {
    case `public`
    case request
    case invite
}

public enum SpaceMembership: String, Codable, Sendable, Hashable, CaseIterable {
    case none
    case pending
    case member
    case moderator
    case owner

    public var canModerate: Bool {
        self == .moderator || self == .owner
    }

    public var canPost: Bool {
        self == .member || canModerate
    }
}

public struct SpaceSummary: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    public var slug: String
    public var name: String
    public var avatarUrl: String?
    public var isOfficial: Bool
    public var memberCount: Int

    public init(
        id: UUID,
        slug: String,
        name: String,
        avatarUrl: String? = nil,
        isOfficial: Bool = false,
        memberCount: Int = 0
    ) {
        self.id = id
        self.slug = slug
        self.name = name
        self.avatarUrl = avatarUrl
        self.isOfficial = isOfficial
        self.memberCount = memberCount
    }
}

public struct SpaceViewerState: Codable, Sendable, Hashable {
    public var membership: SpaceMembership

    public init(membership: SpaceMembership = .none) {
        self.membership = membership
    }
}

/// `Space` inlines every `SpaceSummary` field because the contract defines it by spread.
public struct Space: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    public var slug: String
    public var name: String
    public var avatarUrl: String?
    public var isOfficial: Bool
    public var memberCount: Int
    public var bannerUrl: String?
    public var description: String?
    public var kind: SpaceKind
    public var visibility: SpaceVisibility
    public var viewer: SpaceViewerState?
    public var createdBy: User
    public var createdAt: Date

    public init(
        id: UUID,
        slug: String,
        name: String,
        avatarUrl: String? = nil,
        isOfficial: Bool = false,
        memberCount: Int = 0,
        bannerUrl: String? = nil,
        description: String? = nil,
        kind: SpaceKind,
        visibility: SpaceVisibility,
        viewer: SpaceViewerState? = nil,
        createdBy: User,
        createdAt: Date
    ) {
        self.id = id
        self.slug = slug
        self.name = name
        self.avatarUrl = avatarUrl
        self.isOfficial = isOfficial
        self.memberCount = memberCount
        self.bannerUrl = bannerUrl
        self.description = description
        self.kind = kind
        self.visibility = visibility
        self.viewer = viewer
        self.createdBy = createdBy
        self.createdAt = createdAt
    }

    public var summary: SpaceSummary {
        SpaceSummary(
            id: id,
            slug: slug,
            name: name,
            avatarUrl: avatarUrl,
            isOfficial: isOfficial,
            memberCount: memberCount
        )
    }
}

public struct SpaceMember: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    public var user: User
    public var role: SpaceMembership
    public var joinedAt: Date

    public init(id: UUID, user: User, role: SpaceMembership, joinedAt: Date) {
        self.id = id
        self.user = user
        self.role = role
        self.joinedAt = joinedAt
    }
}
