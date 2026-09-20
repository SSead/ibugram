import Foundation

public struct CreateSpaceBody: Codable, Sendable, Hashable {
    public var slug: String
    public var name: String
    public var description: String?
    public var kind: SpaceKind
    public var visibility: SpaceVisibility
    public var isOfficial: Bool
    public var avatarMediaId: UUID?
    public var bannerMediaId: UUID?

    public init(
        slug: String,
        name: String,
        description: String? = nil,
        kind: SpaceKind,
        visibility: SpaceVisibility = .public,
        isOfficial: Bool = false,
        avatarMediaId: UUID? = nil,
        bannerMediaId: UUID? = nil
    ) {
        self.slug = slug
        self.name = name
        self.description = description
        self.kind = kind
        self.visibility = visibility
        self.isOfficial = isOfficial
        self.avatarMediaId = avatarMediaId
        self.bannerMediaId = bannerMediaId
    }
}

public struct UpdateSpaceBody: Codable, Sendable, Hashable {
    public var name: String?
    public var description: String?
    public var visibility: SpaceVisibility?
    public var avatarMediaId: UUID?
    public var bannerMediaId: UUID?

    public init(
        name: String? = nil,
        description: String? = nil,
        visibility: SpaceVisibility? = nil,
        avatarMediaId: UUID? = nil,
        bannerMediaId: UUID? = nil
    ) {
        self.name = name
        self.description = description
        self.visibility = visibility
        self.avatarMediaId = avatarMediaId
        self.bannerMediaId = bannerMediaId
    }
}

public struct SetSpaceMemberRoleBody: Codable, Sendable, Hashable {
    public var role: SpaceMembership

    public init(role: SpaceMembership) {
        self.role = role
    }
}

public enum SpaceSlug {
    public static let minimumLength = 3
    public static let maximumLength = 40

    public static func isValid(_ candidate: String) -> Bool {
        guard (minimumLength...maximumLength).contains(candidate.count) else { return false }
        guard candidate.lowercased() == candidate else { return false }
        guard let first = candidate.first, first.isLetter || first.isNumber else { return false }
        guard let last = candidate.last, last.isLetter || last.isNumber else { return false }
        guard !candidate.contains("--") else { return false }
        return candidate.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-") }
    }
}
