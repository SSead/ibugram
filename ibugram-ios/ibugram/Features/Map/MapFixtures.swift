import Foundation
import IBUgramKit

enum MapFixtures {
    static let contents = MapContents(
        events: [EventFixtures.openDay, EventFixtures.careerFair, EventFixtures.filmNight],
        posts: [FeedFixtures.singleImage, FeedFixtures.facultyAuthor, FeedFixtures.liked]
    )

    static var stubs: [String: any Sendable] {
        var stubs = EventFixtures.listStubs
        stubs["GET /events/map"] = contents
        stubs["GET /posts/\(FeedFixtures.singleImage.id.uuidString)"] = FeedFixtures.singleImage
        stubs["GET /posts/\(FeedFixtures.facultyAuthor.id.uuidString)"] = FeedFixtures.facultyAuthor
        stubs["GET /posts/\(FeedFixtures.liked.id.uuidString)"] = FeedFixtures.liked
        return stubs
    }
}
