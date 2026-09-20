import Foundation

enum SearchScope: String, Codable, Sendable, CaseIterable, Identifiable {
    case all
    case users
    case hashtags
    case spaces
    case posts

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All"
        case .users: "People"
        case .hashtags: "Hashtags"
        case .spaces: "Spaces"
        case .posts: "Posts"
        }
    }
}

struct Hashtag: Codable, Sendable, Hashable, Identifiable {
    let tag: String
    let postCount: Int

    var id: String { tag }

    var displayTag: String { tag.hasPrefix("#") ? tag : "#\(tag)" }
}

struct SpaceSummary: Codable, Sendable, Hashable, Identifiable {
    let id: UUID
    let slug: String
    let name: String
    let avatarUrl: URL?
    let isOfficial: Bool
    let memberCount: Int
}

struct SearchResults: Codable, Sendable, Hashable {
    var users: [User]
    var hashtags: [Hashtag]
    var spaces: [SpaceSummary]
    var posts: [Post]

    init(
        users: [User] = [],
        hashtags: [Hashtag] = [],
        spaces: [SpaceSummary] = [],
        posts: [Post] = []
    ) {
        self.users = users
        self.hashtags = hashtags
        self.spaces = spaces
        self.posts = posts
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        users = try container.decodeIfPresent([User].self, forKey: .users) ?? []
        hashtags = try container.decodeIfPresent([Hashtag].self, forKey: .hashtags) ?? []
        spaces = try container.decodeIfPresent([SpaceSummary].self, forKey: .spaces) ?? []
        posts = try container.decodeIfPresent([Post].self, forKey: .posts) ?? []
    }

    var isEmpty: Bool {
        users.isEmpty && hashtags.isEmpty && spaces.isEmpty && posts.isEmpty
    }
}
