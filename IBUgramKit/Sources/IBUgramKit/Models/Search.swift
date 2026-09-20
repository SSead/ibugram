import Foundation

public enum SearchScope: String, Codable, Sendable, Hashable, CaseIterable {
    case all
    case users
    case hashtags
    case spaces
    case posts
}

public struct SearchResults: Codable, Sendable, Hashable {
    public var users: [User]
    public var hashtags: [Hashtag]
    public var spaces: [SpaceSummary]
    public var posts: [Post]

    public init(
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

    public var isEmpty: Bool {
        users.isEmpty && hashtags.isEmpty && spaces.isEmpty && posts.isEmpty
    }
}

public enum ReportSubject: String, Codable, Sendable, Hashable, CaseIterable {
    case post
    case comment
    case user
}

public enum ReportReason: String, Codable, Sendable, Hashable, CaseIterable {
    case spam
    case harassment
    case hateSpeech = "hate_speech"
    case nudity
    case violence
    case misinformation
    case other
}
