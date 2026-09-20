import Foundation

struct PostCounts: Codable, Sendable, Hashable {
    let likes: Int
    let comments: Int
}

struct PostViewerState: Codable, Sendable, Hashable {
    let hasLiked: Bool
    let hasSaved: Bool
}

struct Post: Codable, Sendable, Hashable, Identifiable {
    let id: UUID
    let author: User
    let media: [Media]
    let caption: String?
    let hashtags: [String]
    let counts: PostCounts
    let viewer: PostViewerState?
    let commentsEnabled: Bool
    let createdAt: Date
    let editedAt: Date?

    var cover: Media? { media.first }
}

enum ReportSubject: String, Codable, Sendable {
    case post
    case comment
    case user
}

enum ReportReason: String, Codable, Sendable, CaseIterable, Identifiable {
    case spam
    case harassment
    case hateSpeech = "hate_speech"
    case nudity
    case violence
    case misinformation
    case other

    var id: String { rawValue }

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

struct ReportBody: Encodable, Sendable {
    let subject: ReportSubject
    let subjectId: UUID
    let reason: ReportReason
    let detail: String?
}

extension User {
    var roleTitle: String {
        switch role {
        case .student: "Student"
        case .faculty: "Faculty"
        }
    }

    func withFollowState(isFollowing: Bool) -> User {
        let followerDelta: Int
        if viewer?.isFollowing == isFollowing {
            followerDelta = 0
        } else {
            followerDelta = isFollowing ? 1 : -1
        }
        return replacing(
            counts: UserCounts(
                posts: counts.posts,
                followers: max(counts.followers + followerDelta, 0),
                following: counts.following
            ),
            viewer: ViewerRelationship(
                isFollowing: isFollowing,
                isFollowedBy: viewer?.isFollowedBy ?? false,
                isBlocked: viewer?.isBlocked ?? false
            )
        )
    }

    func withBlocked(_ isBlocked: Bool) -> User {
        replacing(
            viewer: ViewerRelationship(
                isFollowing: isBlocked ? false : (viewer?.isFollowing ?? false),
                isFollowedBy: viewer?.isFollowedBy ?? false,
                isBlocked: isBlocked
            )
        )
    }

    fileprivate func replacing(counts: UserCounts? = nil, viewer: ViewerRelationship? = nil) -> User {
        User(
            id: id,
            username: username,
            displayName: displayName,
            avatarUrl: avatarUrl,
            bio: bio,
            role: role,
            department: department,
            yearOfStudy: yearOfStudy,
            isVerified: isVerified,
            counts: counts ?? self.counts,
            viewer: viewer ?? self.viewer,
            createdAt: createdAt
        )
    }
}
