import Fluent
import Foundation
import IBUgramKit
import Testing
import Vapor
import VaporTesting
@testable import App

@Suite("Profile and onboarding", .serialized)
struct UserTests {
    private let student = "amina.hodzic@stu.ibu.edu.ba"

    @Test("The current user is returned for a valid token")
    func currentUserIsReturned() async throws {
        try await withTestServer { context in
            let session = try await context.signIn(as: student)
            let response = try await context.app.testing().sendRequest(
                .GET,
                API.Users.me.fullPath,
                headers: context.authorized(session.accessToken)
            )
            #expect(response.status == .ok)

            let user = try response.content.decode(IBUgramKit.User.self)
            #expect(user.id == session.user.id)
            #expect(user.username.hasPrefix(Username.reservedPrefix))
            #expect(user.displayName == "amina.hodzic")
        }
    }

    @Test("A missing or malformed token is rejected")
    func tokensAreRequired() async throws {
        try await withTestServer { context in
            let missing = try await context.app.testing().sendRequest(.GET, API.Users.me.fullPath)
            #expect(missing.status == .unauthorized)

            let garbage = try await context.app.testing().sendRequest(
                .GET,
                API.Users.me.fullPath,
                headers: context.authorized("not.a.jwt")
            )
            #expect(garbage.status == .unauthorized)
            #expect(garbage.apiError?.code == .unauthorized)
        }
    }

    @Test("Patching the profile stores the new values")
    func profileIsUpdated() async throws {
        try await withTestServer { context in
            let session = try await context.signIn(as: student)
            let response = try await context.app.testing().sendRequest(
                .PATCH,
                API.Users.updateMe.fullPath,
                headers: context.authorized(session.accessToken),
                beforeRequest: {
                    try $0.content.encode(UpdateProfileBody(
                        displayName: "Amina Hodžić",
                        bio: "Third-year software engineering.",
                        department: "Information Technologies",
                        yearOfStudy: 3
                    ))
                }
            )
            #expect(response.status == .ok)

            let user = try response.content.decode(IBUgramKit.User.self)
            #expect(user.displayName == "Amina Hodžić")
            #expect(user.yearOfStudy == 3)
            #expect(user.department == "Information Technologies")
        }
    }

    @Test("An out-of-range year of study is a validation failure")
    func profileValidationIsEnforced() async throws {
        try await withTestServer { context in
            let session = try await context.signIn(as: student)
            let response = try await context.app.testing().sendRequest(
                .PATCH,
                API.Users.updateMe.fullPath,
                headers: context.authorized(session.accessToken),
                beforeRequest: { try $0.content.encode(UpdateProfileBody(yearOfStudy: 99)) }
            )
            #expect(response.status == .unprocessableEntity)
            #expect(response.apiError?.code == .validationFailed)
        }
    }

    @Test("Claiming a username completes onboarding")
    func usernameCompletesOnboarding() async throws {
        try await withTestServer { context in
            let session = try await context.signIn(as: student)
            _ = try await context.app.testing().sendRequest(
                .PATCH,
                API.Users.updateMe.fullPath,
                headers: context.authorized(session.accessToken),
                beforeRequest: { try $0.content.encode(UpdateProfileBody(displayName: "Amina")) }
            )
            let response = try await context.app.testing().sendRequest(
                .POST,
                API.Users.setUsername.fullPath,
                headers: context.authorized(session.accessToken),
                beforeRequest: { try $0.content.encode(SetUsernameBody(username: "amina.h")) }
            )
            #expect(response.status == .ok)
            #expect(try response.content.decode(IBUgramKit.User.self).username == "amina.h")

            let refreshed = try await context.app.testing().sendRequest(
                .POST,
                API.Auth.refresh.fullPath,
                beforeRequest: { try $0.content.encode(RefreshTokenBody(refreshToken: session.refreshToken)) }
            )
            #expect(try refreshed.content.decode(AuthSession.self).needsOnboarding == false)
        }
    }

    @Test("A username already in use reports username_taken, case-insensitively")
    func usernamesAreUnique() async throws {
        try await withTestServer { context in
            let first = try await context.signIn(as: student)
            _ = try await context.app.testing().sendRequest(
                .POST,
                API.Users.setUsername.fullPath,
                headers: context.authorized(first.accessToken),
                beforeRequest: { try $0.content.encode(SetUsernameBody(username: "amina.h")) }
            )

            let second = try await context.signIn(as: "another.student@stu.ibu.edu.ba")
            let clash = try await context.app.testing().sendRequest(
                .POST,
                API.Users.setUsername.fullPath,
                headers: context.authorized(second.accessToken),
                beforeRequest: { try $0.content.encode(SetUsernameBody(username: "AMINA.H")) }
            )
            #expect(clash.status == .conflict)
            #expect(clash.apiError?.code == .usernameTaken)
        }
    }

    @Test("A username that breaks the naming rules is refused")
    func usernameRulesAreEnforced() async throws {
        try await withTestServer { context in
            let session = try await context.signIn(as: student)
            let response = try await context.app.testing().sendRequest(
                .POST,
                API.Users.setUsername.fullPath,
                headers: context.authorized(session.accessToken),
                beforeRequest: { try $0.content.encode(SetUsernameBody(username: "no")) }
            )
            #expect(response.status == .unprocessableEntity)
            #expect(response.apiError?.details["username"]?.stringValue == "tooShort")
        }
    }

    @Test("Claiming your own username again is not a conflict")
    func reclaimingOwnUsernameSucceeds() async throws {
        try await withTestServer { context in
            let session = try await context.signIn(as: student)
            for _ in 0..<2 {
                let response = try await context.app.testing().sendRequest(
                    .POST,
                    API.Users.setUsername.fullPath,
                    headers: context.authorized(session.accessToken),
                    beforeRequest: { try $0.content.encode(SetUsernameBody(username: "amina.h")) }
                )
                #expect(response.status == .ok)
            }
        }
    }
}
