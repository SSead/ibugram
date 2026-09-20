import Fluent
import Foundation
import IBUgramKit
import Testing
import Vapor
import VaporTesting
@testable import App

@Suite("Refresh tokens and sessions", .serialized)
struct SessionTests {
    private let student = "amina.hodzic@stu.ibu.edu.ba"

    private func refresh(_ context: TestContext, token: String) async throws -> TestingHTTPResponse {
        try await context.app.testing().sendRequest(
            .POST,
            API.Auth.refresh.fullPath,
            beforeRequest: { try $0.content.encode(RefreshTokenBody(refreshToken: token)) }
        )
    }

    @Test("Refreshing rotates the token and returns a working access token")
    func refreshRotates() async throws {
        try await withTestServer { context in
            let first = try await context.signIn(as: student)
            let response = try await refresh(context, token: first.refreshToken)
            #expect(response.status == .ok)

            let second = try response.content.decode(AuthSession.self)
            #expect(second.refreshToken != first.refreshToken)
            #expect(second.user.id == first.user.id)

            let profile = try await context.app.testing().sendRequest(
                .GET,
                API.Users.me.fullPath,
                headers: context.authorized(second.accessToken)
            )
            #expect(profile.status == .ok)
        }
    }

    @Test("The rotated-away refresh token stops working")
    func oldTokenIsRejected() async throws {
        try await withTestServer { context in
            let first = try await context.signIn(as: student)
            _ = try await refresh(context, token: first.refreshToken)

            let replay = try await refresh(context, token: first.refreshToken)
            #expect(replay.status == .unauthorized)
            #expect(replay.apiError?.code == .unauthorized)
        }
    }

    @Test("Replaying a rotated token revokes the whole session family")
    func reuseRevokesFamily() async throws {
        try await withTestServer { context in
            let first = try await context.signIn(as: student)
            let second = try await refresh(context, token: first.refreshToken)
                .content.decode(AuthSession.self)

            _ = try await refresh(context, token: first.refreshToken)

            let liveTokenAfterBreach = try await refresh(context, token: second.refreshToken)
            #expect(liveTokenAfterBreach.status == .unauthorized)

            let sessions = try await AuthSessionRecord.query(on: context.app.db).all()
            #expect(sessions.allSatisfy { $0.revokedAt != nil })
            #expect(sessions.contains { $0.revokedReason == .reuseDetected })
        }
    }

    @Test("An unknown refresh token is rejected without revealing anything")
    func unknownTokenIsRejected() async throws {
        try await withTestServer { context in
            let response = try await refresh(context, token: "not-a-real-token")
            #expect(response.status == .unauthorized)
        }
    }

    @Test("Refresh tokens are stored only as hashes")
    func refreshTokensAreHashed() async throws {
        try await withTestServer { context in
            let session = try await context.signIn(as: student)
            let stored = try #require(try await AuthSessionRecord.query(on: context.app.db).first())
            #expect(stored.tokenHash != session.refreshToken)
            #expect(stored.tokenHash == TokenService.hash(session.refreshToken))
        }
    }

    @Test("Logging out invalidates the refresh token")
    func logoutRevokes() async throws {
        try await withTestServer { context in
            let session = try await context.signIn(as: student)
            let logout = try await context.app.testing().sendRequest(
                .POST,
                API.Auth.logout.fullPath,
                beforeRequest: { try $0.content.encode(LogoutBody(refreshToken: session.refreshToken)) }
            )
            #expect(logout.status == .noContent)
            #expect(try await refresh(context, token: session.refreshToken).status == .unauthorized)
        }
    }

    @Test("Access tokens die with their session family, not with a rotation")
    func accessTokensFollowFamilyRevocation() async throws {
        try await withTestServer { context in
            let session = try await context.signIn(as: student)
            _ = try await refresh(context, token: session.refreshToken)

            let afterRotation = try await context.app.testing().sendRequest(
                .GET,
                API.Users.me.fullPath,
                headers: context.authorized(session.accessToken)
            )
            #expect(afterRotation.status == .ok)

            _ = try await refresh(context, token: session.refreshToken)

            let afterBreach = try await context.app.testing().sendRequest(
                .GET,
                API.Users.me.fullPath,
                headers: context.authorized(session.accessToken)
            )
            #expect(afterBreach.status == .unauthorized)
        }
    }

    @Test("Logging out immediately invalidates the access token too")
    func logoutInvalidatesAccessToken() async throws {
        try await withTestServer { context in
            let session = try await context.signIn(as: student)
            _ = try await context.app.testing().sendRequest(
                .POST,
                API.Auth.logout.fullPath,
                beforeRequest: { try $0.content.encode(LogoutBody(refreshToken: session.refreshToken)) }
            )

            let profile = try await context.app.testing().sendRequest(
                .GET,
                API.Users.me.fullPath,
                headers: context.authorized(session.accessToken)
            )
            #expect(profile.status == .unauthorized)
        }
    }

    @Test("Logging out an already dead token still answers 204")
    func logoutIsIdempotent() async throws {
        try await withTestServer { context in
            let logout = try await context.app.testing().sendRequest(
                .POST,
                API.Auth.logout.fullPath,
                beforeRequest: { try $0.content.encode(LogoutBody(refreshToken: "whatever")) }
            )
            #expect(logout.status == .noContent)
        }
    }

    @Test("The session list marks the caller's own session and revoking it works")
    func sessionsAreListedAndRevocable() async throws {
        try await withTestServer { context in
            let session = try await context.signIn(as: student)
            let listing = try await context.app.testing().sendRequest(
                .GET,
                API.Auth.sessions.fullPath,
                headers: context.authorized(session.accessToken)
            )
            #expect(listing.status == .ok)

            let sessions = try listing.content.decode([IBUgramKit.Session].self)
            #expect(sessions.count == 1)
            let current = try #require(sessions.first)
            #expect(current.isCurrent)

            let revoke = try await context.app.testing().sendRequest(
                .DELETE,
                API.Auth.revokeSession(id: current.id).fullPath,
                headers: context.authorized(session.accessToken)
            )
            #expect(revoke.status == .noContent)
            #expect(try await refresh(context, token: session.refreshToken).status == .unauthorized)
        }
    }

    @Test("Listing sessions without a token is unauthorized")
    func sessionsRequireAuthentication() async throws {
        try await withTestServer { context in
            let response = try await context.app.testing().sendRequest(.GET, API.Auth.sessions.fullPath)
            #expect(response.status == .unauthorized)
            #expect(response.apiError?.code == .unauthorized)
        }
    }

    @Test("A session belonging to somebody else cannot be revoked")
    func cannotRevokeAnotherAccountsSession() async throws {
        try await withTestServer { context in
            let mine = try await context.signIn(as: student)
            let theirs = try await context.signIn(as: "other.person@stu.ibu.edu.ba")
            let theirSessions = try await AuthSessionRecord.query(on: context.app.db)
                .filter(\.$user.$id == theirs.user.id)
                .all()
            let target = try #require(theirSessions.first?.id)

            let response = try await context.app.testing().sendRequest(
                .DELETE,
                API.Auth.revokeSession(id: target).fullPath,
                headers: context.authorized(mine.accessToken)
            )
            #expect(response.status == .notFound)
        }
    }
}
