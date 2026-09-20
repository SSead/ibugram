import Fluent
import Foundation
import IBUgramKit
import SQLKit
import Testing
import Vapor
import VaporTesting
@testable import App

actor CommunityDatabaseAccess {
    static let shared = CommunityDatabaseAccess()

    private var isHeld = false
    private var waiting: [CheckedContinuation<Void, Never>] = []

    func acquire() async {
        guard isHeld else {
            isHeld = true
            return
        }
        await withCheckedContinuation { waiting.append($0) }
    }

    func release() {
        if waiting.isEmpty {
            isHeld = false
        } else {
            waiting.removeFirst().resume()
        }
    }
}

actor CommunityTestDatabase {
    static let shared = CommunityTestDatabase()

    private var isPrepared = false

    func prepareSchema(on app: Application) async throws {
        guard !isPrepared else { return }
        guard let sql = app.db as? any SQLDatabase else { return }
        try await sql.raw("DROP SCHEMA IF EXISTS public CASCADE").run()
        try await sql.raw("CREATE SCHEMA public").run()
        try await app.autoMigrate()
        isPrepared = true
    }
}

func withCommunityTestServer<T>(
    _ body: (TestContext) async throws -> T
) async throws -> T {
    await CommunityDatabaseAccess.shared.acquire()
    do {
        let result = try await runCommunityServer(body)
        await CommunityDatabaseAccess.shared.release()
        return result
    } catch {
        await CommunityDatabaseAccess.shared.release()
        throw error
    }
}

private func runCommunityServer<T>(
    _ body: (TestContext) async throws -> T
) async throws -> T {
    let app = try await Application.make(.testing)
    do {
        var configuration = TestSupport.configuration(for: .testing)
        configuration.database.database = "ibugram_test_spaces"
        configuration.mediaDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ibugram-test-media-spaces", isDirectory: true)
        try await configure(app, using: configuration)
        try await CommunityTestDatabase.shared.prepareSchema(on: app)
        try await truncateCommunity(on: app)

        let codes = SentCodeLog()
        var dependencies = app.dependencies
        dependencies.emailSender = codes
        dependencies.otp = OTPService(emailSender: codes, hashCost: 4)
        app.dependencies = dependencies

        let result = try await body(TestContext(app: app, codes: codes))
        try await app.asyncShutdown()
        return result
    } catch {
        try? await app.asyncShutdown()
        throw TestFailure(detail: String(reflecting: error))
    }
}

private func truncateCommunity(on app: Application) async throws {
    guard let sql = app.db as? any SQLDatabase else { return }
    let list = TestSupport.tables.joined(separator: ", ")
    try await sql.raw("TRUNCATE TABLE \(unsafeRaw: list) RESTART IDENTITY CASCADE").run()
    await app.dependencies.authRateLimiter.reset()
}

extension TestContext {
    func createSpace(
        token: String,
        slug: String,
        name: String = "Robotics Club",
        kind: SpaceKind = .club,
        visibility: SpaceVisibility = .public,
        isOfficial: Bool = false
    ) async throws -> TestingHTTPResponse {
        try await app.testing().sendRequest(
            .POST,
            API.Spaces.create.fullPath,
            headers: authorized(token),
            beforeRequest: {
                try $0.content.encode(CreateSpaceBody(
                    slug: slug,
                    name: name,
                    kind: kind,
                    visibility: visibility,
                    isOfficial: isOfficial
                ))
            }
        )
    }
}

@Suite("Spaces", .serialized)
struct SpaceTests {
    private let student = "amina.hodzic@stu.ibu.edu.ba"
    private let faculty = "e.kovac@ibu.edu.ba"
    private let other = "second.student@stu.ibu.edu.ba"

    @Test("A student can create a community space and browse it")
    func studentCreatesAndBrowses() async throws {
        try await withCommunityTestServer { context in
            let session = try await context.signIn(as: student)
            let created = try await context.createSpace(token: session.accessToken, slug: "robotics")
            #expect(created.status == .created)
            let space = try created.content.decode(Space.self)
            #expect(space.slug == "robotics")
            #expect(space.isOfficial == false)
            #expect(space.viewer?.membership == .owner)
            #expect(space.memberCount == 1)

            let list = try await context.app.testing().sendRequest(
                .GET,
                API.Spaces.browse.fullPath + "?kind=club",
                headers: context.authorized(session.accessToken)
            )
            #expect(list.status == .ok)
            let page = try list.content.decode(Paginated<Space>.self)
            #expect(page.items.count == 1)
            #expect(page.items[0].viewer?.membership == .owner)
        }
    }

    @Test("Unauthenticated space requests are rejected")
    func spacesRequireAuth() async throws {
        try await withCommunityTestServer { context in
            let browse = try await context.app.testing().sendRequest(.GET, API.Spaces.browse.fullPath)
            #expect(browse.status == .unauthorized)
            let create = try await context.app.testing().sendRequest(.POST, API.Spaces.create.fullPath)
            #expect(create.status == .unauthorized)
            let detail = try await context.app.testing().sendRequest(.GET, API.Spaces.detail(slug: "x").fullPath)
            #expect(detail.status == .unauthorized)
            let update = try await context.app.testing().sendRequest(.PATCH, API.Spaces.update(slug: "x").fullPath)
            #expect(update.status == .unauthorized)
            let posts = try await context.app.testing().sendRequest(.GET, API.Spaces.posts(slug: "x").fullPath)
            #expect(posts.status == .unauthorized)
            let members = try await context.app.testing().sendRequest(.GET, API.Spaces.members(slug: "x").fullPath)
            #expect(members.status == .unauthorized)
            let join = try await context.app.testing().sendRequest(.POST, API.Spaces.join(slug: "x").fullPath)
            #expect(join.status == .unauthorized)
            let leave = try await context.app.testing().sendRequest(.DELETE, API.Spaces.leave(slug: "x").fullPath)
            #expect(leave.status == .unauthorized)
            let role = try await context.app.testing().sendRequest(
                .POST,
                API.Spaces.setMemberRole(slug: "x", userId: UUID()).fullPath
            )
            #expect(role.status == .unauthorized)
        }
    }

    @Test("A student is refused an official Space")
    func studentCannotCreateOfficialSpace() async throws {
        try await withCommunityTestServer { context in
            let session = try await context.signIn(as: student)
            let response = try await context.createSpace(
                token: session.accessToken,
                slug: "official-it",
                isOfficial: true
            )
            #expect(response.status == .forbidden)
            #expect(response.apiError?.code == .forbidden)
        }
    }

    @Test("Faculty can create an official Space")
    func facultyCreatesOfficialSpace() async throws {
        try await withCommunityTestServer { context in
            let session = try await context.signIn(as: faculty)
            let response = try await context.createSpace(
                token: session.accessToken,
                slug: "it-department",
                name: "IT Department",
                kind: .department,
                isOfficial: true
            )
            #expect(response.status == .created)
            #expect(try response.content.decode(Space.self).isOfficial == true)
        }
    }

    @Test("A non-member cannot read posts of an invite-only Space")
    func invitePostsAreHidden() async throws {
        try await withCommunityTestServer { context in
            let owner = try await context.signIn(as: faculty)
            let created = try await context.createSpace(
                token: owner.accessToken,
                slug: "staff-only",
                visibility: .invite
            )
            #expect(created.status == .created)
            let space = try created.content.decode(Space.self)

            let post = PostRecord()
            post.id = UUID()
            post.$author.id = owner.user.id
            post.$space.id = space.id
            post.commentsEnabled = true
            post.isArchived = false
            post.likeCount = 0
            post.commentCount = 0
            try await post.save(on: context.app.db)

            let ownerPosts = try await context.app.testing().sendRequest(
                .GET,
                API.Spaces.posts(slug: "staff-only").fullPath,
                headers: context.authorized(owner.accessToken)
            )
            #expect(ownerPosts.status == .ok)
            #expect(try ownerPosts.content.decode(Paginated<Post>.self).items.count == 1)

            let outsider = try await context.signIn(as: student)
            let posts = try await context.app.testing().sendRequest(
                .GET,
                API.Spaces.posts(slug: "staff-only").fullPath,
                headers: context.authorized(outsider.accessToken)
            )
            #expect(posts.status == .forbidden)
            #expect(posts.apiError?.code == .forbidden)

            let join = try await context.app.testing().sendRequest(
                .POST,
                API.Spaces.join(slug: "staff-only").fullPath,
                headers: context.authorized(outsider.accessToken)
            )
            #expect(join.status == .forbidden)
        }
    }

    @Test("A pending membership can be approved by an owner")
    func pendingMembershipIsApproved() async throws {
        try await withCommunityTestServer { context in
            let owner = try await context.signIn(as: faculty)
            _ = try await context.createSpace(
                token: owner.accessToken,
                slug: "photo-club",
                visibility: .request
            )
            let applicant = try await context.signIn(as: student)
            let join = try await context.app.testing().sendRequest(
                .POST,
                API.Spaces.join(slug: "photo-club").fullPath,
                headers: context.authorized(applicant.accessToken)
            )
            #expect(join.status == .ok)
            #expect(try join.content.decode(Space.self).viewer?.membership == .pending)

            let members = try await context.app.testing().sendRequest(
                .GET,
                API.Spaces.members(slug: "photo-club").fullPath,
                headers: context.authorized(owner.accessToken)
            )
            let pending = try members.content.decode(Paginated<SpaceMember>.self).items
                .first { $0.user.id == applicant.user.id }
            #expect(pending?.role == .pending)

            let approval = try await context.app.testing().sendRequest(
                .POST,
                API.Spaces.setMemberRole(slug: "photo-club", userId: applicant.user.id).fullPath,
                headers: context.authorized(owner.accessToken),
                beforeRequest: { try $0.content.encode(SetSpaceMemberRoleBody(role: .member)) }
            )
            #expect(approval.status == .ok)
            #expect(try approval.content.decode(SpaceMember.self).role == .member)

            let after = try await context.app.testing().sendRequest(
                .GET,
                API.Spaces.detail(slug: "photo-club").fullPath,
                headers: context.authorized(applicant.accessToken)
            )
            #expect(try after.content.decode(Space.self).viewer?.membership == .member)
        }
    }

    @Test("The last owner cannot leave a Space")
    func lastOwnerCannotLeave() async throws {
        try await withCommunityTestServer { context in
            let session = try await context.signIn(as: faculty)
            _ = try await context.createSpace(token: session.accessToken, slug: "last-owner")
            let leave = try await context.app.testing().sendRequest(
                .DELETE,
                API.Spaces.leave(slug: "last-owner").fullPath,
                headers: context.authorized(session.accessToken)
            )
            #expect(leave.status == .forbidden)
            #expect(leave.apiError?.code == .forbidden)
        }
    }

    @Test("A moderator cannot demote an owner")
    func moderatorCannotDemoteOwner() async throws {
        try await withCommunityTestServer { context in
            let owner = try await context.signIn(as: faculty)
            _ = try await context.createSpace(token: owner.accessToken, slug: "club")
            let moderator = try await context.signIn(as: student)
            _ = try await context.app.testing().sendRequest(
                .POST,
                API.Spaces.join(slug: "club").fullPath,
                headers: context.authorized(moderator.accessToken)
            )
            _ = try await context.app.testing().sendRequest(
                .POST,
                API.Spaces.setMemberRole(slug: "club", userId: moderator.user.id).fullPath,
                headers: context.authorized(owner.accessToken),
                beforeRequest: { try $0.content.encode(SetSpaceMemberRoleBody(role: .moderator)) }
            )
            let demote = try await context.app.testing().sendRequest(
                .POST,
                API.Spaces.setMemberRole(slug: "club", userId: owner.user.id).fullPath,
                headers: context.authorized(moderator.accessToken),
                beforeRequest: { try $0.content.encode(SetSpaceMemberRoleBody(role: .member)) }
            )
            #expect(demote.status == .forbidden)
            #expect(demote.apiError?.code == .forbidden)
        }
    }

    @Test("A non-moderator cannot patch a Space")
    func patchRequiresModerator() async throws {
        try await withCommunityTestServer { context in
            let owner = try await context.signIn(as: faculty)
            _ = try await context.createSpace(token: owner.accessToken, slug: "club")
            let member = try await context.signIn(as: student)
            _ = try await context.app.testing().sendRequest(
                .POST,
                API.Spaces.join(slug: "club").fullPath,
                headers: context.authorized(member.accessToken)
            )
            let patch = try await context.app.testing().sendRequest(
                .PATCH,
                API.Spaces.update(slug: "club").fullPath,
                headers: context.authorized(member.accessToken),
                beforeRequest: { try $0.content.encode(UpdateSpaceBody(name: "Hacked")) }
            )
            #expect(patch.status == .forbidden)
        }
    }

    @Test("Public join is immediate and leave works for a non-owner")
    func publicJoinAndLeave() async throws {
        try await withCommunityTestServer { context in
            let owner = try await context.signIn(as: faculty)
            _ = try await context.createSpace(token: owner.accessToken, slug: "open-club")
            let member = try await context.signIn(as: other)
            let join = try await context.app.testing().sendRequest(
                .POST,
                API.Spaces.join(slug: "open-club").fullPath,
                headers: context.authorized(member.accessToken)
            )
            #expect(try join.content.decode(Space.self).viewer?.membership == .member)
            let leave = try await context.app.testing().sendRequest(
                .DELETE,
                API.Spaces.leave(slug: "open-club").fullPath,
                headers: context.authorized(member.accessToken)
            )
            #expect(leave.status == .noContent)
        }
    }
}
