import Foundation
import IBUgramKit

extension User {
    var avatarURL: URL? { RemoteURL.parse(avatarUrl) }

    var roleTitle: String {
        switch role {
        case .student: "Student"
        case .faculty: "Faculty"
        }
    }

    func withFollowState(isFollowing: Bool) -> User {
        var copy = self
        let followerDelta: Int
        if viewer?.isFollowing == isFollowing {
            followerDelta = 0
        } else {
            followerDelta = isFollowing ? 1 : -1
        }
        copy.counts = UserCounts(
            posts: counts.posts,
            followers: max(counts.followers + followerDelta, 0),
            following: counts.following
        )
        copy.viewer = UserViewerState(
            isFollowing: isFollowing,
            isFollowedBy: viewer?.isFollowedBy ?? false,
            isBlocked: viewer?.isBlocked ?? false
        )
        return copy
    }

    func withBlocked(_ isBlocked: Bool) -> User {
        var copy = self
        copy.viewer = UserViewerState(
            isFollowing: isBlocked ? false : (viewer?.isFollowing ?? false),
            isFollowedBy: viewer?.isFollowedBy ?? false,
            isBlocked: isBlocked
        )
        return copy
    }
}

extension Media {
    var resourceURL: URL? { RemoteURL.parse(url) }
    var thumbnailURL: URL? { RemoteURL.parse(thumbnailUrl) }
}

extension SpaceSummary {
    var avatarURL: URL? { RemoteURL.parse(avatarUrl) }
}

extension Post {
    var cover: Media? { media.first }
    var hasLiked: Bool { viewer?.hasLiked ?? false }
    var hasSaved: Bool { viewer?.hasSaved ?? false }

    func applyingEngagement(
        hasLiked: Bool,
        hasSaved: Bool,
        likeCount: Int,
        commentCount: Int? = nil
    ) -> Post {
        var copy = self
        copy.counts = PostCounts(likes: max(0, likeCount), comments: commentCount ?? counts.comments)
        copy.viewer = PostViewerState(hasLiked: hasLiked, hasSaved: hasSaved)
        return copy
    }
}

extension Comment {
    var hasLiked: Bool { viewer?.hasLiked ?? false }

    func applyingLike(hasLiked: Bool, likeCount: Int) -> Comment {
        var copy = self
        copy.likeCount = max(0, likeCount)
        copy.viewer = CommentViewerState(hasLiked: hasLiked)
        return copy
    }
}

extension Hashtag {
    var displayTag: String { tag.hasPrefix("#") ? tag : "#\(tag)" }
}

extension SearchScope {
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

extension ReportReason {
    var title: String {
        switch self {
        case .spam: "Spam"
        case .harassment: "Harassment"
        case .hateSpeech: "Hate speech"
        case .nudity: "Nudity"
        case .violence: "Violence"
        case .misinformation: "Misinformation"
        case .other: "Something else"
        }
    }
}

extension Session {
    var title: String {
        if let deviceName, !deviceName.isEmpty { return deviceName }
        if let userAgent, !userAgent.isEmpty { return userAgent }
        return "This device"
    }
}

extension IBUgramKit.Notification {
    func markingRead() -> IBUgramKit.Notification {
        var copy = self
        copy.isRead = true
        return copy
    }
}

enum RemoteURL {
    static func parse(_ string: String?) -> URL? {
        guard let string, !string.isEmpty else { return nil }
        return URL(string: string)
    }
}
