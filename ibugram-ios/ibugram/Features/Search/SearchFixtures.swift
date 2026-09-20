import Foundation

enum SearchFixtures {
    static let robotics = Hashtag(tag: "robotics", postCount: 128)
    static let burchLife = Hashtag(tag: "burchlife", postCount: 86)
    static let finals = Hashtag(tag: "finals", postCount: 41)

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
            "GET /search/trending": Page(items: trending),
            "GET /users/suggested": Page(items: [ProfileFixtures.followedStudent, ProfileFixtures.unfollowedFaculty]),
            "GET /search": mixedResults,
            "GET /hashtags/robotics/posts": Page(items: Array(ProfileFixtures.posts.prefix(4))),
            "GET /hashtags/burchlife/posts": Page(items: Array(ProfileFixtures.posts.prefix(3)))
        ]
    }

    static var emptySearchStubs: [String: any Sendable] {
        var stubs = idleStubs
        stubs["GET /search"] = emptyResults
        return stubs
    }
}
