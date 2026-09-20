import Foundation

public struct PostCounts: Codable, Sendable, Hashable {
    public var likes: Int
    public var comments: Int

    public init(likes: Int = 0, comments: Int = 0) {
        self.likes = likes
        self.comments = comments
    }
}

public struct PostViewerState: Codable, Sendable, Hashable {
    public var hasLiked: Bool
    public var hasSaved: Bool

    public init(hasLiked: Bool = false, hasSaved: Bool = false) {
        self.hasLiked = hasLiked
        self.hasSaved = hasSaved
    }
}

public struct Post: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    public var author: User
    public var media: [Media]
    public var caption: String?
    public var hashtags: [String]
    public var mentions: [User]
    public var space: SpaceSummary?
    public var event: Event?
    public var location: Place?
    public var counts: PostCounts
    public var viewer: PostViewerState?
    public var commentsEnabled: Bool
    public var createdAt: Date
    public var editedAt: Date?

    public init(
        id: UUID,
        author: User,
        media: [Media] = [],
        caption: String? = nil,
        hashtags: [String] = [],
        mentions: [User] = [],
        space: SpaceSummary? = nil,
        event: Event? = nil,
        location: Place? = nil,
        counts: PostCounts = PostCounts(),
        viewer: PostViewerState? = nil,
        commentsEnabled: Bool = true,
        createdAt: Date,
        editedAt: Date? = nil
    ) {
        self.id = id
        self.author = author
        self.media = media
        self.caption = caption
        self.hashtags = hashtags
        self.mentions = mentions
        self.space = space
        self.event = event
        self.location = location
        self.counts = counts
        self.viewer = viewer
        self.commentsEnabled = commentsEnabled
        self.createdAt = createdAt
        self.editedAt = editedAt
    }
}

public struct CommentViewerState: Codable, Sendable, Hashable {
    public var hasLiked: Bool

    public init(hasLiked: Bool = false) {
        self.hasLiked = hasLiked
    }
}

public struct Comment: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    public var postId: UUID
    public var author: User
    public var body: String
    public var parentId: UUID?
    public var replyCount: Int
    public var likeCount: Int
    public var viewer: CommentViewerState?
    public var createdAt: Date

    public init(
        id: UUID,
        postId: UUID,
        author: User,
        body: String,
        parentId: UUID? = nil,
        replyCount: Int = 0,
        likeCount: Int = 0,
        viewer: CommentViewerState? = nil,
        createdAt: Date
    ) {
        self.id = id
        self.postId = postId
        self.author = author
        self.body = body
        self.parentId = parentId
        self.replyCount = replyCount
        self.likeCount = likeCount
        self.viewer = viewer
        self.createdAt = createdAt
    }

    public var isReply: Bool { parentId != nil }
}

public struct Hashtag: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    public var tag: String
    public var postCount: Int

    public init(id: UUID, tag: String, postCount: Int = 0) {
        self.id = id
        self.tag = tag
        self.postCount = postCount
    }
}

public enum HashtagParser {
    /// Tags are stored casefolded and without the leading `#`.
    public static func hashtags(in text: String) -> [String] {
        matches(in: text, marker: "#") { $0.isLetter || $0.isNumber || $0 == "_" }
    }

    /// Mentions allow the period because usernames do.
    public static func mentions(in text: String) -> [String] {
        matches(in: text, marker: "@") { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "." }
    }

    private static func matches(
        in text: String,
        marker: Character,
        isBodyCharacter: (Character) -> Bool
    ) -> [String] {
        var found: [String] = []
        var seen: Set<String> = []
        var current: String?
        for character in text {
            if character == marker {
                appendIfUsable(current, to: &found, seen: &seen)
                current = ""
                continue
            }
            guard current != nil else { continue }
            if isBodyCharacter(character) {
                current?.append(character)
            } else {
                appendIfUsable(current, to: &found, seen: &seen)
                current = nil
            }
        }
        appendIfUsable(current, to: &found, seen: &seen)
        return found
    }

    private static func appendIfUsable(_ candidate: String?, to found: inout [String], seen: inout Set<String>) {
        guard let candidate else { return }
        let normalized = candidate.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
        guard !normalized.isEmpty, seen.insert(normalized).inserted else { return }
        found.append(normalized)
    }
}
