import Foundation
import Testing
@testable import ibugram
import IBUgramKit

@Suite("Space join visibility")
@MainActor
struct SpaceJoinTests {
    @Test("joining a public Space becomes a member and increases the count")
    func publicJoinSucceedsOptimistically() async {
        let space = SpaceFixtures.robotics
        let client = ScriptedAPIClient(stubs: SpaceFixtures.detailStubs(for: space))
        let viewModel = SpaceDetailViewModel(api: client, slug: space.slug)
        await viewModel.load()

        await viewModel.join()

        #expect(viewModel.membership == .member)
        #expect(viewModel.space?.memberCount == space.memberCount + 1)
        let calls = await client.recordedCalls()
        #expect(calls.contains("POST /spaces/\(space.slug)/membership"))
    }

    @Test("joining a request Space becomes pending without changing the member count")
    func requestJoinBecomesPending() async {
        let space = SpaceFixtures.engineering
        let client = ScriptedAPIClient(stubs: SpaceFixtures.detailStubs(for: space))
        let viewModel = SpaceDetailViewModel(api: client, slug: space.slug)
        await viewModel.load()

        await viewModel.join()

        #expect(viewModel.membership == .pending)
        #expect(viewModel.space?.memberCount == space.memberCount)
        #expect(viewModel.canLeave)
        let calls = await client.recordedCalls()
        #expect(calls.contains("POST /spaces/\(space.slug)/membership"))
    }

    @Test("joining an invite-only Space is refused locally and never hits the API")
    func inviteJoinIsBlocked() async {
        let space = SpaceFixtures.facultyCircle
        let client = ScriptedAPIClient(stubs: SpaceFixtures.detailStubs(for: space))
        let viewModel = SpaceDetailViewModel(api: client, slug: space.slug)
        await viewModel.load()

        await viewModel.join()

        #expect(viewModel.membership == .none)
        #expect(viewModel.space?.memberCount == space.memberCount)
        #expect(viewModel.isInviteOnlyLocked)
        let calls = await client.recordedCalls()
        #expect(calls.contains { $0.hasPrefix("POST ") } == false)
    }

    @Test("a failed public join rolls membership and the member count back")
    func publicJoinFailureRollsBack() async {
        let space = SpaceFixtures.robotics
        let client = ScriptedAPIClient(
            stubs: SpaceFixtures.detailStubs(for: space),
            failures: ["POST /spaces/\(space.slug)/membership": .offline]
        )
        let viewModel = SpaceDetailViewModel(api: client, slug: space.slug)
        await viewModel.load()

        await viewModel.join()

        #expect(viewModel.membership == .none)
        #expect(viewModel.space?.memberCount == space.memberCount)
        #expect(viewModel.presentedError != nil)
    }

    @Test("leaving a member Space restores none and decrements the count")
    func leaveMemberSucceeds() async {
        let space = SpaceFixtures.filmClub
        let client = ScriptedAPIClient(stubs: SpaceFixtures.detailStubs(for: space))
        let viewModel = SpaceDetailViewModel(api: client, slug: space.slug)
        await viewModel.load()
        #expect(viewModel.membership == .member)

        await viewModel.leave()

        #expect(viewModel.membership == .none)
        #expect(viewModel.space?.memberCount == space.memberCount - 1)
        let calls = await client.recordedCalls()
        #expect(calls.contains("DELETE /spaces/\(space.slug)/membership"))
    }

    @Test("only faculty can mark a created Space as official")
    func officialToggleIsFacultyOnly() {
        let student = CreateSpaceViewModel(api: MockAPIClient(), currentUser: SampleData.amina)
        let faculty = CreateSpaceViewModel(api: MockAPIClient(), currentUser: SampleData.professorKovac)
        #expect(student.canMarkOfficial == false)
        #expect(faculty.canMarkOfficial)
    }
}

@Suite("Space join policy")
struct SpaceJoinPolicyTests {
    @Test("visibility maps onto the membership the join should produce")
    func joinResultsMatchVisibility() {
        #expect(SpaceJoinPolicy.result(ofJoining: .public) == .member)
        #expect(SpaceJoinPolicy.result(ofJoining: .request) == .pending)
        #expect(SpaceJoinPolicy.result(ofJoining: .invite) == nil)
    }
}
