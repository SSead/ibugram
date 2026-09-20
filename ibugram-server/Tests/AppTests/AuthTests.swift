import Fluent
import Foundation
import IBUgramKit
import Testing
import Vapor
import VaporTesting
@testable import App

@Suite("Authentication", .serialized)
struct AuthTests {
    private let student = "amina.hodzic@stu.ibu.edu.ba"
    private let faculty = "e.kovac@ibu.edu.ba"

    @Test("Requesting a code accepts a university address and sends exactly one code")
    func requestCodeSucceeds() async throws {
        try await withTestServer { context in
            let response = try await context.requestCode(for: student)
            #expect(response.status == .accepted)

            let payload = try response.content.decode(RequestCodeResponse.self)
            #expect(payload.resendAfter == 60)
            #expect(payload.expiresAt > Date())
            #expect(await context.codes.deliveryCount(for: student) == 1)
        }
    }

    @Test("A code is not issued to an address outside the university")
    func requestCodeRejectsForeignDomain() async throws {
        try await withTestServer { context in
            let response = try await context.requestCode(for: "someone@gmail.com")
            #expect(response.status == .forbidden)
            #expect(response.apiError?.code == .domainNotAllowed)
            #expect(await context.codes.deliveryCount(for: "someone@gmail.com") == 0)
        }
    }

    @Test("The response is the same shape whether or not the account already exists")
    func requestCodeDoesNotRevealExistence() async throws {
        try await withTestServer { context in
            _ = try await context.signIn(as: student)
            try await context.backdateChallenges(for: student, seconds: 120)

            let known = try await context.requestCode(for: student)
            let unknown = try await context.requestCode(for: "never.seen@stu.ibu.edu.ba")

            #expect(known.status == unknown.status)
            let first = try known.content.decode(RequestCodeResponse.self)
            let second = try unknown.content.decode(RequestCodeResponse.self)
            #expect(first.resendAfter == second.resendAfter)
            #expect(first.debugCode == nil)
            #expect(second.debugCode == nil)
        }
    }

    @Test("A second request inside the resend window is throttled")
    func requestCodeThrottlesBurst() async throws {
        try await withTestServer { context in
            #expect(try await context.requestCode(for: student).status == .accepted)
            let repeated = try await context.requestCode(for: student)
            #expect(repeated.status == .tooManyRequests)
            #expect(repeated.apiError?.code == .otpThrottled)
            #expect(await context.codes.deliveryCount(for: student) == 1)
        }
    }

    @Test("A sixth request within the hour is throttled even when spaced out")
    func requestCodeThrottlesHourly() async throws {
        try await withTestServer { context in
            for _ in 0..<IBUgram.otpHourlyLimit {
                #expect(try await context.requestCode(for: student).status == .accepted)
                try await context.backdateChallenges(for: student, seconds: 120)
            }
            let sixth = try await context.requestCode(for: student)
            #expect(sixth.status == .tooManyRequests)
            #expect(sixth.apiError?.code == .otpThrottled)
        }
    }

    @Test("Verifying the right code creates the account and returns a session")
    func verifyCreatesAccount() async throws {
        try await withTestServer { context in
            let session = try await context.signIn(as: student)
            #expect(session.needsOnboarding)
            #expect(session.user.role == .student)
            #expect(session.user.isVerified == false)
            #expect(session.expiresIn == 900)
            #expect(session.accessToken.split(separator: ".").count == 3)

            let stored = try await UserRecord.query(on: context.app.db)
                .filter(\.$email == student)
                .count()
            #expect(stored == 1)
        }
    }

    @Test("A staff address is given the faculty role and a verified badge")
    func facultyIsBadged() async throws {
        try await withTestServer { context in
            let session = try await context.signIn(as: faculty)
            #expect(session.user.role == .faculty)
            #expect(session.user.isVerified)
        }
    }

    @Test("The plaintext code is never stored")
    func codesAreHashedAtRest() async throws {
        try await withTestServer { context in
            _ = try await context.requestCode(for: student)
            let code = try #require(await context.codes.latestCode(for: student))
            let challenge = try #require(
                try await OTPChallengeRecord.query(on: context.app.db).first()
            )
            #expect(challenge.codeHash != code)
            #expect(challenge.codeHash.hasPrefix("$2"))
        }
    }

    @Test("A wrong code is rejected and counted")
    func wrongCodeIsRejected() async throws {
        try await withTestServer { context in
            _ = try await context.requestCode(for: student)
            let response = try await context.app.testing().sendRequest(
                .POST,
                API.Auth.verifyCode.fullPath,
                beforeRequest: { try $0.content.encode(VerifyCodeBody(email: student, code: "000000")) }
            )
            #expect(response.status == .badRequest)
            #expect(response.apiError?.code == .otpInvalid)

            let challenge = try #require(try await OTPChallengeRecord.query(on: context.app.db).first())
            #expect(challenge.attemptCount == 1)
        }
    }

    @Test("An expired code reports otp_expired rather than otp_invalid")
    func expiredCodeIsReported() async throws {
        try await withTestServer { context in
            _ = try await context.requestCode(for: student)
            let code = try #require(await context.codes.latestCode(for: student))
            try await context.expireChallenges(for: student)

            let response = try await context.app.testing().sendRequest(
                .POST,
                API.Auth.verifyCode.fullPath,
                beforeRequest: { try $0.content.encode(VerifyCodeBody(email: student, code: code)) }
            )
            #expect(response.status == .gone)
            #expect(response.apiError?.code == .otpExpired)
        }
    }

    @Test("Five wrong attempts burn the code even if the sixth attempt is correct")
    func attemptsAreCapped() async throws {
        try await withTestServer { context in
            _ = try await context.requestCode(for: student)
            let code = try #require(await context.codes.latestCode(for: student))

            for _ in 0..<IBUgram.otpMaxAttempts {
                let attempt = try await context.app.testing().sendRequest(
                    .POST,
                    API.Auth.verifyCode.fullPath,
                    beforeRequest: { try $0.content.encode(VerifyCodeBody(email: student, code: "000000")) }
                )
                #expect(attempt.apiError?.code == .otpInvalid)
            }

            let correct = try await context.app.testing().sendRequest(
                .POST,
                API.Auth.verifyCode.fullPath,
                beforeRequest: { try $0.content.encode(VerifyCodeBody(email: student, code: code)) }
            )
            #expect(correct.apiError?.code == .otpInvalid)
        }
    }

    @Test("A code can only be spent once")
    func codesAreSingleUse() async throws {
        try await withTestServer { context in
            _ = try await context.requestCode(for: student)
            let code = try #require(await context.codes.latestCode(for: student))
            let first = try await context.app.testing().sendRequest(
                .POST,
                API.Auth.verifyCode.fullPath,
                beforeRequest: { try $0.content.encode(VerifyCodeBody(email: student, code: code)) }
            )
            #expect(first.status == .ok)

            let replay = try await context.app.testing().sendRequest(
                .POST,
                API.Auth.verifyCode.fullPath,
                beforeRequest: { try $0.content.encode(VerifyCodeBody(email: student, code: code)) }
            )
            #expect(replay.apiError?.code == .otpInvalid)
        }
    }
}
