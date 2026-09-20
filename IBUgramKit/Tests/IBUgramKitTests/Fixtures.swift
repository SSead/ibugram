import Foundation
import IBUgramKit

enum Fixture {
    static let timestampText = "2026-09-20T07:31:12.482Z"
    static let timestamp = IBUgramDateCoding.date(from: timestampText) ?? Date(timeIntervalSince1970: 0)

    static let studentId = UUID(uuidString: "11111111-1111-4111-8111-111111111111") ?? UUID()
    static let facultyId = UUID(uuidString: "22222222-2222-4222-8222-222222222222") ?? UUID()
    static let postId = UUID(uuidString: "33333333-3333-4333-8333-333333333333") ?? UUID()
    static let mediaId = UUID(uuidString: "44444444-4444-4444-8444-444444444444") ?? UUID()
    static let spaceId = UUID(uuidString: "55555555-5555-4555-8555-555555555555") ?? UUID()
    static let eventId = UUID(uuidString: "66666666-6666-4666-8666-666666666666") ?? UUID()
    static let conversationId = UUID(uuidString: "77777777-7777-4777-8777-777777777777") ?? UUID()
    static let messageId = UUID(uuidString: "88888888-8888-4888-8888-888888888888") ?? UUID()

    static let student = User(
        id: studentId,
        username: "amina.h",
        displayName: "Amina Hodžić",
        avatarUrl: "http://127.0.0.1:8080/api/v1/media/\(mediaId.uuidString)",
        bio: "Third-year software engineering.",
        role: .student,
        department: "Information Technologies",
        yearOfStudy: 3,
        isVerified: false,
        counts: UserCounts(posts: 12, followers: 340, following: 180),
        viewer: UserViewerState(isFollowing: true, isFollowedBy: false, isBlocked: false),
        createdAt: timestamp
    )

    static let faculty = User(
        id: facultyId,
        username: "prof.kovac",
        displayName: "Prof. Kovač",
        role: .faculty,
        department: "Information Technologies",
        isVerified: true,
        counts: UserCounts(posts: 4, followers: 900, following: 12),
        createdAt: timestamp
    )

    static let media = Media(
        id: mediaId,
        url: "http://127.0.0.1:8080/api/v1/media/\(mediaId.uuidString)",
        thumbnailUrl: "http://127.0.0.1:8080/api/v1/media/\(mediaId.uuidString)/thumbnail",
        width: 1440,
        height: 1080,
        altText: "Students on the Burch campus lawn.",
        blurhash: "LEHV6nWB2yk8pyo0adR*.7kCMdnj"
    )

    static let spaceSummary = SpaceSummary(
        id: spaceId,
        slug: "burch-robotics",
        name: "Burch Robotics",
        avatarUrl: nil,
        isOfficial: true,
        memberCount: 64
    )

    static let place = Place(
        id: nil,
        name: "Burch Amphitheatre",
        latitude: 43.8186,
        longitude: 18.3564,
        isCampusLocation: true
    )

    static let event = Event(
        id: eventId,
        title: "Robotics Demo Night",
        description: "Line followers and a very confused drone.",
        startsAt: timestamp,
        endsAt: timestamp.addingTimeInterval(7200),
        place: place,
        capacity: 120,
        host: faculty,
        space: spaceSummary,
        counts: EventCounts(going: 41, interested: 87),
        viewer: EventViewerState(rsvp: .interested),
        postId: postId
    )

    static let post = Post(
        id: postId,
        author: student,
        media: [media],
        caption: "Demo night with @prof.kovac #robotics #burch",
        hashtags: ["robotics", "burch"],
        mentions: [faculty],
        space: spaceSummary,
        event: event,
        location: place,
        counts: PostCounts(likes: 128, comments: 9),
        viewer: PostViewerState(hasLiked: true, hasSaved: false),
        commentsEnabled: true,
        createdAt: timestamp,
        editedAt: timestamp.addingTimeInterval(60)
    )

    static let comment = Comment(
        id: UUID(uuidString: "99999999-9999-4999-8999-999999999999") ?? UUID(),
        postId: postId,
        author: faculty,
        body: "Excellent turnout.",
        parentId: nil,
        replyCount: 2,
        likeCount: 5,
        viewer: CommentViewerState(hasLiked: false),
        createdAt: timestamp
    )

    static let space = Space(
        id: spaceId,
        slug: "burch-robotics",
        name: "Burch Robotics",
        avatarUrl: nil,
        isOfficial: true,
        memberCount: 64,
        bannerUrl: nil,
        description: "The official robotics club.",
        kind: .club,
        visibility: .request,
        viewer: SpaceViewerState(membership: .moderator),
        createdBy: faculty,
        createdAt: timestamp
    )

    static let message = Message(
        id: messageId,
        conversationId: conversationId,
        sender: student,
        body: "See you at the demo?",
        media: [],
        delivery: .sent,
        readBy: [facultyId],
        createdAt: timestamp
    )

    static let conversation = Conversation(
        id: conversationId,
        kind: .direct,
        title: nil,
        avatarUrl: nil,
        participants: [student, faculty],
        lastMessage: message,
        unreadCount: 1,
        isRequest: false,
        updatedAt: timestamp
    )

    static let notification = IBUgramKit.Notification(
        id: UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa") ?? UUID(),
        kind: .like,
        actors: [faculty],
        groupCount: 5,
        post: post,
        comment: nil,
        space: spaceSummary,
        event: nil,
        isRead: false,
        createdAt: timestamp
    )

    static let authSession = AuthSession(
        accessToken: "header.payload.signature",
        refreshToken: "9f8e7d6c",
        expiresIn: 900,
        user: student,
        needsOnboarding: false
    )
}
