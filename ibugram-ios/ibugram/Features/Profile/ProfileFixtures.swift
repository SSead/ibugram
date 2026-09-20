import Foundation

enum ProfileFixtures {
    static let currentUser: User = {
        let source = SampleData.amina
        return User(
            id: source.id,
            username: source.username,
            displayName: source.displayName,
            avatarUrl: source.avatarUrl,
            bio: source.bio,
            role: source.role,
            department: source.department,
            yearOfStudy: source.yearOfStudy,
            isVerified: source.isVerified,
            counts: source.counts,
            viewer: nil,
            createdAt: source.createdAt
        )
    }()

    static let followedStudent = User(
        id: UUID(uuidString: "44444444-4444-4444-8444-444444444444") ?? UUID(),
        username: "leila.m",
        displayName: "Leila Marković",
        avatarUrl: nil,
        bio: "Architecture · IBU Film Club",
        role: .student,
        department: "Architecture",
        yearOfStudy: 3,
        isVerified: false,
        counts: UserCounts(posts: 18, followers: 240, following: 190),
        viewer: ViewerRelationship(isFollowing: true, isFollowedBy: true, isBlocked: false),
        createdAt: Date(timeIntervalSince1970: 1_720_000_000)
    )

    static let unfollowedFaculty = SampleData.professorKovac

    static let campusLawn = Media(
        id: UUID(uuidString: "55555555-5555-4555-8555-555555555555") ?? UUID(),
        url: mediaURL("lawn"),
        thumbnailUrl: mediaURL("lawn-thumb"),
        width: 1080,
        height: 1080,
        altText: "Students on the campus lawn at sunset.",
        blurhash: "LEHV6nWB2yk8pyo0adR*.7kCMdnj"
    )

    static let roboticsLab = Media(
        id: UUID(uuidString: "66666666-6666-4666-8666-666666666666") ?? UUID(),
        url: mediaURL("lab"),
        thumbnailUrl: mediaURL("lab-thumb"),
        width: 1080,
        height: 1350,
        altText: "A line-follower robot on the lab bench.",
        blurhash: "LGF5]+Yk^6#M@-5c,1J5@[or[Q6."
    )

    static let posts: [Post] = [
        post(id: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1", media: campusLawn, caption: "Golden hour on the lawn #burchlife"),
        post(id: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2", media: roboticsLab, caption: "Demo night prep with IBU Robotics"),
        post(id: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa3", media: campusLawn, caption: nil),
        post(id: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa4", media: roboticsLab, caption: "Office hours, C-204"),
        post(id: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa5", media: campusLawn, caption: "First coffee of the semester"),
        post(id: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa6", media: roboticsLab, caption: "#robotics")
    ]

    static var ownProfileStubs: [String: any Sendable] {
        profileStubs(
            user: currentUser,
            posts: posts,
            saved: Array(posts.prefix(2)),
            tagged: Array(posts.prefix(1)),
            followers: [followedStudent, unfollowedFaculty],
            following: [followedStudent]
        )
    }

    static var followedUserStubs: [String: any Sendable] {
        profileStubs(
            user: followedStudent,
            posts: Array(posts.prefix(3)),
            saved: [],
            tagged: [],
            followers: [currentUser],
            following: [unfollowedFaculty]
        )
    }

    static var unfollowedFacultyStubs: [String: any Sendable] {
        profileStubs(
            user: unfollowedFaculty,
            posts: Array(posts.suffix(3)),
            saved: [],
            tagged: Array(posts.suffix(1)),
            followers: [currentUser, followedStudent],
            following: [followedStudent]
        )
    }

    static var emptyGridStubs: [String: any Sendable] {
        let empty = User(
            id: currentUser.id,
            username: currentUser.username,
            displayName: currentUser.displayName,
            avatarUrl: currentUser.avatarUrl,
            bio: currentUser.bio,
            role: currentUser.role,
            department: currentUser.department,
            yearOfStudy: currentUser.yearOfStudy,
            isVerified: currentUser.isVerified,
            counts: UserCounts(posts: 0, followers: 0, following: 0),
            viewer: nil,
            createdAt: currentUser.createdAt
        )
        return profileStubs(user: empty, posts: [], saved: [], tagged: [], followers: [], following: [])
    }

    static func profileStubs(
        user: User,
        posts: [Post],
        saved: [Post],
        tagged: [Post],
        followers: [User],
        following: [User]
    ) -> [String: any Sendable] {
        [
            "GET /users/me": currentUser,
            "GET /users/\(user.username)": user,
            "GET /users/\(user.username)/posts": Page(items: posts),
            "GET /users/\(user.username)/tagged": Page(items: tagged),
            "GET /users/\(user.username)/followers": Page(items: followers),
            "GET /users/\(user.username)/following": Page(items: following),
            "GET /me/saved": Page(items: saved),
            "PATCH /users/me": currentUser,
            "POST /users/me/username": currentUser
        ]
    }

    static func post(id: String, media: Media, caption: String?, author: User = currentUser) -> Post {
        Post(
            id: UUID(uuidString: id) ?? UUID(),
            author: author,
            media: [media],
            caption: caption,
            hashtags: caption.map { $0.split(separator: " ").compactMap { word in
                word.hasPrefix("#") ? String(word.dropFirst()).lowercased() : nil
            } } ?? [],
            counts: PostCounts(likes: 24, comments: 3),
            viewer: PostViewerState(hasLiked: false, hasSaved: false),
            commentsEnabled: true,
            createdAt: Date(timeIntervalSince1970: 1_758_000_000),
            editedAt: nil
        )
    }

    static func mediaURL(_ name: String) -> URL {
        URL(string: "https://preview.ibugram.invalid/media/\(name).jpg") ?? URL(fileURLWithPath: "/")
    }
}
