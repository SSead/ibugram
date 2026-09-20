import Foundation

enum FeedFixtures {
    static let campusBlurhash = "LEHV6nWB2yk8pyo0adR*.7kCMdnj"

    static let robotics = SpaceSummary(
        id: uuid("44444444-4444-4444-8444-444444444444"),
        slug: "ibu-robotics",
        name: "IBU Robotics",
        avatarUrl: nil,
        isOfficial: true,
        memberCount: 186
    )

    static let campusLawn = Place(
        id: uuid("55555555-5555-4555-8555-555555555555"),
        name: "Campus lawn",
        latitude: 43.8246,
        longitude: 18.3114,
        isCampusLocation: true
    )

    static let cafeteria = Place(
        id: uuid("55555555-5555-4555-8555-555555555556"),
        name: "Cafeteria",
        latitude: 43.8249,
        longitude: 18.3118,
        isCampusLocation: true
    )

    static let lawnPhoto = Media(
        id: uuid("66666666-6666-4666-8666-666666666661"),
        url: url("https://media.ibugram.invalid/lawn.jpg"),
        thumbnailUrl: url("https://media.ibugram.invalid/lawn-thumb.jpg"),
        width: 1080,
        height: 1350,
        altText: "Students sitting on the Burch campus lawn in late afternoon light",
        blurhash: campusBlurhash
    )

    static let labPhoto = Media(
        id: uuid("66666666-6666-4666-8666-666666666662"),
        url: url("https://media.ibugram.invalid/lab.jpg"),
        thumbnailUrl: url("https://media.ibugram.invalid/lab-thumb.jpg"),
        width: 1080,
        height: 1080,
        altText: "A robotics arm on a workbench in the IBU lab",
        blurhash: campusBlurhash
    )

    static let hallPhoto = Media(
        id: uuid("66666666-6666-4666-8666-666666666663"),
        url: url("https://media.ibugram.invalid/hall.jpg"),
        thumbnailUrl: url("https://media.ibugram.invalid/hall-thumb.jpg"),
        width: 1600,
        height: 900,
        altText: "The main hall of International Burch University",
        blurhash: campusBlurhash
    )

    static let lecturePhoto = Media(
        id: uuid("66666666-6666-4666-8666-666666666664"),
        url: url("https://media.ibugram.invalid/lecture.jpg"),
        thumbnailUrl: url("https://media.ibugram.invalid/lecture-thumb.jpg"),
        width: 1080,
        height: 1350,
        altText: "Professor Kovač speaking to a lecture hall of software engineering students",
        blurhash: campusBlurhash
    )

    static let careerFair = Event(
        id: uuid("77777777-7777-4777-8777-777777777771"),
        title: "Career Fair",
        description: "Meet campus partners hiring this semester.",
        startsAt: Date(timeIntervalSinceNow: 45 * 60),
        endsAt: Date(timeIntervalSinceNow: 4 * 3_600),
        place: cafeteria,
        capacity: 200,
        host: SampleData.professorKovac,
        space: robotics,
        counts: EventCounts(going: 84, interested: 130),
        viewer: EventViewerState(rsvp: .interested),
        postId: nil
    )

    static let openDay = Event(
        id: uuid("77777777-7777-4777-8777-777777777772"),
        title: "Robotics open lab",
        description: "Drop in and see the competition robot.",
        startsAt: Date(timeIntervalSinceNow: -20 * 60),
        endsAt: Date(timeIntervalSinceNow: 90 * 60),
        place: campusLawn,
        capacity: 40,
        host: SampleData.amina,
        space: robotics,
        counts: EventCounts(going: 27, interested: 19),
        viewer: EventViewerState(rsvp: .going),
        postId: nil
    )

    static let filmNight = Event(
        id: uuid("77777777-7777-4777-8777-777777777773"),
        title: "Film night",
        description: "Outdoor screening on the lawn.",
        startsAt: Date(timeIntervalSinceNow: 3 * 3_600),
        endsAt: Date(timeIntervalSinceNow: 6 * 3_600),
        place: campusLawn,
        capacity: nil,
        host: SampleData.amina,
        space: nil,
        counts: EventCounts(going: 56, interested: 41),
        viewer: EventViewerState(rsvp: .none),
        postId: nil
    )

    static let happeningNow: [Event] = [openDay, careerFair, filmNight]

    static let singleImage = Post(
        id: uuid("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1"),
        author: SampleData.amina,
        media: [lawnPhoto],
        caption: "Golden hour on campus. #burchlife",
        hashtags: ["burchlife"],
        counts: PostCounts(likes: 128, comments: 14),
        viewer: PostViewerState(hasLiked: false, hasSaved: false),
        commentsEnabled: true,
        createdAt: Date(timeIntervalSinceNow: -2 * 3_600),
        editedAt: nil
    )

    static let carousel = Post(
        id: uuid("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2"),
        author: SampleData.amina,
        media: [labPhoto, hallPhoto, lawnPhoto],
        caption: "Build week with @d.kovac and the crew. #robotics #burch",
        hashtags: ["robotics", "burch"],
        counts: PostCounts(likes: 86, comments: 9),
        viewer: PostViewerState(hasLiked: false, hasSaved: true),
        commentsEnabled: true,
        createdAt: Date(timeIntervalSinceNow: -26 * 3_600),
        editedAt: nil
    )

    static let longCaption = Post(
        id: uuid("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa3"),
        author: SampleData.amina,
        media: [hallPhoto],
        caption: """
        If you are new this semester: the lawn fills up after 16:00, the cafeteria espresso is the reliable one, \
        and #burchlife is the tag that actually reaches people. Come say hi to @d.kovac at office hours in C-204, \
        bring questions about senior design, and do not be shy about joining a Space in your first week. \
        The campus is small enough that you will keep seeing the same faces — that is the whole point.
        """,
        hashtags: ["burchlife"],
        counts: PostCounts(likes: 54, comments: 6),
        viewer: PostViewerState(hasLiked: false, hasSaved: false),
        commentsEnabled: true,
        createdAt: Date(timeIntervalSinceNow: -5 * 86_400),
        editedAt: nil
    )

    static let facultyAuthor = Post(
        id: uuid("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa4"),
        author: SampleData.professorKovac,
        media: [lecturePhoto],
        caption: "Office hours moved to C-204 on Wednesday. Bring your #seniordesign drafts.",
        hashtags: ["seniordesign"],
        counts: PostCounts(likes: 312, comments: 41),
        viewer: PostViewerState(hasLiked: false, hasSaved: false),
        commentsEnabled: true,
        createdAt: Date(timeIntervalSinceNow: -40 * 60),
        editedAt: nil
    )

    static let liked = Post(
        id: uuid("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa5"),
        author: SampleData.amina,
        media: [labPhoto],
        caption: "Shipped the first demo. @d.kovac believed before we did.",
        hashtags: [],
        counts: PostCounts(likes: 201, comments: 22),
        viewer: PostViewerState(hasLiked: true, hasSaved: true),
        commentsEnabled: true,
        createdAt: Date(timeIntervalSinceNow: -12 * 60),
        editedAt: nil
    )

    static let following: [Post] = [liked, facultyAuthor, carousel, singleImage, longCaption]
    static let discover: [Post] = [facultyAuthor, singleImage, carousel]

    static var stubs: [String: any Sendable] {
        var stubs = SampleData.defaultStubs
        stubs["GET /feed/following"] = Page(items: following, nextCursor: nil)
        stubs["GET /feed/discover"] = Page(items: discover, nextCursor: "discover-2")
        stubs["GET /posts/\(singleImage.id)"] = singleImage
        stubs["GET /posts/\(carousel.id)"] = carousel
        stubs["GET /posts/\(longCaption.id)"] = longCaption
        stubs["GET /posts/\(facultyAuthor.id)"] = facultyAuthor
        stubs["GET /posts/\(liked.id)"] = liked
        stubs["GET /posts/\(singleImage.id)/comments"] = Page(items: PostFixtures.comments, nextCursor: nil)
        stubs["GET /posts/\(carousel.id)/comments"] = Page(items: PostFixtures.comments, nextCursor: nil)
        stubs["GET /posts/\(longCaption.id)/comments"] = Page<Comment>(items: [], nextCursor: nil)
        stubs["GET /posts/\(facultyAuthor.id)/comments"] = Page(items: PostFixtures.facultyComments, nextCursor: nil)
        stubs["GET /posts/\(liked.id)/comments"] = Page(items: PostFixtures.comments, nextCursor: nil)
        stubs["GET /posts/\(singleImage.id)/likes"] = Page(items: SampleData.users, nextCursor: nil)
        stubs["GET /posts/\(liked.id)/likes"] = Page(items: SampleData.users, nextCursor: nil)
        stubs["GET /posts/\(facultyAuthor.id)/likes"] = Page(items: SampleData.users, nextCursor: nil)
        return stubs
    }

    static func uuid(_ string: String) -> UUID {
        UUID(uuidString: string) ?? UUID()
    }

    static func url(_ string: String) -> URL {
        URL(string: string) ?? URL(fileURLWithPath: "/invalid")
    }
}
