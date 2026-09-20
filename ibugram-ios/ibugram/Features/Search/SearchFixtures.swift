import Foundation
import IBUgramKit

enum SearchFixtures {
    static let robotics = Hashtag(
        id: UUID(uuidString: "99999999-9999-4999-8999-999999999991") ?? UUID(),
        tag: "robotics",
        postCount: 128
    )
    static let burchLife = Hashtag(
        id: UUID(uuidString: "99999999-9999-4999-8999-999999999992") ?? UUID(),
        tag: "burchlife",
        postCount: 86
    )
    static let finals = Hashtag(
        id: UUID(uuidString: "99999999-9999-4999-8999-999999999993") ?? UUID(),
        tag: "finals",
        postCount: 41
    )

    static let trending = [burchLife, robotics, finals]

    static let roboticsSpace = SpaceSummary(
        id: UUID(uuidString: "77777777-7777-4777-8777-777777777777") ?? UUID(),
        slug: "ibu-robotics",
        name: "IBU Robotics",
        avatarUrl: nil,
        isOfficial: true,
        memberCount: 64
    )

    static let filmClub = SpaceSummary(
        id: UUID(uuidString: "88888888-8888-4888-8888-888888888888") ?? UUID(),
        slug: "ibu-film",
        name: "IBU Film Club",
        avatarUrl: nil,
        isOfficial: false,
        memberCount: 31
    )

    static let mixedResults = SearchResults(
        users: [ProfileFixtures.followedStudent, ProfileFixtures.unfollowedFaculty],
        hashtags: [robotics, burchLife],
        spaces: [roboticsSpace],
        posts: Array(ProfileFixtures.posts.prefix(4))
    )

    static let peopleResults = SearchResults(users: mixedResults.users)
    static let emptyResults = SearchResults()

    static var idleStubs: [String: any Sendable] {
        [
            "GET /users/me": ProfileFixtures.currentUser,
            "GET /search/trending": Paginated(items: trending),
            "GET /users/suggested": Paginated(items: [ProfileFixtures.followedStudent, ProfileFixtures.unfollowedFaculty]),
            "GET /search": mixedResults,
            "GET /hashtags/robotics/posts": Paginated(items: Array(ProfileFixtures.posts.prefix(4))),
            "GET /hashtags/burchlife/posts": Paginated(items: Array(ProfileFixtures.posts.prefix(3)))
        ]
    }

    static var emptySearchStubs: [String: any Sendable] {
        var stubs = idleStubs
        stubs["GET /search"] = emptyResults
        return stubs
    }
}
