import Foundation
import Testing
@testable import ibugram

@Suite("Profile follow state")
@MainActor
struct ProfileViewModelTests {
    @Test("follow is applied immediately and kept when the request succeeds")
    func followSucceedsOptimistically() async {
        let client = ScriptedAPIClient(stubs: [
            "GET /users/d.kovac": ProfileFixtures.unfollowedFaculty,
            "GET /users/d.kovac/posts": Page<Post>(items: [])
        ])
        let viewModel = ProfileViewModel(
            api: client,
            username: ProfileFixtures.unfollowedFaculty.username,
            currentUser: ProfileFixtures.currentUser
        )
        await viewModel.load()
        #expect(viewModel.user?.viewer?.isFollowing == false)

        await viewModel.toggleFollow()

        #expect(viewModel.user?.viewer?.isFollowing == true)
        #expect(viewModel.user?.counts.followers == ProfileFixtures.unfollowedFaculty.counts.followers + 1)
        let calls = await client.recordedCalls()
        #expect(calls.contains { $0.hasPrefix("POST ") && $0.hasSuffix("/follow") })
    }

    @Test("a failed follow rolls the button and follower count back")
    func followFailureRollsBack() async {
        let faculty = ProfileFixtures.unfollowedFaculty
        let client = ScriptedAPIClient(
            stubs: [
                "GET /users/d.kovac": faculty,
                "GET /users/d.kovac/posts": Page<Post>(items: [])
            ],
            failures: [
                "POST /users/\(faculty.id.uuidString)/follow": .offline
            ]
        )
        let viewModel = ProfileViewModel(
            api: client,
            username: faculty.username,
            currentUser: ProfileFixtures.currentUser
        )
        await viewModel.load()

        await viewModel.toggleFollow()

        #expect(viewModel.user?.viewer?.isFollowing == false)
        #expect(viewModel.user?.counts.followers == faculty.counts.followers)
        #expect(viewModel.presentedError != nil)
    }

    @Test("unfollowing a followed account rolls back when the server rejects it")
    func unfollowFailureRollsBack() async {
        let student = ProfileFixtures.followedStudent
        let client = ScriptedAPIClient(
            stubs: [
                "GET /users/leila.m": student,
                "GET /users/leila.m/posts": Page<Post>(items: [])
            ],
            failures: [
                "DELETE /users/\(student.id.uuidString)/follow": .rateLimited(retryAfter: 5)
            ]
        )
        let viewModel = ProfileViewModel(
            api: client,
            username: student.username,
            currentUser: ProfileFixtures.currentUser
        )
        await viewModel.load()
        #expect(viewModel.user?.viewer?.isFollowing == true)

        await viewModel.toggleFollow()

        #expect(viewModel.user?.viewer?.isFollowing == true)
        #expect(viewModel.user?.counts.followers == student.counts.followers)
        #expect(viewModel.presentedError != nil)
    }
}

@Suite("Follow list follow buttons")
@MainActor
struct FollowListViewModelTests {
    @Test("inline follow rolls back when the request fails")
    func inlineFollowRollsBack() async {
        let student = ProfileFixtures.followedStudent.withFollowState(isFollowing: false)
        let client = ScriptedAPIClient(
            stubs: [
                "GET /users/amina.h/followers": Page(items: [student])
            ],
            failures: [
                "POST /users/\(student.id.uuidString)/follow": .offline
            ]
        )
        let viewModel = FollowListViewModel(
            api: client,
            username: ProfileFixtures.currentUser.username,
            kind: .followers,
            currentUserID: ProfileFixtures.currentUser.id
        )
        await viewModel.load()
        #expect(viewModel.isFollowing(student) == false)

        await viewModel.toggleFollow(student)

        #expect(viewModel.isFollowing(student) == false)
        #expect(viewModel.presentedError != nil)
    }
}
