import Foundation
import IBUgramKit

enum PostFixtures {
    static let rootComment = Comment(
        id: FeedFixtures.uuid("bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1"),
        postId: FeedFixtures.singleImage.id,
        author: SampleData.professorKovac,
        body: "Beautiful light on the lawn today.",
        parentId: nil,
        replyCount: 1,
        likeCount: 8,
        viewer: CommentViewerState(hasLiked: false),
        createdAt: Date(timeIntervalSinceNow: -90 * 60)
    )

    static let reply = Comment(
        id: FeedFixtures.uuid("bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2"),
        postId: FeedFixtures.singleImage.id,
        author: SampleData.amina,
        body: "Come sit with us next time!",
        parentId: rootComment.id,
        replyCount: 0,
        likeCount: 3,
        viewer: CommentViewerState(hasLiked: true),
        createdAt: Date(timeIntervalSinceNow: -70 * 60)
    )

    static let secondRoot = Comment(
        id: FeedFixtures.uuid("bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb3"),
        postId: FeedFixtures.singleImage.id,
        author: SampleData.amina,
        body: "Who is bringing a blanket for film night?",
        parentId: nil,
        replyCount: 0,
        likeCount: 2,
        viewer: CommentViewerState(hasLiked: false),
        createdAt: Date(timeIntervalSinceNow: -20 * 60)
    )

    static let comments: [Comment] = [rootComment, reply, secondRoot]

    static let facultyComments: [Comment] = [
        Comment(
            id: FeedFixtures.uuid("bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb4"),
            postId: FeedFixtures.facultyAuthor.id,
            author: SampleData.amina,
            body: "Will be there with the latest draft.",
            parentId: nil,
            replyCount: 0,
            likeCount: 5,
            viewer: CommentViewerState(hasLiked: false),
            createdAt: Date(timeIntervalSinceNow: -15 * 60)
        )
    ]
}
