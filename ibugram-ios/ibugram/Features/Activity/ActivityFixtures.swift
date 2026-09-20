import Foundation
import IBUgramKit

enum ActivityFixtures {
    static let now = Date(timeIntervalSince1970: 1_779_638_400)

    static let likeToday = item(
        id: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1",
        kind: .like,
        actors: [ProfileFixtures.followedStudent, ProfileFixtures.unfollowedFaculty],
        groupCount: 5,
        post: ProfileFixtures.posts[0],
        isRead: false,
        createdAt: now.addingTimeInterval(-2 * 60 * 60)
    )

    static let commentToday = item(
        id: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2",
        kind: .comment,
        actors: [ProfileFixtures.unfollowedFaculty],
        groupCount: 1,
        post: ProfileFixtures.posts[1],
        comment: Comment(
            id: UUID(uuidString: "cccccccc-cccc-4ccc-8ccc-ccccccccccc1") ?? UUID(),
            postId: ProfileFixtures.posts[1].id,
            author: ProfileFixtures.unfollowedFaculty,
            body: "Excellent turnout.",
            parentId: nil,
            replyCount: 0,
            likeCount: 2,
            viewer: CommentViewerState(hasLiked: false),
            createdAt: now.addingTimeInterval(-3 * 60 * 60)
        ),
        isRead: false,
        createdAt: now.addingTimeInterval(-3 * 60 * 60)
    )

    static let followThisWeek = item(
        id: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb3",
        kind: .follow,
        actors: [ProfileFixtures.followedStudent],
        groupCount: 1,
        isRead: true,
        createdAt: now.addingTimeInterval(-2 * 24 * 60 * 60)
    )

    static let mentionThisWeek = item(
        id: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb4",
        kind: .mention,
        actors: [ProfileFixtures.followedStudent],
        groupCount: 1,
        post: ProfileFixtures.posts[2],
        isRead: true,
        createdAt: now.addingTimeInterval(-3 * 24 * 60 * 60)
    )

    static let spaceInviteEarlier = item(
        id: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb5",
        kind: .spaceInvite,
        actors: [ProfileFixtures.unfollowedFaculty],
        groupCount: 1,
        space: SearchFixtures.roboticsSpace,
        isRead: true,
        createdAt: now.addingTimeInterval(-20 * 24 * 60 * 60)
    )

    static let eventReminderEarlier = item(
        id: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb6",
        kind: .eventReminder,
        actors: [],
        groupCount: 0,
        event: Event(
            id: UUID(uuidString: "dddddddd-dddd-4ddd-8ddd-ddddddddddd1") ?? UUID(),
            title: "Robotics Demo Night",
            description: "Line followers and a very confused drone.",
            startsAt: now.addingTimeInterval(3_600),
            endsAt: now.addingTimeInterval(10_800),
            place: Place(
                id: nil,
                name: "Burch Amphitheatre",
                latitude: 43.8186,
                longitude: 18.3564,
                isCampusLocation: true
            ),
            capacity: 120,
            host: ProfileFixtures.unfollowedFaculty,
            space: SearchFixtures.roboticsSpace,
            counts: EventCounts(going: 41, interested: 87),
            viewer: EventViewerState(rsvp: .interested),
            postId: ProfileFixtures.posts[1].id
        ),
        isRead: false,
        createdAt: now.addingTimeInterval(-30 * 24 * 60 * 60)
    )

    static let replyToday = item(
        id: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb7",
        kind: .reply,
        actors: [ProfileFixtures.followedStudent],
        groupCount: 1,
        post: ProfileFixtures.posts[0],
        comment: Comment(
            id: UUID(uuidString: "cccccccc-cccc-4ccc-8ccc-ccccccccccc2") ?? UUID(),
            postId: ProfileFixtures.posts[0].id,
            author: ProfileFixtures.followedStudent,
            body: "See you there!",
            parentId: UUID(uuidString: "cccccccc-cccc-4ccc-8ccc-ccccccccccc1"),
            replyCount: 0,
            likeCount: 0,
            viewer: CommentViewerState(hasLiked: false),
            createdAt: now.addingTimeInterval(-40 * 60)
        ),
        isRead: true,
        createdAt: now.addingTimeInterval(-40 * 60)
    )

    static let all: [IBUgramKit.Notification] = [
        replyToday,
        likeToday,
        commentToday,
        followThisWeek,
        mentionThisWeek,
        spaceInviteEarlier,
        eventReminderEarlier
    ]

    static var stubs: [String: any Sendable] {
        [
            "GET /users/me": ProfileFixtures.currentUser,
            "GET /notifications": Paginated(items: all),
            "GET /notifications/unread-count": UnreadCount(count: 3)
        ]
    }

    static var emptyStubs: [String: any Sendable] {
        [
            "GET /users/me": ProfileFixtures.currentUser,
            "GET /notifications": Paginated<IBUgramKit.Notification>(items: []),
            "GET /notifications/unread-count": UnreadCount(count: 0)
        ]
    }

    static func item(
        id: String,
        kind: NotificationKind,
        actors: [User],
        groupCount: Int,
        post: Post? = nil,
        comment: Comment? = nil,
        space: SpaceSummary? = nil,
        event: Event? = nil,
        isRead: Bool,
        createdAt: Date
    ) -> IBUgramKit.Notification {
        IBUgramKit.Notification(
            id: UUID(uuidString: id) ?? UUID(),
            kind: kind,
            actors: actors,
            groupCount: groupCount,
            post: post,
            comment: comment,
            space: space,
            event: event,
            isRead: isRead,
            createdAt: createdAt
        )
    }
}
