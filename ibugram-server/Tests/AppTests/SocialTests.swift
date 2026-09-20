import Fluent
import Foundation
import IBUgramKit
import SQLKit
import Testing
import Vapor
import VaporTesting
@testable import App

actor SocialTestDatabase {
    static let shared = SocialTestDatabase()
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

func socialTestConfiguration() -> AppConfiguration {
    var configuration = TestSupport.configuration(for: .testing)
    configuration.database.database = "ibugram_test_social"
    configuration.publicBaseURL = "http://127.0.0.1:8091"
    return configuration
}

func withSocialTestServer<T>(_ body: (TestContext) async throws -> T) async throws -> T {
    await ExclusiveDatabaseAccess.shared.acquire()
    do {
        let result = try await runSocialServer(body)
        await ExclusiveDatabaseAccess.shared.release()
        return result
    } catch {
        await ExclusiveDatabaseAccess.shared.release()
        throw error
    }
}

private func runSocialServer<T>(_ body: (TestContext) async throws -> T) async throws -> T {
    let app = try await Application.make(.testing)
    do {
        try await configure(app, using: socialTestConfiguration())
        try await SocialTestDatabase.shared.prepareSchema(on: app)
        if let sql = app.db as? any SQLDatabase {
            let list = TestSupport.tables.joined(separator: ", ")
            try await sql.raw("TRUNCATE TABLE \(unsafeRaw: list) RESTART IDENTITY CASCADE").run()
        }
        await app.dependencies.authRateLimiter.reset()

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

extension TestContext {
    func completeOnboarding(
        _ session: AuthSession,
        username: String,
        displayName: String,
        department: String? = "Information Technologies"
    ) async throws {
        _ = try await app.testing().sendRequest(
            .PATCH,
            API.Users.updateMe.fullPath,
            headers: authorized(session.accessToken),
            beforeRequest: {
                try $0.content.encode(UpdateProfileBody(displayName: displayName, department: department))
            }
        )
        let response = try await app.testing().sendRequest(
            .POST,
            API.Users.setUsername.fullPath,
            headers: authorized(session.accessToken),
            beforeRequest: { try $0.content.encode(SetUsernameBody(username: username)) }
        )
        #expect(response.status == .ok)
    }

    func insertMedia(for userId: UUID) async throws -> UUID {
        let media = MediaRecord(
            id: UUID(),
            uploadedById: userId,
            storageKey: "test/\(UUID().uuidString).jpg",
            thumbnailStorageKey: "test/\(UUID().uuidString)-thumb.jpg",
            contentType: "image/jpeg",
            byteSize: 128,
            width: 100,
            height: 100,
            altText: "campus"
        )
        try await media.create(on: app.db)
        return try media.requireID()
    }

    func createPost(
        token: String,
        userId: UUID,
        caption: String? = "hello campus"
    ) async throws -> Post {
        let mediaId = try await insertMedia(for: userId)
        let response = try await app.testing().sendRequest(
            .POST,
            API.Posts.create.fullPath,
            headers: authorized(token),
            beforeRequest: {
                try $0.content.encode(CreatePostBody(mediaIds: [mediaId], caption: caption))
            }
        )
        if response.status != .created {
            throw TestFailure(detail: "POST /posts \(response.status): \(response.body.string)")
        }
        return try response.content.decode(Post.self)
    }

    func get(_ path: String, token: String? = nil) async throws -> TestingHTTPResponse {
        if let token {
            return try await app.testing().sendRequest(.GET, path, headers: authorized(token))
        }
        return try await app.testing().sendRequest(.GET, path)
    }

    func send(
        _ method: HTTPMethod,
        _ path: String,
        token: String? = nil,
        body: (any Content)? = nil
    ) async throws -> TestingHTTPResponse {
        try await app.testing().sendRequest(method, path, headers: token.map(authorized) ?? HTTPHeaders()) {
            if let body {
                try $0.content.encode(body)
            }
        }
    }
}

extension TestingHTTPResponse {
    func decodeJSON<T: Decodable>(_ type: T.Type) throws -> T {
        try JSONDecoder.ibugram.decode(T.self, from: Data(buffer: body))
    }
}

@Suite("Social graph", .serialized)
struct SocialTests {
    @Test("A public profile is returned with viewer relationship flags")
    func profileIsReturned() async throws {
        try await withSocialTestServer { context in
            let amina = try await context.signIn(as: "amina.hodzic@stu.ibu.edu.ba")
            try await context.completeOnboarding(amina, username: "amina.h", displayName: "Amina")
            let emir = try await context.signIn(as: "emir.k@stu.ibu.edu.ba")
            try await context.completeOnboarding(emir, username: "emir.k", displayName: "Emir")

            let follow = try await context.send(.POST, API.Users.follow(id: amina.user.id).fullPath, token: emir.accessToken)
            #expect(follow.status == .noContent)

            let response = try await context.get(API.Users.profile(username: "amina.h").fullPath, token: emir.accessToken)
            #expect(response.status == .ok)
            let user = try response.content.decode(IBUgramKit.User.self)
            #expect(user.username == "amina.h")
            #expect(user.viewer?.isFollowing == true)
            #expect(user.counts.followers == 1)
        }
    }

    @Test("Profile, follow and block endpoints reject a missing token")
    func graphRequiresAuthentication() async throws {
        try await withSocialTestServer { context in
            let id = UUID()
            let paths: [(HTTPMethod, String)] = [
                (.GET, API.Users.profile(username: "amina.h").fullPath),
                (.GET, API.Users.posts(username: "amina.h").fullPath),
                (.GET, API.Users.followers(username: "amina.h").fullPath),
                (.GET, API.Users.following(username: "amina.h").fullPath),
                (.POST, API.Users.follow(id: id).fullPath),
                (.DELETE, API.Users.unfollow(id: id).fullPath),
                (.POST, API.Users.block(id: id).fullPath),
                (.DELETE, API.Users.unblock(id: id).fullPath),
                (.GET, API.Users.suggested.fullPath)
            ]
            for (method, path) in paths {
                let response = try await context.send(method, path)
                #expect(response.status == .unauthorized)
            }
        }
    }

    @Test("Username availability is public and reports taken names")
    func usernameAvailabilityIsPublic() async throws {
        try await withSocialTestServer { context in
            let open = try await context.get("/api/v1/users/fresh.name/available")
            #expect(open.status == .ok)
            #expect(try open.content.decode(UsernameAvailability.self).available)

            let amina = try await context.signIn(as: "amina.hodzic@stu.ibu.edu.ba")
            try await context.completeOnboarding(amina, username: "amina.h", displayName: "Amina")
            let taken = try await context.get("/api/v1/users/amina.h/available")
            #expect(try taken.content.decode(UsernameAvailability.self).available == false)
        }
    }

    @Test("Following is idempotent and unfollow clears the edge")
    func followAndUnfollow() async throws {
        try await withSocialTestServer { context in
            let amina = try await context.signIn(as: "amina.hodzic@stu.ibu.edu.ba")
            try await context.completeOnboarding(amina, username: "amina.h", displayName: "Amina")
            let emir = try await context.signIn(as: "emir.k@stu.ibu.edu.ba")
            try await context.completeOnboarding(emir, username: "emir.k", displayName: "Emir")

            let path = API.Users.follow(id: amina.user.id).fullPath
            #expect(try await context.send(.POST, path, token: emir.accessToken).status == .noContent)
            #expect(try await context.send(.POST, path, token: emir.accessToken).status == .noContent)

            let following = try await context.get(API.Users.following(username: "emir.k").fullPath, token: emir.accessToken)
            #expect(try following.content.decode(Paginated<IBUgramKit.User>.self).items.map(\.username) == ["amina.h"])

            #expect(try await context.send(.DELETE, path, token: emir.accessToken).status == .noContent)
            let after = try await context.get(API.Users.profile(username: "amina.h").fullPath, token: emir.accessToken)
            #expect(try after.content.decode(IBUgramKit.User.self).viewer?.isFollowing == false)
        }
    }

    @Test("A user cannot follow themselves")
    func selfFollowIsRejected() async throws {
        try await withSocialTestServer { context in
            let amina = try await context.signIn(as: "amina.hodzic@stu.ibu.edu.ba")
            try await context.completeOnboarding(amina, username: "amina.h", displayName: "Amina")
            let response = try await context.send(.POST, API.Users.follow(id: amina.user.id).fullPath, token: amina.accessToken)
            #expect(response.status == .unprocessableEntity)
        }
    }

    @Test("Blocking hides the target and drops both follow edges")
    func blockRemovesFollows() async throws {
        try await withSocialTestServer { context in
            let amina = try await context.signIn(as: "amina.hodzic@stu.ibu.edu.ba")
            try await context.completeOnboarding(amina, username: "amina.h", displayName: "Amina")
            let emir = try await context.signIn(as: "emir.k@stu.ibu.edu.ba")
            try await context.completeOnboarding(emir, username: "emir.k", displayName: "Emir")
            _ = try await context.send(.POST, API.Users.follow(id: amina.user.id).fullPath, token: emir.accessToken)

            let blocked = try await context.send(.POST, API.Users.block(id: emir.user.id).fullPath, token: amina.accessToken)
            #expect(blocked.status == .noContent)

            let hidden = try await context.get(API.Users.profile(username: "amina.h").fullPath, token: emir.accessToken)
            #expect(hidden.status == .notFound)

            let profile = try await context.get(API.Users.profile(username: "emir.k").fullPath, token: amina.accessToken)
            #expect(try profile.content.decode(IBUgramKit.User.self).viewer?.isBlocked == true)

            #expect(try await context.send(.DELETE, API.Users.block(id: emir.user.id).fullPath, token: amina.accessToken).status == .noContent)
        }
    }

    @Test("Suggested users are same-department people the viewer does not follow")
    func suggestedUsersMatchDepartment() async throws {
        try await withSocialTestServer { context in
            let amina = try await context.signIn(as: "amina.hodzic@stu.ibu.edu.ba")
            try await context.completeOnboarding(amina, username: "amina.h", displayName: "Amina", department: "IT")
            let emir = try await context.signIn(as: "emir.k@stu.ibu.edu.ba")
            try await context.completeOnboarding(emir, username: "emir.k", displayName: "Emir", department: "IT")
            let lejla = try await context.signIn(as: "lejla.s@stu.ibu.edu.ba")
            try await context.completeOnboarding(lejla, username: "lejla.s", displayName: "Lejla", department: "Law")

            let response = try await context.get(API.Users.suggested.fullPath, token: amina.accessToken)
            #expect(response.status == .ok)
            let usernames = try response.content.decode(Paginated<IBUgramKit.User>.self).items.map(\.username)
            #expect(usernames.contains("emir.k"))
            #expect(!usernames.contains("lejla.s"))
            #expect(!usernames.contains("amina.h"))
        }
    }

    @Test("Followers and following lists paginate with a stable cursor")
    func followListsPaginate() async throws {
        try await withSocialTestServer { context in
            let amina = try await context.signIn(as: "amina.hodzic@stu.ibu.edu.ba")
            try await context.completeOnboarding(amina, username: "amina.h", displayName: "Amina")
            var others: [AuthSession] = []
            for index in 1...3 {
                let session = try await context.signIn(as: "student\(index)@stu.ibu.edu.ba")
                try await context.completeOnboarding(session, username: "stu\(index)", displayName: "Student \(index)")
                _ = try await context.send(.POST, API.Users.follow(id: amina.user.id).fullPath, token: session.accessToken)
                others.append(session)
            }
            let first = try await context.get(
                API.Users.followers(username: "amina.h").fullPath + "?limit=2",
                token: amina.accessToken
            )
            let page = try first.content.decode(Paginated<IBUgramKit.User>.self)
            #expect(page.items.count == 2)
            let cursor = try #require(page.nextCursor)

            let second = try await context.get(
                API.Users.followers(username: "amina.h").fullPath + "?limit=2&cursor=\(cursor)",
                token: amina.accessToken
            )
            let rest = try second.content.decode(Paginated<IBUgramKit.User>.self)
            #expect(rest.items.count == 1)
            #expect(rest.nextCursor == nil)
            let overlap = Set(page.items.map(\.id)).intersection(rest.items.map(\.id))
            #expect(overlap.isEmpty)
        }
    }
}
